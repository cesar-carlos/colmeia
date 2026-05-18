import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';
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
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agent_access_request_row_input.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
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

class _MockGetClientAgentTokenUseCase extends Mock
    implements GetClientAgentTokenUseCase {}

class _MockSaveClientAgentTokenUseCase extends Mock
    implements SaveClientAgentTokenUseCase {}

class _MockRetryClientAccessRequestUseCase extends Mock
    implements RetryClientAccessRequestUseCase {}

class _MockLocalAgentClientTokenStore extends Mock
    implements LocalAgentClientTokenStore {}

void main() {
  late _MockAuthController authController;
  late _MockLocalAgentClientTokenStore tokenStore;
  late _MockLoadClientApprovedAgentsUseCase loadApprovedAgentsUseCase;
  late _MockLoadClientAccessRequestsUseCase loadAccessRequestsUseCase;
  late _MockLoadClientAccessStatusUseCase loadClientAccessStatusUseCase;
  late _MockLoadClientAgentDetailUseCase loadClientAgentDetailUseCase;
  late _MockQueueClientAgentRequestAccessUseCase queueRequestAccessUseCase;
  late _MockQueueClientAgentRemoveAccessUseCase queueRemoveAccessUseCase;
  late _MockProbeClientApprovedAgentUseCase probeUseCase;
  late _MockDiscardQueuedClientAgentRequestAccessUseCase discardUseCase;
  late _MockReadPendingClientAgentActionsUseCase readPendingActionsUseCase;
  late _MockSyncPendingClientAgentActionsUseCase syncPendingActionsUseCase;
  late _MockGetClientAgentTokenUseCase getTokenUseCase;
  late _MockSaveClientAgentTokenUseCase saveTokenUseCase;
  late _MockRetryClientAccessRequestUseCase retryClientAccessRequestUseCase;
  late ClientAgentsController controller;

  const userId = 'client-1';
  const newAgentId = '11111111-1111-1111-8111-111111111111';
  const linkedAgentId = '22222222-2222-2222-8222-222222222222';

  final session = AuthSession(
    userId: userId,
    email: EmailAddress('client@example.com'),
    accessToken: 't',
    refreshToken: 'r',
    expiresAt: DateTime(2099),
    accountStatus: ClientAccountStatus.active,
  );

  ClientAgent buildAgent(String id) => ClientAgent(
    agentId: id,
    name: 'Agent $id',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime(2026, 4, 4),
    updatedAt: DateTime(2026, 4, 4),
  );

  setUpAll(() {
    registerFallbackValue(const PaginatedQuery());
    registerFallbackValue(<String>{});
  });

  setUp(() {
    authController = _MockAuthController();
    tokenStore = _MockLocalAgentClientTokenStore();
    loadApprovedAgentsUseCase = _MockLoadClientApprovedAgentsUseCase();
    loadAccessRequestsUseCase = _MockLoadClientAccessRequestsUseCase();
    loadClientAccessStatusUseCase = _MockLoadClientAccessStatusUseCase();
    loadClientAgentDetailUseCase = _MockLoadClientAgentDetailUseCase();
    queueRequestAccessUseCase = _MockQueueClientAgentRequestAccessUseCase();
    queueRemoveAccessUseCase = _MockQueueClientAgentRemoveAccessUseCase();
    probeUseCase = _MockProbeClientApprovedAgentUseCase();
    discardUseCase = _MockDiscardQueuedClientAgentRequestAccessUseCase();
    readPendingActionsUseCase = _MockReadPendingClientAgentActionsUseCase();
    syncPendingActionsUseCase = _MockSyncPendingClientAgentActionsUseCase();
    getTokenUseCase = _MockGetClientAgentTokenUseCase();
    saveTokenUseCase = _MockSaveClientAgentTokenUseCase();
    retryClientAccessRequestUseCase = _MockRetryClientAccessRequestUseCase();

    when(() => authController.session).thenReturn(session);
    when(
      () => readPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<List<PendingAgentAction>, AppFailure>(
        <PendingAgentAction>[],
      ),
    );
    when(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => const Success<PaginatedResult<ClientAgent>, AppFailure>(
        PaginatedResult<ClientAgent>(
          items: <ClientAgent>[],
          count: 0,
          total: 0,
          page: 1,
          pageSize: 50,
        ),
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
      () => syncPendingActionsUseCase(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<SyncPendingAgentActionsResult, AppFailure>(
        SyncPendingAgentActionsResult(),
      ),
    );
    when(
      () => discardUseCase(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));
    when(
      () => tokenStore.read(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => tokenStore.write(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => tokenStore.delete(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => getTokenUseCase(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
        ClientAgentTokenSnapshot.empty(),
      ),
    );
    when(
      () => saveTokenUseCase(
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

    controller = ClientAgentsController(
      authController: authController,
      clientTokenDraftStore: ClientAgentTokenDraftStore(tokenStore),
      loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
      loadAccessRequestsUseCase: loadAccessRequestsUseCase,
      loadClientAccessStatusUseCase: loadClientAccessStatusUseCase,
      loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
      queueRequestAccessUseCase: queueRequestAccessUseCase,
      queueRemoveAccessUseCase: queueRemoveAccessUseCase,
      probeClientApprovedAgentUseCase: probeUseCase,
      discardQueuedClientAgentRequestAccessUseCase: discardUseCase,
      readPendingActionsUseCase: readPendingActionsUseCase,
      syncPendingActionsUseCase: syncPendingActionsUseCase,
      getClientAgentTokenUseCase: getTokenUseCase,
      saveClientAgentTokenUseCase: saveTokenUseCase,
      retryClientAccessRequestUseCase: retryClientAccessRequestUseCase,
    )..activeLocalizations = AppLocalizationsEn();
  });

  tearDown(() => controller.dispose());

  group('submitAccessRequestWithLocalTokens — transactional behavior', () {
    test(
      'rejects token longer than the server cap before any side effect',
      () async {
        final tooLong = 'x' * (ClientAgentTokenRequestDto.maxTokenLength + 1);
        final accepted = await controller.submitAccessRequestWithLocalTokens(
          <ClientAgentAccessRequestRowInput>[
            ClientAgentAccessRequestRowInput(
              agentIdRaw: newAgentId,
              clientTokenRaw: tooLong,
            ),
          ],
        );

        check(accepted).isFalse();
        check(controller.actionErrorMessage).isNotNull();
        verifyNever(
          () => tokenStore.write(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
            clientToken: any(named: 'clientToken'),
          ),
        );
        verifyNever(
          () => tokenStore.delete(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        );
        verifyNever(
          () => probeUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        );
      },
    );

    test(
      'queued path: writes token to local cache only after queueing succeeds',
      () async {
        when(
          () => probeUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<ClientApprovedAgentProbeOutcome, AppFailure>(
                ClientApprovedAgentProbeOutcome.notLinked(),
              ),
        );
        when(
          () => queueRequestAccessUseCase(
            userId: any(named: 'userId'),
            agentIds: any(named: 'agentIds'),
          ),
        ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));

        final accepted = await controller.submitAccessRequestWithLocalTokens(
          const <ClientAgentAccessRequestRowInput>[
            ClientAgentAccessRequestRowInput(
              agentIdRaw: newAgentId,
              clientTokenRaw: '  tok-new  ',
            ),
          ],
        );

        check(accepted).isTrue();
        verify(
          () => tokenStore.write(
            userId: userId,
            agentId: newAgentId,
            clientToken: 'tok-new',
          ),
        ).called(1);
        verifyNever(
          () => saveTokenUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
            clientToken: any(named: 'clientToken'),
          ),
        );
      },
    );

    test(
      'relink path: PUTs token to the server immediately via SaveTokenUseCase',
      () async {
        when(
          () => probeUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer(
          (_) async => Success<ClientApprovedAgentProbeOutcome, AppFailure>(
            ClientApprovedAgentProbeOutcome.linked(buildAgent(linkedAgentId)),
          ),
        );

        final accepted = await controller.submitAccessRequestWithLocalTokens(
          const <ClientAgentAccessRequestRowInput>[
            ClientAgentAccessRequestRowInput(
              agentIdRaw: linkedAgentId,
              clientTokenRaw: 'tok-relink',
            ),
          ],
        );

        check(accepted).isTrue();
        verify(
          () => saveTokenUseCase(
            userId: userId,
            agentId: linkedAgentId,
            clientToken: 'tok-relink',
          ),
        ).called(1);
      },
    );

    test(
      'relink server PUT failure falls back to local cache',
      () async {
        when(
          () => probeUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer(
          (_) async => Success<ClientApprovedAgentProbeOutcome, AppFailure>(
            ClientApprovedAgentProbeOutcome.linked(buildAgent(linkedAgentId)),
          ),
        );
        when(
          () => saveTokenUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
            clientToken: any(named: 'clientToken'),
          ),
        ).thenAnswer(
          (_) async => const Failure<ClientAgentTokenSnapshot, AppFailure>(
            NetworkFailure(message: 'timeout', userMessage: 'sem rede'),
          ),
        );

        final accepted = await controller.submitAccessRequestWithLocalTokens(
          const <ClientAgentAccessRequestRowInput>[
            ClientAgentAccessRequestRowInput(
              agentIdRaw: linkedAgentId,
              clientTokenRaw: 'tok-relink',
            ),
          ],
        );

        check(accepted).isTrue();
        verify(
          () => tokenStore.write(
            userId: userId,
            agentId: linkedAgentId,
            clientToken: 'tok-relink',
          ),
        ).called(1);
      },
    );

    test(
      'queue failure restores the local-token snapshot for touched ids',
      () async {
        // Pre-existing token in the cache for this id (simulating a prior
        // saved value the user did not intend to wipe out).
        when(
          () => tokenStore.read(
            userId: any(named: 'userId'),
            agentId: newAgentId,
          ),
        ).thenAnswer((_) async => 'previous-token');
        when(
          () => probeUseCase(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<ClientApprovedAgentProbeOutcome, AppFailure>(
                SessionFailure(
                  message: 'unauthorized',
                  userMessage: 'sem sessao',
                ),
              ),
        );

        final accepted = await controller.submitAccessRequestWithLocalTokens(
          const <ClientAgentAccessRequestRowInput>[
            ClientAgentAccessRequestRowInput(
              agentIdRaw: newAgentId,
              clientTokenRaw: 'overwrite-attempt',
            ),
          ],
        );

        check(accepted).isFalse();
        // Snapshot restoration: previous token written back, not the new
        // value the user tried to submit.
        verify(
          () => tokenStore.write(
            userId: userId,
            agentId: newAgentId,
            clientToken: 'previous-token',
          ),
        ).called(1);
        verifyNever(
          () => tokenStore.write(
            userId: userId,
            agentId: newAgentId,
            clientToken: 'overwrite-attempt',
          ),
        );
      },
    );
  });

  group('readLocalClientToken', () {
    test('hits the server for already-approved agents', () async {
      when(
        () => loadApprovedAgentsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
          PaginatedResult<ClientAgent>(
            items: <ClientAgent>[buildAgent(linkedAgentId)],
            count: 1,
            total: 1,
            page: 1,
            pageSize: 50,
          ),
        ),
      );
      when(
        () => getTokenUseCase(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
          ClientAgentTokenSnapshot(token: 'srv-token'),
        ),
      );

      await controller.initialize();

      final value = await controller.readLocalClientToken(linkedAgentId);
      check(value).equals('srv-token');
      verify(
        () => getTokenUseCase(userId: userId, agentId: linkedAgentId),
      ).called(1);
    });

    test('falls back to local store for not-yet-approved agents', () async {
      when(
        () => tokenStore.read(
          userId: any(named: 'userId'),
          agentId: newAgentId,
        ),
      ).thenAnswer((_) async => 'local-only');

      final value = await controller.readLocalClientToken(newAgentId);
      check(value).equals('local-only');
      verifyNever(
        () => getTokenUseCase(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      );
    });
  });

  group('persistLocalClientTokenDraftLine', () {
    test('drops persistence when token exceeds the server cap', () async {
      final tooLong = 'x' * (ClientAgentTokenRequestDto.maxTokenLength + 1);
      await controller.persistLocalClientTokenDraftLine(
        agentIdRaw: newAgentId,
        clientTokenRaw: tooLong,
      );
      verifyNever(
        () => tokenStore.write(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      );
    });

    test('writes when token fits within the cap', () async {
      await controller.persistLocalClientTokenDraftLine(
        agentIdRaw: newAgentId,
        clientTokenRaw: 'short',
      );
      verify(
        () => tokenStore.write(
          userId: userId,
          agentId: newAgentId,
          clientToken: 'short',
        ),
      ).called(1);
    });

    test('deletes when token is empty after trim', () async {
      await controller.persistLocalClientTokenDraftLine(
        agentIdRaw: newAgentId,
        clientTokenRaw: '   ',
      );
      verify(
        () => tokenStore.delete(userId: userId, agentId: newAgentId),
      ).called(1);
    });
  });
}
