# Design técnico — `ConsumerSocketConnection`

> Companheiro técnico de `docs/Features/socket_consumer_channel_plan.md` §6.2.
> Este documento detalha **estado**, **lifecycle**, **handshake**,
> **autenticação**, **reconexão** e **integração com o app lifecycle**
> da conexão única do app Colmeia ao namespace `/consumers` do hub
> `plug_server`.
>
> Nenhum código de produção foi escrito ainda. Os blocos `dart` são
> **esqueletos normativos** — a implementação deve seguir literalmente
> as assinaturas e contratos descritos.

---

## 1. Responsabilidade única (SRP)

`ConsumerSocketConnection` é responsável **somente** por:

1. Manter, no máximo, **uma** instância de `IO.Socket` apontada para
   `<apiBaseUrl>/consumers`.
2. Conduzir o handshake (com JWT atual) e confirmar `connection:ready`.
3. Expor o **estado** observável da conexão (`Stream` + getter sync).
4. Aplicar a política de reconexão controlada com **single-flight**
   (evita reconexões em paralelo).
5. Em `connect_error` 401-like: pedir `AuthRefreshCoordinator.refreshAccessToken()`
   e reconectar **uma vez**; em falha, sinalizar
   `AuthSessionEvents.notifyInvalidated()`.
6. Reagir a `AuthSessionEvents.invalidated` desconectando.
7. Liberar todos os recursos em `dispose()`.

**Não responde por:**

- Envio de RPC (é do `SocketCommandDispatcher` — doc próprio).
- Decode/validação de payloads de domínio (é dos _listeners_ específicos).
- Gating por visibilidade de tela (é do controller de feature).
- Reconnect em transições de foreground/background (delegado ao app
  shell que chama `pause()`/`resume()`).

---

## 2. Estado público

`lib/core/socket/consumer_socket_connection_state.dart`

```dart
/// Estado de alto nível da conexão única ao namespace /consumers.
///
/// Transições válidas:
///   disconnected -> connecting
///   connecting   -> connected   (após connection:ready)
///   connecting   -> error       (handshake/connect_error fora de auth)
///   connecting   -> unauthorized (connect_error 401-like sem refresh)
///   connected    -> disconnected (disconnect manual / AuthSessionEvents)
///   connected    -> error       (server-side disconnect com motivo de erro)
///   error        -> connecting  (retry pelo policy)
///   unauthorized -> disconnected (sempre terminal; novo login = nova instância)
sealed class ConsumerSocketConnectionState {
  const ConsumerSocketConnectionState();
}

final class ConsumerSocketDisconnected extends ConsumerSocketConnectionState {
  const ConsumerSocketDisconnected({this.reason});
  final String? reason;
}

final class ConsumerSocketConnecting extends ConsumerSocketConnectionState {
  const ConsumerSocketConnecting({required this.attempt});
  final int attempt; // 1-based
}

final class ConsumerSocketConnected extends ConsumerSocketConnectionState {
  const ConsumerSocketConnected({
    required this.socketId,
    required this.handshakeAt,
    this.hubInstanceId,
  });
  final String socketId;
  final DateTime handshakeAt;
  final String? hubInstanceId;
}

final class ConsumerSocketError extends ConsumerSocketConnectionState {
  const ConsumerSocketError({
    required this.message,
    required this.transient,
    this.cause,
    this.stackTrace,
  });
  final String message;
  final bool transient;
  final Object? cause;
  final StackTrace? stackTrace;
}

/// 401/403 no handshake **após** uma tentativa de refresh já ter
/// falhado. Estado terminal: requer novo login.
final class ConsumerSocketUnauthorized extends ConsumerSocketConnectionState {
  const ConsumerSocketUnauthorized();
}
```

**Por que sealed em vez de enum:** carregamos contexto operacional
(reason, socketId, hubInstanceId, attempt) sem inventar parâmetros
opcionais soltos. UI e logs lêem por `switch` exaustivo.

---

## 3. URL e namespace

`lib/core/socket/app_socket_url_resolver.dart`

```dart
import 'package:colmeia/core/network/app_dio_client.dart';

/// Converte `apiBaseUrl` (ex.: https://hub.example.com/api/v1) para
/// a URL Socket.IO sem o prefixo /api/v1, e devolve a parte do
/// **namespace** /consumers separadamente.
class AppSocketUrlResolver {
  AppSocketUrlResolver(this._rawApiBaseUrl);

  final String _rawApiBaseUrl;
  static const String _namespace = '/consumers';

  String get _normalizedApiBase =>
      AppDioClient.normalizeBaseUrl(_rawApiBaseUrl);

  /// URL completa para `IO.io('<host>/consumers', ...)`.
  ///
  /// - Mantém o scheme original (https → wss negociado pelo socket.io;
  ///   socket.io aceita https/http e usa websocket por baixo).
  /// - Remove o segmento `/api/v1` (o servidor expõe socket.io na raiz).
  String get consumersUrl {
    final uri = Uri.parse(_normalizedApiBase);
    final stripped = uri.replace(path: '');
    return '$stripped$_namespace';
  }

  /// Origin (sem path/namespace), útil para logs e métricas.
  String get hubOrigin {
    final uri = Uri.parse(_normalizedApiBase);
    return uri.replace(path: '').toString();
  }

  String get namespace => _namespace;
}
```

> Observação: o nginx de produção do hub roteia WebSocket sem o
> prefixo `/api/v1` — confirmar com `plug_server/docs/nginx_production.md`.
> Em ambiente de desenvolvimento local com porta diferente, usar
> `API_BASE_URL` apontando para a porta do hub raiz.

