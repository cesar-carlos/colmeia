// Test-only:
// - `_agent(connectionStatus: AgentConnectionStatus.online)` is sometimes
//   passed even when it matches the default, to keep each test
//   self-documenting about which initial state it is asserting against.
// - Sequential `presenceStream.emit(...)` calls drive the controller
//   through distinct phases (event A → assertion → event B); cascades
//   would obscure the intent.
// ignore_for_file: avoid_redundant_argument_values, cascade_invocations

import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/consumer_socket_connection_state.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/client_agent_token_draft_store.dart';
import 'package:colmeia/features/client_agents/application/services/agent_presence_poller.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/observe_agent_presence_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/retry_client_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLoadClientApprovedAgentsUseCase extends Mock
    implements LoadClientApprovedAgentsUseCase {}

class _MockLoadClientAccessRequestsUseCase extends Mock
    implements LoadClientAccessRequestsUseCase {}

class _MockLoadClientAccessStatusUseCase extends Mock
    implements LoadClientAccessStatusUseCase {}

class _MockLoadClientAgentDetailUseCase extends Mock
    implements LoadClientAgentDetailUseCase {}

class _MockQueueClientAgentRequestAccessUseCase extends Mock
    implements QueueClientAgentRequestAccessUseCase {}

class _MockQueueClientAgentRemoveAccessUseCase extends Mock
    implements QueueClientAgentRemoveAccessUseCase {}

class _MockProbeClientApprovedAgentUseCase extends Mock
    implements ProbeClientApprovedAgentUseCase {}

class _MockDiscardQueuedClientAgentRequestAccessUseCase extends Mock
    implements DiscardQueuedClientAgentRequestAccessUseCase {}

class _MockReadPendingClientAgentActionsUseCase extends Mock
    implements ReadPendingClientAgentActionsUseCase {}

class _MockSyncPendingClientAgentActionsUseCase extends Mock
    implements SyncPendingClientAgentActionsUseCase {}

class _MockLocalAgentClientTokenStore extends Mock
    implements LocalAgentClientTokenStore {}

class _MockGetClientAgentTokenUseCase extends Mock
    implements GetClientAgentTokenUseCase {}

class _MockSaveClientAgentTokenUseCase extends Mock
    implements SaveClientAgentTokenUseCase {}

class _MockRetryClientAccessRequestUseCase extends Mock
    implements RetryClientAccessRequestUseCase {}

class _MockAgentPresencePoller extends Mock implements AgentPresencePoller {}

class _MockConsumerSocketConnection extends Mock
    implements ConsumerSocketConnection {}

/// In-memory presence stream + use case so tests drive `_onPresence` by
/// pushing events through `emit(...)`. The controller treats the use
/// case like any other source — if `_observeAgentPresenceUseCase` is
/// `null` the wire-up code paths are skipped entirely.
class _FakePresenceStream implements AgentPresenceStream {
  _FakePresenceStream()
    : _controller = StreamController<AgentPresenceEvent>.broadcast();

  final StreamController<AgentPresenceEvent> _controller;
  bool disposed = false;

  void emit(AgentPresenceEvent event) => _controller.add(event);

  @override
  Stream<AgentPresenceEvent> events() => _controller.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}

