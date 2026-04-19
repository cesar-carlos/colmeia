import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/agent_meta/data/datasources/agent_meta_remote_datasource.dart';
import 'package:colmeia/features/agent_meta/data/repositories/agent_meta_repository_impl.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

void registerInjectorAgentMeta(GetIt getIt) {
  getIt
    ..registerLazySingleton<AgentMetaRemoteDataSource>(
      () => ApiAgentMetaRemoteDataSource(getIt<Dio>()),
    )
    ..registerLazySingleton<AgentMetaRepository>(
      () => AgentMetaRepositoryImpl(getIt<AgentMetaRemoteDataSource>()),
    )
    ..registerLazySingleton<RefreshAgentProfileUseCase>(
      () => RefreshAgentProfileUseCase(getIt<AgentMetaRepository>()),
    )
    ..registerLazySingleton<LoadClientTokenPolicyUseCase>(
      () => LoadClientTokenPolicyUseCase(getIt<AgentMetaRepository>()),
    )
    ..registerLazySingleton<DiscoverAgentRpcMethodsUseCase>(
      () => DiscoverAgentRpcMethodsUseCase(getIt<AgentMetaRepository>()),
    );
}
