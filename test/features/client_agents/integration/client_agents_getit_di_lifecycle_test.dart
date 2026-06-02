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
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLocalAgentClientTokenStore extends Mock
    implements LocalAgentClientTokenStore {}

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

/// Mirrors agents route wiring: factory [ClientAgentsController] with optional
/// injected shared [RetryAfterGate] instances (production uses owned gates).
void main() {
  late GetIt getIt;
  late _MockAuthController authController;
  late ClientAgentTokenDraftStore draftStore;

  setUp(() {
    getIt = GetIt.asNewInstance();
    authController = _MockAuthController();
    draftStore = ClientAgentTokenDraftStore(_MockLocalAgentClientTokenStore());

    when(() => authController.session).thenReturn(
      AuthSession(
        userId: 'client-1',
        email: EmailAddress('client@example.com'),
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime(2099),
      ),
    );

    final sharedSyncGate = RetryAfterGate();
    final sharedRequestGate = RetryAfterGate();
    getIt
      ..registerLazySingleton<RetryAfterGate>(() => sharedSyncGate)
      ..registerLazySingleton<RetryAfterGate>(
        instanceName: 'requestAccess',
        () => sharedRequestGate,
      )
      ..registerFactory<ClientAgentsController>(
        () => ClientAgentsController(
          authController: authController,
          clientTokenDraftStore: draftStore,
          loadApprovedAgentsUseCase: _MockLoadClientApprovedAgentsUseCase(),
          loadAccessRequestsUseCase: _MockLoadClientAccessRequestsUseCase(),
          loadClientAccessStatusUseCase: _MockLoadClientAccessStatusUseCase(),
          loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
          queueRequestAccessUseCase:
              _MockQueueClientAgentRequestAccessUseCase(),
          queueRemoveAccessUseCase: _MockQueueClientAgentRemoveAccessUseCase(),
          probeClientApprovedAgentUseCase:
              _MockProbeClientApprovedAgentUseCase(),
          discardQueuedClientAgentRequestAccessUseCase:
              _MockDiscardQueuedClientAgentRequestAccessUseCase(),
          readPendingActionsUseCase:
              _MockReadPendingClientAgentActionsUseCase(),
          syncPendingActionsUseCase:
              _MockSyncPendingClientAgentActionsUseCase(),
          getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
          saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
          retryClientAccessRequestUseCase:
              _MockRetryClientAccessRequestUseCase(),
          syncRetryAfterGate: getIt<RetryAfterGate>(),
          requestAccessRetryAfterGate: getIt<RetryAfterGate>(
            instanceName: 'requestAccess',
          ),
        ),
      );
  });

  tearDown(() async {
    await getIt.reset();
  });

  test(
    'second ClientAgentsController from GetIt reuses injected RetryAfterGates',
    () {
      final syncGate = getIt<RetryAfterGate>();
      final requestGate = getIt<RetryAfterGate>(instanceName: 'requestAccess');

      final first = getIt<ClientAgentsController>();
      expect(first.isSyncOnCooldown, isFalse);
      first.dispose();

      syncGate.arm(const Duration(seconds: 20));

      final second = getIt<ClientAgentsController>();
      expect(second.isSyncOnCooldown, isTrue);
      expect(requestGate.isOpen, isTrue);
    },
  );
}
