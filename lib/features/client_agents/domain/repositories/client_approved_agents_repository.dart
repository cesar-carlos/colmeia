import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_approved_agent_probe_outcome.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:result_dart/result_dart.dart';

/// Reads the agents the current client has been approved to access, plus
/// the presence side-effects needed to render online status. Mutations
/// for granting/revoking access live in
/// `ClientAccessRequestsRepository` and `OwnerAgentsRepository`.
abstract interface class ClientApprovedAgentsRepository {
  Future<AppResult<PaginatedResult<ClientAgent>>> loadApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
    bool includeOnlineStatus = true,
    bool refresh = false,
  });

  Future<AppResult<ClientAgent>> loadApprovedAgentById({
    required String userId,
    required String agentId,
  });

  /// Network-only probe: linked vs not linked (`404`). Does not fall back to
  /// stale cached detail on 404.
  Future<AppResult<ClientApprovedAgentProbeOutcome>> probeApprovedAgentLink({
    required String userId,
    required String agentId,
  });

  /// Mirrors a freshly loaded [AgentProfileSnapshot] into the local approved
  /// caches so subsequent reads do not show pre-update data.
  Future<AppResult<Unit>> applyApprovedAgentProfileSnapshotLocally({
    required String userId,
    required String agentId,
    required AgentProfileSnapshot snapshot,
  });

  /// Agent ids currently reported as connected (hub/cache), or `null` when
  /// presence could not be resolved.
  Future<Set<String>?> loadOnlineAgentIds({required String userId});
}
