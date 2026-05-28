import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_manager.dart';
import 'package:colmeia/core/socket/relay/relay_conversation_pre_warmer.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/client_agents/application/client_agent_token_draft_store.dart';
import 'package:colmeia/features/client_agents/application/client_agents_page_session_service.dart';
import 'package:colmeia/features/client_agents/application/client_approved_agents_relay_pre_warm_loader.dart';
import 'package:colmeia/features/client_agents/application/services/agent_presence_poller.dart';
import 'package:colmeia/features/client_agents/application/usecases/approve_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_catalog_agent_by_id_use_case.dart';
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
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/data/repositories/remote_agent_client_token_repository.dart';
import 'package:colmeia/features/client_agents/data/socket/agent_command_presence_hinter.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/data/socket/socket_agent_presence_stream.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void registerInjectorClientAgents(GetIt getIt) {
  getIt
    ..registerLazySingleton<LocalAgentClientTokenStore>(
      () => LocalAgentClientTokenStore(getIt<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<ClientAgentTokenDraftStore>(
      () => ClientAgentTokenDraftStore(getIt<LocalAgentClientTokenStore>()),
    )
    ..registerLazySingleton<ClientAgentsPageSessionService>(
      () => ClientAgentsPageSessionService(getIt<SharedPreferences>()),
    )
    ..registerLazySingleton<AgentClientTokenRepository>(
      () => RemoteAgentClientTokenRepository(
        remoteDataSource: getIt<ClientAgentsRemoteDataSource>(),
        localStore: getIt<LocalAgentClientTokenStore>(),
      ),
    )
    // Server-aware repository doubles as the bulk reader used by the
    // agent_queries SQL pipeline (cache-backed). Old wiring pointed straight
    // to LocalAgentClientTokenStore; consumers using AgentClientTokenReader
    // do not need to change.
    ..registerLazySingleton<AgentClientTokenReader>(
      () => getIt<AgentClientTokenRepository>(),
    )
    ..registerLazySingleton<ClientAgentsLocalDataSource>(
      () => ClientAgentsLocalDataSource(getIt<AppCacheStore>()),
    )
    ..registerLazySingleton<ClientAgentsRemoteDataSource>(
      () => AppEnvironment.useFakeBackend
          ? FakeClientAgentsRemoteDataSource()
          : ApiClientAgentsRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<ClientAgentsRepository>(
      () => ClientAgentsRepositoryImpl(
        remoteDataSource: getIt<ClientAgentsRemoteDataSource>(),
        localDataSource: getIt<ClientAgentsLocalDataSource>(),
      ),
    )
    ..registerLazySingleton<LoadCatalogAgentByIdUseCase>(
      () => LoadCatalogAgentByIdUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<LoadClientApprovedAgentsUseCase>(
      () => LoadClientApprovedAgentsUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<LoadManagedAgentsUseCase>(
      () => LoadManagedAgentsUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<LoadClientAccessRequestsUseCase>(
      () => LoadClientAccessRequestsUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<LoadOwnerAccessRequestsUseCase>(
      () => LoadOwnerAccessRequestsUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<LoadClientAccessStatusUseCase>(
      () => LoadClientAccessStatusUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<LoadClientAgentDetailUseCase>(
      () => LoadClientAgentDetailUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<UpdateClientAgentProfileUseCase>(
      () => UpdateClientAgentProfileUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<PersistClientAgentProfileSnapshotUseCase>(
      () => PersistClientAgentProfileSnapshotUseCase(
        getIt<ClientAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<GetClientAgentTokenUseCase>(
      () => GetClientAgentTokenUseCase(getIt<AgentClientTokenRepository>()),
    )
    ..registerLazySingleton<SaveClientAgentTokenUseCase>(
      () => SaveClientAgentTokenUseCase(getIt<AgentClientTokenRepository>()),
    )
    ..registerLazySingleton<RemoveClientAgentTokenUseCase>(
      () => RemoveClientAgentTokenUseCase(getIt<AgentClientTokenRepository>()),
    )
    ..registerLazySingleton<QueueClientAgentRequestAccessUseCase>(
      () =>
          QueueClientAgentRequestAccessUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<RetryClientAccessRequestUseCase>(
      () => RetryClientAccessRequestUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<ProbeClientApprovedAgentUseCase>(
      () => ProbeClientApprovedAgentUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<DiscardQueuedClientAgentRequestAccessUseCase>(
      () => DiscardQueuedClientAgentRequestAccessUseCase(
        getIt<ClientAgentsRepository>(),
      ),
    )
    ..registerLazySingleton<QueueClientAgentRemoveAccessUseCase>(
      () =>
          QueueClientAgentRemoveAccessUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<ReadPendingClientAgentActionsUseCase>(
      () =>
          ReadPendingClientAgentActionsUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<SyncPendingClientAgentActionsUseCase>(
      () =>
          SyncPendingClientAgentActionsUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<ApproveOwnerAccessRequestUseCase>(
      () => ApproveOwnerAccessRequestUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<RejectOwnerAccessRequestUseCase>(
      () => RejectOwnerAccessRequestUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<LoadOwnerApprovedClientsUseCase>(
      () => LoadOwnerApprovedClientsUseCase(getIt<ClientAgentsRepository>()),
    )
    ..registerLazySingleton<RevokeOwnerClientAccessUseCase>(
      () => RevokeOwnerClientAccessUseCase(getIt<ClientAgentsRepository>()),
    );

  // PR-M: realtime presence (client:agent.profile.updated + agents:command
  // hints). Lives next to the existing client_agents wiring because that
  // is the feature consuming it. Gated by SOCKET_PRESENCE_LISTENER_ENABLED
  // so builds without the socket transport never instantiate the
  // PayloadFrame codec or the dispatcher subscription.
  if (AppEnvironment.socketPresenceListenerEnabled) {
    getIt
      ..registerLazySingleton<ClientAgentProfileUpdatedListener>(
        () => ClientAgentProfileUpdatedListener(
          connection: getIt<ConsumerSocketConnection>(),
          sink: getIt<SocketAgentPresenceStream>().sink,
          acceptLegacyRawJson:
              AppEnvironment.socketProfileUpdatedLegacyRawJsonEnabled,
        ),
        dispose: (l) => l.dispose(),
      )
      ..registerLazySingleton<AgentCommandPresenceHinter>(
        () => AgentCommandPresenceHinter(
          dispatcher: getIt<SocketCommandDispatcher>(),
          sink: getIt<SocketAgentPresenceStream>().sink,
        ),
        dispose: (h) => h.dispose(),
      )
      ..registerLazySingleton<SocketAgentPresenceStream>(
        () => SocketAgentPresenceStream.deferred(
          connection: getIt<ConsumerSocketConnection>(),
        ),
        dispose: (s) => s.dispose(),
      )
      ..registerLazySingleton<AgentPresenceStream>(
        () {
          // Touch the listeners through getIt so DI graph instantiates
          // them and they self-attach via the `deferred()` post-init.
          final stream = getIt<SocketAgentPresenceStream>()
            ..bind(
              catalogListener: getIt<ClientAgentProfileUpdatedListener>(),
              commandHinter: getIt<AgentCommandPresenceHinter>(),
            );
          return stream;
        },
      )
      ..registerLazySingleton<ObserveAgentPresenceUseCase>(
        () => ObserveAgentPresenceUseCase(getIt<AgentPresenceStream>()),
      )
      // PR-M part 3: Camada 3 (REST poller) shares the presence stream
      // sink so its `online` hints land in the same `AgentPresenceEvent`
      // pipeline that the controller already consumes. Stays idle by
      // default — `ClientAgentsController.onScreenVisible/Hidden` plus
      // the socket state transitions decide when to call `start()`.
      ..registerLazySingleton<AgentPresencePoller>(
        () => AgentPresencePoller(
          clientAgentsRepository: getIt<ClientAgentsRepository>(),
          sink: getIt<SocketAgentPresenceStream>().sink,
        ),
        dispose: (poller) => poller.dispose(),
      );
  }

  // Relay conversation pre-warm: opens `relay:conversation.start` for the
  // client's approved agents as soon as the consumer socket is connected,
  // so the first cross-agent `mergeAll` wave does not pay one synchronous
  // round-trip per agent. Lives here because it bridges the relay manager
  // (core/socket) and the client_agents data layer; the implementation
  // itself stays in `core/socket/relay/` and only depends on a callback.
  if (getIt.isRegistered<RelayConversationManager>()) {
    getIt
      ..registerLazySingleton<ClientApprovedAgentsRelayPreWarmLoader>(
        () => ClientApprovedAgentsRelayPreWarmLoader(
          sessionAccessor: getIt<AuthSessionAccessor>(),
          approvedAgentsRepository: getIt<ClientAgentsRepository>(),
        ),
      )
      ..registerLazySingleton<RelayConversationPreWarmer>(
        () => RelayConversationPreWarmer(
          connection: getIt<ConsumerSocketConnection>(),
          conversationManager: getIt<RelayConversationManager>(),
          loadAgentIds: getIt<ClientApprovedAgentsRelayPreWarmLoader>()
              .loadApprovedAgentIds,
        ),
        dispose: (preWarmer) => preWarmer.dispose(),
      );
  }
}