---

## 4. Token provider (port)

`lib/core/socket/socket_auth_token_provider.dart`

```dart
abstract interface class SocketAuthTokenProvider {
  /// Devolve o access token corrente ou `null` se não há sessão.
  /// Não dispara refresh.
  Future<String?> readAccessToken();

  /// Faz o single-flight do refresh (delegado ao
  /// `AuthRefreshCoordinator`). Retorna o novo access token ou
  /// `null` se a sessão deve ser invalidada.
  Future<String?> refreshAccessToken();

  /// Stream `broadcast` que dispara quando a sessão foi invalidada
  /// fora do socket (ex.: logout pelo router). Implementação típica
  /// reaproveita `AuthSessionEvents.stream`.
  Stream<void> sessionInvalidations();
}
```

Implementação default (em `data/`, embora o port viva em `core/socket/`
para não acoplar `core/socket/` a `features/auth/`):

```dart
class SessionSocketAuthTokenProvider implements SocketAuthTokenProvider {
  SessionSocketAuthTokenProvider({
    required AuthSessionAccessor sessionAccessor,
    required AuthRefreshCoordinator refreshCoordinator,
    required AuthSessionEvents sessionEvents,
  })  : _sessionAccessor = sessionAccessor,
        _refreshCoordinator = refreshCoordinator,
        _sessionEvents = sessionEvents;

  final AuthSessionAccessor _sessionAccessor;
  final AuthRefreshCoordinator _refreshCoordinator;
  final AuthSessionEvents _sessionEvents;

  @override
  Future<String?> readAccessToken() async {
    final session = await _sessionAccessor.read();
    return session?.accessToken;
  }

  @override
  Future<String?> refreshAccessToken() {
    return _refreshCoordinator.refreshAccessToken();
  }

  @override
  Stream<void> sessionInvalidations() => _sessionEvents.stream
      .where((e) => e.type == AuthSessionEventType.invalidated)
      .map((_) => null);
}
```

---

## 5. Factory do `IO.Socket`

`lib/core/socket/socket_io_client_factory.dart`

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Encapsula a criação do socket. Expor uma factory permite mockar
/// em testes sem precisar de `IO.io(...)` real.
abstract interface class SocketIoClientFactory {
  IO.Socket create({
    required String url,
    required String accessToken,
  });
}

class DefaultSocketIoClientFactory implements SocketIoClientFactory {
  @override
  IO.Socket create({
    required String url,
    required String accessToken,
  }) {
    return IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          // Reconexão controlada pela ConsumerSocketConnection;
          // socket.io tenta reconectar sozinho, mas no auth-fail
          // queremos parar e refrescar token nós mesmos.
          .disableReconnection()
          .setAuth(<String, dynamic>{'token': accessToken})
          .build(),
    );
  }
}
```

> `disableReconnection()`: a reconexão automática nativa do `socket.io`
> não passa por `refreshAccessToken()`. Preferimos uma policy explícita
> em `ConsumerSocketConnection.reconnect()` controlando timing e
> número máximo de tentativas. Reduz superfície de bugs na auth.

---

## 6. Decoder mínimo de `connection:ready`

`lib/core/socket/connection_ready_payload.dart`

```dart
/// Suporta os dois formatos do hub (raw JSON legado + PayloadFrame).
/// Detalhe real de PayloadFrame fica em `core/socket/payload_frame.dart`
/// (Fase 2 do plano principal).
class ConnectionReadyPayload {
  const ConnectionReadyPayload({
    required this.socketId,
    required this.message,
    required this.userClaims,
    this.hubInstanceId,
  });

  final String socketId;
  final String message;
  final Map<String, Object?> userClaims;
  final String? hubInstanceId;
}

abstract interface class ConnectionReadyDecoder {
  /// Aceita Map (raw JSON), Map com formato PayloadFrame, ou String
  /// (base64 dentro do PayloadFrame). Retorna `null` quando não puder
  /// ser interpretado — chamadores tratam como erro de handshake.
  ConnectionReadyPayload? decode(Object? raw);
}
```

A implementação default tenta JSON puro primeiro (Fase 1) e cai para
`PayloadFrameDecoder` se encontrar `enc`/`cmp`/`payload` no envelope
(Fase 2). Estratégia tolerante: enquanto o flag
`SOCKET_CONNECTION_READY_COMPAT_MODE` ainda não terminou (após
`2026-09-30`), os dois formatos coexistem.

---

## 7. API pública da conexão

`lib/core/socket/consumer_socket_connection.dart`

```dart
import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Única conexão Socket.IO `/consumers` viva no app.
/// Singleton via `get_it` (lazy). Não criar instâncias avulsas.
class ConsumerSocketConnection {
  ConsumerSocketConnection({
    required AppSocketUrlResolver urlResolver,
    required SocketAuthTokenProvider tokenProvider,
    required SocketIoClientFactory factory,
    required ConnectionReadyDecoder readyDecoder,
    Duration handshakeTimeout = const Duration(seconds: 10),
    int maxReconnectAttempts = 5,
    Duration reconnectInitialDelay = const Duration(seconds: 1),
    Duration reconnectMaxDelay = const Duration(seconds: 30),
  })  : _urlResolver = urlResolver,
        _tokenProvider = tokenProvider,
        _factory = factory,
        _readyDecoder = readyDecoder,
        _handshakeTimeout = handshakeTimeout,
        _maxReconnectAttempts = maxReconnectAttempts,
        _reconnectInitialDelay = reconnectInitialDelay,
        _reconnectMaxDelay = reconnectMaxDelay {
    _sessionInvalidationSub = _tokenProvider
        .sessionInvalidations()
        .listen((_) => unawaited(disconnect(reason: 'session_invalidated')));
  }

