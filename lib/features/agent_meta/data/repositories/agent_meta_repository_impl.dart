import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_meta/data/datasources/agent_meta_remote_datasource.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class AgentMetaRepositoryImpl implements AgentMetaRepository {
  AgentMetaRepositoryImpl(this._remoteDataSource);

  final AgentMetaRemoteDataSource _remoteDataSource;

  /// JSON-RPC error code emitted by agents that do not implement (or
  /// disabled) introspection of the client token policy. Surfaced as
  /// `Success(null)` rather than a failure so the UI can quietly hide
  /// the "permissions" section instead of showing a red error.
  static const String _methodNotFound = '-32601';
  static const String _methodNotFoundCode = 'method_not_found';

  @override
  Future<AppResult<AgentProfileSnapshot>> getAgentProfile({
    required String agentId,
    String? clientToken,
  }) async {
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return const Failure<AgentProfileSnapshot, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }
    try {
      final dto = await _remoteDataSource.agentGetProfile(
        agentId: trimmedAgentId,
        clientToken: clientToken,
      );
      return Success<AgentProfileSnapshot, AppFailure>(dto.toEntity());
    } on DioException catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read agent profile via RPC',
          fallbackUserMessage:
              'Nao foi possivel ler o perfil do agente atraves do bridge.',
          context: <String, Object?>{
            'operation': 'agent.getProfile',
            'agentId': trimmedAgentId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read agent profile via RPC',
          fallbackUserMessage:
              'Nao foi possivel ler o perfil do agente atraves do bridge.',
          context: <String, Object?>{
            'operation': 'agent.getProfile',
            'agentId': trimmedAgentId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<ClientTokenPolicySnapshot>> getClientTokenPolicy({
    required String agentId,
    required String clientToken,
  }) async {
    final trimmedAgentId = agentId.trim();
    final trimmedToken = clientToken.trim();
    if (trimmedAgentId.isEmpty) {
      return const Failure<ClientTokenPolicySnapshot, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }
    if (trimmedToken.isEmpty) {
      return const Failure<ClientTokenPolicySnapshot, AppFailure>(
        ValidationFailure(
          message: 'Client token is empty',
          userMessage: 'A token is required to read its policy.',
        ),
      );
    }
    try {
      final dto = await _remoteDataSource.clientTokenGetPolicy(
        agentId: trimmedAgentId,
        clientToken: trimmedToken,
      );
      return Success<ClientTokenPolicySnapshot, AppFailure>(
        ClientTokenPolicySnapshot.from(dto.toEntity()),
      );
    } on DioException catch (error, stackTrace) {
      if (_isMethodNotFound(error)) {
        AppLogger.info(
          'client_token.getPolicy not implemented by agent; ignoring',
          context: <String, Object?>{
            'operation': 'client_token.getPolicy',
            'agentId': trimmedAgentId,
          },
        );
        return const Success<ClientTokenPolicySnapshot, AppFailure>(
          ClientTokenPolicySnapshot.unsupported(),
        );
      }
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read client token policy via RPC',
          fallbackUserMessage:
              'Nao foi possivel ler a politica do token no agente.',
          context: <String, Object?>{
            'operation': 'client_token.getPolicy',
            'agentId': trimmedAgentId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read client token policy via RPC',
          fallbackUserMessage:
              'Nao foi possivel ler a politica do token no agente.',
          context: <String, Object?>{
            'operation': 'client_token.getPolicy',
            'agentId': trimmedAgentId,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<AgentRpcDescriptor>> discoverAgentRpc({
    required String agentId,
  }) async {
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return const Failure<AgentRpcDescriptor, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }
    try {
      final dto = await _remoteDataSource.rpcDiscover(
        agentId: trimmedAgentId,
      );
      return Success<AgentRpcDescriptor, AppFailure>(dto.toEntity());
    } on DioException catch (error, stackTrace) {
      if (_isMethodNotFound(error)) {
        return const Success<AgentRpcDescriptor, AppFailure>(
          AgentRpcDescriptor.empty(),
        );
      }
      return Failure<AgentRpcDescriptor, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to discover agent RPC catalogue',
          fallbackUserMessage:
              'Nao foi possivel descobrir os metodos RPC do agente.',
          context: <String, Object?>{
            'operation': 'rpc.discover',
            'agentId': trimmedAgentId,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failure<AgentRpcDescriptor, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to discover agent RPC catalogue',
          fallbackUserMessage:
              'Nao foi possivel descobrir os metodos RPC do agente.',
          context: <String, Object?>{
            'operation': 'rpc.discover',
            'agentId': trimmedAgentId,
          },
        ),
      );
    }
  }

  bool _isMethodNotFound(DioException error) {
    final response = error.response?.data;
    if (response is! Map) {
      return false;
    }
    Object? errorBlock = response['error'];
    if (errorBlock is! Map) {
      final inner = response['response'];
      if (inner is Map) {
        final item = inner['item'];
        if (item is Map) {
          errorBlock = item['error'];
        }
      }
    }
    if (errorBlock is! Map) {
      return false;
    }
    final code = errorBlock['code']?.toString();
    final reason = errorBlock['reason']?.toString().toLowerCase();
    return code == _methodNotFound || reason == _methodNotFoundCode;
  }
}
