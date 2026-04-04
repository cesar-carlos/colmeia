import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_catalog_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/dashboards/application/usecases/load_dashboard_overview_use_case.dart';
import 'package:colmeia/features/dashboards/presentation/controllers/dashboard_controller.dart';
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
    ..registerFactory<DashboardController>(
      () => DashboardController(getIt<LoadDashboardOverviewUseCase>()),
    )
    ..registerFactory<ClientAgentsController>(
      () => ClientAgentsController(
        authController: getIt<AuthController>(),
        loadCatalogUseCase: getIt<LoadClientAgentCatalogUseCase>(),
        loadApprovedAgentsUseCase: getIt<LoadClientApprovedAgentsUseCase>(),
        loadAccessRequestsUseCase: getIt<LoadClientAccessRequestsUseCase>(),
        queueRequestAccessUseCase:
            getIt<QueueClientAgentRequestAccessUseCase>(),
        queueRemoveAccessUseCase: getIt<QueueClientAgentRemoveAccessUseCase>(),
        readPendingActionsUseCase:
            getIt<ReadPendingClientAgentActionsUseCase>(),
        syncPendingActionsUseCase:
            getIt<SyncPendingClientAgentActionsUseCase>(),
      ),
    )
    ..registerFactory<ClientAgentDetailController>(
      () => ClientAgentDetailController(
        authController: getIt<AuthController>(),
        loadClientAgentDetailUseCase: getIt<LoadClientAgentDetailUseCase>(),
      ),
    );
}
