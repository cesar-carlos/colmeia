import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:get_it/get_it.dart';

void registerInjectorPresentation(GetIt getIt) {
  getIt
    ..registerFactory<CurrentUserContextController>(
      () => CurrentUserContextController(
        authController: getIt<AuthController>(),
        loadCurrentUserContextUseCase: getIt<LoadCurrentUserContextUseCase>(),
        persistActiveStoreUseCase: getIt<PersistActiveStoreUseCase>(),
        clearActiveStoreUseCase: getIt<ClearActiveStoreUseCase>(),
      ),
    )
    ..registerFactory<OverviewController>(
      () => OverviewController(
        getIt<LoadOverviewUseCase>(),
        getIt<ClientAgentsRepository>(),
      ),
    )
    ..registerFactory<ClientAgentsController>(
      () => ClientAgentsController(
        authController: getIt<AuthController>(),
        clientTokenStore: getIt<LocalAgentClientTokenStore>(),
        loadApprovedAgentsUseCase: getIt<LoadClientApprovedAgentsUseCase>(),
        loadAccessRequestsUseCase: getIt<LoadClientAccessRequestsUseCase>(),
        loadClientAccessStatusUseCase: getIt<LoadClientAccessStatusUseCase>(),
        loadClientAgentDetailUseCase: getIt<LoadClientAgentDetailUseCase>(),
        queueRequestAccessUseCase:
            getIt<QueueClientAgentRequestAccessUseCase>(),
        queueRemoveAccessUseCase: getIt<QueueClientAgentRemoveAccessUseCase>(),
        probeClientApprovedAgentUseCase:
            getIt<ProbeClientApprovedAgentUseCase>(),
        discardQueuedClientAgentRequestAccessUseCase:
            getIt<DiscardQueuedClientAgentRequestAccessUseCase>(),
        readPendingActionsUseCase:
            getIt<ReadPendingClientAgentActionsUseCase>(),
        syncPendingActionsUseCase:
            getIt<SyncPendingClientAgentActionsUseCase>(),
      ),
    )
    ..registerFactory<ClientAgentDetailController>(
      () => ClientAgentDetailController(
        authController: getIt<AuthController>(),
        clientTokenStore: getIt<LocalAgentClientTokenStore>(),
        loadClientAgentDetailUseCase: getIt<LoadClientAgentDetailUseCase>(),
        updateClientAgentProfileUseCase:
            getIt<UpdateClientAgentProfileUseCase>(),
      ),
    );
}