  final AppSocketUrlResolver _urlResolver;
  final SocketAuthTokenProvider _tokenProvider;
  final SocketIoClientFactory _factory;
  final ConnectionReadyDecoder _readyDecoder;
  final Duration _handshakeTimeout;
  final int _maxReconnectAttempts;
  final Duration _reconnectInitialDelay;
  final Duration _reconnectMaxDelay;

  IO.Socket? _socket;
  StreamSubscription<void>? _sessionInvalidationSub;

  final StreamController<ConsumerSocketConnectionState> _states =
      StreamController<ConsumerSocketConnectionState>.broadcast();
  ConsumerSocketConnectionState _state = const ConsumerSocketDisconnected();

  Future<ConsumerSocketConnected>? _inFlightConnect;
  bool _isDisposed = false;
  int _attemptCounter = 0;

  // ----- Public API -----

  ConsumerSocketConnectionState get state => _state;

  bool get isConnected => _state is ConsumerSocketConnected;

  Stream<ConsumerSocketConnectionState> states() => _states.stream;

  /// Acesso restrito para os adapters em `core/socket/*` e
  /// `features/.../data/socket/*`. Não usar de presentation.
  IO.Socket get raw {
    final s = _socket;
    if (s == null) {
      throw StateError(
        'ConsumerSocketConnection.raw read before connect()',
      );
    }
    return s;
  }

  /// Idempotente. Single-flight: se já há um connect em curso,
  /// retorna o mesmo Future. Se já está conectado, devolve o estado
  /// imediato.
  Future<ConsumerSocketConnected> connect() async {
    if (_isDisposed) {
      throw StateError('ConsumerSocketConnection used after dispose');
    }
    final inFlight = _inFlightConnect;
    if (inFlight != null) {
      return inFlight;
    }
    if (_state is ConsumerSocketConnected) {
      return _state as ConsumerSocketConnected;
    }
    final operation = _connectInternal().whenComplete(() {
      _inFlightConnect = null;
    });
    _inFlightConnect = operation;
    return operation;
  }

  /// Idempotente. Para reconectar, chame `connect()` de novo.
  Future<void> disconnect({String? reason}) async {
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        socket.disconnect();
        socket.dispose();
      } on Object catch (_) {
        // Não escalar; estado vai para disconnected mesmo assim.
      }
    }
    _setState(ConsumerSocketDisconnected(reason: reason));
  }

  /// Equivalente a `disconnect()` + `connect()`, mas garante que
  /// rola um único single-flight quando chamado durante uma reconexão
  /// já programada.
  Future<ConsumerSocketConnected> reconnect({String? reason}) async {
    await disconnect(reason: reason);
    return connect();
  }

  /// Foreground/background hooks chamados pelo app shell.
  Future<void> pause() => disconnect(reason: 'app_paused');
  Future<ConsumerSocketConnected> resume() => connect();

  Future<void> dispose() async {
    _isDisposed = true;
    await _sessionInvalidationSub?.cancel();
    _sessionInvalidationSub = null;
    await disconnect(reason: 'disposed');
    await _states.close();
  }

  // ----- Internals -----

  Future<ConsumerSocketConnected> _connectInternal() async {
    var attempt = 0;
    Duration delay = _reconnectInitialDelay;

    while (true) {
      attempt += 1;
      _attemptCounter = attempt;
      _setState(ConsumerSocketConnecting(attempt: attempt));

      final outcome = await _connectOnce();
      switch (outcome) {
        case _ConnectSuccess(:final connectedState):
          _setState(connectedState);
          return connectedState;

        case _ConnectAuthFailure():
          // Já tentou refresh internamente em _connectOnce; aqui é fim.
          _setState(const ConsumerSocketUnauthorized());
          throw StateError('Consumer socket unauthorized');

        case _ConnectTransientFailure(:final error):
          if (attempt >= _maxReconnectAttempts) {
            _setState(ConsumerSocketError(
              message: 'Max reconnect attempts reached',
              transient: false,
              cause: error,
            ));
            throw error;
          }
          _setState(ConsumerSocketError(
            message: 'Transient socket failure (attempt $attempt)',
            transient: true,
            cause: error,
          ));
          await Future<void>.delayed(delay);
          delay = _nextBackoff(delay);
      }
    }
  }

  Future<_ConnectOutcome> _connectOnce() async {
    final token = await _tokenProvider.readAccessToken();
    if (token == null || token.isEmpty) {
      return const _ConnectAuthFailure(reason: 'no_token');
    }

    final socket = _factory.create(
      url: _urlResolver.consumersUrl,
      accessToken: token,
    );
    _socket = socket;

    final readyCompleter = Completer<ConsumerSocketConnected>();
    final errorCompleter = Completer<_ConnectOutcome>();

    void cleanup() {
      socket
        ..off('connect')
        ..off('connect_error')
        ..off('connection:ready')
        ..off('disconnect');
    }

    socket.onConnect((_) {/* aguardamos connection:ready, não 'connect' */});

    socket.on('connection:ready', (Object? raw) {
      final decoded = _readyDecoder.decode(raw);
      if (decoded == null) {
        if (!errorCompleter.isCompleted) {
          errorCompleter.complete(
            const _ConnectTransientFailure(
              error: 'connection:ready_decode_failed',
            ),
          );
        }
        return;
      }
      if (!readyCompleter.isCompleted) {
        readyCompleter.complete(ConsumerSocketConnected(
          socketId: decoded.socketId,
          handshakeAt: DateTime.now().toUtc(),
          hubInstanceId: decoded.hubInstanceId,
        ));
      }
    });

    socket.onConnectError((Object? err) async {
      if (_isAuthFailure(err)) {
        // Tenta um único refresh. Se conseguir, encerra esta tentativa
        // como auth-failure transitória — _connectInternal vai pedir
        // outro _connectOnce que usará o novo token.
        final refreshed = await _tokenProvider.refreshAccessToken();
        if (refreshed != null && refreshed.isNotEmpty) {
          if (!errorCompleter.isCompleted) {
            errorCompleter.complete(
              const _ConnectTransientFailure(
                error: 'auth_refreshed_retry',
              ),
            );
          }
          return;
        }
        if (!errorCompleter.isCompleted) {
          errorCompleter.complete(
            const _ConnectAuthFailure(reason: 'refresh_failed'),
          );
        }
        return;
      }
      if (!errorCompleter.isCompleted) {
        errorCompleter.complete(_ConnectTransientFailure(error: err));
      }
    });

    socket.onDisconnect((Object? reason) {
      if (_state is! ConsumerSocketConnecting) {
        // Disconnect inesperado depois de já estar connected.
        _setState(ConsumerSocketDisconnected(reason: reason?.toString()));
      }
    });

    socket.connect();

    final outcome = await Future.any<_ConnectOutcome>(<Future<_ConnectOutcome>>[
      readyCompleter.future.then((s) => _ConnectSuccess(connectedState: s)),
      errorCompleter.future,
      _timeoutFuture(),
    ]);

    if (outcome is! _ConnectSuccess) {
      try {
        socket.disconnect();
        socket.dispose();
      } on Object catch (_) {}
      _socket = null;
    }
    cleanup();
    return outcome;
  }

  Future<_ConnectOutcome> _timeoutFuture() {
    return Future<_ConnectOutcome>.delayed(
      _handshakeTimeout,
      () => const _ConnectTransientFailure(error: 'handshake_timeout'),
    );
  }

  bool _isAuthFailure(Object? err) {
    if (err == null) {
      return false;
    }
    final s = err.toString().toLowerCase();
    return s.contains('401') ||
        s.contains('403') ||
        s.contains('unauthorized') ||
        s.contains('forbidden');
  }

  Duration _nextBackoff(Duration current) {
    final next = current * 2;
    if (next > _reconnectMaxDelay) {
      return _reconnectMaxDelay;
    }
    return next;
  }

  void _setState(ConsumerSocketConnectionState state) {
    if (_isDisposed) {
      return;
    }
    _state = state;
    if (!_states.isClosed) {
      _states.add(state);
    }
  }
}

