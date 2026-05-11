import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/network/bridge_rpc_response.dart';
import 'package:colmeia/core/socket/agent_command_sender.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
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
    AppLogger.debug(
      'Agent meta bridge RPC request prepared',
      context: <String, Object?>{
        'component': 'AgentMetaRemoteDataSource',
        'agentId': trimmedAgentId,
        'method': method,
        'transport': transportLabel,
      },
    );
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

/// Socket datasource with a permanent REST fallback for socket failures that
/// are session/server-configuration scoped. This keeps agent metadata aligned
/// with the SQL bridge path: when the consumer namespace rejects the current
/// JWT role, or socket auth is exhausted, metadata calls do not become the
/// only failing part of an otherwise REST-fallback-capable flow.
class SocketWithRestFallbackAgentMetaRemoteDataSource
    implements AgentMetaRemoteDataSource {
  SocketWithRestFallbackAgentMetaRemoteDataSource({
    required AgentMetaRemoteDataSource socketDelegate,
    required AgentMetaRemoteDataSource restDelegate,
    void Function(SocketDispatchException trigger)? onFallback,
  }) : _socketDelegate = socketDelegate,
       _restDelegate = restDelegate,
       _onFallback = onFallback;

  final AgentMetaRemoteDataSource _socketDelegate;
  final AgentMetaRemoteDataSource _restDelegate;
  final void Function(SocketDispatchException trigger)? _onFallback;

  bool _latched = false;

  bool get isLatchedToRest => _latched;

  @override
  String get transportLabel => _latched
      ? _restDelegate.transportLabel
      : '${_socketDelegate.transportLabel}+rest_fallback';

  @override
  Future<AgentGetProfileResponseDto> agentGetProfile({
    required String agentId,
    String? clientToken,
  }) {
    return _run(
      socketCall: () => _socketDelegate.agentGetProfile(
        agentId: agentId,
        clientToken: clientToken,
      ),
      restCall: () => _restDelegate.agentGetProfile(
        agentId: agentId,
        clientToken: clientToken,
      ),
    );
  }

  @override
  Future<ClientTokenPolicyResponseDto> clientTokenGetPolicy({
    required String agentId,
    required String clientToken,
  }) {
    return _run(
      socketCall: () => _socketDelegate.clientTokenGetPolicy(
        agentId: agentId,
        clientToken: clientToken,
      ),
      restCall: () => _restDelegate.clientTokenGetPolicy(
        agentId: agentId,
        clientToken: clientToken,
      ),
    );
  }

  @override
  Future<RpcDiscoverResponseDto> rpcDiscover({
    required String agentId,
  }) {
    return _run(
      socketCall: () => _socketDelegate.rpcDiscover(agentId: agentId),
      restCall: () => _restDelegate.rpcDiscover(agentId: agentId),
    );
  }

  Future<T> _run<T>({
    required Future<T> Function() socketCall,
    required Future<T> Function() restCall,
  }) async {
    if (_latched) {
      return restCall();
    }
    try {
      return await socketCall();
    } on SocketDispatchLegacyStreamingUnsupported catch (trigger) {
      AppLogger.warning(
        'Agent meta: hub chose legacy socket streaming; retrying once on REST',
        context: <String, Object?>{
          'component': 'SocketWithRestFallbackAgentMetaRemoteDataSource',
          'triggerCode': trigger.code,
          'streamId': trigger.streamId,
        },
        error: trigger,
      );
      return restCall();
    } on SocketDispatchNamespaceForbidden catch (trigger) {
      _latch(trigger, reason: 'namespace_forbidden');
      return restCall();
    } on SocketDispatchUnauthorized catch (trigger) {
      _latch(trigger, reason: 'unauthorized_exhausted');
      return restCall();
    }
  }

  void _latch(
    SocketDispatchException trigger, {
    required String reason,
  }) {
    if (_latched) {
      return;
    }
    _latched = true;
    AppLogger.warning(
      'Agent meta datasource latched to REST fallback '
      '(socket permanent failure)',
      context: <String, Object?>{
        'component': 'SocketWithRestFallbackAgentMetaRemoteDataSource',
        'reason': reason,
        'triggerCode': trigger.code,
        'triggerMessage': trigger.message,
      },
      error: trigger,
    );
    final hook = _onFallback;
    if (hook == null) {
      return;
    }
    try {
      hook(trigger);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Agent meta fallback observability hook threw',
        context: const <String, Object?>{
          'component': 'SocketWithRestFallbackAgentMetaRemoteDataSource',
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
