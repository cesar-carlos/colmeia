import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/paginated_agent_catalog_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/pending_agent_action_dto.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';

class ClientAgentsLocalDataSource {
  ClientAgentsLocalDataSource(this._cacheStore);

  final AppCacheStore _cacheStore;

  Future<PaginatedAgentCatalogResponseDto?> readCatalog({
    required String userId,
    required PaginatedQuery query,
    String? search,
  }) async {
    final json = await _readMap(
      _catalogKey(
        userId: userId,
        query: query,
        search: search,
      ),
    );
    if (json == null) {
      return null;
    }
    return PaginatedAgentCatalogResponseDto.fromJson(json);
  }

  Future<void> saveCatalog({
    required String userId,
    required PaginatedQuery query,
    required PaginatedAgentCatalogResponseDto payload,
    String? search,
  }) {
    return _writeMap(
      _catalogKey(
        userId: userId,
        query: query,
        search: search,
      ),
      payload.toJson(),
    );
  }

  Future<AgentCatalogRecordDto?> readCatalogAgentById({
    required String userId,
    required String agentId,
  }) async {
    final json = await _readMap(_catalogAgentKey(userId, agentId));
    if (json == null) {
      return null;
    }
    return AgentCatalogRecordDto.fromJson(json);
  }

  Future<void> saveCatalogAgentById({
    required String userId,
    required String agentId,
    required AgentCatalogRecordDto payload,
  }) {
    return _writeMap(_catalogAgentKey(userId, agentId), payload.toJson());
  }

