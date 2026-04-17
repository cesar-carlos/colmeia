# Design técnico — Presença de agente em tempo real

> Companheiro técnico de `docs/Features/socket_consumer_channel_plan.md` §19.
> Este documento detalha **contratos**, **lifecycle**, **DI**, **casos de
> borda** e **plano de testes** para a capacidade de presença em tempo real.
> Nenhum código de produção foi escrito ainda; os blocos `dart` abaixo são
> **esqueletos normativos** — a implementação deve seguir literalmente as
> assinaturas, comentários e contratos descritos.

---

## 1. Resumo dos atores

```text
                   ┌──────────────────────────────────────────────┐
                   │             ClientAgentsController            │
                   │  (presentation, ChangeNotifier, único cliente) │
                   └──────────────────────────────────────────────┘
                                       ▲
                            depende só de (DIP)
                                       │
                   ┌──────────────────────────────────────────────┐
                   │        ObserveAgentPresenceUseCase            │
                   │  (application — Stream<AgentPresenceEvent>)   │
                   └──────────────────────────────────────────────┘
                                       ▲
                                       │ depende de (DIP, port)
                   ┌──────────────────────────────────────────────┐
                   │            AgentPresenceStream                │
                   │  (domain port; sem dependência de transporte) │
                   └──────────────────────────────────────────────┘
                                       ▲
                                       │ implementado por (data)
              ┌──────────────────────────────────────────────────┐
              │   SocketAgentPresenceStream  (composição interna)  │
              │   ┌───────────────────────────────────────────┐    │
              │   │ ClientAgentProfileUpdatedListener (Socket) │    │
              │   │ AgentCommandPresenceHinter (Socket dispatcher)│  │
              │   │ AgentPresencePoller (REST fallback, opcional) │  │
              │   └───────────────────────────────────────────┘    │
              └──────────────────────────────────────────────────┘
```

Fronteiras:

- **`domain`** — só tipos, sem `Socket.IO`, sem `Dio`, sem `dart:io`.
- **`application`** — coordena, usa `Stream` e `AppResult`.
- **`data`** — adapta Socket / REST para o port `AgentPresenceStream`.
- **`presentation`** — apenas consome o stream e atualiza in-memory state
  via `_upsertApprovedAgentsInMemory(...)` (já existe).

---

## 2. Domínio (`features/client_agents/domain/`)

### 2.1 Eventos

`lib/features/client_agents/domain/events/agent_presence_event.dart`

```dart
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';

/// Source-of-truth for "something changed about the presence/profile of agent X".
///
/// Sealed: subclasses são as únicas formas válidas de evento.
/// `agentId` está sempre presente porque a UI sempre precisa saber
/// **qual** card precisa rebuild.
sealed class AgentPresenceEvent {
  const AgentPresenceEvent({
    required this.agentId,
    required this.observedAt,
  });

  final String agentId;

  /// UTC. Usado para deduplicação por janela e ordenação quando dois
  /// eventos chegam para o mesmo agentId em sequência (ver §6.4).
  final DateTime observedAt;
}

/// Hub notificou que o catálogo desse agente mudou
/// (`client:agent.profile.updated`). A presença pode ter mudado junto
/// com o profile; a regra é refrescar via REST e deixar o servidor
/// dizer o `isHubConnected` atual.
final class AgentPresenceCatalogUpdated extends AgentPresenceEvent {
  const AgentPresenceCatalogUpdated({
    required super.agentId,
    required super.observedAt,
    required this.changedFields,
    this.profileVersion,
    this.source,
  });

  /// Conjunto vazio quando o hub não enviou (defensivo). Quando contém
  /// apenas chaves de profile (ex.: `phone`, `address`), o consumer
  /// pode optar por **não** repuxar presença, só perfil.
  final Set<String> changedFields;

  /// Inteiro monotônico exposto pelo hub. Usado para descartar
  /// notificações fora de ordem.
  final int? profileVersion;

  /// `http`, `socket`, `pull_sync`. Apenas informativo — não muda
  /// a reação da UI.
  final String? source;
}

/// Heurística vinda do próprio canal de comandos: ao executar um RPC
/// (sql.execute, agent.getProfile, etc.), inferimos online/offline.
/// Não substitui catálogo: serve para **antecipar** o feedback visual
/// e para alimentar o cache de `loadOnlineAgentIds`.
final class AgentPresenceHint extends AgentPresenceEvent {
  const AgentPresenceHint({
    required super.agentId,
    required super.observedAt,
    required this.online,
    required this.source,
  });

  final bool online;

  /// Identifica de onde veio o hint, para logging/observabilidade:
  /// `agents:command_success` | `agents:command_error_offline`
  /// | `socket_disconnected_from_consumer` | `polling_rest`.
  final String source;
}

/// Conveniência para mapear hints para o enum existente sem forçar a
/// camada de UI a fazer switch.
AgentConnectionStatus connectionStatusFromHint(AgentPresenceHint hint) {
  return hint.online
      ? AgentConnectionStatus.online
      : AgentConnectionStatus.offline;
}
```