sealed class _ConnectOutcome {
  const _ConnectOutcome();
}

final class _ConnectSuccess extends _ConnectOutcome {
  const _ConnectSuccess({required this.connectedState});
  final ConsumerSocketConnected connectedState;
}

final class _ConnectAuthFailure extends _ConnectOutcome {
  const _ConnectAuthFailure({required this.reason});
  final String reason;
}

final class _ConnectTransientFailure extends _ConnectOutcome {
  const _ConnectTransientFailure({required this.error});
  final Object error;
}
```

---

## 8. Política de reconexão

| Camada                                      | Comportamento                                                                                             |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `socket.io` nativo                          | **Desativado** (`disableReconnection()`).                                                                 |
| `ConsumerSocketConnection._connectInternal` | Retry com **backoff exponencial** (`1s → 2s → 4s → 8s → 16s → 30s teto`), até `maxReconnectAttempts = 5`. |
| Após `unauthorized`                         | **Não reconecta**. Estado terminal; UI deve mandar usuário para login.                                    |
| Após `error` final                          | Permanece em `error`; nova tentativa só com `connect()` explícito (ex.: usuário aciona "Reconectar").     |
| `pause()` (background)                      | `disconnect(reason: 'app_paused')`; em `resume()` chama `connect()` que reinicia o ciclo.                 |

> Por que single-flight: chamadas concorrentes a `connect()` durante
> reconexão pendente devem **compartilhar** o mesmo Future, e nunca
> abrir um segundo socket. Isso evita "fantasmas" que aparecem quando
> o app shell tenta reconectar em paralelo com retry interno.

---

## 9. Integração com o app shell (lifecycle)

Adicionar um `WidgetsBindingObserver` em algum lugar central
(`lib/app/app.dart` ou no `MaterialApp` root):

```dart
class _AppLifecycleHook extends StatefulWidget {
  const _AppLifecycleHook({required this.child});
  final Widget child;
  @override
  State<_AppLifecycleHook> createState() => _AppLifecycleHookState();
}

class _AppLifecycleHookState extends State<_AppLifecycleHook>
    with WidgetsBindingObserver {
  late final ConsumerSocketConnection _conn = getIt<ConsumerSocketConnection>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_conn.pause());
      case AppLifecycleState.resumed:
        unawaited(_conn.resume());
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

> **Decisão deliberada:** desconectar em background. Mobile economy >
> latência mínima. Quando o usuário volta para o app, o `resume()`
> reabre o socket; a UI se atualiza pelo refresh normal e pelo stream
> de presença (assim que reconectar).

---

## 10. Estratégia para `connection:ready` em PayloadFrame (Fase 2)

