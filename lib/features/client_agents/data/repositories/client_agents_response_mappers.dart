import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_profile_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_approved_clients_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/services/agent_connection_status_resolver.dart';

/// Pure response → entity mappers used by `ClientAgentsRepositoryImpl`.
///
/// Extracted out of the repository so the impl can focus on data-flow
/// orchestration (remote ↔ local cache, error mapping, retries) without
/// being inflated by trivial transforms.
PaginatedResult<ClientAgentCatalogItem> mapClientAgentCatalogResponse(
  PaginatedAgentCatalogResponseDto response, {
  required Set<String>? onlineIds,
  bool isStaleCache = false,
}) {
  return response.toPaginatedResult(
    response.agents
        .map(
          (agent) => ClientAgentCatalogItem(
            agent: mapClientAgentProfile(agent, onlineIds: onlineIds),
          ),
        )
        .toList(growable: false),
    isStaleCache: isStaleCache,
  );
}

PaginatedResult<ClientAgent> mapClientApprovedAgentsResponse(
  ClientApprovedAgentsResponseDto response, {
  required Set<String>? onlineIds,
  bool isStaleCache = false,
}) {
  return response.toPaginatedResult(
    response.agents
        .map((agent) => mapClientAgentProfile(agent, onlineIds: onlineIds))
        .toList(growable: false),
    isStaleCache: isStaleCache,
  );
}

PaginatedResult<ClientAgentAccessRequest> mapClientAccessRequestsResponse(
  ClientAccessRequestsResponseDto response, {
  bool isStaleCache = false,
}) {
  return response.toPaginatedResult(
    response.requests
        .map((request) => request.toEntity())
        .toList(growable: false),
    isStaleCache: isStaleCache,
  );
}

List<OwnerClientAccessRequest> mapOwnerAccessRequestsResponse(
  OwnerAccessRequestsResponseDto response, {
  bool isStaleCache = false,
}) {
  return response.requests
      .map((request) => request.toEntity(isStaleCache: isStaleCache))
      .toList(growable: false);
}

List<OwnerApprovedClient> mapOwnerApprovedClientsResponse(
  OwnerApprovedClientsResponseDto response, {
  bool isStaleCache = false,
}) {
  return response.clients
      .map((client) => client.toEntity(isStaleCache: isStaleCache))
      .toList(growable: false);
}

ClientAgent mapClientAgentProfile(
  ClientAgentProfileDto profile, {
  required Set<String>? onlineIds,
  bool isStaleCache = false,
}) {
  final connectionStatus = resolveAgentConnectionStatus(
    agentId: profile.agentId,
    isHubConnected: profile.isHubConnected,
    onlineAgentIds: onlineIds,
  );
  return profile.toEntity(
    connectionStatus: connectionStatus,
    isStaleCache: isStaleCache,
  );
}
