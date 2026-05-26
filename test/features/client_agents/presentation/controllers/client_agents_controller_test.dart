import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/client_agent_token_draft_store.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/retry_client_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_presentation_message_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_invalidator.dart';
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

class _MockAgentQueryTargetResolutionInvalidator extends Mock
    implements AgentQueryTargetResolutionInvalidator {}

String? _localizedMessage(
  ClientAgentsPresentationMessage? message, {
  AppLocalizations? l10n,
}) {
  if (message == null) {
    return null;
  }
  return localizeClientAgentsPresentationMessage(
    message,
    l10n ?? AppLocalizationsEn(),
  );
}

String? _actionErrorText(
  ClientAgentsController controller, {
  AppLocalizations? l10n,
}) {
  return _localizedMessage(controller.actionError, l10n: l10n);
}

String? _actionFeedbackText(
  ClientAgentsController controller, {
  AppLocalizations? l10n,
}) {
  return _localizedMessage(controller.actionNotice?.message, l10n: l10n);
}

String? _approvedAgentsErrorText(
  ClientAgentsController controller, {
  AppLocalizations? l10n,
}) {
  return _localizedMessage(controller.approvedAgentsError, l10n: l10n);
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
  late _MockAgentQueryTargetResolutionInvalidator targetResolutionInvalidator;
  late ClientAgentsController controller;

  final approvedAgentsResult = PaginatedResult<ClientAgent>(
    items: <ClientAgent>[
      ClientAgent(
        agentId: '11111111-1111-1111-8111-111111111111',
        name: 'Agente aprovado',
        catalogStatus: AgentCatalogStatus.active,
        connectionStatus: AgentConnectionStatus.online,
        createdAt: DateTime(2026, 4, 4),
        updatedAt: DateTime(2026, 4, 4),
      ),
    ],
    count: 1,
    total: 1,
    page: 1,
    pageSize: 50,
  );

  final refreshedApprovedAgentsResult = PaginatedResult<ClientAgent>(
    items: <ClientAgent>[
      ClientAgent(
        agentId: '99999999-9999-9999-8999-999999999999',
        name: 'Agente atualizado',
        catalogStatus: AgentCatalogStatus.active,
        connectionStatus: AgentConnectionStatus.online,
        createdAt: DateTime(2026, 4, 8),
        updatedAt: DateTime(2026, 4, 8),
      ),
    ],
    count: 1,
    total: 1,
    page: 1,
    pageSize: 50,
  );

  const pendingRemoteRequestsResult = PaginatedResult<ClientAgentAccessRequest>(
    items: <ClientAgentAccessRequest>[
      ClientAgentAccessRequest(
        agentId: '22222222-2222-2222-8222-222222222222',
        agentName: 'Agente remoto pendente',
        status: AgentAccessRequestStatus.pending,
      ),
    ],
    count: 1,
    total: 1,
    page: 1,
    pageSize: 50,
  );

  const emptyRequestsResult = PaginatedResult<ClientAgentAccessRequest>(
    items: <ClientAgentAccessRequest>[],
    count: 0,
    total: 0,
    page: 1,
    pageSize: 50,
  );

  final queuedPendingActions = <PendingAgentAction>[
    PendingAgentAction(
      id: 'requestAccess_33333333-3333-3333-8333-333333333333',
      agentId: '33333333-3333-3333-8333-333333333333',
      type: PendingAgentActionType.requestAccess,
      state: PendingAgentActionState.queued,
      createdAt: DateTime(2026, 4, 4),
      attemptCount: 0,
    ),
  ];

  const emptyPendingActions = <PendingAgentAction>[];

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

    when(() => authController.session).thenReturn(session);
    when(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        approvedAgentsResult,
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
            emptyRequestsResult,
          ),
    );
    when(
      () => loadAccessRequestsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
            emptyRequestsResult,
          ),
    );
    when(
      () => loadClientAgentDetailUseCase(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Failure<ClientAgent, AppFailure>(
        UnknownFailure(message: 'Agent not approved yet'),
      ),
    );
    when(
      () => loadClientAccessStatusUseCase(token: any(named: 'token')),
    ).thenAnswer(
      (_) async => const Success<ClientAccessStatusSnapshot, AppFailure>(
        ClientAccessStatusSnapshot(
          status: AgentAccessRequestStatus.pending,
        ),
      ),
    );
    when(
      () => syncPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<SyncPendingAgentActionsResult, AppFailure>(
        SyncPendingAgentActionsResult(),
      ),
    );
    when(
      () => queueRequestAccessUseCase(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));
    when(
      () => queueRemoveAccessUseCase(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));
    when(
      () => probeClientApprovedAgentUseCase(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Success<ClientApprovedAgentProbeOutcome, AppFailure>(
        ClientApprovedAgentProbeOutcome.notLinked(),
      ),
    );
    when(
      () => discardQueuedClientAgentRequestAccessUseCase(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));
    when(
      () => readPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<List<PendingAgentAction>, AppFailure>(
        emptyPendingActions,
      ),
    );
    clientTokenStore = _MockLocalAgentClientTokenStore();
    when(
      () => clientTokenStore.read(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => clientTokenStore.write(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => clientTokenStore.delete(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => clientTokenStore.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => <String, String>{});
    getClientAgentTokenUseCase = _MockGetClientAgentTokenUseCase();
    retryClientAccessRequestUseCase = _MockRetryClientAccessRequestUseCase();
    targetResolutionInvalidator = _MockAgentQueryTargetResolutionInvalidator();
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
    saveClientAgentTokenUseCase = _MockSaveClientAgentTokenUseCase();
    when(
      () => retryClientAccessRequestUseCase(
        userId: any(named: 'userId'),
        requestId: any(named: 'requestId'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));
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
      targetResolutionInvalidator: targetResolutionInvalidator,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('should auto sync pending actions during initialize', () async {
    when(
      () => readPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => Success<List<PendingAgentAction>, AppFailure>(
        queuedPendingActions,
      ),
    );
    when(
      () => syncPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<SyncPendingAgentActionsResult, AppFailure>(
        SyncPendingAgentActionsResult(
          successfulRequestAccessAgentIds: <String>{
            '33333333-3333-3333-8333-333333333333',
          },
          requestAccessPollAgentIds: <String>{
            '33333333-3333-3333-8333-333333333333',
          },
        ),
      ),
    );

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);

    verify(() => syncPendingActionsUseCase(userId: session.userId)).called(1);
    check(controller.actionNotice).isNotNull();
    expect(
      _actionFeedbackText(controller),
      contains('pending action finished syncing'),
    );
    expect(
      _actionFeedbackText(controller),
      contains('track approval'),
    );
  });

  test(
    'should retry automatic sync after the cooldown gate reopens while pending remains',
    () async {
      final retryGate = RetryAfterGate(
        tickInterval: const Duration(milliseconds: 20),
      );
      var syncCallCount = 0;

      when(
        () => readPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => Success<List<PendingAgentAction>, AppFailure>(
          queuedPendingActions,
        ),
      );
      when(
        () => syncPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer((_) async {
        syncCallCount++;
        if (syncCallCount == 1) {
          return const Failure<SyncPendingAgentActionsResult, AppFailure>(
            NetworkFailure(
              message: 'rate limited',
              userMessage: 'rate limited',
              retryAfter: Duration(milliseconds: 80),
            ),
          );
        }
        return const Success<SyncPendingAgentActionsResult, AppFailure>(
          SyncPendingAgentActionsResult(),
        );
      });

      final dedicatedController = ClientAgentsController(
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
        syncRetryAfterGate: retryGate,
      );
      addTearDown(dedicatedController.dispose);

      await dedicatedController.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(syncCallCount, greaterThanOrEqualTo(2));
    },
  );

  test(
    'should preserve loaded content while refreshing all sections',
    () async {
      final approvedRefreshCompleter =
          Completer<AppResult<PaginatedResult<ClientAgent>>>();

      await controller.refreshAll();

      when(
        () => loadApprovedAgentsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer((_) => approvedRefreshCompleter.future);

      final refreshFuture = controller.refreshAll();

      await Future<void>.delayed(Duration.zero);

      check(controller.isRefreshing).isTrue();
      check(controller.isLoadingInitial).isFalse();
      check(controller.approvedAgents).isNotNull();
      check(controller.approvedAgents!.items.single.name).equals(
        'Agente aprovado',
      );

      approvedRefreshCompleter.complete(
        Success<PaginatedResult<ClientAgent>, AppFailure>(
          refreshedApprovedAgentsResult,
        ),
      );

      await refreshFuture;

      check(controller.isRefreshing).isFalse();
      check(controller.approvedAgents).isNotNull();
      check(controller.approvedAgents!.items.single.name).equals(
        'Agente atualizado',
      );
    },
  );

  test(
    'should ignore stale refresh result when a newer refresh wins',
    () async {
      final firstRefreshCompleter =
          Completer<AppResult<PaginatedResult<ClientAgent>>>();
      final secondRefreshCompleter =
          Completer<AppResult<PaginatedResult<ClientAgent>>>();
      var approvedCallCount = 0;

      await controller.refreshAll();

      when(
        () => loadApprovedAgentsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer((_) {
        approvedCallCount += 1;
        return approvedCallCount == 1
            ? firstRefreshCompleter.future
            : secondRefreshCompleter.future;
      });

      final firstRefresh = controller.refreshAll();
      final secondRefresh = controller.refreshAll();

      firstRefreshCompleter.complete(
        Success<PaginatedResult<ClientAgent>, AppFailure>(
          approvedAgentsResult,
        ),
      );

      await firstRefresh;

      check(controller.isRefreshing).isTrue();
      check(controller.approvedAgents).isNotNull();
      check(controller.approvedAgents!.items.single.name).equals(
        'Agente aprovado',
      );

      secondRefreshCompleter.complete(
        Success<PaginatedResult<ClientAgent>, AppFailure>(
          refreshedApprovedAgentsResult,
        ),
      );

      await secondRefresh;

      check(controller.isRefreshing).isFalse();
      check(controller.approvedAgents).isNotNull();
      check(controller.approvedAgents!.items.single.name).equals(
        'Agente atualizado',
      );
    },
  );

  test(
    'should map repository failure key to Portuguese when Pt localizations '
    'are active',
    () async {
      when(
        () => loadApprovedAgentsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async => const Failure<PaginatedResult<ClientAgent>, AppFailure>(
          NetworkFailure(
            message: 'technical',
            userMessage: 'Fallback user message',
            context: <String, Object?>{
              ClientAgentsFailureUiKey.field:
                  ClientAgentsFailureUiKey.loadApprovedAgents,
            },
          ),
        ),
      );

      await controller.refreshAll();

      check(
        _approvedAgentsErrorText(controller, l10n: AppLocalizationsPt()),
      ).equals(
        AppLocalizationsPt().clientAgentsErrorLoadApproved,
      );
    },
  );

  test(
    'should block request when all ids are already approved or pending',
    () async {
      when(
        () => loadAccessRequestsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              PaginatedResult<ClientAgentAccessRequest>,
              AppFailure
            >(
              pendingRemoteRequestsResult,
            ),
      );
      when(
        () => readPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Success<List<PendingAgentAction>, AppFailure>(
          emptyPendingActions,
        ),
      );

      await controller.refreshAll();
      await controller.requestAccess(
        agentIds: const <String>{
          '11111111-1111-1111-8111-111111111111',
          '22222222-2222-2222-8222-222222222222',
        },
      );

      verifyNever(
        () => queueRequestAccessUseCase(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      );
      check(controller.actionError).isNotNull();
      expect(
        _actionErrorText(controller),
        contains('No new agents can be requested'),
      );
    },
  );

  test('should queue only fresh ids and report ignored duplicates', () async {
    when(
      () => loadAccessRequestsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
            pendingRemoteRequestsResult,
          ),
    );
    when(
      () => readPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<List<PendingAgentAction>, AppFailure>(
        emptyPendingActions,
      ),
    );

    await controller.refreshAll();
    await controller.requestAccess(
      agentIds: const <String>{
        '11111111-1111-1111-8111-111111111111',
        '22222222-2222-2222-8222-222222222222',
        '44444444-4444-4444-8444-444444444444',
      },
    );

    verify(
      () => queueRequestAccessUseCase(
        userId: session.userId,
        agentIds: const <String>{'44444444-4444-4444-8444-444444444444'},
      ),
    ).called(1);
    check(controller.actionNotice).isNotNull();
    expect(_actionFeedbackText(controller), contains('Request submitted'));
    expect(_actionFeedbackText(controller), contains('IDs were ignored'));
  });

  test(
    'should relink when probe finds agent already approved on server',
    () async {
      const agentId = '44444444-4444-4444-8444-444444444444';
      final linkedAt = DateTime(2026, 4);
      final linkedAgent = ClientAgent(
        agentId: agentId,
        name: 'Relink agent',
        catalogStatus: AgentCatalogStatus.active,
        connectionStatus: AgentConnectionStatus.offline,
        createdAt: linkedAt,
        updatedAt: linkedAt,
      );
      reset(probeClientApprovedAgentUseCase);
      when(
        () => probeClientApprovedAgentUseCase(
          userId: session.userId,
          agentId: agentId,
        ),
      ).thenAnswer(
        (_) async => Success<ClientApprovedAgentProbeOutcome, AppFailure>(
          ClientApprovedAgentProbeOutcome.linked(linkedAgent),
        ),
      );

      await controller.refreshAll();
      final accepted = await controller.requestAccess(
        agentIds: const <String>{agentId},
      );

      check(accepted).isTrue();
      verifyNever(
        () => queueRequestAccessUseCase(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      );
      verify(
        () => discardQueuedClientAgentRequestAccessUseCase(
          userId: session.userId,
          agentIds: const <String>{agentId},
        ),
      ).called(1);
      verify(
        () => loadApprovedAgentsUseCase(
          userId: session.userId,
          query: any(named: 'query'),
          refresh: true,
        ),
      ).called(1);
      check(controller.actionNotice).isNotNull();
      expect(
        _actionFeedbackText(controller),
        contains('already approved on the server'),
      );
      check(
        controller.approvedAgents!.items.any((a) => a.agentId == agentId),
      ).isTrue();
    },
  );

  test(
    'should abort request access when probe returns session failure',
    () async {
      const agentId = 'aaaaaaaa-aaaa-aaaa-8aaa-aaaaaaaaaaaa';
      reset(probeClientApprovedAgentUseCase);
      when(
        () => probeClientApprovedAgentUseCase(
          userId: session.userId,
          agentId: agentId,
        ),
      ).thenAnswer(
        (_) async => const Failure<ClientApprovedAgentProbeOutcome, AppFailure>(
          SessionFailure(message: 'Unauthorized'),
        ),
      );

      await controller.refreshAll();
      final accepted = await controller.requestAccess(
        agentIds: const <String>{agentId},
      );

      check(accepted).isFalse();
      verifyNever(
        () => queueRequestAccessUseCase(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      );
      check(controller.actionError).isNotNull();
      expect(
        _actionErrorText(controller),
        contains('Session unavailable'),
      );
    },
  );

  test(
    'should queue ids that fell back after probe failure alongside fresh ids',
    () async {
      const failedProbeId = 'aaaaaaaa-aaaa-aaaa-8aaa-aaaaaaaaaaaa';
      const notLinkedId = 'bbbbbbbb-bbbb-bbbb-8bbb-bbbbbbbbbbbb';
      reset(probeClientApprovedAgentUseCase);
      when(
        () => probeClientApprovedAgentUseCase(
          userId: session.userId,
          agentId: failedProbeId,
        ),
      ).thenAnswer(
        (_) async => const Failure<ClientApprovedAgentProbeOutcome, AppFailure>(
          NetworkFailure(message: 'offline'),
        ),
      );
      when(
        () => probeClientApprovedAgentUseCase(
          userId: session.userId,
          agentId: notLinkedId,
        ),
      ).thenAnswer(
        (_) async => const Success<ClientApprovedAgentProbeOutcome, AppFailure>(
          ClientApprovedAgentProbeOutcome.notLinked(),
        ),
      );

      await controller.refreshAll();
      final accepted = await controller.requestAccess(
        agentIds: const <String>{failedProbeId, notLinkedId},
      );

      check(accepted).isTrue();
      verify(
        () => queueRequestAccessUseCase(
          userId: session.userId,
          agentIds: const <String>{failedProbeId, notLinkedId},
        ),
      ).called(1);
    },
  );

  test(
    'should combine relink summary and queued message when mixing linked and new ids',
    () async {
      const linkedId = '44444444-4444-4444-8444-444444444444';
      const freshId = '55555555-5555-5555-8555-555555555555';
      final linkedAt = DateTime(2026, 4);
      final linkedAgent = ClientAgent(
        agentId: linkedId,
        name: 'Relink agent',
        catalogStatus: AgentCatalogStatus.active,
        connectionStatus: AgentConnectionStatus.offline,
        createdAt: linkedAt,
        updatedAt: linkedAt,
      );
      reset(probeClientApprovedAgentUseCase);
      when(
        () => probeClientApprovedAgentUseCase(
          userId: session.userId,
          agentId: linkedId,
        ),
      ).thenAnswer(
        (_) async => Success<ClientApprovedAgentProbeOutcome, AppFailure>(
          ClientApprovedAgentProbeOutcome.linked(linkedAgent),
        ),
      );
      when(
        () => probeClientApprovedAgentUseCase(
          userId: session.userId,
          agentId: freshId,
        ),
      ).thenAnswer(
        (_) async => const Success<ClientApprovedAgentProbeOutcome, AppFailure>(
          ClientApprovedAgentProbeOutcome.notLinked(),
        ),
      );

      await controller.refreshAll();
      final accepted = await controller.requestAccess(
        agentIds: const <String>{linkedId, freshId},
      );

      check(accepted).isTrue();
      verify(
        () => queueRequestAccessUseCase(
          userId: session.userId,
          agentIds: const <String>{freshId},
        ),
      ).called(1);
      verify(
        () => targetResolutionInvalidator.invalidate(userId: session.userId),
      ).called(1);
      check(controller.actionNotice).isNotNull();
      expect(
        _actionFeedbackText(controller),
        contains('already approved on the server'),
      );
      expect(_actionFeedbackText(controller), contains('Request submitted'));
      expect(_actionFeedbackText(controller), contains('. Request'));
    },
  );

  test(
    'should still update approved list when discard fails after relink probe',
    () async {
      const agentId = '44444444-4444-4444-8444-444444444444';
      final linkedAt = DateTime(2026, 4);
      final linkedAgent = ClientAgent(
        agentId: agentId,
        name: 'Relink agent',
        catalogStatus: AgentCatalogStatus.active,
        connectionStatus: AgentConnectionStatus.offline,
        createdAt: linkedAt,
        updatedAt: linkedAt,
      );
      reset(probeClientApprovedAgentUseCase);
      when(
        () => probeClientApprovedAgentUseCase(
          userId: session.userId,
          agentId: agentId,
        ),
      ).thenAnswer(
        (_) async => Success<ClientApprovedAgentProbeOutcome, AppFailure>(
          ClientApprovedAgentProbeOutcome.linked(linkedAgent),
        ),
      );
      reset(discardQueuedClientAgentRequestAccessUseCase);
      when(
        () => discardQueuedClientAgentRequestAccessUseCase(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      ).thenAnswer(
        (_) async => const Failure<Unit, AppFailure>(
          StorageFailure(message: 'disk'),
        ),
      );

      await controller.refreshAll();
      final accepted = await controller.requestAccess(
        agentIds: const <String>{agentId},
      );

      check(accepted).isTrue();
      check(controller.actionError).isNull();
      check(controller.actionNotice).isNotNull();
      expect(
        _actionFeedbackText(controller),
        contains('Could not clear local pending'),
      );
      check(
        controller.approvedAgents!.items.any((a) => a.agentId == agentId),
      ).isTrue();
      verify(
        () => discardQueuedClientAgentRequestAccessUseCase(
          userId: session.userId,
          agentIds: const <String>{agentId},
        ),
      ).called(2);
    },
  );

  test(
    'should upsert approved agent when directed polling finds approval',
    () async {
      const watchedAgentId = '33333333-3333-3333-8333-333333333333';
      when(
        () => readPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => Success<List<PendingAgentAction>, AppFailure>(
          queuedPendingActions,
        ),
      );
      when(
        () => syncPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Success<SyncPendingAgentActionsResult, AppFailure>(
          SyncPendingAgentActionsResult(
            successfulRequestAccessAgentIds: <String>{watchedAgentId},
            requestAccessPollAgentIds: <String>{watchedAgentId},
          ),
        ),
      );
      when(
        () => loadClientAgentDetailUseCase(
          userId: any(named: 'userId'),
          agentId: watchedAgentId,
        ),
      ).thenAnswer(
        (_) async => Success<ClientAgent, AppFailure>(
          ClientAgent(
            agentId: watchedAgentId,
            name: 'Agente novo aprovado',
            catalogStatus: AgentCatalogStatus.active,
            connectionStatus: AgentConnectionStatus.unknown,
            createdAt: DateTime(2026, 4, 7),
            updatedAt: DateTime(2026, 4, 7),
          ),
        ),
      );
      when(
        () => loadAccessRequestsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              PaginatedResult<ClientAgentAccessRequest>,
              AppFailure
            >(
              emptyRequestsResult,
            ),
      );

      await controller.refreshAll();
      await controller.syncPending();
      await Future<void>.delayed(Duration.zero);

      check(controller.approvedAgents).isNotNull();
      expect(
        controller.approvedAgents!.items.any(
          (agent) => agent.agentId == watchedAgentId,
        ),
        isTrue,
      );
      expect(
        _actionFeedbackText(controller),
        contains('already available under "My agents"'),
      );
      verify(
        () => targetResolutionInvalidator.invalidate(userId: session.userId),
      ).called(1);
    },
  );

  test(
    'syncPending invalidates target resolution after successful remove access',
    () async {
      final removePending = <PendingAgentAction>[
        PendingAgentAction(
          id: 'removeAccess_33333333-3333-3333-8333-333333333333',
          agentId: '33333333-3333-3333-8333-333333333333',
          type: PendingAgentActionType.removeAccess,
          state: PendingAgentActionState.queued,
          createdAt: DateTime(2026, 4, 4),
          attemptCount: 0,
        ),
      ];
      var readCount = 0;
      when(
        () => readPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer((_) async {
        readCount++;
        return Success<List<PendingAgentAction>, AppFailure>(
          readCount == 1 ? removePending : emptyPendingActions,
        );
      });
      when(
        () => syncPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Success<SyncPendingAgentActionsResult, AppFailure>(
          SyncPendingAgentActionsResult(
            successfulRemoveAccessAgentIds: <String>{
              '33333333-3333-3333-8333-333333333333',
            },
          ),
        ),
      );

      await controller.initialize();
      clearInteractions(targetResolutionInvalidator);

      await controller.syncPending();

      verify(
        () => targetResolutionInvalidator.invalidate(userId: session.userId),
      ).called(1);
    },
  );

  group('Retry-After integration', () {
    test(
      'syncPending arms the cooldown gate when failure carries retryAfter',
      () async {
        when(
          () => readPendingActionsUseCase(userId: any(named: 'userId')),
        ).thenAnswer(
          (_) async => Success<List<PendingAgentAction>, AppFailure>(
            queuedPendingActions,
          ),
        );
        when(
          () => syncPendingActionsUseCase(userId: any(named: 'userId')),
        ).thenAnswer(
          (_) async => const Failure<SyncPendingAgentActionsResult, AppFailure>(
            NetworkFailure(
              message: 'rate limited',
              userMessage: 'rate limited',
              retryAfter: Duration(seconds: 10),
            ),
          ),
        );

        await controller.initialize();
        await controller.syncPending();

        expect(controller.isSyncOnCooldown, isTrue);
        expect(controller.syncRetryAfter, isNotNull);
        expect(controller.syncRetryAfter!.inSeconds, greaterThan(0));
      },
    );

    test(
      'second syncPending call short-circuits while cooldown is active',
      () async {
        when(
          () => readPendingActionsUseCase(userId: any(named: 'userId')),
        ).thenAnswer(
          (_) async => Success<List<PendingAgentAction>, AppFailure>(
            queuedPendingActions,
          ),
        );
        when(
          () => syncPendingActionsUseCase(userId: any(named: 'userId')),
        ).thenAnswer(
          (_) async => const Failure<SyncPendingAgentActionsResult, AppFailure>(
            NetworkFailure(
              message: 'rate limited',
              userMessage: 'rate limited',
              retryAfter: Duration(seconds: 30),
            ),
          ),
        );

        await controller.initialize();
        await controller.syncPending();
        // Reset the mock so we can detect a second call.
        clearInteractions(syncPendingActionsUseCase);
        await controller.syncPending();

        verifyNever(
          () => syncPendingActionsUseCase(userId: any(named: 'userId')),
        );
        expect(controller.actionError, isNotNull);
      },
    );
  });

  test(
    'retryAccessRequest replays request by requestId and exposes feedback',
    () async {
      const retriableRequest = ClientAgentAccessRequest(
        agentId: '22222222-2222-2222-8222-222222222222',
        agentName: 'Agente remoto pendente',
        requestId: 'rq-1001',
        status: AgentAccessRequestStatus.rejected,
      );
      when(
        () => loadAccessRequestsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              PaginatedResult<ClientAgentAccessRequest>,
              AppFailure
            >(
              PaginatedResult<ClientAgentAccessRequest>(
                items: <ClientAgentAccessRequest>[retriableRequest],
                count: 1,
                total: 1,
                page: 1,
                pageSize: 50,
              ),
            ),
      );

      await controller.initialize();
      await controller.retryAccessRequest(request: retriableRequest);

      verify(
        () => retryClientAccessRequestUseCase(
          userId: session.userId,
          requestId: 'rq-1001',
        ),
      ).called(1);
      expect(controller.actionError, isNull);
      expect(_actionFeedbackText(controller), contains('approval'));
    },
  );

  test(
    'discardQueuedRequestAccess ignores removeAccess pending actions',
    () async {
      final removeQueued = PendingAgentAction(
        id: 'removeAccess_x',
        agentId: '33333333-3333-3333-8333-333333333333',
        type: PendingAgentActionType.removeAccess,
        state: PendingAgentActionState.queued,
        createdAt: DateTime(2026, 4, 4),
        attemptCount: 0,
      );
      when(
        () => readPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => Success<List<PendingAgentAction>, AppFailure>(
          <PendingAgentAction>[removeQueued],
        ),
      );

      await controller.initialize();
      await controller.discardQueuedRequestAccess(action: removeQueued);

      verifyNever(
        () => discardQueuedClientAgentRequestAccessUseCase(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      );
      expect(controller.actionError, isNotNull);
    },
  );

  test(
    'discardQueuedRequestAccess calls discard use case and clears local token',
    () async {
      var readIdx = 0;
      final pendingSequence = <List<PendingAgentAction>>[
        List<PendingAgentAction>.from(queuedPendingActions),
        List<PendingAgentAction>.from(queuedPendingActions),
        emptyPendingActions,
      ];
      when(
        () => readPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer((_) async {
        final idx = readIdx < pendingSequence.length
            ? readIdx
            : pendingSequence.length - 1;
        readIdx++;
        return Success<List<PendingAgentAction>, AppFailure>(
          pendingSequence[idx],
        );
      });
      when(
        () => syncPendingActionsUseCase(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Failure<SyncPendingAgentActionsResult, AppFailure>(
          UnknownFailure(message: 'sync failed for test'),
        ),
      );

      await controller.initialize();
      await Future<void>.delayed(Duration.zero);

      await controller.discardQueuedRequestAccess(
        action: queuedPendingActions.single,
      );

      verify(
        () => discardQueuedClientAgentRequestAccessUseCase(
          userId: session.userId,
          agentIds: <String>{'33333333-3333-3333-8333-333333333333'},
        ),
      ).called(1);
      verify(
        () => clientTokenStore.delete(
          userId: session.userId,
          agentId: '33333333-3333-3333-8333-333333333333',
        ),
      ).called(1);
      expect(controller.actionError, isNull);
      expect(_actionFeedbackText(controller), contains('removed'));
    },
  );
}
