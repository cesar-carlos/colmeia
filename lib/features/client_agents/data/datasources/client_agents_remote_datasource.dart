import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_catalog_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_client_access_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_owner_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource_parsers.dart';
import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_status_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_ids_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_request_access_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_approved_clients_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:dio/dio.dart';

export 'package:colmeia/features/client_agents/data/datasources/client_agents_catalog_remote_datasource.dart';
export 'package:colmeia/features/client_agents/data/datasources/client_agents_client_access_remote_datasource.dart';
export 'package:colmeia/features/client_agents/data/datasources/client_agents_owner_remote_datasource.dart';
export 'package:colmeia/features/client_agents/data/datasources/fake_client_agents_remote_datasource.dart';

/// Facade composing catalog, client-access and owner bounded contexts.
abstract interface class ClientAgentsRemoteDataSource
    implements
        ClientAgentsCatalogRemoteDataSource,
        ClientAgentsClientAccessRemoteDataSource,
        ClientAgentsOwnerRemoteDataSource {}

/// Segregated contract for the per-(client, agent) bearer token endpoints.
///
/// Token persistence has a single consumer (`RemoteAgentClientTokenRepository`)
/// that does not touch catalog/access/owner operations, so it depends on this
/// narrow interface instead of the broad [ClientAgentsRemoteDataSource] (ISP).
abstract interface class ClientAgentTokenRemoteDataSource {
  /// `GET /client/me/agents/{agentId}/client-token` — returns the bearer token
  /// the hub forwards as `params.client_token` on the SQL bridge, or `null`
  /// when no token is stored. Throws on 401/403/404 so the repository layer
  /// can map to typed failures.
  Future<ClientAgentTokenResponseDto> fetchClientAgentToken({
    required String agentId,
  });

  /// `PUT /client/me/agents/{agentId}/client-token` — stores or clears the
  /// bearer token for the authenticated client + agent pair. Pass
  /// [ClientAgentTokenRequestDto] with `clientToken: null` (or empty) to
  /// clear. Returns the updated state.
  Future<ClientAgentTokenResponseDto> putClientAgentToken({
    required String agentId,
    required ClientAgentTokenRequestDto request,
  });
}

