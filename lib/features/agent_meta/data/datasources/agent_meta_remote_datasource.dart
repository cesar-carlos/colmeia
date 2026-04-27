import 'package:colmeia/core/network/bridge_rpc_response.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/features/agent_meta/data/models/agent_get_profile_response_dto.dart';
import 'package:colmeia/features/agent_meta/data/models/client_token_policy_response_dto.dart';
import 'package:colmeia/features/agent_meta/data/models/rpc_discover_response_dto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Datasource for `agent.getProfile`, `client_token.getPolicy` and
/// `rpc.discover`. Implementations keep the bridge body identical across REST
/// and socket transports.
abstract interface class AgentMetaRemoteDataSource {
  String get transportLabel;

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

abstract class _BridgeAgentMetaRemoteDataSource
    implements AgentMetaRemoteDataSource {
  _BridgeAgentMetaRemoteDataSource({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

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
    final result = BridgeRpcResponse.parseSingleResultMap(response);
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
    final result = BridgeRpcResponse.parseSingleResultMap(response);
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
    final result = BridgeRpcResponse.parseSingleResultMap(response);
    return RpcDiscoverResponseDto.fromResult(result);
  }

  Future<Map<String, dynamic>> _post({
    required String agentId,
    required String method,
    required Map<String, Object?> params,
  }) {
    final trimmedAgentId = agentId.trim();
    final rpcId = _uuid.v4();
    return postBridgeCommand(
      agentId: trimmedAgentId,
      rpcId: rpcId,
      body: <String, Object?>{
        'agentId': trimmedAgentId,
        'command': <String, Object?>{
          'jsonrpc': '2.0',
          'method': method,
          'id': rpcId,
          if (params.isNotEmpty) 'params': params,
        },
      },
    );
  }

  Future<Map<String, dynamic>> postBridgeCommand({
    required String agentId,
    required String rpcId,
    required Map<String, Object?> body,
  });
}

/// Dio-backed implementation. Generates a fresh `command.id` (UUID) for
/// every call so the bridge does not deduplicate when the user retries.
class ApiAgentMetaRemoteDataSource extends _BridgeAgentMetaRemoteDataSource {
  ApiAgentMetaRemoteDataSource(this._dio, {super.uuid});

  final Dio _dio;

  @override
  String get transportLabel => 'rest';

  @override
  Future<Map<String, dynamic>> postBridgeCommand({
    required String agentId,
    required String rpcId,
    required Map<String, Object?> body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AgentCommandsApiRoutes.commands,
      data: body,
    );
    return response.data ?? const <String, dynamic>{};
  }
}

/// Socket-backed implementation. It sends the same bridge body through
/// `agents:command` that [ApiAgentMetaRemoteDataSource] posts to REST.
class SocketAgentMetaRemoteDataSource extends _BridgeAgentMetaRemoteDataSource {
  SocketAgentMetaRemoteDataSource({
    required AgentCommandSender sender,
    super.uuid,
  }) : _sender = sender;

  final AgentCommandSender _sender;

  @override
  String get transportLabel => 'socket';

  @override
  Future<Map<String, dynamic>> postBridgeCommand({
    required String agentId,
    required String rpcId,
    required Map<String, Object?> body,
  }) {
    return _sender.send(
      agentId: agentId.trim(),
      body: body,
      rpcId: rpcId,
    );
  }
}
