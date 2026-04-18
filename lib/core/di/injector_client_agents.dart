import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/socket/consumer_socket_connection.dart';
import 'package:colmeia/core/socket/socket_command_dispatcher.dart';
import 'package:colmeia/features/client_agents/application/services/agent_presence_poller.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_catalog_agent_by_id_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/observe_agent_presence_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/data/socket/agent_command_presence_hinter.dart';
import 'package:colmeia/features/client_agents/data/socket/client_agent_profile_updated_listener.dart';
import 'package:colmeia/features/client_agents/data/socket/socket_agent_presence_stream.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/ports/agent_presence_stream.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

void registerInjectorClientAgents(GetIt getIt) {
  getIt
    ..registerLazySingleton<LocalAgentClientTokenStore>(
      () => LocalAgentClientTokenStore(getIt<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<AgentClientTokenReader>(
      () => getIt<LocalAgentClientTokenStore>(),
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
    ..registerLazySingleton<LoadClientAccessRequestsUseCase>(
      () => LoadClientAccessRequestsUseCase(getIt<ClientAgentsRepository>()),
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
    ..registerLazySingleton<QueueClientAgentRequestAccessUseCase>(
      () =>
          QueueClientAgentRequestAccessUseCase(getIt<ClientAgentsRepository>()),
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
}
