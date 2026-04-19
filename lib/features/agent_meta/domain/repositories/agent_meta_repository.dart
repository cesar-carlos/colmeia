import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';

/// Read-only meta-API for an `Agent` reachable via the hub.
///
/// Surface kept narrow: the controllers consume one method per use case,
/// so we expose three explicit calls instead of a generic `invokeRpc`.
abstract interface class AgentMetaRepository {
  /// Calls `agent.getProfile` on the agent (forwarded by the hub via
  /// `POST /api/v1/agents/commands`). Returns the current snapshot of
  /// agent profile data, including `profileVersion` when the agent
  /// implements profile 2.7+.
  Future<AppResult<AgentProfileSnapshot>> getAgentProfile({
    required String agentId,
    String? clientToken,
  });

  /// Calls `client_token.getPolicy` on the agent. The agent does NOT
  /// execute SQL — it only returns the resolved authorization policy for
  /// the supplied token. Useful to render "what can this token do?" in
  /// the UI.
  ///
  /// Returns [ClientTokenPolicySnapshot.unsupported] when the agent
  /// reports the method as unimplemented (older profile / introspection
  /// disabled), so callers can hide the section without surfacing an
  /// error.
  Future<AppResult<ClientTokenPolicySnapshot>> getClientTokenPolicy({
    required String agentId,
    required String clientToken,
  });

  /// Calls `rpc.discover` on the agent and returns the catalogue of
  /// methods. Use [AgentRpcDescriptor.supportsMethod] to gate UI features
  /// that depend on a specific RPC (e.g. show the "Refresh from agent"
  /// button only when `agent.getProfile` is in the catalogue).
  Future<AppResult<AgentRpcDescriptor>> discoverAgentRpc({
    required String agentId,
  });
}