> **PR-K (entregue):** o decoder PayloadFrame e o compat decoder agora
> existem em `lib/core/socket/connection_ready_payload.dart`
> (`PayloadFrameConnectionReadyDecoder`,
> `CompatConnectionReadyDecoder`). O DI escolhe a implementação ativa
> via `SOCKET_CONNECTION_READY_COMPAT_MODE` (`compat` por padrão;
> `payload_frame_only` ou `raw_json_only` para forçar). O `compat`
> tenta primeiro o frame e cai para JSON puro, emitindo
> `ConnectionReadyShape` para que o `AppLogger` (`shape=payloadFrame`
> | `rawJson`) deixe rastro de quando podemos remover o fallback.
> A migração final está prevista pelo hub para após **2026-09-30**
> (`SOCKET_CONNECTION_READY_COMPAT_MODE` no `plug_server`).

A `ConnectionReadyDecoder` é um _port_. Em Fase 1 a implementação
default detecta o formato:

```dart
class CompatConnectionReadyDecoder implements ConnectionReadyDecoder {
  CompatConnectionReadyDecoder({
    required PayloadFrameDecoder payloadFrameDecoder,
  }) : _payloadFrameDecoder = payloadFrameDecoder;

  final PayloadFrameDecoder _payloadFrameDecoder;

  @override
  ConnectionReadyPayload? decode(Object? raw) {
    if (raw is Map<String, Object?>) {
      // Heurística: PayloadFrame tem 'enc', 'cmp', 'payload'.
      final looksLikeFrame = raw.containsKey('enc') &&
          raw.containsKey('cmp') &&
          raw.containsKey('payload');
      final logical = looksLikeFrame ? _payloadFrameDecoder.decode(raw) : raw;
      return _fromLogical(logical);
    }
    if (raw is String) {
      // PayloadFrame serializado completo? Tentar JSON puro primeiro.
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, Object?>) {
          return decode(parsed);
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  ConnectionReadyPayload? _fromLogical(Object? logical) {
    if (logical is! Map<String, Object?>) {
      return null;
    }
    final id = (logical['id'] as Object?)?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }
    final user = logical['user'];
    return ConnectionReadyPayload(
      socketId: id,
      message: (logical['message'] as Object?)?.toString() ?? '',
      userClaims: user is Map<String, Object?> ? user : const <String, Object?>{},
      hubInstanceId: (logical['hub_instance_id'] as Object?)?.toString(),
    );
  }
}
```

---

## 11. DI

`lib/core/di/injector_socket.dart` (delta sobre o esqueleto do plano §9.1):

```dart
void registerInjectorSocket(GetIt getIt) {
  getIt
    ..registerLazySingleton<SocketAuthTokenProvider>(
      () => SessionSocketAuthTokenProvider(
        sessionAccessor: getIt<AuthSessionAccessor>(),
        refreshCoordinator: getIt<AuthRefreshCoordinator>(),
        sessionEvents: getIt<AuthSessionEvents>(),
      ),
    )
    ..registerLazySingleton<AppSocketUrlResolver>(
      () => AppSocketUrlResolver(AppEnvironment.apiBaseUrl),
    )
    ..registerLazySingleton<SocketIoClientFactory>(
      DefaultSocketIoClientFactory.new,
    )
    ..registerLazySingleton<ConnectionReadyDecoder>(
      () => CompatConnectionReadyDecoder(
        payloadFrameDecoder: getIt<PayloadFrameDecoder>(),
      ),
    )
    ..registerLazySingleton<ConsumerSocketConnection>(
      () => ConsumerSocketConnection(
        urlResolver: getIt<AppSocketUrlResolver>(),
        tokenProvider: getIt<SocketAuthTokenProvider>(),
        factory: getIt<SocketIoClientFactory>(),
        readyDecoder: getIt<ConnectionReadyDecoder>(),
      ),
      dispose: (c) => c.dispose(),
    );
}
```

> `PayloadFrameDecoder` ainda não existe na Fase 1; um decoder
> "no-op" pode ser registrado temporariamente que devolve `null`
> para frames com `cmp == 'gzip'`. Em Fase 2, troca-se a implementação
> sem mexer em `ConsumerSocketConnection`.

> **PR-K (entregue):** o `PayloadFrameCodec` substituiu o no-op acima.
> O `injector_socket` agora resolve o `ConnectionReadyDecoder` por env
> (`SOCKET_CONNECTION_READY_COMPAT_MODE`):
> `payload_frame_only` → `PayloadFrameConnectionReadyDecoder`,
> `raw_json_only` → `JsonOnlyConnectionReadyDecoder`,
> `compat` (default) → `CompatConnectionReadyDecoder` que loga
> `ConnectionReadyShape` (`payloadFrame` | `rawJson`) via `AppLogger`.

> **PR-L (entregue):** o `injector_socket` ganhou um bloco gated por
> `SOCKET_RELAY_ENABLED` que registra `RelayConversationManager` e
> `RelayCommandDispatcher` reaproveitando o **mesmo
> `ConsumerSocketConnection`**. Quando o flag está em `false` (default),
> o relay não consome listeners adicionais nem aloca o
> `PayloadFrameCodec` — paridade exata com Fase 1 garantida.

---

## 11.1 Relay (PR-L) — `relay:*` em cima da mesma conexão

A mesma `ConsumerSocketConnection` carrega tanto `agents:command` quanto
`relay:*`. PR-L adicionou três peças em `lib/core/socket/relay/`:

