import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_status_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_access_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_ids_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_request_access_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:dio/dio.dart';

abstract interface class ClientAgentsRemoteDataSource {
  Future<PaginatedAgentCatalogResponseDto> fetchCatalog({
    required PaginatedQuery query,
    String? search,
  });

  Future<AgentCatalogRecordDto> fetchCatalogAgentById(String agentId);

  Future<ClientApprovedAgentsResponseDto> fetchApprovedAgents({
    required PaginatedQuery query,
    String? search,
    String? status,
    bool refresh = false,
  });

  Future<ClientApprovedAgentDetailResponseDto> fetchApprovedAgentById(
    String agentId,
  );

  /// `GET /client/me/agents/{agentId}` — returns `null` when the client has no
  /// linked approved agent (HTTP 404, or HTTP 403 without a blocked-account
  /// payload). Rethrows 401 and 403 that indicate a blocked account.
  Future<ClientApprovedAgentDetailResponseDto?> fetchApprovedAgentDetailOrNull(
    String agentId,
  );

  Future<ClientAccessRequestsResponseDto> fetchAccessRequests({
    required PaginatedQuery query,
    String? search,
    String? status,
  });

  Future<ClientRequestAccessResponseDto> requestAccess({
    required Set<String> agentIds,
  });

  Future<Set<String>> removeAccess({
    required Set<String> agentIds,
  });

  /// `DELETE /client/me/agents/{agentId}` — same as bulk remove with one id.
  Future<void> removeApprovedAgentById(String agentId);

  Future<OnlineAgentsResponseDto> fetchOnlineAgents({String? logUserId});

  Future<ClientAccessStatusResponseDto> fetchClientAccessStatus({
    required String token,
  });

  Future<AgentCatalogRecordDto> patchAgentProfile({
    required String agentId,
    required Map<String, Object?> body,
  });
}

class ApiClientAgentsRemoteDataSource implements ClientAgentsRemoteDataSource {
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
    return _parseCatalogAgentBody(response.data ?? const <String, dynamic>{});
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
  Future<ClientRequestAccessResponseDto> requestAccess({
    required Set<String> agentIds,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ClientAgentApiRoutes.approvedAgents,
      data: ClientAgentIdsRequestDto(agentIds: agentIds).toJson(),
    );
    return ClientRequestAccessResponseDto.parse(
      response.data ?? const <String, dynamic>{},
      agentIds,
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
    return _resolveMutatedAgentIds(
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
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      AgentCatalogApiRoutes.profileByAgentId(agentId),
      data: body,
    );
    return _parseCatalogAgentBody(response.data ?? const <String, dynamic>{});
  }

  Set<String> _resolveMutatedAgentIds({
    required Map<String, dynamic> body,
    required Set<String> fallbackAgentIds,
  }) {
    final knownLists = <String>[
      'agentIds',
      'processedAgentIds',
      'affectedAgentIds',
      'requestedAgentIds',
      'removedAgentIds',
    ];
    for (final key in knownLists) {
      final raw = body[key];
      if (raw is List<dynamic>) {
        final mapped = raw.whereType<String>().toSet();
        if (mapped.isNotEmpty) {
          return mapped;
        }
      }
    }
    return fallbackAgentIds;
  }
}

AgentCatalogRecordDto _parseCatalogAgentBody(Map<String, dynamic> json) {
  final direct = json['agent'];
  if (direct is Map<String, dynamic>) {
    return AgentCatalogRecordDto.fromJson(direct);
  }
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['agent'];
    if (nested is Map<String, dynamic>) {
      return AgentCatalogRecordDto.fromJson(nested);
    }
    return AgentCatalogRecordDto.fromJson(data);
  }
  return AgentCatalogRecordDto.fromJson(json);
}

class FakeClientAgentsRemoteDataSource implements ClientAgentsRemoteDataSource {
  FakeClientAgentsRemoteDataSource();

  final List<Map<String, dynamic>> _catalog = <Map<String, dynamic>>[
    _agentRecord(
      agentId: '6ac362c2-72b5-4f2f-a071-96fe6f5f5080',
      name: 'Plug Agente Norte',
      tradeName: 'Norte BI',
      status: 'active',
      city: 'Sao Paulo',
      state: 'SP',
    ),
    _agentRecord(
      agentId: '67bcaf42-6ee2-4f8d-8e76-0c74a16de9bd',
      name: 'Plug Agente Sul',
      tradeName: 'Sul Insights',
      status: 'active',
      city: 'Curitiba',
      state: 'PR',
    ),
    _agentRecord(
      agentId: '5736f60b-33d0-4811-8b66-30d3f507f270',
      name: 'Plug Agente Legado',
      tradeName: 'Legacy Ops',
      status: 'inactive',
      city: 'Rio de Janeiro',
      state: 'RJ',
    ),
  ];