  Future<ClientApprovedAgentsResponseDto?> readApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) async {
    final json = await _readMap(
      _approvedKey(
        userId: userId,
        query: query,
        search: search,
        status: status,
      ),
    );
    if (json == null) {
      return null;
    }
    return ClientApprovedAgentsResponseDto.fromJson(json);
  }

  Future<void> saveApprovedAgents({
    required String userId,
    required PaginatedQuery query,
    required ClientApprovedAgentsResponseDto payload,
    String? search,
    String? status,
  }) {
    return _writeMap(
      _approvedKey(
        userId: userId,
        query: query,
        search: search,
        status: status,
      ),
      payload.toJson(),
    );
  }

  Future<ClientApprovedAgentDetailResponseDto?> readApprovedAgentDetail({
    required String userId,
    required String agentId,
  }) async {
    final json = await _readMap(_detailKey(userId, agentId));
    if (json == null) {
      return null;
    }
    return ClientApprovedAgentDetailResponseDto.fromJson(json);
  }

  Future<void> saveApprovedAgentDetail({
    required String userId,
    required String agentId,
    required ClientApprovedAgentDetailResponseDto payload,
  }) {
    return _writeMap(_detailKey(userId, agentId), payload.toJson());
  }

  Future<void> clearApprovedAgentDetail({
    required String userId,
    required String agentId,
  }) {
    return _cacheStore.removeString(_detailKey(userId, agentId));
  }

  Future<ClientAccessRequestsResponseDto?> readAccessRequests({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) async {
    final json = await _readMap(
      _requestsKey(
        userId: userId,
        query: query,
        search: search,
        status: status,
      ),
    );
    if (json == null) {
      return null;
    }
    return ClientAccessRequestsResponseDto.fromJson(json);
  }

  Future<void> saveAccessRequests({
    required String userId,
    required PaginatedQuery query,
    required ClientAccessRequestsResponseDto payload,
    String? search,
    String? status,
  }) {
    return _writeMap(
      _requestsKey(
        userId: userId,
        query: query,
        search: search,
        status: status,
      ),
      payload.toJson(),
    );
  }

  Future<OnlineAgentsResponseDto?> readOnlineAgents({
    required String userId,
    Duration? maxAge,
  }) async {
    final json = await _readMap(_onlineKey(userId));
    if (json == null) {
      return null;
    }
    final payload = json['payload'];
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    if (maxAge != null &&
        savedAt != null &&
        DateTime.now().difference(savedAt) > maxAge) {
      return null;
    }
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    return OnlineAgentsResponseDto.fromJson(payload);
  }

  Future<void> saveOnlineAgents({
    required String userId,
    required OnlineAgentsResponseDto payload,
  }) {
    return _writeMap(_onlineKey(userId), <String, Object?>{
      'savedAt': DateTime.now().toIso8601String(),
      'payload': payload.toJson(),
    });
  }

  Future<List<PendingAgentAction>> readPendingActions({
    required String userId,
  }) async {
    final json = await _readMap(_pendingActionsKey(userId));
    if (json == null) {
      return const <PendingAgentAction>[];
    }
    final rawItems = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(PendingAgentActionDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList(growable: false);
  }

  Future<void> savePendingActions({
    required String userId,
    required List<PendingAgentAction> actions,
  }) {
    final payload = <String, Object?>{
      'items': actions
          .map(PendingAgentActionDto.fromEntity)
          .map((dto) => dto.toJson())
          .toList(growable: false),
    };
    return _writeMap(_pendingActionsKey(userId), payload);
  }

  Future<Map<String, dynamic>?> _readMap(String key) async {
    final raw = await _cacheStore.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        AppLogger.warning(
          'Client agents cache value is not a JSON object',
          context: _readMapLogContext(key),
        );
        return null;
      }
      return decoded;
    } on FormatException catch (error, stackTrace) {
      AppLogger.warning(
        'Client agents cache JSON decode failed; treating as miss',
        context: _readMapLogContext(key),
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Client agents cache read failed',
        context: _readMapLogContext(key),
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _writeMap(String key, Map<String, Object?> data) {
    return _cacheStore.putString(
      key: key,
      value: jsonEncode(data),
    );
  }

  String _catalogKey({
    required String userId,
    required PaginatedQuery query,
    String? search,
  }) {
    final normalizedSearch = _normalizeOptionalSegment(search);
    return '${AppKvCacheKeyPrefixes.clientAgentsCatalog}'
        '${userId}_p${query.page}_s${query.pageSize}_q$normalizedSearch';
  }

  String _approvedKey({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) {
    final normalizedSearch = _normalizeOptionalSegment(search);
    final normalizedStatus = _normalizeOptionalSegment(status);
    return '${AppKvCacheKeyPrefixes.clientAgentsApproved}'
        '${userId}_p${query.page}_s${query.pageSize}_q$normalizedSearch'
        '_st$normalizedStatus';
  }

  String _requestsKey({
    required String userId,
    required PaginatedQuery query,
    String? search,
    String? status,
  }) {
    final normalizedSearch = _normalizeOptionalSegment(search);
    final normalizedStatus = _normalizeOptionalSegment(status);
    return '${AppKvCacheKeyPrefixes.clientAgentsRequests}'
        '${userId}_p${query.page}_s${query.pageSize}_q$normalizedSearch'
        '_st$normalizedStatus';
  }

  String _catalogAgentKey(String userId, String agentId) {
    return '${AppKvCacheKeyPrefixes.clientAgentsCatalogAgent}'
        '${userId}_$agentId';
  }

  String _detailKey(String userId, String agentId) {
    return '${AppKvCacheKeyPrefixes.clientAgentsDetail}${userId}_$agentId';
  }

  String _pendingActionsKey(String userId) {
    return '${AppKvCacheKeyPrefixes.clientAgentsPendingActions}$userId';
  }

  String _onlineKey(String userId) {
    return '${AppKvCacheKeyPrefixes.clientAgentsOnline}$userId';
  }

  String _normalizeOptionalSegment(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'all';
    }
    final lower = trimmed.toLowerCase();
    final slug = lower.replaceAll(RegExp('[^a-z0-9]+'), '_');
    final digest = Object.hash(trimmed, trimmed.length).toUnsigned(32);
    return '${slug}_h$digest';
  }

  Map<String, Object?> _readMapLogContext(String key) {
    return <String, Object?>{
      'operation': 'readClientAgentsCache',
      'cacheKeyLength': key.length,
      'cacheKeyHash': key.hashCode,
    };
  }
}