| Arquivo                                | Papel                                                                                                                                                                                                                                                                                                                                                                                                                           |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `relay_event_names.dart`               | Constantes para todos os eventos do protocolo (`relay:conversation.*`, `relay:rpc.*`, `app:error`) + enum `RelayPayloadFrameCompression` (`auto`/`none`/`always` com `wireValue` `default`/`none`/`always`).                                                                                                                                                                                                                    |
| `relay_dispatch_exception.dart`        | Sealed `RelayDispatchException` com subtipos estáveis: `RelayConversationStartFailure`, `RelayConversationLost`, `RelayRequestRejected`, `RelayStreamTerminated`, `RelayRequestTimeout`, `RelayDecodeFailure`, `RelayDuplicateRequestId`, `RelayDispatcherDisposed`. Todos carregam `code`, `conversationId`, `clientRequestId` para metric pivots.                                                                             |
| `relay_conversation_state.dart`        | Sealed (`Idle`, `Starting`, `Active`, `Ending`, `Ended`).                                                                                                                                                                                                                                                                                                                                                                       |
| `relay_conversation.dart`              | Single-flight em `start()` (não emite dois `relay:conversation.start` em paralelo); `end()` idempotente; `forceEnd(reason)` para socket drop sem emitir nada para o hub.                                                                                                                                                                                                                                                        |
| `relay_conversation_manager.dart`      | Map `agentId → RelayConversation`. Reescuta `connection.states()` e descarta tudo em `Disconnected/Error/Unauthorized`. Reabre on demand via `obtain(agentId)` (que primeiro garante `connection.connect()`).                                                                                                                                                                                                                   |
| `relay_command_dispatcher.dart` (port) | `Future<Map> sendUnary({agentId, body, clientRequestId, timeout, compression})` + `Stream<RelayRpcOutcome> outcomes()`.                                                                                                                                                                                                                                                                                                         |
| `relay_command_dispatcher_impl.dart`   | Encoda `body` como `PayloadFrame` (auto-gzip via `PayloadFrameCodec`), emite `relay:rpc.request` com `{conversationId, frame, payloadFrameCompression}`, registra ouvintes uma vez por conexão para `accepted/response/chunk/complete`. Correlaciona via `clientRequestId` ↔ `requestId` (do `accepted`). Ignora `chunk` graciosamente (esqueleto pronto para PR-L+) e termina em `response` ou `complete` (`terminal_status`). |
| `relay_rpc_outcome.dart`               | Sealed `RelayRpcOutcome` (`RelayRpcSuccess` com `deduplicated/replayed`, `RelayRpcFailure` com `exception`). Mesmo padrão do `AgentCommandOutcome`.                                                                                                                                                                                                                                                                             |

A correlação interna do dispatcher mantém **dois mapas**:

```dart
Map<String, _PendingRelayRpc> _pendingByClientId;  // primário
Map<String, String> _clientIdByRequestId;          // depois do accepted
```

Em eventos de stream de alto débito o hub pode omitir `traceId`/`requestId`
no envelope (`socket_relay_protocol.md` §PayloadFrame). Quando isso acontece
e há uma única request pendente naquela `conversationId`, o dispatcher
roteia para ela como fallback determinístico (`_pendingFromFrame`).

### Política de erro

| Evento                                                  | Mapeamento                                                                                |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `relay:conversation.started` com `success: false`       | `RelayConversationStartFailure(code: error.code)`                                         |
| Timeout do `start()`                                    | `RelayConversationStartFailure(code: 'start_timeout')`                                    |
| `relay:rpc.accepted` com `success: false`               | `RelayRequestRejected(code: error.code)` (preserva `RATE_LIMITED`, `VALIDATION_ERROR`, …) |
| `relay:rpc.complete` com `terminal_status != completed` | `RelayStreamTerminated(code: 'stream_<status>')`                                          |
| Frame inválido (`enc != json`, gzip ratio, schema)      | `RelayDecodeFailure(code: <PayloadFrameDecodeException.code>)`                            |
| Sem resposta no `defaultTimeout`/`timeout`              | `RelayRequestTimeout`                                                                     |
| `dispatcher.dispose()` com pendentes                    | `RelayDispatcherDisposed`                                                                 |

### PR-L+ parte 2 — streaming (entregue)

`RelayCommandDispatcher` ganhou um segundo modo via
`Stream<Map<String, dynamic>> sendStreaming(...)`. Mesmo wire format do
`sendUnary` (mesmo `relay:rpc.request`, mesmo PayloadFrame), mas a
resposta é entregue chunk por chunk via `relay:rpc.chunk`.

**Refator interno.** Para o mesmo dispatcher cobrir os dois modos sem
duplicar correlator/timeout/listeners, o `_PendingRelayRpc` original
virou uma sealed class:

| Tipo             | Consumidor                                           | Como entrega resultado                                                      |
| ---------------- | ---------------------------------------------------- | --------------------------------------------------------------------------- |
| `_PendingUnary`  | `Completer<Map<String, dynamic>>`                    | `complete(response)` na primeira `rpc.response` ou `rpc.complete`           |
| `_PendingStream` | `StreamController<Map<String, dynamic>>.broadcast()` | `add(chunk)` por chunk; `close()` em `rpc.complete` (`completed`/`success`) |

Os erros caem no mesmo `_failPending` (que chama
`failExternally(exception)` no pending — completer ou controller).
Outcomes em `RelayRpcSuccess`/`RelayRpcFailure` continuam idênticos
para presença e métricas.

