# Design técnico — `SocketCommandDispatcher`

> Current socket/relay contract for Colmeia:
> [`../../plug_server_docs_index_for_colmeia.md`](../../plug_server_docs_index_for_colmeia.md)
> and [`../../bridge_agent_sql_api_options.md`](../../bridge_agent_sql_api_options.md).
> Progressive streaming in Colmeia is relay-only.

> Companheiro técnico de `docs/Features/socket_consumer_channel_plan.md` §6.5
> e de `docs/Features/agent_presence_realtime_design.md` §4.2.
> Detalha o **contrato de envio de comandos**, **correlação por id**,
> **timeout/idempotência**, **mapeamento de erros** e o
> **`Stream<AgentCommandOutcome>`** consumido pela presença em tempo real.
>
> Nenhum código de produção foi escrito ainda. Os blocos `dart` são
> **esqueletos normativos**.

---

## 1. Responsabilidade única (SRP)

`SocketCommandDispatcher` é responsável por:

1. Aceitar um body JSON-RPC já validado e enviá-lo via Socket.
2. Aguardar a **resposta correlacionada** (timeout configurável).
3. Retornar o `Map<String, dynamic>` no **mesmo formato** que o REST
   produz hoje (`AgentSqlBridgeResponse.parseSuccess` continua
   funcionando sem alteração).
4. Publicar **outcomes** (`Stream<AgentCommandOutcome>`) que terceiros
   (presença, métricas) podem assinar **sem** bloquear o caller.

**Não responde por:**

- Construir o body JSON-RPC (o `agent_sql_execute_request_to_bridge_body.dart`
  faz, compartilhado entre REST e Socket — ver plano principal §6.7).
- Conectar/desconectar o socket (delegado a `ConsumerSocketConnection`).
- Decidir entre REST e Socket (o switch fica na DI, plano principal §7).
- Tratar streaming **relay** (`relay:rpc.chunk` / `relay:rpc.complete`) — isso
  vive no `RelayCommandDispatcherImpl`.
- Consumir streaming **legado** `agents:command_stream_*` /
  `agents:stream_pull`: quando o hub devolve `stream_id` / `streamId` no
  `result` do primeiro `agents:command_response` (com ou sem linhas parciais),
  o dispatcher falha com `SocketDispatchLegacyStreamingUnsupported` — o
  cliente nao puxa chunks nesse canal e o wrapper de fallback nao converte esse
  erro em REST. Para consultas com streaming progressivo, use `useRelay: true`.

---

## 2. API pública

### 2.1 Interface

`lib/core/socket/socket_command_dispatcher.dart`

```dart
import 'dart:async';

/// Único ponto de envio de comandos `agents:command` no namespace
/// `/consumers`. Singleton via `get_it`.
abstract interface class SocketCommandDispatcher {
  /// Envia um body JSON-RPC e aguarda a resposta correlacionada.
  ///
  /// Contrato:
  /// - `body` deve ser exatamente o mesmo do REST
  ///   `POST /api/v1/agents/commands` (ver `agent_sql_execute_request_to_bridge_body.dart`).
  /// - `agentId` é repassado para roteamento de outcomes (não
  ///   precisa estar duplicado no body — virá do `body['agentId']`,
  ///   mas o caller também passa para evitar parsing nesta camada).
  /// - `rpcId` é o `command.id` JSON-RPC: deve ser **único** por
  ///   request; o dispatcher NÃO gera ids (responsabilidade do caller).
  /// - `timeout`: se nulo, usa `defaultTimeout` (ver implementação).
  ///
  /// Retorna o JSON normalizado (igual ao do REST). Em falha, lança:
  /// - `SocketDispatchException` (rede / timeout / decode).
  /// - `AgentSqlRpcException` (erros JSON-RPC do hub/agente; idêntico
  ///   ao path REST).
  Future<Map<String, dynamic>> sendAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  });

  /// Stream broadcast de outcomes de comandos. Cada chamada de
  /// `sendAgentsCommand` produz **exatamente um** outcome ao final.
  /// Usado pela camada de presença para gerar hints e por métricas.
  Stream<AgentCommandOutcome> outcomes();

  /// Encerra subscriptions internas. Idempotente.
  Future<void> dispose();
}
```

### 2.2 Outcomes

`lib/core/socket/agent_command_outcome.dart`

