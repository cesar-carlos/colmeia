import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
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

class _MockReadPendingClientAgentActionsUseCase extends Mock
    implements ReadPendingClientAgentActionsUseCase {}

class _MockSyncPendingClientAgentActionsUseCase extends Mock
    implements SyncPendingClientAgentActionsUseCase {}

void main() {
  late _MockAuthController authController;
  late _MockLoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase;
  late _MockLoadClientAccessRequestsUseCase loadAccessRequestsUseCase;
  late _MockLoadClientAccessStatusUseCase loadClientAccessStatusUseCase;
  late _MockLoadClientAgentDetailUseCase loadClientAgentDetailUseCase;
  late _MockQueueClientAgentRequestAccessUseCase queueRequestAccessUseCase;
  late _MockQueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase;
  late _MockReadPendingClientAgentActionsUseCase readPendingActionsUseCase;
  late _MockSyncPendingClientAgentActionsUseCase syncPendingActionsUseCase;
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
    readPendingActionsUseCase = _MockReadPendingClientAgentActionsUseCase();
    syncPendingActionsUseCase = _MockSyncPendingClientAgentActionsUseCase();

    when(() => authController.session).thenReturn(session);
    when(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
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
      (_) async =>
          const Success<ClientAccessStatusSnapshot, AppFailure>(
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
      () => readPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<List<PendingAgentAction>, AppFailure>(
        emptyPendingActions,
      ),
    );
    controller = ClientAgentsController(
      authController: authController,
      loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
      loadAccessRequestsUseCase: loadAccessRequestsUseCase,
      loadClientAccessStatusUseCase: loadClientAccessStatusUseCase,
      loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
      queueRequestAccessUseCase: queueRequestAccessUseCase,
      queueRemoveAccessUseCase: queueRemoveAccessUseCase,
      readPendingActionsUseCase: readPendingActionsUseCase,
      syncPendingActionsUseCase: syncPendingActionsUseCase,
    )..activeLocalizations = AppLocalizationsEn();
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
        ),
      ),
    );

    await controller.initialize();
    await Future<void>.delayed(Duration.zero);

    verify(() => syncPendingActionsUseCase(userId: session.userId)).called(1);
    check(controller.actionFeedbackMessage).isNotNull();
    expect(controller.actionFeedbackMessage, contains('sent for review'));
    expect(
      controller.actionFeedbackMessage,
      contains('track approval'),
    );
  });

  test(
    'should map repository failure key to Portuguese when Pt localizations '
    'are active',
    () async {
      when(
        () => loadApprovedAgentsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
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

      controller.activeLocalizations = AppLocalizationsPt();
      await controller.refreshAll();

      check(controller.approvedAgentsErrorMessage).equals(
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
      check(controller.actionErrorMessage).isNotNull();
      expect(
        controller.actionErrorMessage,
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
    check(controller.actionFeedbackMessage).isNotNull();
    expect(controller.actionFeedbackMessage, contains('Request submitted'));
    expect(controller.actionFeedbackMessage, contains('IDs were ignored'));
  });

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
        controller.actionFeedbackMessage,
        contains('already available under "My agents"'),
      );
    },
  );
}