**Auto-pull rolante.** Ao receber `relay:rpc.accepted`, o dispatcher
emite imediatamente `relay:rpc.stream.pull` com
`windowSize = initialWindow` (env `SOCKET_RELAY_STREAM_INITIAL_WINDOW`,
default 32). A cada chunk decrementa `outstandingCredits`; quando ele
cai a/abaixo de `refillThreshold` (env
`SOCKET_RELAY_STREAM_REFILL_THRESHOLD`, default 16), emite um novo
pull granting `initialWindow - outstanding` créditos para reenchemer
até a janela cheia.

**Casos limite cobertos pelos testes**
(`test/core/socket/relay/relay_command_dispatcher_streaming_test.dart`):

| Cenário                                              | Comportamento                                                                               |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Pull antes de `accepted`                             | Não emite. Pull só sai após `requestId` conhecido.                                          |
| `relay:rpc.response` inesperado num caller streaming | Forward como single-chunk + `close()` (legal sob o protocolo).                              |
| `terminal_status: aborted`/`error`                   | `addError(RelayStreamTerminated(stream_<status>))` + `close()`.                             |
| `accepted` com `success: false`                      | `addError(RelayRequestRejected(serverCode: ...))` + `close()`.                              |
| Timeout                                              | `addError(RelayRequestTimeout)` + `close()`.                                                |
| `dispatcher.dispose()` mid-stream                    | `addError(RelayDispatcherDisposed)` + `close()`.                                            |
| `relay:rpc.chunk` num caller unitário                | Conta para diagnóstico (`receivedChunkCount`) e ignora — o `complete` ainda fecha o futuro. |

**Não fazemos cancel ao hub.** O protocolo relay atual não tem ack
de cancel; cancelar a subscription apenas para de drenar localmente.
O timeout existente (`SOCKET_RELAY_REQUEST_TIMEOUT_MS`) mais o
`forceEnd` da conversação no socket drop garantem que pendings não
vazam.

**PR-L+ p3 (entregue).** A camada de dados ganhou a opção 2 do
trio acima — port irmão **`AgentQueriesStreamingRemoteDataSource`**

- impl **`RelayStreamingAgentQueriesRemoteDataSource`** + DI gated
  (`lib/features/agent_queries/data/datasources/`,
  `lib/core/di/injector_agent_queries.dart`). Por que opção 2:

* Mantém o port unary intacto: callers que só precisam de
  `Future<Map>` continuam dependendo de
  `AgentQueriesRemoteDataSource` e nunca veem o stream (ISP).
* Reusa o mesmo `AgentSqlExecuteRequestToBridgeBody`, então o
  payload vai byte-igual ao REST/`agents:command`/relay unitário.
* DI fica condicional em `RelayCommandDispatcher` — builds sem
  `SOCKET_RELAY_ENABLED` não pagam allocation extra.

**PR-L+ p3.5 (entregue) — collector + adapter.** Para que o
streaming wire vire usável **sem reescrever o `AgentQueryExecutor`**,
a parte 3.5 fechou três peças:

1. O dispatcher (`RelayCommandDispatcherImpl`) agora forwarda o
   payload de `relay:rpc.complete` como o **item final** do stream
   (em vez de descartá-lo antes de fechar). Sem isso, todo
   collector perderia `total_rows` / `execution_id` /
   `started_at` / `finished_at` — só veria os `rows`.
2. `BridgeShapedSqlExecuteCollector` (em
   `lib/features/agent_queries/data/streaming_sql_execute_collector.dart`)
   agrega N `rpc.chunk` (`{rows, chunk_index, ...}`) + 1
   `rpc.complete` (`{total_rows, execution_id, ...}`) num único
   `Map` no formato canônico que `AgentSqlBridgeResponse.parseSuccess`
   já entende:
   `response.{type:'single',item:{success:true,result:{rows,row_count,
execution_id,started_at,finished_at,affected_rows,column_metadata}}}`.
   Tolerante: se o `complete` nunca chegar, `row_count` cai pra
   `rows.length` e os campos opcionais ficam ausentes — o parser
   ainda aceita.
3. `CollectingRelayStreamingAgentQueriesRemoteDataSource` implementa
   o **port unitário** `AgentQueriesRemoteDataSource` por dentro
   usando `streamSqlExecute(...) → collect(...)`. Repositories
   continuam dependendo do mesmo port, mas o transporte vira
   relay streaming — economia de RAM no hub + backpressure
   correto, sem mudar o repositório nem o executor.

A integração efetiva (registrar o adapter para uma query específica)
fica para **PR-L+ p4**: é um swap de DI (uma linha no
`injector_agent_queries.dart`) que não muda contrato nem comportamento
observável; depende só de identificar a query que sofre com
materialização, decisão de produto.

---

### PR-L+ parte 1 — selector per-query (entregue)

Adotamos a opção 1 (flag por request) por ter o menor blast radius e
manter as decisões de roteamento na borda da feature, sem precisar
mudar o domínio para classificar queries.

**Mudanças:**

- `AgentSqlExecuteRequest` ganhou `useRelay` (default `false`). O campo
  é puramente uma dica para a camada de dados — o
  `AgentSqlExecuteRequestToBridgeBody` continua produzindo o **mesmo
  body byte-a-byte** quando `useRelay` muda (snapshot test pinou esse
  invariante em
  `agent_sql_execute_request_to_bridge_body_test.dart`).
- `HybridAgentQueriesRemoteDataSource` (em
  `lib/features/agent_queries/data/datasources/`) recebe um
  `baseDelegate` (REST ou `agents:command`) e um `relayDelegate`
  opcional. Despacha por chamada:
  - `useRelay == false` → `baseDelegate.postSqlExecute(request)`.
  - `useRelay == true` + `relayDelegate != null` → relay.
  - `useRelay == true` + `relayDelegate == null` → fallback no
    `baseDelegate` com warning estruturado
    (`reason: relay_datasource_missing`) para a métrica de bypass.