### 2.2 Port

`lib/features/client_agents/domain/ports/agent_presence_stream.dart`

```dart
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';

/// Fonte agnóstica de eventos de presença/catálogo.
///
/// Implementações: `SocketAgentPresenceStream` (Camadas 1+2 do plano §19),
/// `RestPollingAgentPresenceStream` (Camada 3, opcional), e
/// `CompositeAgentPresenceStream` para juntar ambas em testes/produção.
abstract interface class AgentPresenceStream {
  /// Stream broadcast: múltiplos consumidores legítimos são raros
  /// (controller único), mas a interface não impede.
  ///
  /// Eventos podem chegar fora de ordem — o consumidor deve usar
  /// `observedAt` para resolver conflitos.
  Stream<AgentPresenceEvent> events();

  /// Encerra subscriptions internas (Socket listeners, timers, ...).
  /// Deve ser idempotente.
  Future<void> dispose();
}
```

### 2.3 Por que **não** estendemos `ClientAgentsRepository`

- `ClientAgentsRepository` é request/response. Adicionar `Stream` aqui
  quebra **ISP** (clientes que só fazem `loadApprovedAgents` passariam
  a depender de Socket).
- O port novo segue **SRP**: presença é uma preocupação separada do
  CRUD/sync de aprovação.

---

## 3. Application (`features/client_agents/application/`)

### 3.1 UseCase de observação

`lib/features/client_agents/application/usecases/observe_agent_presence_use_case.dart`

```dart
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';

/// Único ponto pelo qual a UI assina presença.
///
/// O usecase NÃO faz fan-out por agentId; quem filtra é o controller.
/// Mantém a interface mínima para não amarrar a UI a uma estrutura
/// específica de subscription.
class ObserveAgentPresenceUseCase {
  ObserveAgentPresenceUseCase(this._stream);

  final AgentPresenceStream _stream;

  Stream<AgentPresenceEvent> call() => _stream.events();
}
```

### 3.2 Service de polling (fallback REST)

`lib/features/client_agents/application/services/agent_presence_poller.dart`