```dart
sealed class AgentCommandOutcome {
  const AgentCommandOutcome({
    required this.agentId,
    required this.rpcId,
    required this.observedAt,
    required this.elapsed,
  });

  final String agentId;

  /// Mesmo `command.id` JSON-RPC enviado pelo caller.
  final String rpcId;

  /// UTC quando o outcome foi observado.
  final DateTime observedAt;

  /// Tempo do envio até a observação (sucesso ou erro). Útil para
  /// histograma de latência por agente.
  final Duration elapsed;
}

/// Resposta `agents:command_response` chegou e foi correlacionada.
final class AgentCommandSuccess extends AgentCommandOutcome {
  const AgentCommandSuccess({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
  });
}

/// Erro indicando que o agente está offline / hub sem rota
/// (ex.: `AGENT_OFFLINE`, `protocol_not_ready`, `agent_not_found`).
/// **Sinaliza presença = offline** para o `AgentPresenceHinter`.
final class AgentCommandFailedOffline extends AgentCommandOutcome {
  const AgentCommandFailedOffline({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
    required this.reasonCode,
  });

  /// String exata do hub para logging/diagnóstico.
  final String reasonCode;
}

/// 401/403 / `AGENT_ACCESS_DENIED` — não diz nada sobre presença.
/// Hinter ignora; controller pode invalidar sessão se for 401.
final class AgentCommandFailedAuth extends AgentCommandOutcome {
  const AgentCommandFailedAuth({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
    required this.reasonCode,
  });

  final String reasonCode;
}

/// Timeout, decode falhou, socket caiu, rate-limit (`RATE_LIMITED`),
/// erro genérico do bridge. Não interpreta presença.
final class AgentCommandFailedTransient extends AgentCommandOutcome {
  const AgentCommandFailedTransient({
    required super.agentId,
    required super.rpcId,
    required super.observedAt,
    required super.elapsed,
    required this.reasonCode,
    this.cause,
  });

  final String reasonCode;
  final Object? cause;
}
```

> **Por que sealed:** o `AgentCommandPresenceHinter` faz `switch`
> exaustivo. Quando aparecer um novo tipo (ex.: `AgentCommandRateLimited`
> em Fase 2), o compilador força a tratar.

---

## 3. Exceções específicas

`lib/core/socket/socket_dispatch_exception.dart`

```dart
/// Falhas que **não** são erros JSON-RPC (esses já são representados
/// por `AgentSqlRpcException` no fluxo REST e devem ser lançados
/// idênticos pelo Socket).
sealed class SocketDispatchException implements Exception {
  const SocketDispatchException({
    required this.message,
    required this.code,
    this.cause,
    this.stackTrace,
  });

  final String message;
  final String code; // "timeout" | "disconnected" | "decode_failed" | "duplicate_id" | ...
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'SocketDispatchException($code): $message';
}

final class SocketDispatchTimeout extends SocketDispatchException {
  const SocketDispatchTimeout({required super.message, super.cause})
      : super(code: 'timeout');
}

final class SocketDispatchDisconnected extends SocketDispatchException {
  const SocketDispatchDisconnected({required super.message, super.cause})
      : super(code: 'disconnected');
}

final class SocketDispatchDecodeFailure extends SocketDispatchException {
  const SocketDispatchDecodeFailure({required super.message, super.cause})
      : super(code: 'decode_failed');
}

final class SocketDispatchDuplicateId extends SocketDispatchException {
  const SocketDispatchDuplicateId({required super.message})
      : super(code: 'duplicate_id');
}

final class SocketDispatchUnauthorized extends SocketDispatchException {
  const SocketDispatchUnauthorized({required super.message, super.cause})
      : super(code: 'unauthorized');
}
```

---

## 4. Correlator interno

`lib/core/socket/socket_request_correlator.dart`

