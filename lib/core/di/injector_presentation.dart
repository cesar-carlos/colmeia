import 'package:colmeia/core/di/injector_agent_queries.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/client_agent_token_draft_store.dart';
import 'package:colmeia/features/client_agents/application/services/agent_presence_poller.dart';
import 'package:colmeia/features/client_agents/application/usecases/approve_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_managed_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_approved_clients_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/observe_agent_presence_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/persist_client_agent_profile_snapshot_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/reject_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/retry_client_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/revoke_owner_client_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:colmeia/features/user_context/application/usecases/clear_active_store_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/load_current_user_context_use_case.dart';
import 'package:colmeia/features/user_context/application/usecases/persist_active_store_use_case.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/ports/agent_query_target_resolution_invalidator.dart';
import 'package:get_it/get_it.dart';

void registerInjectorPresentation(GetIt getIt) {
  getIt
    // App scope — same instance as [ColmeiaBootstrap]; Provider must not dispose.
    ..registerLazySingleton<CurrentUserContextController>(
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
        // App singleton — OverviewController must not dispose it on route exit.
        retryAfterGate: getIt<RetryAfterGate>(),
        agentRpcCapabilitiesRegistry: getIt<AgentRpcCapabilitiesRegistry>(),
        relayCancelScopeBinder: (scope) =>
            wireAgentQueriesCancelScopeHandlers(getIt, scope),
      ),
    )
    ..registerFactory<ClientAgentsController>(
      () => ClientAgentsController(
        authController: getIt<AuthController>(),
        clientTokenDraftStore: getIt<ClientAgentTokenDraftStore>(),
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
        getClientAgentTokenUseCase: getIt<GetClientAgentTokenUseCase>(),
        saveClientAgentTokenUseCase: getIt<SaveClientAgentTokenUseCase>(),
        retryClientAccessRequestUseCase:
            getIt<RetryClientAccessRequestUseCase>(),
        // Optional: only registered when SOCKET_PRESENCE_LISTENER_ENABLED.
        // The controller falls back to the legacy Refresh-only flow when
        // null, which keeps non-socket builds untouched.
        observeAgentPresenceUseCase:
            getIt.isRegistered<ObserveAgentPresenceUseCase>()
            ? getIt<ObserveAgentPresenceUseCase>()
            : null,
        // PR-M part 3: REST fallback poller + the connection used to
        // observe socket-state transitions. Both are nullable so
        // builds without the socket layer keep working unchanged.
        agentPresencePoller: getIt.isRegistered<AgentPresencePoller>()
            ? getIt<AgentPresencePoller>()
            : null,
        consumerSocketConnection: getIt.isRegistered<ConsumerSocketConnection>()
            ? getIt<ConsumerSocketConnection>()
            : null,
        targetResolutionInvalidator:
            getIt.isRegistered<AgentQueryTargetResolutionInvalidator>()
            ? getIt<AgentQueryTargetResolutionInvalidator>()
            : null,
      ),
    )
    ..registerFactory<ClientAgentsOwnerController>(
      () => ClientAgentsOwnerController(
        authController: getIt<AuthController>(),
        loadManagedAgentsUseCase: getIt<LoadManagedAgentsUseCase>(),
        loadOwnerAccessRequestsUseCase: getIt<LoadOwnerAccessRequestsUseCase>(),
        approveOwnerAccessRequestUseCase:
            getIt<ApproveOwnerAccessRequestUseCase>(),
        rejectOwnerAccessRequestUseCase:
            getIt<RejectOwnerAccessRequestUseCase>(),
        loadOwnerApprovedClientsUseCase:
            getIt<LoadOwnerApprovedClientsUseCase>(),
        revokeOwnerClientAccessUseCase: getIt<RevokeOwnerClientAccessUseCase>(),
      ),
    )
    ..registerFactory<ClientAgentDetailController>(
      () => ClientAgentDetailController(
        authController: getIt<AuthController>(),
        loadClientAgentDetailUseCase: getIt<LoadClientAgentDetailUseCase>(),
        updateClientAgentProfileUseCase:
            getIt<UpdateClientAgentProfileUseCase>(),
        getClientAgentTokenUseCase: getIt<GetClientAgentTokenUseCase>(),
        saveClientAgentTokenUseCase: getIt<SaveClientAgentTokenUseCase>(),
        removeClientAgentTokenUseCase: getIt<RemoveClientAgentTokenUseCase>(),
        persistClientAgentProfileSnapshotUseCase:
            getIt<PersistClientAgentProfileSnapshotUseCase>(),
        refreshAgentProfileUseCase: getIt<RefreshAgentProfileUseCase>(),
        loadClientTokenPolicyUseCase: getIt<LoadClientTokenPolicyUseCase>(),
        discoverAgentRpcMethodsUseCase: getIt<DiscoverAgentRpcMethodsUseCase>(),
        agentRpcCapabilitiesRegistry: getIt<AgentRpcCapabilitiesRegistry>(),
        targetResolutionInvalidator:
            getIt.isRegistered<AgentQueryTargetResolutionInvalidator>()
            ? getIt<AgentQueryTargetResolutionInvalidator>()
            : null,
      ),
    );
}