```dart
import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';

/// Camada 3 do plano §19. Liga só quando o socket está fora de
/// `connected` E a tela do client_agents está visível.
///
/// Não é um `AgentPresenceStream`: ele alimenta um sink externo
/// (passado pelo composer) que, por sua vez, encaminha para o stream.
class AgentPresencePoller {
  AgentPresencePoller({
    required ClientAgentsRepository clientAgentsRepository,
    required Sink<AgentPresenceEvent> sink,
    Duration interval = const Duration(seconds: 30),
  })  : _clientAgentsRepository = clientAgentsRepository,
        _sink = sink,
        _interval = interval;

  final ClientAgentsRepository _clientAgentsRepository;
  final Sink<AgentPresenceEvent> _sink;
  final Duration _interval;

  Timer? _timer;
  bool _isRunning = false;

  /// Liga o polling. Idempotente: chamadas extras são ignoradas
  /// enquanto o timer está ativo.
  void start({required String userId}) {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    _timer = Timer.periodic(_interval, (_) => _tick(userId: userId));
  }

  /// Desliga e libera o timer. Idempotente.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  Future<void> _tick({required String userId}) async {
    try {
      final ids = await _clientAgentsRepository.loadOnlineAgentIds(
        userId: userId,
      );
      if (ids == null) {
        return; // presença indeterminada; não emite evento.
      }
      final now = DateTime.now().toUtc();
      for (final id in ids) {
        _sink.add(AgentPresenceHint(
          agentId: id,
          observedAt: now,
          online: true,
          source: 'polling_rest',
        ));
      }
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'AgentPresencePoller tick failed',
        context: const <String, Object?>{
          'component': 'AgentPresencePoller',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
```

> Limitação consciente: o REST `loadOnlineAgentIds` só **lista quem
> está online**. Para `offline` confiável, dependemos do
> `AgentPresenceCatalogUpdated` ou da Camada 2.

---

## 4. Data layer (`features/client_agents/data/socket/`)

### 4.1 Listener do `client:agent.profile.updated`

`lib/features/client_agents/data/socket/client_agent_profile_updated_listener.dart`

```dart
import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';

/// Adapter de borda: observa o socket cru e emite eventos de domínio.
///
/// Não decide ação nenhuma — só transforma payload em evento e empurra
/// para o sink. Falhas de decode são logadas e descartadas silenciosamente,
/// evitando matar o stream principal.
class ClientAgentProfileUpdatedListener {
  ClientAgentProfileUpdatedListener({
    required ConsumerSocketConnection connection,
    required Sink<AgentPresenceEvent> sink,
    required PayloadFrameDecoder decoder,
  })  : _connection = connection,
        _sink = sink,
        _decoder = decoder;

  static const String _eventName = 'client:agent.profile.updated';

  final ConsumerSocketConnection _connection;
  final Sink<AgentPresenceEvent> _sink;
  final PayloadFrameDecoder _decoder;

  StreamSubscription<Object?>? _socketSub;
  bool _attached = false;

  /// Chame após `connection.connect()` ter passado pelo `connection:ready`.
  /// É seguro chamar múltiplas vezes (idempotente).
  void attach() {
    if (_attached) {
      return;
    }
    _attached = true;
    _connection.raw.on(_eventName, _onEvent);
  }

  Future<void> dispose() async {
    if (!_attached) {
      return;
    }
    _attached = false;
    _connection.raw.off(_eventName, _onEvent);
    await _socketSub?.cancel();
    _socketSub = null;
  }

  void _onEvent(Object? rawPayload) {
    try {
      final logical = _decoder.decode(rawPayload);
      if (logical is! Map<String, Object?>) {
        return;
      }
      final agentId = (logical['agent_id'] as Object?)?.toString().trim();
      if (agentId == null || agentId.isEmpty) {
        return;
      }
      final profileVersion = (logical['profile_version'] as num?)?.toInt();
      final changed = <String>{
        ...?(logical['changed_fields'] as List<Object?>?)
            ?.whereType<String>(),
      };
      final source = (logical['source'] as Object?)?.toString();
      final observedAtRaw =
          (logical['profileUpdatedAt'] as Object?)?.toString();
      final observedAt = observedAtRaw != null
              ? DateTime.tryParse(observedAtRaw)?.toUtc()
              : null;

      _sink.add(AgentPresenceCatalogUpdated(
        agentId: agentId,
        observedAt: observedAt ?? DateTime.now().toUtc(),
        changedFields: changed,
        profileVersion: profileVersion,
        source: source,
      ));
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'client:agent.profile.updated decode failed',
        context: const <String, Object?>{
          'component': 'ClientAgentProfileUpdatedListener',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
```

