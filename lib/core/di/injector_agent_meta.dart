import 'package:colmeia/core/config/agent_bridge_transport.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
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
      () => switch (AppEnvironment.agentBridgeTransport) {
        AgentBridgeTransport.socket =>
          SocketWithRestFallbackAgentMetaRemoteDataSource(
            socketDelegate: SocketAgentMetaRemoteDataSource(
              sender: getIt<AgentCommandSender>(),
            ),
            restDelegate: ApiAgentMetaRemoteDataSource(getIt<Dio>()),
            onFallback: (trigger) => AppLogger.warning(
              'AgentMetaRemoteDataSource latched to REST fallback',
              context: <String, Object?>{
                'triggerCode': trigger.code,
                'triggerMessage': trigger.message,
                'agentBridgeTransport':
                    AppEnvironment.agentBridgeTransport.wireValue,
              },
            ),
          ),
        AgentBridgeTransport.rest => ApiAgentMetaRemoteDataSource(getIt<Dio>()),
      },
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
    )
    // Registry is a process-wide cache — register as a singleton so
    // every controller (overview, detail, queries) shares the same
    // capability snapshot. Disposed implicitly when GetIt is reset.
    ..registerLazySingleton<AgentRpcCapabilitiesRegistry>(
      () => AgentRpcCapabilitiesRegistry(
        discoverAgentRpcMethodsUseCase: getIt<DiscoverAgentRpcMethodsUseCase>(),
      ),
    );
}