```dart
import 'dart:async';

/// Gerencia o mapa `rpcId -> Completer`. Não conhece o socket.
/// Pode ser substituído em testes por uma versão fake.
class SocketRequestCorrelator {
  SocketRequestCorrelator({Duration sweepInterval = const Duration(minutes: 1)})
      : _sweepInterval = sweepInterval {
    _sweepTimer = Timer.periodic(_sweepInterval, (_) => _sweepStale());
  }

  final Duration _sweepInterval;
  Timer? _sweepTimer;

  final Map<String, _PendingRequest> _pending = <String, _PendingRequest>{};

  /// Registra um completer. Lança `SocketDispatchDuplicateId` se já
  /// houver outro pendente para o mesmo `rpcId`.
  Future<Map<String, dynamic>> register(
    String rpcId, {
    required Duration timeout,
  }) {
    if (_pending.containsKey(rpcId)) {
      throw SocketDispatchDuplicateId(
        message: 'rpcId already pending: $rpcId',
      );
    }
    final completer = Completer<Map<String, dynamic>>();
    final timer = Timer(timeout, () {
      final entry = _pending.remove(rpcId);
      entry?.completer.completeError(
        SocketDispatchTimeout(
          message: 'No response for rpcId=$rpcId after ${timeout.inSeconds}s',
        ),
      );
      entry?.timer.cancel();
    });
    _pending[rpcId] = _PendingRequest(
      completer: completer,
      timer: timer,
      registeredAt: DateTime.now(),
      timeout: timeout,
    );
    return completer.future;
  }

  /// Resolve a request com a resposta JSON normalizada.
  void completeWith(String rpcId, Map<String, dynamic> response) {
    final entry = _pending.remove(rpcId);
    if (entry == null) {
      // Late response (timeout já completou); descartar silenciosamente
      // — o caller já recebeu o erro.
      return;
    }
    entry.timer.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.complete(response);
    }
  }

  /// Resolve com erro (ex.: `app:error`).
  void failWith(String rpcId, Object error, [StackTrace? stack]) {
    final entry = _pending.remove(rpcId);
    if (entry == null) {
      return;
    }
    entry.timer.cancel();
    if (!entry.completer.isCompleted) {
      entry.completer.completeError(error, stack);
    }
  }

  /// Cancela TODAS as pendentes (ex.: socket caiu).
  void failAll(Object error, [StackTrace? stack]) {
    final entries = _pending.values.toList(growable: false);
    _pending.clear();
    for (final entry in entries) {
      entry.timer.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(error, stack);
      }
    }
  }

  Future<void> dispose() async {
    _sweepTimer?.cancel();
    _sweepTimer = null;
    failAll(
      const SocketDispatchDisconnected(message: 'correlator disposed'),
    );
  }

  /// Defesa em profundidade caso um Timer não tenha disparado por
  /// razão exótica (suspensão de relógio em background, etc).
  void _sweepStale() {
    final now = DateTime.now();
    final stale = <String>[];
    for (final entry in _pending.entries) {
      final age = now.difference(entry.value.registeredAt);
      if (age > entry.value.timeout * 2) {
        stale.add(entry.key);
      }
    }
    for (final id in stale) {
      failWith(
        id,
        SocketDispatchTimeout(
          message: 'Stale request swept: rpcId=$id',
        ),
      );
    }
  }
}

class _PendingRequest {
  _PendingRequest({
    required this.completer,
    required this.timer,
    required this.registeredAt,
    required this.timeout,
  });
  final Completer<Map<String, dynamic>> completer;
  final Timer timer;
  final DateTime registeredAt;
  final Duration timeout;
}
```

---

## 5. Implementação default

`lib/core/socket/socket_command_dispatcher_impl.dart`

