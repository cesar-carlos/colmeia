import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_status_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_access_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_request_access_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_approved_client_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_approved_clients_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/owner_client_access_request_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:dio/dio.dart';

class FakeClientAgentsRemoteDataSource
    implements ClientAgentsRemoteDataSource, ClientAgentTokenRemoteDataSource {
  FakeClientAgentsRemoteDataSource();

  /// Per-agent server-side client tokens. Mirrors the `client-token` REST
  /// endpoints so dev builds can exercise the same UI flow.
  final Map<String, String> _serverClientTokens = <String, String>{};

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

  final Set<String> _managedAgentIds = <String>{
    '6ac362c2-72b5-4f2f-a071-96fe6f5f5080',
    '67bcaf42-6ee2-4f8d-8e76-0c74a16de9bd',
  };

  final Map<String, List<Map<String, dynamic>>> _approvedClientsByAgentId =
      <String, List<Map<String, dynamic>>>{
        '6ac362c2-72b5-4f2f-a071-96fe6f5f5080': <Map<String, dynamic>>[
          <String, dynamic>{
            'clientId': 'client-101',
            'clientName': 'CASA DO MEL BARRA DO GARCAS LTDA',
            'clientEmail': 'barra@example.com',
            'status': 'active',
            'approvedAt': DateTime.now()
                .subtract(const Duration(days: 8))
                .toIso8601String(),
          },
        ],
      };

  final List<Map<String, dynamic>> _requests = <Map<String, dynamic>>[
    <String, dynamic>{
      'requestId': 'rq-1001',
      'agentId': '67bcaf42-6ee2-4f8d-8e76-0c74a16de9bd',
      'agentName': 'Plug Agente Sul',
      'clientId': 'client-202',
      'clientName': 'CASA DO MEL SORRISO LOJA 2',
      'clientEmail': 'sorriso@example.com',
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
          .map(_accessibleAgentDtoWithServerTokenFlag)
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
      agent: _accessibleAgentDtoWithServerTokenFlag(agent),
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
      agent: _accessibleAgentDtoWithServerTokenFlag(agent),
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
  Future<ClientApprovedAgentsResponseDto> fetchManagedAgents() async {
    final managed = _catalog
        .where((item) => _managedAgentIds.contains(item['agentId']))
        .toList(growable: false);
    return ClientApprovedAgentsResponseDto(
      agents: managed
          .map(_accessibleAgentDtoWithServerTokenFlag)
          .toList(growable: false),
      agentIds: managed.map((item) => item['agentId'] as String).toSet(),
      count: managed.length,
      total: managed.length,
      page: 1,
      pageSize: managed.length,
    );
  }

  @override
  Future<void> retryAccessRequest({required String requestId}) async {
    final index = _requests.indexWhere(
      (item) => item['requestId'] == requestId,
    );
    if (index < 0) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ClientAgentApiRoutes.retryAccessRequestById(requestId),
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: ClientAgentApiRoutes.retryAccessRequestById(requestId),
          ),
          statusCode: 404,
          data: <String, dynamic>{'message': 'Request not found'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    _requests[index] = <String, dynamic>{
      ..._requests[index],
      'status': 'pending',
      'requestedAt': DateTime.now().toIso8601String(),
      'reviewToken': 'retry-token-$requestId',
      'reason': null,
    };
  }

  @override
  Future<OwnerAccessRequestsResponseDto> fetchOwnerAccessRequests() async {
    return OwnerAccessRequestsResponseDto(
      requests: _requests
          .map(OwnerClientAccessRequestDto.fromJson)
          .toList(growable: false),
      count: _requests.length,
      total: _requests.length,
    );
  }

  @override
  Future<void> approveOwnerAccessRequest({required String requestId}) async {
    final index = _requests.indexWhere(
      (item) => item['requestId'] == requestId,
    );
    if (index < 0) {
      throw DioException(
        requestOptions: RequestOptions(
          path: OwnerClientAccessApiRoutes.approveRequestById(requestId),
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: OwnerClientAccessApiRoutes.approveRequestById(requestId),
          ),
          statusCode: 404,
          data: <String, dynamic>{'message': 'Request not found'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    final request = _requests[index];
    _requests[index] = <String, dynamic>{
      ...request,
      'status': 'approved',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reason': null,
    };
    final agentId = request['agentId'] as String? ?? '';
    if (agentId.isNotEmpty) {
      _approvedClientsByAgentId.putIfAbsent(
        agentId,
        () => <Map<String, dynamic>>[],
      );
      final clientId = request['clientId'] as String? ?? '';
      _approvedClientsByAgentId[agentId]!
        ..removeWhere((item) => item['clientId'] == clientId)
        ..add(<String, dynamic>{
          'clientId': clientId,
          'clientName': request['clientName'],
          'clientEmail': request['clientEmail'],
          'status': 'active',
          'approvedAt': DateTime.now().toIso8601String(),
        });
    }
  }

  @override
  Future<void> rejectOwnerAccessRequest({required String requestId}) async {
    final index = _requests.indexWhere(
      (item) => item['requestId'] == requestId,
    );
    if (index < 0) {
      throw DioException(
        requestOptions: RequestOptions(
          path: OwnerClientAccessApiRoutes.rejectRequestById(requestId),
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: OwnerClientAccessApiRoutes.rejectRequestById(requestId),
          ),
          statusCode: 404,
          data: <String, dynamic>{'message': 'Request not found'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    _requests[index] = <String, dynamic>{
      ..._requests[index],
      'status': 'rejected',
      'reviewedAt': DateTime.now().toIso8601String(),
      'reason': 'Rejected by owner review',
    };
  }

  @override
  Future<OwnerApprovedClientsResponseDto> fetchApprovedClientsForManagedAgent({
    required String agentId,
  }) async {
    final clients =
        _approvedClientsByAgentId[agentId] ?? const <Map<String, dynamic>>[];
    return OwnerApprovedClientsResponseDto(
      clients: clients
          .map(OwnerApprovedClientDto.fromJson)
          .toList(growable: false),
      count: clients.length,
      total: clients.length,
    );
  }

  @override
  Future<void> revokeManagedAgentClientAccess({
    required String agentId,
    required String clientId,
  }) async {
    final clients = _approvedClientsByAgentId[agentId];
    if (clients == null) {
      return;
    }
    clients.removeWhere((item) => item['clientId'] == clientId);
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
        'clientId': 'client-${DateTime.now().millisecondsSinceEpoch}',
        'clientName': 'Cliente Demo',
        'clientEmail': 'cliente.demo@example.com',
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
    String? idempotencyKey,
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
    final currentVersion = (current['profileVersion'] as num?)?.toInt() ?? 0;
    final expectedVersion = (body['expectedProfileVersion'] as num?)?.toInt();
    if (expectedVersion != null && expectedVersion != currentVersion) {
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
            'code': 'AGENT_PROFILE_CAS_MISMATCH',
            'message': 'Profile version mismatch',
            'expected': expectedVersion,
            'current': currentVersion,
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

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
    current['profileVersion'] = currentVersion + 1;
    if (current['cnpjCpf'] != null) {
      final v = current['cnpjCpf']!.toString().replaceAll(RegExp(r'\D'), '');
      current['cnpjCpf'] = v.isEmpty ? null : v;
      current['document'] = current['cnpjCpf'];
    }
    _catalog[index] = current;
    return AgentCatalogRecordDto.fromJson(current);
  }

  @override
  Future<ClientAgentTokenResponseDto> fetchClientAgentToken({
    required String agentId,
  }) async {
    if (!_approvedAgentIds.contains(agentId)) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ClientAgentApiRoutes.clientTokenForAgent(agentId),
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: ClientAgentApiRoutes.clientTokenForAgent(agentId),
          ),
          statusCode: 403,
          data: <String, dynamic>{
            'code': 'CLIENT_AGENT_ACCESS_REQUIRED',
            'message': 'Client does not have approved access to this agent',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return ClientAgentTokenResponseDto(
      agentId: agentId,
      clientToken: _serverClientTokens[agentId],
    );
  }

  @override
  Future<ClientAgentTokenResponseDto> putClientAgentToken({
    required String agentId,
    required ClientAgentTokenRequestDto request,
  }) async {
    if (!_approvedAgentIds.contains(agentId)) {
      throw DioException(
        requestOptions: RequestOptions(
          path: ClientAgentApiRoutes.clientTokenForAgent(agentId),
        ),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: ClientAgentApiRoutes.clientTokenForAgent(agentId),
          ),
          statusCode: 403,
          data: <String, dynamic>{
            'code': 'CLIENT_AGENT_ACCESS_REQUIRED',
            'message': 'Client does not have approved access to this agent',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }
    final normalized = request.normalized;
    if (normalized == null) {
      _serverClientTokens.remove(agentId);
    } else {
      _serverClientTokens[agentId] = normalized;
    }
    return ClientAgentTokenResponseDto(
      agentId: agentId,
      clientToken: normalized,
    );
  }

  ClientAccessibleAgentDto _accessibleAgentDtoWithServerTokenFlag(
    Map<String, dynamic> raw,
  ) {
    final agentId = raw['agentId'] as String? ?? '';
    final hasToken =
        agentId.isNotEmpty && _serverClientTokens.containsKey(agentId);
    final enriched = <String, dynamic>{...raw, 'hasClientToken': hasToken};
    return ClientAccessibleAgentDto.fromJson(enriched);
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
