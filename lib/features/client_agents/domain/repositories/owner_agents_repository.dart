import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:result_dart/result_dart.dart';

/// Owner-side moderation: list the agents this owner administers, review
/// access requests filed by clients, approve/reject them, and revoke
/// existing client links per agent.
abstract interface class OwnerAgentsRepository {
  Future<AppResult<List<ClientAgent>>> loadManagedAgents({
    required String userId,
  });

  Future<AppResult<List<OwnerClientAccessRequest>>> loadOwnerAccessRequests({
    required String userId,
  });

  Future<AppResult<Unit>> approveOwnerAccessRequest({
    required String userId,
    required String requestId,
  });

  Future<AppResult<Unit>> rejectOwnerAccessRequest({
    required String userId,
    required String requestId,
  });

  Future<AppResult<List<OwnerApprovedClient>>> loadOwnerApprovedClients({
    required String userId,
    required String agentId,
  });

  Future<AppResult<Unit>> revokeOwnerClientAccess({
    required String userId,
    required String agentId,
    required String clientId,
  });
}
