import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/features/agent_meta/data/models/agent_get_profile_response_dto.dart';
import 'package:colmeia/features/agent_meta/data/models/client_token_policy_response_dto.dart';
import 'package:colmeia/features/agent_meta/data/models/rpc_discover_response_dto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// REST datasource for `agent.getProfile`, `client_token.getPolicy` and
/// `rpc.discover`. Uses the same `POST /api/v1/agents/commands` bridge that
/// `agent_queries` uses for SQL — no streaming required for these methods.
abstract interface class AgentMetaRemoteDataSource {
  Future<AgentGetProfileResponseDto> agentGetProfile({
    required String agentId,
    String? clientToken,
  });

  Future<ClientTokenPolicyResponseDto> clientTokenGetPolicy({
    required String agentId,
    required String clientToken,
  });

  Future<RpcDiscoverResponseDto> rpcDiscover({
    required String agentId,
  });
}

/// Dio-backed implementation. Generates a fresh `command.id` (UUID) for
/// every call so the bridge does not deduplicate when the user retries.
class ApiAgentMetaRemoteDataSource implements AgentMetaRemoteDataSource {
  ApiAgentMetaRemoteDataSource(this._dio, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final Dio _dio;
  final Uuid _uuid;

  @override
  Future<AgentGetProfileResponseDto> agentGetProfile({
    required String agentId,
    String? clientToken,
  }) async {
    final response = await _post(
      agentId: agentId,
      method: 'agent.getProfile',
      params: <String, Object?>{
        if (clientToken != null && clientToken.isNotEmpty)
          'client_token': clientToken,
      },
    );
    final result = _extractResultMap(response);
    return AgentGetProfileResponseDto.fromResult(result);
  }

  @override
  Future<ClientTokenPolicyResponseDto> clientTokenGetPolicy({
    required String agentId,
    required String clientToken,
  }) async {
    final response = await _post(
      agentId: agentId,
      method: 'client_token.getPolicy',
      params: <String, Object?>{'client_token': clientToken},
    );
    final result = _extractResultMap(response);
    return ClientTokenPolicyResponseDto.fromResult(result);
  }

  @override
  Future<RpcDiscoverResponseDto> rpcDiscover({
    required String agentId,
  }) async {
    final response = await _post(
      agentId: agentId,
      method: 'rpc.discover',
      params: const <String, Object?>{},
    );
    final result = _extractResultMap(response);
    return RpcDiscoverResponseDto.fromResult(result);
  }

  Future<Map<String, dynamic>> _post({
    required String agentId,
    required String method,
    required Map<String, Object?> params,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AgentCommandsApiRoutes.commands,
      data: <String, Object?>{
        'agentId': agentId,
        'command': <String, Object?>{
          'jsonrpc': '2.0',
          'method': method,
          'id': _uuid.v4(),
          if (params.isNotEmpty) 'params': params,
        },
      },
    );
    return response.data ?? const <String, dynamic>{};
  }

  /// The bridge wraps the agent's `result` inside `response.item.result`
  /// (single-command path) or `response.items[0].result` (batch). We do
  /// not use batch for these methods, so we look at the single-item shape
  /// first and fall back gracefully when the contract changes.
  Map<String, Object?> _extractResultMap(Map<String, dynamic> raw) {
    final response = raw['response'];
    if (response is Map) {
      final item = response['item'];
      if (item is Map) {
        final result = item['result'];
        if (result is Map) {
          return result.map(
            (key, value) =>
                MapEntry<String, Object?>(key.toString(), value),
          );
        }
      }
      final items = response['items'];
      if (items is List && items.isNotEmpty) {
        final first = items.first;
        if (first is Map) {
          final result = first['result'];
          if (result is Map) {
            return result.map(
              (key, value) =>
                  MapEntry<String, Object?>(key.toString(), value),
            );
          }
        }
      }
    }
    final flatResult = raw['result'];
    if (flatResult is Map) {
      return flatResult.map(
        (key, value) => MapEntry<String, Object?>(key.toString(), value),
      );
    }
    return const <String, Object?>{};
  }
}