```dart
import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_command_outcome.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_request_correlator.dart';
import 'package:colmeia/features/agent_queries/data/models/agent_sql_bridge_response.dart';

class SocketCommandDispatcherImpl implements SocketCommandDispatcher {
  SocketCommandDispatcherImpl({
    required ConsumerSocketConnection connection,
    required SocketRequestCorrelator correlator,
    Duration defaultTimeout = const Duration(seconds: 20),
  })  : _connection = connection,
        _correlator = correlator,
        _defaultTimeout = defaultTimeout,
        _outcomes = StreamController<AgentCommandOutcome>.broadcast() {
    _stateSub = _connection.states().listen(_onConnectionState);
  }

  final ConsumerSocketConnection _connection;
  final SocketRequestCorrelator _correlator;
  final Duration _defaultTimeout;
  final StreamController<AgentCommandOutcome> _outcomes;

  StreamSubscription<ConsumerSocketConnectionState>? _stateSub;
  bool _listenersAttached = false;
  bool _isDisposed = false;

  // Mapa para lookup de metadados (agentId, startTime) ao receber
  // resposta correlacionada — permite construir outcomes ricos.
  final Map<String, _PendingMeta> _meta = <String, _PendingMeta>{};

  @override
  Stream<AgentCommandOutcome> outcomes() => _outcomes.stream;

  @override
  Future<Map<String, dynamic>> sendAgentsCommand({
    required String agentId,
    required Map<String, Object?> body,
    required String rpcId,
    Duration? timeout,
  }) async {
    if (_isDisposed) {
      throw const SocketDispatchDisconnected(
        message: 'Dispatcher disposed',
      );
    }

    // Garante conexão ativa (single-flight no ConsumerSocketConnection).
    try {
      await _connection.connect();
    } on StateError catch (e, s) {
      throw SocketDispatchUnauthorized(
        message: 'Cannot connect: $e',
        cause: e,
      );
    } on Object catch (e, s) {
      throw SocketDispatchDisconnected(
        message: 'Connect failed before dispatch: $e',
        cause: e,
      );
    }

    _ensureListenersAttached();

    final effectiveTimeout = timeout ?? _defaultTimeout;
    final stopwatch = Stopwatch()..start();
    _meta[rpcId] = _PendingMeta(agentId: agentId, stopwatch: stopwatch);

    Future<Map<String, dynamic>> pending;
    try {
      pending = _correlator.register(rpcId, timeout: effectiveTimeout);
    } on SocketDispatchDuplicateId catch (e) {
      _meta.remove(rpcId);
      _emitTransient(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: Duration.zero,
        reasonCode: 'duplicate_id',
        cause: e,
      );
      rethrow;
    }

    try {
      _connection.raw.emit('agents:command', body);
    } on Object catch (e, s) {
      _correlator.failWith(rpcId, e, s);
      _meta.remove(rpcId);
      _emitTransient(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: stopwatch.elapsed,
        reasonCode: 'emit_failed',
        cause: e,
      );
      throw SocketDispatchDisconnected(
        message: 'emit failed: $e',
        cause: e,
        stackTrace: s,
      );
    }

    try {
      final response = await pending;
      stopwatch.stop();
      _meta.remove(rpcId);

      // Reaproveita o parser do REST. Se for erro JSON-RPC,
      // AgentSqlBridgeResponse lança AgentSqlRpcException — vamos
      // emitir outcome offline/auth conforme o `code` antes de relançar.
      try {
        AgentSqlBridgeResponse.parseSuccess(response);
        _outcomes.add(AgentCommandSuccess(
          agentId: agentId,
          rpcId: rpcId,
          observedAt: DateTime.now().toUtc(),
          elapsed: stopwatch.elapsed,
        ));
        return response;
      } on AgentSqlRpcException catch (rpcError) {
        _emitOutcomeFromRpcError(
          agentId: agentId,
          rpcId: rpcId,
          elapsed: stopwatch.elapsed,
          rpcError: rpcError,
        );
        rethrow;
      }
    } on SocketDispatchException catch (e) {
      stopwatch.stop();
      _meta.remove(rpcId);
      _emitTransient(
        agentId: agentId,
        rpcId: rpcId,
        elapsed: stopwatch.elapsed,
        reasonCode: e.code,
        cause: e.cause ?? e,
      );
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    await _stateSub?.cancel();
    _stateSub = null;
    if (_listenersAttached) {
      try {
        _connection.raw
          ..off('agents:command_response')
          ..off('app:error');
      } on StateError catch (_) {
        // raw pode estar inválido se a conexão já caiu.
      }
      _listenersAttached = false;
    }
    await _correlator.dispose();
    if (!_outcomes.isClosed) {
      await _outcomes.close();
    }
    _meta.clear();
  }

  // ----- Internals -----

  void _ensureListenersAttached() {
    if (_listenersAttached) {
      return;
    }
    _listenersAttached = true;
    _connection.raw
      ..on('agents:command_response', _onCommandResponse)
      ..on('app:error', _onAppError);
  }

  void _onCommandResponse(Object? raw) {
    if (raw is! Map) {
      AppLogger.warning(
        'agents:command_response was not a Map',
        context: const <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
        },
      );
      return;
    }
    final map = raw.cast<String, dynamic>();
    final rpcId = _extractRpcId(map);
    if (rpcId == null) {
      AppLogger.warning(
        'agents:command_response missing rpcId',
        context: const <String, Object?>{
          'component': 'SocketCommandDispatcherImpl',
        },
      );
      return;
    }
    _correlator.completeWith(rpcId, map);
  }

  void _onAppError(Object? raw) {
    if (raw is! Map) {
      return;
    }
    final map = raw.cast<String, dynamic>();
    final rpcId = _extractRpcId(map);
    final code = (map['code'] as Object?)?.toString() ?? 'app_error';
    final message = (map['message'] as Object?)?.toString() ?? code;

    if (rpcId != null) {
      _correlator.failWith(
        rpcId,
        SocketDispatchException._appError(code: code, message: message),
      );
      return;
    }
    // Erro global (ex.: SERVICE_UNAVAILABLE em overload). Falha tudo.
    _correlator.failAll(
      SocketDispatchException._appError(code: code, message: message),
    );
  }

  void _onConnectionState(ConsumerSocketConnectionState state) {
    switch (state) {
      case ConsumerSocketDisconnected():
      case ConsumerSocketError():
      case ConsumerSocketUnauthorized():
        _correlator.failAll(
          const SocketDispatchDisconnected(
            message: 'Socket disconnected during request',
          ),
        );
      default:
        break;
    }
  }

  String? _extractRpcId(Map<String, dynamic> map) {
    // Hub envelope: a resposta tem `requestId`/`response.item.id` ou
    // `command.id`. Tentamos os candidatos conhecidos.
    final candidates = <Object?>[
      map['rpcId'],
      map['requestId'],
      _read(map, const ['response', 'item', 'id']),
      _read(map, const ['command', 'id']),
    ];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) {
        return c;
      }
    }
    return null;
  }

  Object? _read(Map<String, dynamic> map, List<String> path) {
    Object? current = map;
    for (final key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  void _emitOutcomeFromRpcError({
    required String agentId,
    required String rpcId,
    required Duration elapsed,
    required AgentSqlRpcException rpcError,
  }) {
    final code = rpcError.details.code;
    final reason = rpcError.details.reason ?? 'rpc_error';
    final now = DateTime.now().toUtc();

    if (_isOfflineCode(code, reason)) {
      _outcomes.add(AgentCommandFailedOffline(
        agentId: agentId,
        rpcId: rpcId,
        observedAt: now,
        elapsed: elapsed,
        reasonCode: '$code/$reason',
      ));
      return;
    }
    if (_isAuthCode(code, reason)) {
      _outcomes.add(AgentCommandFailedAuth(
        agentId: agentId,
        rpcId: rpcId,
        observedAt: now,
        elapsed: elapsed,
        reasonCode: '$code/$reason',
      ));
      return;
    }
    _outcomes.add(AgentCommandFailedTransient(
      agentId: agentId,
      rpcId: rpcId,
      observedAt: now,
      elapsed: elapsed,
      reasonCode: '$code/$reason',
      cause: rpcError,
    ));
  }

  void _emitTransient({
    required String agentId,
    required String rpcId,
    required Duration elapsed,
    required String reasonCode,
    Object? cause,
  }) {
    _outcomes.add(AgentCommandFailedTransient(
      agentId: agentId,
      rpcId: rpcId,
      observedAt: DateTime.now().toUtc(),
      elapsed: elapsed,
      reasonCode: reasonCode,
      cause: cause,
    ));
  }

  // Catalog of offline-like codes/reasons (alinhado a
  // `plug_server/docs/api_rest_bridge.md` e `socket_relay_protocol.md`).
  bool _isOfflineCode(int? code, String? reason) {
    if (reason == null) return false;
    const offlineReasons = <String>{
      'agent_offline',
      'protocol_not_ready',
      'agent_not_found',
      'agent_unreachable',
      'circuit_open',
    };
    return offlineReasons.contains(reason.toLowerCase());
  }

  bool _isAuthCode(int? code, String? reason) {
    if (code == -32001 || code == -32002) {
      return true; // catálogo do hub
    }
    if (reason == null) return false;
    const authReasons = <String>{
      'unauthorized',
      'authentication_failed',
      'agent_access_denied',
      'token_revoked',
      'missing_client_token',
    };
    return authReasons.contains(reason.toLowerCase());
  }
}

class _PendingMeta {
  _PendingMeta({required this.agentId, required this.stopwatch});
  final String agentId;
  final Stopwatch stopwatch;
}

// Helper de fábrica interna; SocketDispatchException é sealed mas
// queremos uma forma "padrão" para mapear erros do servidor sem
// criar mais subclasses.
extension on SocketDispatchException {
  static SocketDispatchException _appError({
    required String code,
    required String message,
  }) {
    return _AppErrorDispatchException(code: code, message: message);
  }
}

final class _AppErrorDispatchException extends SocketDispatchException {
  const _AppErrorDispatchException({
    required String code,
    required String message,
  }) : super(message: message, code: code);
}
```