  final Set<String> _approvedAgentIds = <String>{
    '6ac362c2-72b5-4f2f-a071-96fe6f5f5080',
  };

  final List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[
    <String, dynamic>{
      'requestId': 'rq-1001',
      'agentId': '67bcaf42-6ee2-4f8d-8e76-0c74a16de9bd',
      'agentName': 'Plug Agente Sul',
      'status': 'pending',
      'reviewToken': 'fake-review-token-sul',
      'requestedAt': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
  ];

  @override
  Future<PaginatedAgentCatalogResponseDto> fetchCatalog({
    required PaginatedQuery query,
    String? search,
  }) async {
    final filtered = _applySearch(
      items: _catalog,
      search: search,
      key: 'name',
    );
    return PaginatedAgentCatalogResponseDto(
      agents: _slice(
        filtered,
        query,
      ).map(AgentCatalogRecordDto.fromJson).toList(growable: false),
      count: filtered.length,
      total: filtered.length,
      page: query.page,
      pageSize: query.pageSize,
    );
  }

  @override
  Future<AgentCatalogRecordDto> fetchCatalogAgentById(String agentId) async {
    final raw = _catalog.firstWhere((item) => item['agentId'] == agentId);
    return AgentCatalogRecordDto.fromJson(raw);
  }

  @override
  Future<ClientApprovedAgentsResponseDto> fetchApprovedAgents({
    required PaginatedQuery query,
    String? search,
    String? status,
    bool refresh = false,
  }) async {
    final approved = _catalog
        .where((item) {
          if (!_approvedAgentIds.contains(item['agentId'])) {
            return false;
          }
          if (status != null && status.trim().isNotEmpty) {
            if ((item['status'] as String?) != status.trim()) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
    final filtered = _applySearch(items: approved, search: search, key: 'name');
    final paged = _slice(filtered, query);
    return ClientApprovedAgentsResponseDto(
      agents: paged
          .map(ClientAccessibleAgentDto.fromJson)
          .toList(growable: false),
      agentIds: approved.map((item) => item['agentId'] as String).toSet(),
      count: filtered.length,
      total: filtered.length,
      page: query.page,
      pageSize: query.pageSize,
    );
  }

  @override
  Future<ClientApprovedAgentDetailResponseDto> fetchApprovedAgentById(
    String agentId,
  ) async {
    final agent = _catalog.firstWhere((item) => item['agentId'] == agentId);
    return ClientApprovedAgentDetailResponseDto(
      agent: ClientAccessibleAgentDto.fromJson(agent),
    );
  }

  @override
  Future<ClientApprovedAgentDetailResponseDto?> fetchApprovedAgentDetailOrNull(
    String agentId,
  ) async {
    if (!_approvedAgentIds.contains(agentId)) {
      return null;
    }
    final agent = _catalog.firstWhere(
      (item) => item['agentId'] == agentId,
      orElse: () => <String, dynamic>{
        'agentId': agentId,
        'name': 'Agente $agentId',
        'status': 'active',
      },
    );
    return ClientApprovedAgentDetailResponseDto(
      agent: ClientAccessibleAgentDto.fromJson(agent),
    );
  }

  @override
  Future<ClientAccessRequestsResponseDto> fetchAccessRequests({
    required PaginatedQuery query,
    String? search,
    String? status,
  }) async {
    final filtered = _requests
        .where((item) {
          if (status != null && status.trim().isNotEmpty) {
            if ((item['status'] as String?) != status.trim()) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
    final searched = _applySearch(
      items: filtered,
      search: search,
      key: 'agentName',
    );
    return ClientAccessRequestsResponseDto(
      requests: _slice(
        searched,
        query,
      ).map(ClientAgentAccessRequestDto.fromJson).toList(growable: false),
      count: searched.length,
      total: searched.length,
      page: query.page,
      pageSize: query.pageSize,
    );
  }

  @override
  Future<ClientRequestAccessResponseDto> requestAccess({
    required Set<String> agentIds,
  }) async {
    final requested = <String>[];
    final alreadyApproved = <String>[];
    for (final agentId in agentIds) {
      if (_approvedAgentIds.contains(agentId)) {
        alreadyApproved.add(agentId);
        continue;
      }
      final agent = _catalog.firstWhere(
        (item) => item['agentId'] == agentId,
        orElse: () => <String, dynamic>{'name': 'Agente $agentId'},
      );
      _requests.add(<String, dynamic>{
        'requestId': 'rq-${DateTime.now().microsecondsSinceEpoch}',
        'agentId': agentId,
        'agentName': agent['name'] as String? ?? 'Agente $agentId',
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
      });
      requested.add(agentId);
    }
    return ClientRequestAccessResponseDto(
      requested: requested,
      alreadyApproved: alreadyApproved,
      newRequests: List<String>.from(requested),
    );
  }

  @override
  Future<void> removeApprovedAgentById(String agentId) async {
    await removeAccess(agentIds: <String>{agentId});
  }

  @override
  Future<Set<String>> removeAccess({
    required Set<String> agentIds,
  }) async {
    _approvedAgentIds.removeAll(agentIds);
    _requests.removeWhere((item) {
      final requestAgentId = item['agentId'] as String?;
      return requestAgentId != null && agentIds.contains(requestAgentId);
    });
    return agentIds;
  }

  @override
  Future<OnlineAgentsResponseDto> fetchOnlineAgents({String? logUserId}) async {
    // Simulate hub presence for every approved agent (real API returns all
    // connected agent ids; do not use take(1) or only the first id is online).
    final onlineIds = _approvedAgentIds.toSet();
    return OnlineAgentsResponseDto(
      agents: onlineIds
          .map(
            (agentId) => OnlineAgentDto(
              agentId: agentId,
              connectedAt: DateTime.now().subtract(const Duration(minutes: 6)),
              lastSeenAt: DateTime.now(),
            ),
          )
          .toList(growable: false),
      count: onlineIds.length,
    );
  }

  @override
  Future<ClientAccessStatusResponseDto> fetchClientAccessStatus({
    required String token,
  }) async {
    final wire = token.contains('reject')
        ? 'rejected'
        : (token.contains('approve') ? 'approved' : 'pending');
    return ClientAccessStatusResponseDto(
      statusWire: wire,
      agentId: '6ac362c2-72b5-4f2f-a071-96fe6f5f5080',
    );
  }

  @override
  Future<AgentCatalogRecordDto> patchAgentProfile({
    required String agentId,
    required Map<String, Object?> body,
  }) async {
    final index = _catalog.indexWhere((e) => e['agentId'] == agentId);
    if (index < 0) {
      throw DioException(
        requestOptions: RequestOptions(
          path: AgentCatalogApiRoutes.profileByAgentId(agentId),
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: AgentCatalogApiRoutes.profileByAgentId(agentId),
          ),
          statusCode: 404,
          data: <String, dynamic>{'message': 'Agent not found'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final cnpj =
        body['cnpjCpf'] as String? ?? body['document'] as String? ?? '';
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');
    if (digits == '11111111111111') {
      throw DioException(
        requestOptions: RequestOptions(
          path: AgentCatalogApiRoutes.profileByAgentId(agentId),
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: AgentCatalogApiRoutes.profileByAgentId(agentId),
          ),
          statusCode: 409,
          data: <String, dynamic>{
            'code': 'AGENT_DOCUMENT_CONFLICT',
            'message': 'Document already in use',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final current = Map<String, dynamic>.from(_catalog[index]);
    final now = DateTime.now().toIso8601String();
    final addressBody = body['address'];
    if (addressBody is Map<String, dynamic>) {
      final previousAddress = current['address'] as Map<String, dynamic>?;
      current['address'] = <String, dynamic>{
        ...?previousAddress,
        ...addressBody,
      };
    }
    void put(String key) {
      if (body.containsKey(key) && body[key] != null) {
        current[key] = body[key];
      }
    }

    put('name');
    put('tradeName');
    put('document');
    put('cnpjCpf');
    put('documentType');
    put('phone');
    put('mobile');
    put('email');
    put('notes');
    put('observation');
    current['updatedAt'] = now;
    current['profileUpdatedAt'] = now;
    if (current['cnpjCpf'] != null) {
      final v = current['cnpjCpf']!.toString().replaceAll(RegExp(r'\D'), '');
      current['cnpjCpf'] = v.isEmpty ? null : v;
      current['document'] = current['cnpjCpf'];
    }
    _catalog[index] = current;
    return AgentCatalogRecordDto.fromJson(current);
  }

  static Map<String, dynamic> _agentRecord({
    required String agentId,
    required String name,
    required String tradeName,
    required String status,
    required String city,
    required String state,
  }) {
    final now = DateTime.now();
    return <String, dynamic>{
      'agentId': agentId,
      'name': name,
      'tradeName': tradeName,
      'document': null,
      'cnpjCpf': null,
      'documentType': null,
      'phone': null,
      'mobile': null,
      'email': null,
      'address': <String, dynamic>{
        'street': null,
        'number': null,
        'district': null,
        'postalCode': null,
        'city': city,
        'state': state,
      },
      'notes': null,
      'observation': null,
      'status': status,
      'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'profileUpdatedAt': now.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _applySearch({
    required List<Map<String, dynamic>> items,
    required String? search,
    required String key,
  }) {
    final normalized = search?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return items;
    }
    return items
        .where((item) {
          final value = (item[key] as String?)?.toLowerCase() ?? '';
          return value.contains(normalized);
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _slice(
    List<Map<String, dynamic>> items,
    PaginatedQuery query,
  ) {
    final start = (query.page - 1) * query.pageSize;
    if (start >= items.length) {
      return const <Map<String, dynamic>>[];
    }
    final end = (start + query.pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }
}