### 4.2 Hinter dos comandos do dispatcher

`lib/features/client_agents/data/socket/agent_command_presence_hinter.dart`

```dart
import 'dart:async';

import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';

/// Observa SocketCommandDispatcher (porta interna que expõe um stream
/// de outcomes) e produz hints de presença.
///
/// O dispatcher precisa expor `Stream<AgentCommandOutcome>` (a definir
/// em core/socket/socket_command_dispatcher.dart):
///
/// ```dart
/// sealed class AgentCommandOutcome {
///   String get agentId;
///   DateTime get observedAt;
/// }
/// final class AgentCommandSuccess extends AgentCommandOutcome { ... }
/// final class AgentCommandFailedOffline extends AgentCommandOutcome { ... }
/// final class AgentCommandFailedAuth extends AgentCommandOutcome { ... }
/// ```
class AgentCommandPresenceHinter {
  AgentCommandPresenceHinter({
    required SocketCommandDispatcher dispatcher,
    required Sink<AgentPresenceEvent> sink,
  })  : _dispatcher = dispatcher,
        _sink = sink;

  final SocketCommandDispatcher _dispatcher;
  final Sink<AgentPresenceEvent> _sink;

  StreamSubscription<AgentCommandOutcome>? _sub;

  void attach() {
    _sub ??= _dispatcher.outcomes().listen(_onOutcome);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onOutcome(AgentCommandOutcome outcome) {
    switch (outcome) {
      case AgentCommandSuccess():
        _sink.add(AgentPresenceHint(
          agentId: outcome.agentId,
          observedAt: outcome.observedAt,
          online: true,
          source: 'agents:command_success',
        ));
      case AgentCommandFailedOffline():
        _sink.add(AgentPresenceHint(
          agentId: outcome.agentId,
          observedAt: outcome.observedAt,
          online: false,
          source: 'agents:command_error_offline',
        ));
      case AgentCommandFailedAuth():
        // 401/403 não fala sobre presença — ignora.
        return;
    }
  }
}
```

### 4.3 Composição: `SocketAgentPresenceStream`

`lib/features/client_agents/data/socket/socket_agent_presence_stream.dart`

```dart
import 'dart:async';

import 'package:colmeia/features/client_agents/data/socket/agent_command_presence_hinter.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';

/// Combina Camada 1 (push de catálogo) + Camada 2 (hints implícitos)
/// num único `AgentPresenceStream`. Polling REST (Camada 3) entra
/// **opcional** via construtor `withPolling`.
class SocketAgentPresenceStream implements AgentPresenceStream {
  SocketAgentPresenceStream({
    required ClientAgentProfileUpdatedListener catalogListener,
    required AgentCommandPresenceHinter commandHinter,
  })  : _catalogListener = catalogListener,
        _commandHinter = commandHinter,
        _controller = StreamController<AgentPresenceEvent>.broadcast() {
    _catalogListener.attach();
    _commandHinter.attach();
  }

  final ClientAgentProfileUpdatedListener _catalogListener;
  final AgentCommandPresenceHinter _commandHinter;
  final StreamController<AgentPresenceEvent> _controller;

  /// Sink que listeners empurram. Exposto via construtor (DI), garantindo
  /// que **toda** entrada vai para o mesmo controller.
  Sink<AgentPresenceEvent> get sink => _controller.sink;

  @override
  Stream<AgentPresenceEvent> events() => _controller.stream;