> Observação: `_AppErrorDispatchException` é privado; vaza só o
> contrato sealed `SocketDispatchException`. Em testes, validamos
> só `e.code == 'AGENT_ACCESS_DENIED'`.

---

## 6. Datasource Socket de `agent_queries`

`lib/features/agent_queries/data/datasources/socket_agent_queries_remote_datasource.dart`

```dart
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_execute_request_to_bridge_body.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:uuid/uuid.dart';

class SocketAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  SocketAgentQueriesRemoteDataSource({
    required SocketCommandDispatcher dispatcher,
    required AgentSqlExecuteRequestToBridgeBody bodyMapper,
  })  : _dispatcher = dispatcher,
        _bodyMapper = bodyMapper;

  final SocketCommandDispatcher _dispatcher;
  final AgentSqlExecuteRequestToBridgeBody _bodyMapper;
  static const Uuid _uuid = Uuid();

  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) async {
    final rpcId = _uuid.v4();
    final body = _bodyMapper.build(request: request, rpcId: rpcId);
    return _dispatcher.sendAgentsCommand(
      agentId: request.trimmedAgentId,
      body: body,
      rpcId: rpcId,
      timeout: _resolveTimeout(request),
    );
  }

  Duration _resolveTimeout(AgentSqlExecuteRequest request) {
    final base = request.bridgeTimeoutMs ?? 15000;
    return Duration(milliseconds: base + 5000);
  }
}
```

