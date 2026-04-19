import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:result_dart/result_dart.dart';

/// Server-aware client-token repository.
///
/// The hub stores a per-(client, agent) bearer token used by the SQL bridge as
/// `params.client_token`. The full value is only readable through the
/// dedicated GET endpoint; list/detail endpoints expose `hasClientToken`
/// instead. Implementations may keep a local fallback cache so that offline
/// dashboards keep working when the server is unreachable.
///
/// Extends [AgentClientTokenReader] so the same instance can be wired into
/// [AgentClientTokenReader] consumers (e.g. `agent_queries` SQL pipeline)
/// without dual registration.
abstract interface class AgentClientTokenRepository
    implements AgentClientTokenReader {
  /// Reads the token currently stored for `(userId, agentId)`.
  ///
  /// Returns `Success(ClientAgentTokenSnapshot.empty())` when no token is
  /// configured. Returns a typed failure when the network call fails AND no
  /// usable cached value exists.
  Future<AppResult<ClientAgentTokenSnapshot>> getToken({
    required String userId,
    required String agentId,
  });

  /// Stores [clientToken] on the server. When the call succeeds, the local
  /// cache is updated to mirror the new value. Returns the normalized server
  /// value (which may differ in whitespace).
  Future<AppResult<ClientAgentTokenSnapshot>> saveToken({
    required String userId,
    required String agentId,
    required String clientToken,
  });

  /// Clears the token for `(userId, agentId)` on the server and locally.
  Future<AppResult<Unit>> removeToken({
    required String userId,
    required String agentId,
  });
}