- `injector_agent_queries.dart` constrói o `baseDelegate` como antes
  e, **se** `RelayCommandDispatcher` estiver registrado (i.e.
  `SOCKET_RELAY_ENABLED=true` no `injector_socket`), embrulha tudo
  num `HybridAgentQueriesRemoteDataSource`. Caso contrário,
  `baseDelegate` é registrado direto — paridade exata com Phase 1.

**O que ainda falta (PR-L+ parte 2):** agregar `relay:rpc.chunk` num
`Stream<Map>` real (auto-pull com `relay:rpc.stream.pull`). O
`RelayCommandDispatcher.sendUnary` atual continua adequado para
queries unitárias; o método streaming será uma adição
(`Stream<Map<String,dynamic>> sendStreaming(...)`) sem quebrar o
contrato unitário.

---

## 12. Casos de borda

| #   | Cenário                                                            | Comportamento esperado                                                                                                |
| --- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| 1   | `connect()` chamado duas vezes em paralelo                         | Único Future single-flight. Apenas um socket aberto.                                                                  |
| 2   | `connect()` em estado `unauthorized`                               | Lança `StateError`; UI deve forçar login.                                                                             |
| 3   | `connection:ready` nunca chega                                     | Timeout de `handshakeTimeout` (10 s) → backoff → retry.                                                               |
| 4   | `connect_error` com mensagem 401                                   | Refresh token, retry **uma vez**; em segunda 401 → `unauthorized`.                                                    |
| 5   | `disconnect` server-side com motivo `transport close`              | Estado `disconnected` (sem auto-reconnect); chamador decide quando reconectar.                                        |
| 6   | `AuthSessionEvents.invalidated` durante `connecting`               | Cancela cleanup; estado vai para `disconnected(reason: 'session_invalidated')`.                                       |
| 7   | App vai para background durante streaming pendente                 | `pause()` desconecta; o `SocketCommandDispatcher` falha pendentes com `NetworkFailure(transient: true)`.              |
| 8   | `dispose()` durante `connect()` em curso                           | Single-flight é completado; `dispose()` aguarda e fecha tudo.                                                         |
| 9   | `apiBaseUrl` vazio                                                 | `AppSocketUrlResolver.consumersUrl` é uma string inválida; `connect_error` imediato; `error` com causa "invalid url". |
| 10  | Hub multi-réplica (sem sticky) e refresh REST cai em outra réplica | `hubInstanceId` no `connection:ready` muda; logar transição como `info` para diagnóstico.                             |

---

## 13. Plano de testes

### 13.1 Unit

`test/core/socket/app_socket_url_resolver_test.dart`

- Strip `/api/v1`; mantém scheme; apêndice `/consumers`.

`test/core/socket/connection_ready_payload_test.dart`

- Decode raw JSON Map.
- Decode PayloadFrame (mock decoder).
- Retorna `null` para entrada inválida.

`test/core/socket/consumer_socket_connection_test.dart`

- Usa um `FakeSocketIoClientFactory` que retorna um `FakeIoSocket`
  (interface mínima: `connect`, `disconnect`, `dispose`, `on`, `off`,
  `onConnect`, `onConnectError`, `onDisconnect`).
- Cobertura:
  - Happy path: `connect()` → `connection:ready` → `connected`.
  - Single-flight: dois `connect()` paralelos compartilham Future.
  - Timeout de handshake leva a `error` transiente e retry.
  - 401 dispara `refreshAccessToken`; em segundo 401 → `unauthorized`.
  - `disconnect()` é idempotente.
  - `pause()` e `resume()` ciclam estados corretamente.
  - `AuthSessionEvents.invalidated` desconecta automaticamente.
  - `dispose()` não emite mais estados depois.

### 13.2 Integração (opt-in)

`test/integration/e2e/consumer_socket_handshake_e2e_test.dart`

- Login REST com credenciais e2e.
- `connect()` real contra hub de staging.
- Asserts: `state` chega a `connected`, `socketId` não vazio, `hubInstanceId`
  presente quando configurado no servidor.

---

## 14. Logging / Sentry

| Evento                                 | Nível                       | `component`                |
| -------------------------------------- | --------------------------- | -------------------------- |
| Transição de estado                    | `info`                      | `ConsumerSocketConnection` |
| Refresh de token disparado pelo socket | `info`                      | `ConsumerSocketConnection` |
| Refresh falhou → unauthorized          | `warning`                   | `ConsumerSocketConnection` |
| `connection:ready` decode falhou       | `warning`                   | `ConnectionReadyDecoder`   |
| Backoff acionado                       | `info`                      | `ConsumerSocketConnection` |
| `Max reconnect attempts reached`       | `error` + Sentry breadcrumb | `ConsumerSocketConnection` |

> **Nunca** logar `auth.token`. Logar apenas presença/ausência e
> primeiros 6 caracteres do `socketId` se necessário diagnosticar.

---

## 15. Critérios de aceite

1. `core/socket/` não importa `features/auth/` direto (apenas via port).
2. `domain/` continua sem qualquer import de socket.
3. Cobertura ≥ 90% nos arquivos novos de `core/socket/`.
4. Single-flight verificado em teste com 100 chamadas paralelas a
   `connect()`.
5. Backoff respeita o teto (`reconnectMaxDelay`).
6. `flutter analyze` limpo (sem `avoid_dynamic_calls` em
   `consumer_socket_connection.dart`; `Object?` cast explícito).