class ApiClientAgentsRemoteDataSource
    implements ClientAgentsRemoteDataSource, ClientAgentTokenRemoteDataSource {
  ApiClientAgentsRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedAgentCatalogResponseDto> fetchCatalog({
    required PaginatedQuery query,
    String? search,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AgentCatalogApiRoutes.catalog,
      queryParameters: <String, Object?>{
        'page': query.page,
        'pageSize': query.pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return PaginatedAgentCatalogResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<AgentCatalogRecordDto> fetchCatalogAgentById(String agentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      AgentCatalogApiRoutes.catalogByAgentId(agentId),
    );
    return parseCatalogAgentBody(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<ClientApprovedAgentsResponseDto> fetchApprovedAgents({
    required PaginatedQuery query,
    String? search,
    String? status,
    bool refresh = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAgentApiRoutes.approvedAgents,
      queryParameters: <String, Object?>{
        'page': query.page,
        'pageSize': query.pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (refresh) 'refresh': true,
      },
    );
    return ClientApprovedAgentsResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<ClientApprovedAgentDetailResponseDto> fetchApprovedAgentById(
    String agentId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAgentApiRoutes.approvedAgentById(agentId),
    );
    return ClientApprovedAgentDetailResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<ClientApprovedAgentDetailResponseDto?> fetchApprovedAgentDetailOrNull(
    String agentId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ClientAgentApiRoutes.approvedAgentById(agentId),
      );
      return ClientApprovedAgentDetailResponseDto.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return null;
      }
      if (statusCode == 403) {
        final payload = error.response?.data;
        if (isBlockedAccountApiPayload(payload)) {
          rethrow;
        }
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ClientAccessRequestsResponseDto> fetchAccessRequests({
    required PaginatedQuery query,
    String? search,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAgentApiRoutes.accessRequests,
      queryParameters: <String, Object?>{
        'page': query.page,
        'pageSize': query.pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    return ClientAccessRequestsResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<ClientApprovedAgentsResponseDto> fetchManagedAgents() async {
    final response = await _dio.get<Map<String, dynamic>>(
      UserAgentApiRoutes.managedAgents,
    );
    return ClientApprovedAgentsResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<void> retryAccessRequest({required String requestId}) {
    return _dio.post<void>(
      ClientAgentApiRoutes.retryAccessRequestById(requestId),
    );
  }

  @override
  Future<OwnerAccessRequestsResponseDto> fetchOwnerAccessRequests() async {
    final response = await _dio.get<Map<String, dynamic>>(
      OwnerClientAccessApiRoutes.accessRequests,
    );
    return OwnerAccessRequestsResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<void> approveOwnerAccessRequest({required String requestId}) {
    return _dio.post<void>(
      OwnerClientAccessApiRoutes.approveRequestById(requestId),
    );
  }

  @override
  Future<void> rejectOwnerAccessRequest({required String requestId}) {
    return _dio.post<void>(
      OwnerClientAccessApiRoutes.rejectRequestById(requestId),
    );
  }

  @override
  Future<OwnerApprovedClientsResponseDto> fetchApprovedClientsForManagedAgent({
    required String agentId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      UserAgentApiRoutes.managedAgentClients(agentId),
    );
    return OwnerApprovedClientsResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<void> revokeManagedAgentClientAccess({
    required String agentId,
    required String clientId,
  }) {
    return _dio.delete<void>(
      UserAgentApiRoutes.managedAgentClientById(
        agentId: agentId,
        clientId: clientId,
      ),
    );
  }

  @override
  Future<ClientRequestAccessResponseDto> requestAccess({
    required Set<String> agentIds,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ClientAgentApiRoutes.approvedAgents,
      data: ClientAgentIdsRequestDto(agentIds: agentIds).toJson(),
    );
    return ClientRequestAccessResponseDto.parse(
      response.data ?? const <String, dynamic>{},
      fallbackRequestedIds: agentIds,
    );
  }

  @override
  Future<void> removeApprovedAgentById(String agentId) async {
    await _dio.delete<void>(
      ClientAgentApiRoutes.approvedAgentById(agentId),
    );
  }

  @override
  Future<Set<String>> removeAccess({
    required Set<String> agentIds,
  }) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      ClientAgentApiRoutes.approvedAgents,
      data: ClientAgentIdsRequestDto(agentIds: agentIds).toJson(),
    );
    return resolveMutatedAgentIds(
      body: response.data ?? const <String, dynamic>{},
      fallbackAgentIds: agentIds,
    );
  }

  @override
  Future<OnlineAgentsResponseDto> fetchOnlineAgents({String? logUserId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiRoutes.onlineAgents,
    );
    final dto = OnlineAgentsResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
    final logContext = <String, Object?>{
      'operation': 'fetchOnlineAgents',
      'path': ApiRoutes.onlineAgents,
      'userId': ?logUserId,
    };
    if (dto.malformedAgentRowCount > 0) {
      AppLogger.warning(
        'Online agents response omitted malformed rows',
        context: <String, Object?>{
          ...logContext,
          'malformedRowCount': dto.malformedAgentRowCount,
          'parsedAgentCount': dto.agents.length,
        },
      );
    }
    if (dto.count != dto.agents.length) {
      AppLogger.warning(
        'Online agents response count does not match parsed list length',
        context: <String, Object?>{
          ...logContext,
          'declaredCount': dto.count,
          'parsedAgentCount': dto.agents.length,
        },
      );
    }
    return dto;
  }

  @override
  Future<ClientAccessStatusResponseDto> fetchClientAccessStatus({
    required String token,
  }) async {
    // Plug Server: GET /client-access/status?token=…
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAgentApiRoutes.accessStatusByToken,
      queryParameters: <String, Object?>{'token': token},
    );
    return ClientAccessStatusResponseDto.fromJson(
      response.data ?? const <String, dynamic>{},
    );
  }

  @override
  Future<AgentCatalogRecordDto> patchAgentProfile({
    required String agentId,
    required Map<String, Object?> body,
    String? idempotencyKey,
  }) async {
    final trimmedIdempotencyKey = idempotencyKey?.trim();
    final hasHeader =
        trimmedIdempotencyKey != null && trimmedIdempotencyKey.isNotEmpty;
    final response = await _dio.patch<Map<String, dynamic>>(
      AgentCatalogApiRoutes.profileByAgentId(agentId),
      data: body,
      options: hasHeader
          ? Options(
              headers: <String, Object?>{
                'Idempotency-Key': trimmedIdempotencyKey,
              },
            )
          : null,
    );
    return parseCatalogAgentBody(response.data ?? const <String, dynamic>{});
  }

  @override
  Future<ClientAgentTokenResponseDto> fetchClientAgentToken({
    required String agentId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ClientAgentApiRoutes.clientTokenForAgent(agentId),
    );
    return parseClientAgentTokenBody(
      response.data ?? const <String, dynamic>{},
      fallbackAgentId: agentId,
    );
  }

  @override
  Future<ClientAgentTokenResponseDto> putClientAgentToken({
    required String agentId,
    required ClientAgentTokenRequestDto request,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ClientAgentApiRoutes.clientTokenForAgent(agentId),
      data: request.toJson(),
    );
    return parseClientAgentTokenBody(
      response.data ?? const <String, dynamic>{},
      fallbackAgentId: agentId,
    );
  }
}