> A factory de body é a **mesma** usada por
> `ApiAgentQueriesRemoteDataSource` no plano principal §6.7. Garante
> paridade byte-a-byte do payload.

---

## 7. Mapeamento Socket → `AppFailure` no repository

O `AgentQueriesRepositoryImpl` **não muda**, mas precisa ganhar dois
catches novos no mesmo padrão dos existentes:

```dart
// Antes do catch genérico Object:
} on SocketDispatchUnauthorized catch (error, stackTrace) {
  return Failure(SessionFailure(
    message: error.message,
    userMessage: 'Sua sessão expirou. Faça login novamente.',
    cause: error,
    stackTrace: stackTrace,
    context: <String, Object?>{
      'operation': 'executeAgentSql',
      'agentId': request.trimmedAgentId,
      'transport': 'socket',
    },
  ));
} on SocketDispatchException catch (error, stackTrace) {
  return Failure(NetworkFailure(
    message: error.message,
    userMessage: 'Falha de comunicação com o servidor. Tente novamente.',
    cause: error,
    stackTrace: stackTrace,
    context: <String, Object?>{
      'operation': 'executeAgentSql',
      'agentId': request.trimmedAgentId,
      'transport': 'socket',
      'socketCode': error.code,
    },
  ));
}
```

> `AgentSqlRpcException` continua caindo no catch existente
> (compartilhado com REST). `FormatException` idem.

---

## 8. DI

`lib/core/di/injector_socket.dart` (delta sobre o esqueleto do plano §9.1):

```dart
getIt
  ..registerLazySingleton<SocketRequestCorrelator>(
    SocketRequestCorrelator.new,
    dispose: (c) => c.dispose(),
  )
  ..registerLazySingleton<SocketCommandDispatcher>(
    () => SocketCommandDispatcherImpl(
      connection: getIt<ConsumerSocketConnection>(),
      correlator: getIt<SocketRequestCorrelator>(),
    ),
    dispose: (d) => d.dispose(),
  );
```

E no `injector_agent_queries.dart` o registro do datasource passa a:

```dart
getIt.registerLazySingleton<AgentQueriesRemoteDataSource>(() {
  if (AppEnvironment.useFakeBackend) {
    return FakeAgentQueriesRemoteDataSource();
  }
  return switch (AppEnvironment.agentBridgeTransport) {
    AgentBridgeTransport.socket => SocketAgentQueriesRemoteDataSource(
      dispatcher: getIt<SocketCommandDispatcher>(),
      bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
    ),
    AgentBridgeTransport.rest => ApiAgentQueriesRemoteDataSource(
      dio: getIt<Dio>(),
      bodyMapper: getIt<AgentSqlExecuteRequestToBridgeBody>(),
    ),
  };
});
```

E:

```dart
getIt.registerLazySingleton<AgentSqlExecuteRequestToBridgeBody>(
  AgentSqlExecuteRequestToBridgeBody.new,
);
```

---

## 9. Casos de borda

