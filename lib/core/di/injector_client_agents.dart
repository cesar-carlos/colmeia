import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_catalog_agent_by_id_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_catalog_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

void registerInjectorClientAgents(GetIt getIt) {
  getIt
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
    ..registerLazySingleton<LoadClientAgentCatalogUseCase>(
      () => LoadClientAgentCatalogUseCase(getIt<ClientAgentsRepository>()),
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
    ..registerLazySingleton<QueueClientAgentRequestAccessUseCase>(
      () =>
          QueueClientAgentRequestAccessUseCase(getIt<ClientAgentsRepository>()),
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
}