  @override
  Future<void> dispose() async {
    await _catalogListener.dispose();
    await _commandHinter.dispose();
    await _controller.close();
  }
}
```

> O sink é o **mesmo** para os dois listeners (e para o `AgentPresencePoller`
> opcional). A composição correta é feita no `injector` (§5).

---

## 5. DI — `lib/core/di/injector_client_agents.dart` (delta)

Adicionar **abaixo** do registro existente do `ClientAgentsController`:

```dart
// 1) Eventos: controller único de fan-out
getIt.registerLazySingleton<StreamController<AgentPresenceEvent>>(
  () => StreamController<AgentPresenceEvent>.broadcast(),
  dispose: (c) => c.close(),
);

// 2) Listener Socket: catálogo
getIt.registerLazySingleton<ClientAgentProfileUpdatedListener>(
  () => ClientAgentProfileUpdatedListener(
    connection: getIt<ConsumerSocketConnection>(),
    sink: getIt<StreamController<AgentPresenceEvent>>().sink,
    decoder: getIt<PayloadFrameDecoder>(),
  ),
  dispose: (l) => l.dispose(),
);

// 3) Hinter Socket: comandos
getIt.registerLazySingleton<AgentCommandPresenceHinter>(
  () => AgentCommandPresenceHinter(
    dispatcher: getIt<SocketCommandDispatcher>(),
    sink: getIt<StreamController<AgentPresenceEvent>>().sink,
  ),
  dispose: (h) => h.dispose(),
);

// 4) Poller REST: opcional, ligado pelo controller quando socket cai
getIt.registerLazySingleton<AgentPresencePoller>(
  () => AgentPresencePoller(
    clientAgentsRepository: getIt<ClientAgentsRepository>(),
    sink: getIt<StreamController<AgentPresenceEvent>>().sink,
  ),
  dispose: (p) async => p.stop(),
);

// 5) Stream port (composição) — Camadas 1+2 já anexadas no construtor
getIt.registerLazySingleton<AgentPresenceStream>(
  () => SocketAgentPresenceStream(
    catalogListener: getIt<ClientAgentProfileUpdatedListener>(),
    commandHinter: getIt<AgentCommandPresenceHinter>(),
  ),
  dispose: (s) => s.dispose(),
);

// 6) Use case
getIt.registerLazySingleton<ObserveAgentPresenceUseCase>(
  () => ObserveAgentPresenceUseCase(getIt<AgentPresenceStream>()),
);
```

Atualizar o construtor do controller:

```dart
ClientAgentsController(
  // ...existing args
  observeAgentPresenceUseCase: getIt<ObserveAgentPresenceUseCase>(),
  agentPresencePoller: getIt<AgentPresencePoller>(),
  consumerSocketConnection: getIt<ConsumerSocketConnection>(),
);
```

> Importante: o `SocketAgentPresenceStream` instancia o `StreamController`
> internamente no esqueleto da §4.3 **mas** na DI usamos um controller
> **compartilhado** registrado no `getIt` (item 1 acima). Ajuste no esqueleto
> antes da implementação: receber o controller por construtor para que o
> poller também consiga `add` no mesmo sink.

---

## 6. Lifecycle no `ClientAgentsController` (delta)

### 6.1 Campos novos

```dart
final ObserveAgentPresenceUseCase _observeAgentPresenceUseCase;
final AgentPresencePoller _agentPresencePoller;
final ConsumerSocketConnection _consumerSocketConnection;

StreamSubscription<AgentPresenceEvent>? _presenceSub;
StreamSubscription<ConsumerSocketConnectionState>? _socketStateSub;

final Map<String, DateTime> _lastObservedByAgentId = <String, DateTime>{};
final Map<String, Timer> _hintConfirmTimers = <String, Timer>{};
```

### 6.2 Em `initialize()` (após o `_refreshAll(...)` atual)

```dart
final userId = _authController.session?.userId;
if (userId == null || userId.isEmpty) {
  return;
}

_presenceSub ??= _observeAgentPresenceUseCase().listen(
  (event) => _onPresence(event, userId: userId),
  onError: (Object e, StackTrace s) {
    AppLogger.warning('Presence stream error', error: e, stackTrace: s);
  },
);

_socketStateSub ??= _consumerSocketConnection.states().listen((state) {
  switch (state) {
    case ConsumerSocketConnectionState.connected:
      _agentPresencePoller.stop();
    case ConsumerSocketConnectionState.disconnected:
    case ConsumerSocketConnectionState.error:
      // Liga polling REST só se a tela está visível
      if (_isScreenVisible) {
        _agentPresencePoller.start(userId: userId);
      }
    default:
      break;
  }
});
```

### 6.3 Visibility gating

Como o controller é `ChangeNotifier` por feature, expor:

```dart
void onScreenVisible() {
  _isScreenVisible = true;
  if (!_consumerSocketConnection.isConnected && _hasUserId) {
    _agentPresencePoller.start(userId: _userId!);
  }
}

void onScreenHidden() {
  _isScreenVisible = false;
  _agentPresencePoller.stop();
}
```

E chamar no `RouteAware` da página `client_agents_page.dart`
(`didPush`/`didPopNext` e `didPop`/`didPushNext`).

### 6.4 Tratamento de evento

```dart
Future<void> _onPresence(
  AgentPresenceEvent event, {
  required String userId,
}) async {
  // Deduplica: ignora eventos cujo observedAt é mais antigo que o último
  // observado para o mesmo agentId.
  final last = _lastObservedByAgentId[event.agentId];
  if (last != null && !event.observedAt.isAfter(last)) {
    return;
  }
  _lastObservedByAgentId[event.agentId] = event.observedAt;

  switch (event) {
    case AgentPresenceCatalogUpdated():
      await _refreshAgentDetail(
        userId: userId,
        agentId: event.agentId,
      );
    case AgentPresenceHint(:final online):
      _applyHintInMemory(event.agentId, online: online);
      _scheduleHintConfirm(userId: userId, agentId: event.agentId);
  }
}

Future<void> _refreshAgentDetail({
  required String userId,
  required String agentId,
}) async {
  final result = await _loadClientAgentDetailUseCase(
    userId: userId,
    agentId: agentId,
  );
  result.fold(
    (agent) {
      _upsertApprovedAgentsInMemory(<ClientAgent>[agent]);
      _notifyListenersIfAlive();
    },
    (failure) {
      AppLogger.warning(
        'Refresh after presence event failed',
        context: <String, Object?>{
          'agentId': agentId,
          'reason': failure.message,
        },
      );
    },
  );
}

void _applyHintInMemory(String agentId, {required bool online}) {
  final current = _approvedAgents;
  if (current == null) {
    return;
  }
  final items = current.items.map((a) {
    if (a.agentId != agentId) {
      return a;
    }
    return a.copyWith(
      connectionStatus: online
          ? AgentConnectionStatus.online
          : AgentConnectionStatus.offline,
    );
  }).toList(growable: false);
  _approvedAgents = PaginatedResult<ClientAgent>(
    items: items,
    count: current.count,
    total: current.total,
    page: current.page,
    pageSize: current.pageSize,
  );
  _notifyListenersIfAlive();
}

void _scheduleHintConfirm({
  required String userId,
  required String agentId,
}) {
  _hintConfirmTimers[agentId]?.cancel();
  _hintConfirmTimers[agentId] = Timer(
    const Duration(seconds: 5),
    () => unawaited(_refreshAgentDetail(userId: userId, agentId: agentId)),
  );
}
```

### 6.5 Em `dispose()`

```dart
@override
void dispose() {
  _stopApprovalPolling(clearTracked: true);
  for (final t in _hintConfirmTimers.values) {
    t.cancel();
  }
  _hintConfirmTimers.clear();
  unawaited(_presenceSub?.cancel());
  unawaited(_socketStateSub?.cancel());
  _agentPresencePoller.stop();
  _isDisposed = true;
  super.dispose();
}
```

---

## 7. Casos de borda (testar 1-a-1)

| # | Cenário | Comportamento esperado |
| - | ------- | ---------------------- |
| 1 | Evento de catálogo com `agent_id` desconhecido (não aprovado) | Ignorar silenciosamente; não chamar REST. |
| 2 | Evento com `observedAt` mais antigo que o último visto | Descartar via dedup §6.4. |
| 3 | Hint `online: true` seguido de hint `online: false` em < 1 s | Aplica os dois (último ganha); confirm timer roda só uma vez (debounce). |
| 4 | `AgentPresenceCatalogUpdated.changedFields` só com `phone`/`address` | Refresh ainda acontece (perfil precisa atualizar). Otimização futura: filtrar para refresh somente quando `connectionStatus` puder ter mudado. |
| 5 | `client:agent.profile.updated` chega antes do `connection:ready` | Listener só anexa **depois** do ready (§4.1: chame `attach()` no callback de `connected`). |
| 6 | Socket cai durante hint pendente | Hint já aplicado in-memory; poller assume; ao reconectar, stream retoma normalmente. |
| 7 | Logout durante stream | `AuthSessionEvents.invalidated` → `ConsumerSocketConnection.disconnect()` → listeners caem; controller `dispose()` cancela `presenceSub`. |
| 8 | Hub multi-instância sem sticky session | `isHubConnected` pode oscilar entre refreshes. Documentar; não há mitigação no app. |
| 9 | Frame Socket inválido | `_onEvent` engole exceção e loga; stream principal segue vivo. |
| 10 | Tela hidden + socket connected | Não emite hint para UI invisível? **Emite sim** (state já está in-memory para próximo `onScreenVisible`); só o poller REST respeita visibility. |

---

## 8. Plano de testes

### 8.1 Domain

`test/features/client_agents/domain/events/agent_presence_event_test.dart`

- `AgentPresenceCatalogUpdated` é `==` quando todos os campos batem.
- `AgentPresenceHint` mapeado por `connectionStatusFromHint` retorna o
  `AgentConnectionStatus` correto.

### 8.2 Application

`test/features/client_agents/application/usecases/observe_agent_presence_use_case_test.dart`

- Stream do port é repassado intacto.

`test/features/client_agents/application/services/agent_presence_poller_test.dart`

- `start` → `tick` chama `loadOnlineAgentIds` e empurra um `AgentPresenceHint(online: true)` por id.
- `start` chamado duas vezes não cria timers extras (idempotência).
- `stop` cancela o timer; novo `start` reativa.
- Falha em `loadOnlineAgentIds` é logada e **não** propaga.

### 8.3 Data

`test/features/client_agents/data/socket/client_agent_profile_updated_listener_test.dart`

- Mock de `ConsumerSocketConnection.raw` (interface fake) e
  `PayloadFrameDecoder`. Verifica que:
  - payload válido → `AgentPresenceCatalogUpdated` no sink.
  - payload sem `agent_id` → ignora.
  - decoder lança → loga e ignora; sink não recebe nada.
  - `dispose()` faz `off` no socket e é idempotente.

`test/features/client_agents/data/socket/agent_command_presence_hinter_test.dart`

- `AgentCommandSuccess` → hint `online: true` com source correto.
- `AgentCommandFailedOffline` → hint `online: false`.
- `AgentCommandFailedAuth` → não emite nada.

`test/features/client_agents/data/socket/socket_agent_presence_stream_test.dart`

- Eventos do listener e do hinter aparecem no stream do port em ordem.
- `dispose()` libera ambos e fecha o controller.

### 8.4 Controller (presentation)

`test/features/client_agents/presentation/controllers/client_agents_controller_presence_test.dart`

- Subscreve em `initialize()` e cancela em `dispose()`.
- Ao receber `AgentPresenceCatalogUpdated`, chama `_loadClientAgentDetailUseCase`
  e aplica `_upsertApprovedAgentsInMemory`.
- Hint aplica `copyWith(connectionStatus)` sem chamar REST imediatamente.
- Confirm timer (5 s, fake `Clock`) chama REST após o intervalo.
- Dedup: evento com `observedAt` mais antigo é ignorado.

### 8.5 Integração

`test/integration/e2e/agent_presence_realtime_test.dart` (opt-in,
mesmas envs do plano §13.2):

- Login REST + socket.
- Server simula `client:agent.profile.updated` (ou usar mock server).
- UI atualiza badge `online`/`offline` em ≤ 5 s.

---

## 9. Métricas e observabilidade

`AppLogger` keys padronizadas (alinhadas a `project_conventions.mdc`):

| Evento | `component` | `operation` | Nível |
| ------ | ----------- | ----------- | ----- |
| Listener anexado | `ClientAgentProfileUpdatedListener` | `attach` | `info` |
| Frame inválido | `ClientAgentProfileUpdatedListener` | `decode_failed` | `warning` |
| Hinter outcome | `AgentCommandPresenceHinter` | `outcome` | `debug` |
| Poller tick OK | `AgentPresencePoller` | `tick` | `debug` |
| Poller tick falhou | `AgentPresencePoller` | `tick_failed` | `warning` |
| Refresh agente | `ClientAgentsController` | `refreshAfterPresence` | `info` |
| Hint dedup | `ClientAgentsController` | `presence_dedup` | `debug` |

Sentry breadcrumbs: estado da `ConsumerSocketConnection` (transições) +
contagem agregada de hints/min (não logar `agentId` em produção fora
de erro real).

---

## 10. Critérios de aceite (técnicos)

1. `domain/` continua sem importar `socket_io_client`, `dio`, `dart:io`.
2. `ClientAgentsController` continua sem conhecer `ConsumerSocketConnection.raw`
   (depende só de `states()` e do use case).
3. Cobertura ≥ 90% em:
   - `agent_presence_event.dart`,
   - `socket_agent_presence_stream.dart`,
   - `client_agent_profile_updated_listener.dart`,
   - `agent_command_presence_hinter.dart`,
   - `agent_presence_poller.dart`,
   - novos branches do `client_agents_controller`.
4. `flutter analyze` limpo (sem `avoid_dynamic_calls`, sem
   `prefer_relative_imports`).
5. Nenhuma regressão em `test/features/client_agents/**`.
6. CI passa em todos os flutter test e dart test.

---

## 11. Ordem sugerida de implementação

| PR | Conteúdo | Depende de |
| -- | -------- | ---------- |
| **PR-1** | Apenas domain: `agent_presence_event.dart` + `agent_presence_stream.dart` + tests. | — |
| **PR-2** | `AgentPresencePoller` + `ObserveAgentPresenceUseCase` + tests; ainda sem socket. | PR-1, plano principal §11 (Fase 1 Socket). |
| **PR-3** | `ClientAgentProfileUpdatedListener` + `AgentCommandPresenceHinter` + `SocketAgentPresenceStream` + DI + tests. | PR-2 + Fase 2 do plano principal (`PayloadFrame`). |
| **PR-4** | Wire-up no `ClientAgentsController` (subscription, hint cache, poller gating) + tests do controller. | PR-3. |
| **PR-5** | Telemetria/breadcrumbs + métricas internas (contadores). | PR-4. |

> Nenhum PR introduz dependência runtime nova: `socket_io_client` já é
> trazido no PR-1 do plano principal; tudo aqui usa `dart:async`.

---

## 12. Referências cruzadas

- Plano executivo: `docs/Features/socket_consumer_channel_plan.md` (§19).
- Hub: `plug_server/docs/socket_client_sdk.md` (§"Push de catalogo"),
  `plug_server/docs/client_agent_business_rules.md` (§3.4 e §"Perfil no catálogo"),
  `plug_server/docs/observability.md` (§"agent_profile_broadcast").
- Regras Colmeia: `.cursor/rules/clean_architecture.mdc`,
  `.cursor/rules/solid_principles.mdc`,
  `.cursor/rules/project_data_domain.mdc` (Estratégia de dados —
  socket complementar a REST).
