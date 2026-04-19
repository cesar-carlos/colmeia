import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';

/// Asks the agent which RPC methods it supports (`rpc.discover`).
///
/// Use the resulting [AgentRpcDescriptor] to gate UI features that depend
/// on a specific method (e.g. only show "Refresh from agent" when the
/// agent advertises `agent.getProfile`).
class DiscoverAgentRpcMethodsUseCase {
  DiscoverAgentRpcMethodsUseCase(this._repository);

  final AgentMetaRepository _repository;

  Future<AppResult<AgentRpcDescriptor>> call({
    required String agentId,
  }) {
    return _repository.discoverAgentRpc(agentId: agentId);
  }
}
