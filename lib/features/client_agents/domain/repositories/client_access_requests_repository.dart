import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_access_status_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:result_dart/result_dart.dart';

/// Client-side workflow: filing access requests, retrying or discarding
/// queued ones, syncing the local queue with the server, and reading the
/// authorization status of an opaque token (used by deep-link landings).
abstract interface class ClientAccessRequestsRepository {
  Future<AppResult<PaginatedResult<ClientAgentAccessRequest>>>
  loadAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  });

  Future<AppResult<Unit>> retryClientAccessRequest({
    required String userId,
    required String requestId,
  });

  Future<AppResult<ClientAccessStatusSnapshot>> loadClientAccessStatus({
    required String token,
  });

  /// Drops local `requestAccess` actions in `queued` or `failed` for [agentIds].
  Future<AppResult<Unit>> discardQueuedRequestAccessForAgents({
    required String userId,
    required Set<String> agentIds,
  });

  Future<AppResult<Unit>> queueRequestAccess({
    required String userId,
    required Set<String> agentIds,
  });

  Future<AppResult<Unit>> queueRemoveAccess({
    required String userId,
    required Set<String> agentIds,
  });

  Future<AppResult<List<PendingAgentAction>>> readPendingActions({
    required String userId,
  });

  Future<AppResult<SyncPendingAgentActionsResult>> syncPendingActions({
    required String userId,
  });
}