ClientAgent _agent({
  required String id,
  AgentConnectionStatus connectionStatus = AgentConnectionStatus.online,
}) {
  return ClientAgent(
    agentId: id,
    name: 'Agent $id',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: connectionStatus,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

PaginatedResult<ClientAgent> _approvedListWith(List<ClientAgent> items) {
  return PaginatedResult<ClientAgent>(
    items: items,
    count: items.length,
    total: items.length,
    page: 1,
    pageSize: 50,
  );
}

void main() {
  late _MockAuthController authController;
  late _MockLocalAgentClientTokenStore clientTokenStore;
  late _MockLoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase;
  late _MockLoadClientAccessRequestsUseCase loadAccessRequestsUseCase;
  late _MockLoadClientAccessStatusUseCase loadClientAccessStatusUseCase;
  late _MockLoadClientAgentDetailUseCase loadClientAgentDetailUseCase;
  late _MockQueueClientAgentRequestAccessUseCase queueRequestAccessUseCase;
  late _MockQueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase;
  late _MockProbeClientApprovedAgentUseCase probeClientApprovedAgentUseCase;
  late _MockDiscardQueuedClientAgentRequestAccessUseCase
  discardQueuedClientAgentRequestAccessUseCase;
  late _MockReadPendingClientAgentActionsUseCase readPendingActionsUseCase;
  late _MockSyncPendingClientAgentActionsUseCase syncPendingActionsUseCase;
  late _MockGetClientAgentTokenUseCase getClientAgentTokenUseCase;
  late _MockSaveClientAgentTokenUseCase saveClientAgentTokenUseCase;
  late _MockRetryClientAccessRequestUseCase retryClientAccessRequestUseCase;
  late _FakePresenceStream presenceStream;
  late ClientAgentsController controller;

  final session = AuthSession(
    userId: 'client-1',
    email: EmailAddress('client@example.com'),
    accessToken: 'token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime(2099),
    accountStatus: ClientAccountStatus.active,
  );

  setUpAll(() {
    registerFallbackValue(const PaginatedQuery());
    registerFallbackValue(<String>{});
  });

  setUp(() {
    authController = _MockAuthController();
    clientTokenStore = _MockLocalAgentClientTokenStore();
    loadApprovedAgentsUseCase = _MockLoadClientApprovedAgentsUseCase();
    loadAccessRequestsUseCase = _MockLoadClientAccessRequestsUseCase();
    loadClientAccessStatusUseCase = _MockLoadClientAccessStatusUseCase();
    loadClientAgentDetailUseCase = _MockLoadClientAgentDetailUseCase();
    queueRequestAccessUseCase = _MockQueueClientAgentRequestAccessUseCase();
    queueRemoveAccessUseCase = _MockQueueClientAgentRemoveAccessUseCase();
    probeClientApprovedAgentUseCase = _MockProbeClientApprovedAgentUseCase();
    discardQueuedClientAgentRequestAccessUseCase =
        _MockDiscardQueuedClientAgentRequestAccessUseCase();
    readPendingActionsUseCase = _MockReadPendingClientAgentActionsUseCase();
    syncPendingActionsUseCase = _MockSyncPendingClientAgentActionsUseCase();
    getClientAgentTokenUseCase = _MockGetClientAgentTokenUseCase();
    saveClientAgentTokenUseCase = _MockSaveClientAgentTokenUseCase();
    retryClientAccessRequestUseCase = _MockRetryClientAccessRequestUseCase();
    when(
      () => getClientAgentTokenUseCase(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
        ClientAgentTokenSnapshot.empty(),
      ),
    );
    when(
      () => saveClientAgentTokenUseCase(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
        ClientAgentTokenSnapshot.empty(),
      ),
    );
    when(
      () => retryClientAccessRequestUseCase(
        userId: any(named: 'userId'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));
    presenceStream = _FakePresenceStream();

    when(() => authController.session).thenReturn(session);
    when(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        _approvedListWith(<ClientAgent>[
          _agent(id: 'a1', connectionStatus: AgentConnectionStatus.online),
          _agent(id: 'a2', connectionStatus: AgentConnectionStatus.offline),
        ]),
      ),
    );
    when(
      () => loadAccessRequestsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
            PaginatedResult<ClientAgentAccessRequest>(
              items: <ClientAgentAccessRequest>[],
              count: 0,
              total: 0,
              page: 1,
              pageSize: 50,
            ),
          ),
    );
    when(
      () => readPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<List<PendingAgentAction>, AppFailure>(
        <PendingAgentAction>[],
      ),
    );

    controller = ClientAgentsController(
      authController: authController,
      clientTokenDraftStore: ClientAgentTokenDraftStore(clientTokenStore),
      loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
      loadAccessRequestsUseCase: loadAccessRequestsUseCase,
      loadClientAccessStatusUseCase: loadClientAccessStatusUseCase,
      loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
      queueRequestAccessUseCase: queueRequestAccessUseCase,
      queueRemoveAccessUseCase: queueRemoveAccessUseCase,
      probeClientApprovedAgentUseCase: probeClientApprovedAgentUseCase,
      discardQueuedClientAgentRequestAccessUseCase:
          discardQueuedClientAgentRequestAccessUseCase,
      readPendingActionsUseCase: readPendingActionsUseCase,
      syncPendingActionsUseCase: syncPendingActionsUseCase,
      getClientAgentTokenUseCase: getClientAgentTokenUseCase,
      saveClientAgentTokenUseCase: saveClientAgentTokenUseCase,
      retryClientAccessRequestUseCase: retryClientAccessRequestUseCase,
      observeAgentPresenceUseCase: ObserveAgentPresenceUseCase(presenceStream),
      // Tight delay so the debounce path runs in the test budget.
      hintConfirmDelay: const Duration(milliseconds: 30),
    );
  });

  tearDown(() async {
    controller.dispose();
    if (!presenceStream.disposed) {
      await presenceStream.dispose();
    }
  });

  group('ClientAgentsController PR-M part 2 — presence wire-up', () {
    test(
      'AgentPresenceHint(online) flips connectionStatus in-memory '
      'without calling REST immediately',
      () async {
        await controller.initialize();
        check(controller.approvedAgents).isNotNull();

        // a2 starts offline; a hint flips it to online without the
        // confirm timer firing yet.
        presenceStream.emit(
          AgentPresenceHint(
            agentId: 'a2',
            observedAt: DateTime.utc(2026, 4, 17, 12),
            online: true,
            source: 'agents:command_success',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final updated = controller.approvedAgents!.items.firstWhere(
          (a) => a.agentId == 'a2',
        );
        check(updated.connectionStatus).equals(AgentConnectionStatus.online);
        // Confirm timer hasn't fired yet (delay is 30 ms).
        verifyNever(
          () => loadClientAgentDetailUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        );
      },
    );

    test(
      'hint debounce calls LoadClientAgentDetailUseCase after the delay',
      () async {
        when(
          () => loadClientAgentDetailUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer(
          (_) async => Success<ClientAgent, AppFailure>(
            _agent(id: 'a2', connectionStatus: AgentConnectionStatus.online),
          ),
        );

        await controller.initialize();
        presenceStream.emit(
          AgentPresenceHint(
            agentId: 'a2',
            observedAt: DateTime.utc(2026, 4, 17, 12),
            online: true,
            source: 'agents:command_success',
          ),
        );
        // Wait past the 30 ms hint confirm delay.
        await Future<void>.delayed(const Duration(milliseconds: 80));

        verify(
          () => loadClientAgentDetailUseCase(
            userId: 'client-1',
            agentId: 'a2',
          ),
        ).called(1);
      },
    );

    test(
      'AgentPresenceCatalogUpdated triggers LoadClientAgentDetailUseCase '
      'and upserts the returned agent',
      () async {
        when(
          () => loadClientAgentDetailUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer(
          (_) async => Success<ClientAgent, AppFailure>(
            ClientAgent(
              agentId: 'a1',
              name: 'Agent a1 — refreshed',
              catalogStatus: AgentCatalogStatus.active,
              connectionStatus: AgentConnectionStatus.offline,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026, 4, 17, 13),
            ),
          ),
        );

        await controller.initialize();
        presenceStream.emit(
          AgentPresenceCatalogUpdated(
            agentId: 'a1',
            observedAt: DateTime.utc(2026, 4, 17, 12),
            changedFields: const <String>{'name'},
            profileVersion: 5,
            source: 'http',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        verify(
          () => loadClientAgentDetailUseCase(
            userId: 'client-1',
            agentId: 'a1',
          ),
        ).called(1);
        final updated = controller.approvedAgents!.items.firstWhere(
          (a) => a.agentId == 'a1',
        );
        check(updated.name).equals('Agent a1 — refreshed');
        check(updated.connectionStatus).equals(AgentConnectionStatus.offline);
      },
    );

    test('events with stale observedAt are dropped (dedup)', () async {
      when(
        () => loadClientAgentDetailUseCase(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => Success<ClientAgent, AppFailure>(
          _agent(id: 'a2', connectionStatus: AgentConnectionStatus.online),
        ),
      );
      await controller.initialize();

      // First event at t=12:00.
      presenceStream.emit(
        AgentPresenceHint(
          agentId: 'a2',
          observedAt: DateTime.utc(2026, 4, 17, 12),
          online: true,
          source: 'agents:command_success',
        ),
      );
      // Stale event at t=11:59 must be ignored.
      presenceStream.emit(
        AgentPresenceHint(
          agentId: 'a2',
          observedAt: DateTime.utc(2026, 4, 17, 11, 59),
          online: false,
          source: 'agents:command_error_offline',
        ),
      );
      // Equal observedAt is also stale (strictly newer wins).
      presenceStream.emit(
        AgentPresenceHint(
          agentId: 'a2',
          observedAt: DateTime.utc(2026, 4, 17, 12),
          online: false,
          source: 'agents:command_error_offline',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final updated = controller.approvedAgents!.items.firstWhere(
        (a) => a.agentId == 'a2',
      );
      check(updated.connectionStatus).equals(AgentConnectionStatus.online);
    });

    test('hint for an unknown agentId is a silent no-op', () async {
      await controller.initialize();
      final initialItems = controller.approvedAgents!.items.toList();

      presenceStream.emit(
        AgentPresenceHint(
          agentId: 'never-seen',
          observedAt: DateTime.utc(2026, 4, 17, 12),
          online: true,
          source: 'agents:command_success',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      check(controller.approvedAgents!.items).deepEquals(initialItems);
    });

    test(
      'controller without ObserveAgentPresenceUseCase ignores presence events '
      'and behaves like the legacy Refresh-only flow',
      () async {
        final legacyController = ClientAgentsController(
          authController: authController,
          clientTokenDraftStore: ClientAgentTokenDraftStore(clientTokenStore),
          loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
          loadAccessRequestsUseCase: loadAccessRequestsUseCase,
          loadClientAccessStatusUseCase: loadClientAccessStatusUseCase,
          loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
          queueRequestAccessUseCase: queueRequestAccessUseCase,
          queueRemoveAccessUseCase: queueRemoveAccessUseCase,
          probeClientApprovedAgentUseCase: probeClientApprovedAgentUseCase,
          discardQueuedClientAgentRequestAccessUseCase:
              discardQueuedClientAgentRequestAccessUseCase,
          readPendingActionsUseCase: readPendingActionsUseCase,
          syncPendingActionsUseCase: syncPendingActionsUseCase,
          getClientAgentTokenUseCase: getClientAgentTokenUseCase,
          saveClientAgentTokenUseCase: saveClientAgentTokenUseCase,
          retryClientAccessRequestUseCase: retryClientAccessRequestUseCase,
          // No `observeAgentPresenceUseCase` argument.
        );
        addTearDown(legacyController.dispose);

        await legacyController.initialize();
        // Emitting on the parallel stream must NOT touch the legacy
        // controller because it never subscribed.
        presenceStream.emit(
          AgentPresenceHint(
            agentId: 'a2',
            observedAt: DateTime.utc(2026, 4, 17, 12),
            online: true,
            source: 'agents:command_success',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final agent = legacyController.approvedAgents!.items.firstWhere(
          (a) => a.agentId == 'a2',
        );
        check(agent.connectionStatus).equals(AgentConnectionStatus.offline);
      },
    );

    group('PR-M part 3 — visibility-gated REST poller', () {
      late _MockAgentPresencePoller poller;
      late _MockConsumerSocketConnection connection;
      late StreamController<ConsumerSocketConnectionState> stateController;
      late ClientAgentsController gatedController;

      setUp(() {
        poller = _MockAgentPresencePoller();
        connection = _MockConsumerSocketConnection();
        stateController =
            StreamController<ConsumerSocketConnectionState>.broadcast();

        when(() => connection.isConnected).thenReturn(false);
        when(
          () => connection.states(),
        ).thenAnswer((_) => stateController.stream);
        when(() => poller.start(userId: any(named: 'userId'))).thenReturn(null);
        when(poller.stop).thenReturn(null);

        gatedController = ClientAgentsController(
          authController: authController,
          clientTokenDraftStore: ClientAgentTokenDraftStore(clientTokenStore),
          loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
          loadAccessRequestsUseCase: loadAccessRequestsUseCase,
          loadClientAccessStatusUseCase: loadClientAccessStatusUseCase,
          loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
          queueRequestAccessUseCase: queueRequestAccessUseCase,
          queueRemoveAccessUseCase: queueRemoveAccessUseCase,
          probeClientApprovedAgentUseCase: probeClientApprovedAgentUseCase,
          discardQueuedClientAgentRequestAccessUseCase:
              discardQueuedClientAgentRequestAccessUseCase,
          readPendingActionsUseCase: readPendingActionsUseCase,
          syncPendingActionsUseCase: syncPendingActionsUseCase,
          getClientAgentTokenUseCase: getClientAgentTokenUseCase,
          saveClientAgentTokenUseCase: saveClientAgentTokenUseCase,
          retryClientAccessRequestUseCase: retryClientAccessRequestUseCase,
          observeAgentPresenceUseCase: ObserveAgentPresenceUseCase(
            presenceStream,
          ),
          agentPresencePoller: poller,
          consumerSocketConnection: connection,
          hintConfirmDelay: const Duration(milliseconds: 30),
        );
      });

      tearDown(() async {
        gatedController.dispose();
        await stateController.close();
      });

      test(
        'starts polling when screen is visible AND socket is disconnected',
        () async {
          await gatedController.initialize();
          // Initialise() seeds the socket-state observer with the
          // current `isConnected == false`. Visibility transition turns
          // on the poller.
          gatedController.onScreenVisible();
          verify(() => poller.start(userId: 'client-1')).called(1);
        },
      );

      test('stops the poller when the socket comes back', () async {
        await gatedController.initialize();
        gatedController.onScreenVisible();
        clearInteractions(poller);

        // Socket comes back: poller must stop.
        when(() => connection.isConnected).thenReturn(true);
        stateController.add(
          ConsumerSocketConnected(
            socketId: 'sock',
            handshakeAt: DateTime.utc(2026),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        verify(poller.stop).called(1);
        verifyNever(() => poller.start(userId: any(named: 'userId')));
      });

      test('does NOT start the poller while the screen is hidden', () async {
        await gatedController.initialize();
        // Screen never went visible — even with the socket down the
        // poller should not run.
        verifyNever(() => poller.start(userId: any(named: 'userId')));
      });

      test('stops the poller when the screen hides', () async {
        await gatedController.initialize();
        gatedController.onScreenVisible();
        clearInteractions(poller);
        gatedController.onScreenHidden();
        verify(poller.stop).called(1);
      });

      test(
        'dispose cancels the socket subscription and stops the poller',
        () async {
          await gatedController.initialize();
          gatedController.onScreenVisible();
          clearInteractions(poller);

          gatedController.dispose();
          verify(poller.stop).called(1);
          // After dispose, future state events must not crash or call
          // start again.
          stateController.add(const ConsumerSocketDisconnected());
          await Future<void>.delayed(Duration.zero);
          verifyNever(() => poller.start(userId: any(named: 'userId')));
        },
      );
    });

    test(
      'dispose cancels the presence subscription and the hint timers',
      () async {
        when(
          () => loadClientAgentDetailUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer(
          (_) async => Success<ClientAgent, AppFailure>(
            _agent(id: 'a2', connectionStatus: AgentConnectionStatus.online),
          ),
        );
        await controller.initialize();
        presenceStream.emit(
          AgentPresenceHint(
            agentId: 'a2',
            observedAt: DateTime.utc(2026, 4, 17, 12),
            online: true,
            source: 'agents:command_success',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        controller.dispose();
        // Past the debounce window — confirm timer must NOT fire on a
        // disposed controller.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        verifyNever(
          () => loadClientAgentDetailUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        );
      },
    );
  });
}
