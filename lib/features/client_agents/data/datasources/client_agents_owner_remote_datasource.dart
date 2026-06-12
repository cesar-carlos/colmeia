import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_approved_clients_response_dto.dart';

/// Owner-side moderation of managed agents and client access.
abstract interface class ClientAgentsOwnerRemoteDataSource {
  Future<ClientApprovedAgentsResponseDto> fetchManagedAgents();

  Future<OwnerAccessRequestsResponseDto> fetchOwnerAccessRequests();

  Future<void> approveOwnerAccessRequest({required String requestId});

  Future<void> rejectOwnerAccessRequest({required String requestId});

  Future<OwnerApprovedClientsResponseDto> fetchApprovedClientsForManagedAgent({
    required String agentId,
  });

  Future<void> revokeManagedAgentClientAccess({
    required String agentId,
    required String clientId,
  });
}