| #   | Cenário                                                   | Comportamento esperado                                                                                                             |
| --- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `sendAgentsCommand` chamado antes do `connect()`          | Dispatcher chama `_connection.connect()` (single-flight).                                                                          |
| 2   | Socket cai durante request pendente                       | `_correlator.failAll(SocketDispatchDisconnected)`; outcome `Transient(reason: disconnected)`.                                      |
| 3   | Timeout antes da resposta                                 | `SocketDispatchTimeout` → outcome `Transient(reason: timeout)`.                                                                    |
| 4   | Resposta chega DEPOIS do timeout                          | `_correlator.completeWith` é no-op silencioso (entry não existe). Log `info`.                                                      |
| 5   | Dois `sendAgentsCommand` com mesmo `rpcId`                | Segundo lança `SocketDispatchDuplicateId` síncrono.                                                                                |
| 6   | `app:error` global (sem rpcId)                            | `failAll`; todos os outcomes ficam `Transient(reason: <code do app:error>)`.                                                       |
| 7   | `app:error` com `code: AGENT_ACCESS_DENIED` para um rpcId | Outcome `FailedAuth`; repository mapeia para `AuthorizationFailure`.                                                               |
| 8   | Resposta com erro JSON-RPC `agent_offline`                | `parseSuccess` lança `AgentSqlRpcException`; outcome `FailedOffline`; repository mapeia para `RpcFailure(retryable: …)` como hoje. |
| 9   | `dispose()` durante request pendente                      | `failAll(SocketDispatchDisconnected('correlator disposed'))`; pendente recebe erro.                                                |
| 10  | Resposta com `requestId` ausente                          | Log `warning` e descarta; o caller bate em timeout.                                                                                |
| 11  | Rate-limit `RATE_LIMITED`                                 | Tratado como `Transient(reason: 'rate_limited')`; repository devolve `NetworkFailure(isTransient: true)`.                          |
| 12  | App em background (`pause`) interrompe pendente           | Mesmo cenário 2; `resume()` reabre o socket; cliente precisa **reenviar**.                                                         |

---

## 10. Plano de testes

### 10.1 Unit — correlator

`test/core/socket/socket_request_correlator_test.dart`

- Registro + `completeWith` resolve completer.
- Registro + timeout completa com `SocketDispatchTimeout`.
- `failWith` resolve com erro custom.
- `failAll` cancela todos pendentes.
- Registro duplicado lança `SocketDispatchDuplicateId`.
- Sweep stale: timer fake (`fake_async`) avança >2× timeout sem disparo do
  Timer original (simulando background); sweep limpa.

### 10.2 Unit — dispatcher

`test/core/socket/socket_command_dispatcher_impl_test.dart`

- Usa `FakeConsumerSocketConnection` (interface mínima) e
  `FakeSocketRequestCorrelator`.
- Cobertura:
  - Happy path: `sendAgentsCommand` emite `agents:command`,
    correlator resolve, retorna Map, outcome `Success`.
  - Resposta com erro JSON-RPC `agent_offline` → outcome `FailedOffline`
    - `AgentSqlRpcException` propagada.
  - Resposta com `app:error` `AGENT_ACCESS_DENIED` → outcome `FailedAuth`
    - `SocketDispatchException` propagada.
  - Timeout → outcome `Transient(reason: timeout)` + `SocketDispatchTimeout`.
  - Disconnect durante request → outcome `Transient(reason: disconnected)`.
  - Duplicate id → `SocketDispatchDuplicateId` síncrona, outcome
    `Transient(reason: duplicate_id)`.
  - `dispose()` cancela pendentes e fecha o stream `outcomes`.

### 10.3 Contract test — body parity REST vs Socket

`test/features/agent_queries/data/agent_sql_execute_request_to_bridge_body_test.dart`

- Para um `AgentSqlExecuteRequest` parametrizado (with/without
  pagination, with/without options), o body emitido é **igual** ao
  body que `ApiAgentQueriesRemoteDataSource` historicamente enviava
  (snapshot).

### 10.4 Datasource

`test/features/agent_queries/data/datasources/socket_agent_queries_remote_datasource_test.dart`

- Body emitido casa com o esperado (mesmas regras de hoje).
- Map retornado é repassado intacto ao chamador.
- Erros do dispatcher propagam.

### 10.5 Repository

`test/features/agent_queries/data/repositories/agent_queries_repository_impl_socket_failures_test.dart`

- `SocketDispatchUnauthorized` → `SessionFailure`.
- `SocketDispatchException(code: ...)` → `NetworkFailure` com `socketCode` no contexto.
- `AgentSqlRpcException` continua produzindo `RpcFailure` (sem regressão).

### 10.6 Integração (opt-in)

`test/integration/e2e/agent_queries_socket_e2e_test.dart`

