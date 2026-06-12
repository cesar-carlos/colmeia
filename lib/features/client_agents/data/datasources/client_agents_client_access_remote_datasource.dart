import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_status_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_request_access_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';

/// Client-side approved agents, access requests, mutations and presence.
abstract interface class ClientAgentsClientAccessRemoteDataSource {
  Future<ClientApprovedAgentsResponseDto> fetchApprovedAgents({
    required PaginatedQuery query,
    String? search,
    String? status,
    bool refresh = false,
  });

  Future<ClientApprovedAgentDetailResponseDto> fetchApprovedAgentById(
    String agentId,
  );

  Future<ClientApprovedAgentDetailResponseDto?> fetchApprovedAgentDetailOrNull(
    String agentId,
  );

  Future<ClientAccessRequestsResponseDto> fetchAccessRequests({
    required PaginatedQuery query,
    String? search,
    String? status,
  });

  Future<void> retryAccessRequest({required String requestId});

  Future<ClientRequestAccessResponseDto> requestAccess({
    required Set<String> agentIds,
  });

  Future<Set<String>> removeAccess({
    required Set<String> agentIds,
  });

  Future<void> removeApprovedAgentById(String agentId);

  Future<OnlineAgentsResponseDto> fetchOnlineAgents({String? logUserId});

  Future<ClientAccessStatusResponseDto> fetchClientAccessStatus({
    required String token,
  });
}