- Login REST + socket conectado.
- Executa um `sql.execute` simples e compara `row_count` com a
  mesma query via REST (mesmo agentId / token).
- Asserta que o `outcomes()` emitiu `AgentCommandSuccess` com
  `elapsed > 0`.

---

## 11. Métricas e logging

| Evento                     | Nível     | `component`                   | Campos extras                        |
| -------------------------- | --------- | ----------------------------- | ------------------------------------ |
| Send iniciado              | `debug`   | `SocketCommandDispatcherImpl` | `agentId`, `rpcId`, `timeoutMs`      |
| Outcome Success            | `info`    | `SocketCommandDispatcherImpl` | `agentId`, `rpcId`, `elapsedMs`      |
| Outcome FailedOffline      | `info`    | `SocketCommandDispatcherImpl` | `agentId`, `rpcId`, `reasonCode`     |
| Outcome FailedAuth         | `warning` | `SocketCommandDispatcherImpl` | `agentId`, `reasonCode`              |
| Outcome Transient          | `warning` | `SocketCommandDispatcherImpl` | `agentId`, `reasonCode`, `elapsedMs` |
| Resposta sem rpcId         | `warning` | `SocketCommandDispatcherImpl` | `responseKeys` (sem dados sensíveis) |
| Late response (descartada) | `info`    | `SocketRequestCorrelator`     | `rpcId`                              |

> **Nunca** logar `command.params.sql` em produção (pode conter
> dados de usuário). Logar somente `agentId`, contagem de params
> e `rpcId`.

---

## 12. Critérios de aceite

1. `core/socket/` não importa `features/agent_queries/` (port `agent_sql_bridge_response.dart` deve ser **promovido** para um lugar compartilhado se necessário; ver "Pontos abertos"). Alternativa: o repository injeta um `SocketResponseValidator` no dispatcher para chamar `parseSuccess`. Decidir antes da PR.
2. Cobertura ≥ 90% em `correlator`, `dispatcher`, exceções e datasource.
3. `flutter analyze` limpo.
4. Single-flight do `connect()` é honrado (já garantido em `ConsumerSocketConnection`).
5. Body do Socket é byte-igual ao do REST para as queries do
   `agent_queries` (snapshot test).
6. Sem regressão em `test/features/agent_queries/data/...`.

---

## 13. Pontos abertos (decidir antes da PR)

1. **Local de `AgentSqlBridgeResponse.parseSuccess`**: hoje vive em
   `features/agent_queries/data/models/`. Para o dispatcher usar sem
   importar a feature, opções:
   - **(a)** Mover `parseSuccess` para `core/network/jsonrpc/` como
     função pura (recomendado — desacopla de feature).
   - **(b)** Receber `bool Function(Map) isSuccess` por construtor
     (testes simples; mas dispatch fica menos opinionated).
   - **(c)** Não chamar `parseSuccess` no dispatcher; deixar repository
     fazer e dispatcher só emite outcomes a partir de `app:error` /
     timeout / disconnect (sem distinguir `FailedOffline`).
     Sugestão: **(a)** com função top-level `parseAgentSqlBridgeResponse`
     exportada de `core/network/jsonrpc/agent_sql_bridge_response.dart`.

2. **`hub_instance_id` em `AgentCommandOutcome`**: útil para diagnóstico
   multi-réplica. Adicionar campo opcional?

3. **Backpressure de outcomes**: `StreamController.broadcast()` sem
   buffer; consumidores lentos perdem eventos? Para presença não é
   problema (último estado vence). Para métricas, considerar buffer.

4. **Renomear `AgentCommandFailedOffline` → `AgentCommandReportedOffline`**?
   Discussão de nomenclatura — não bloqueia.

---

## 14. Referências cruzadas

- Plano executivo: `docs/Features/socket_consumer_channel_plan.md` (§6.5).
- Conexão: `docs/Features/consumer_socket_connection_design.md`.
- Presença: `docs/Features/agent_presence_realtime_design.md` (§4.2).
- Hub:
  - `plug_server/docs/api_rest_bridge.md` (§"Agente direto" e tabela
    de códigos JSON-RPC `-32001`/`-32002`).
  - `plug_server/docs/socket_client_sdk.md` (§"Bridge de comandos
    `agents:command`").
  - `plug_server/docs/socket_relay_protocol.md` (Fase 2: `relay:*`).
- Falhas internas: `lib/core/errors/app_failure.dart` (matriz de
  mapeamento usada no repository).
