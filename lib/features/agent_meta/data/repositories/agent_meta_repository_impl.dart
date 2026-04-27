import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/network/bridge_rpc_response.dart';
import 'package:colmeia/features/agent_meta/data/datasources/agent_meta_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class AgentMetaRepositoryImpl implements AgentMetaRepository {
  AgentMetaRepositoryImpl(this._remoteDataSource);

  final AgentMetaRemoteDataSource _remoteDataSource;

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
    } on BridgeRpcException catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        _bridgeRpcFailure(
          error,
          stackTrace: stackTrace,
          fallbackUserMessage:
              'Nao foi possivel ler o perfil do agente atraves do bridge.',
          context: _context(
            operation: 'agent.getProfile',
            agentId: trimmedAgentId,
          ),
        ),
      );
    } on DioException catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read agent profile via RPC',
          fallbackUserMessage:
              'Nao foi possivel ler o perfil do agente atraves do bridge.',
          context: <String, Object?>{
            ..._context(operation: 'agent.getProfile', agentId: trimmedAgentId),
          },
        ),
      );
    } on SocketDispatchNamespaceForbidden catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        AuthorizationFailure(
          message: error.message,
          userMessage:
              'Servidor indisponivel para o seu perfil de acesso. '
              'Contate o administrador.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(operation: 'agent.getProfile', agentId: trimmedAgentId),
            'transportCode': error.code,
            'role': error.role,
            'namespace': error.namespace,
          },
        ),
      );
    } on SocketDispatchUnauthorized catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        SessionFailure(
          message: error.message,
          userMessage:
              'Sua sessao expirou. Faca login novamente para continuar.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(operation: 'agent.getProfile', agentId: trimmedAgentId),
            'transportCode': error.code,
          },
        ),
      );
    } on SocketDispatchAppError catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        _socketAppErrorToFailure(
          error,
          stackTrace: stackTrace,
          fallbackUserMessage:
              'Nao foi possivel ler o perfil do agente atraves do bridge.',
          context: _context(
            operation: 'agent.getProfile',
            agentId: trimmedAgentId,
          ),
        ),
      );
    } on SocketDispatchException catch (error, stackTrace) {
      return Failure<AgentProfileSnapshot, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'Falha de comunicacao com o servidor. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(operation: 'agent.getProfile', agentId: trimmedAgentId),
            'transportCode': error.code,
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
          context: _context(operation: 'agent.getProfile', agentId: trimmedAgentId),
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
    } on BridgeRpcException catch (error, stackTrace) {
      if (BridgeRpcResponse.isMethodNotFound(error)) {
        AppLogger.info(
          'client_token.getPolicy not implemented by agent; ignoring',
          context: _context(
            operation: 'client_token.getPolicy',
            agentId: trimmedAgentId,
          ),
        );
        return const Success<ClientTokenPolicySnapshot, AppFailure>(
          ClientTokenPolicySnapshot.unsupported(),
        );
      }
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        _bridgeRpcFailure(
          error,
          stackTrace: stackTrace,
          fallbackUserMessage:
              'Nao foi possivel ler a politica do token no agente.',
          context: _context(
            operation: 'client_token.getPolicy',
            agentId: trimmedAgentId,
          ),
        ),
      );
    } on DioException catch (error, stackTrace) {
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read client token policy via RPC',
          fallbackUserMessage:
              'Nao foi possivel ler a politica do token no agente.',
          context: _context(
            operation: 'client_token.getPolicy',
            agentId: trimmedAgentId,
          ),
        ),
      );
    } on SocketDispatchNamespaceForbidden catch (error, stackTrace) {
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        AuthorizationFailure(
          message: error.message,
          userMessage:
              'Servidor indisponivel para o seu perfil de acesso. '
              'Contate o administrador.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(
              operation: 'client_token.getPolicy',
              agentId: trimmedAgentId,
            ),
            'transportCode': error.code,
            'role': error.role,
            'namespace': error.namespace,
          },
        ),
      );
    } on SocketDispatchUnauthorized catch (error, stackTrace) {
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        SessionFailure(
          message: error.message,
          userMessage:
              'Sua sessao expirou. Faca login novamente para continuar.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(
              operation: 'client_token.getPolicy',
              agentId: trimmedAgentId,
            ),
            'transportCode': error.code,
          },
        ),
      );
    } on SocketDispatchAppError catch (error, stackTrace) {
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        _socketAppErrorToFailure(
          error,
          stackTrace: stackTrace,
          fallbackUserMessage:
              'Nao foi possivel ler a politica do token no agente.',
          context: _context(
            operation: 'client_token.getPolicy',
            agentId: trimmedAgentId,
          ),
        ),
      );
    } on SocketDispatchException catch (error, stackTrace) {
      return Failure<ClientTokenPolicySnapshot, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'Falha de comunicacao com o servidor. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(
              operation: 'client_token.getPolicy',
              agentId: trimmedAgentId,
            ),
            'transportCode': error.code,
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
          context: _context(
            operation: 'client_token.getPolicy',
            agentId: trimmedAgentId,
          ),
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
    } on BridgeRpcException catch (error, stackTrace) {
      if (BridgeRpcResponse.isMethodNotFound(error)) {
        return const Success<AgentRpcDescriptor, AppFailure>(
          AgentRpcDescriptor.empty(),
        );
      }
      return Failure<AgentRpcDescriptor, AppFailure>(
        _bridgeRpcFailure(
          error,
          stackTrace: stackTrace,
          fallbackUserMessage:
              'Nao foi possivel descobrir os metodos RPC do agente.',
          context: _context(operation: 'rpc.discover', agentId: trimmedAgentId),
        ),
      );
    } on DioException catch (error, stackTrace) {
      return Failure<AgentRpcDescriptor, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to discover agent RPC catalogue',
          fallbackUserMessage:
              'Nao foi possivel descobrir os metodos RPC do agente.',
          context: _context(operation: 'rpc.discover', agentId: trimmedAgentId),
        ),
      );
    } on SocketDispatchNamespaceForbidden catch (error, stackTrace) {
      return Failure<AgentRpcDescriptor, AppFailure>(
        AuthorizationFailure(
          message: error.message,
          userMessage:
              'Servidor indisponivel para o seu perfil de acesso. '
              'Contate o administrador.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(operation: 'rpc.discover', agentId: trimmedAgentId),
            'transportCode': error.code,
            'role': error.role,
            'namespace': error.namespace,
          },
        ),
      );
    } on SocketDispatchUnauthorized catch (error, stackTrace) {
      return Failure<AgentRpcDescriptor, AppFailure>(
        SessionFailure(
          message: error.message,
          userMessage:
              'Sua sessao expirou. Faca login novamente para continuar.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(operation: 'rpc.discover', agentId: trimmedAgentId),
            'transportCode': error.code,
          },
        ),
      );
    } on SocketDispatchAppError catch (error, stackTrace) {
      return Failure<AgentRpcDescriptor, AppFailure>(
        _socketAppErrorToFailure(
          error,
          stackTrace: stackTrace,
          fallbackUserMessage:
              'Nao foi possivel descobrir os metodos RPC do agente.',
          context: _context(operation: 'rpc.discover', agentId: trimmedAgentId),
        ),
      );
    } on SocketDispatchException catch (error, stackTrace) {
      return Failure<AgentRpcDescriptor, AppFailure>(
        NetworkFailure(
          message: error.message,
          userMessage:
              'Falha de comunicacao com o servidor. Tente novamente.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ..._context(operation: 'rpc.discover', agentId: trimmedAgentId),
            'transportCode': error.code,
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
          context: _context(operation: 'rpc.discover', agentId: trimmedAgentId),
        ),
      );
    }
  }

  Map<String, Object?> _context({
    required String operation,
    required String agentId,
  }) {
    return <String, Object?>{
      'operation': operation,
      'agentId': agentId,
      'transport': _remoteDataSource.transportLabel,
    };
  }

  RpcFailure _bridgeRpcFailure(
    BridgeRpcException error, {
    required StackTrace stackTrace,
    required String fallbackUserMessage,
    required Map<String, Object?> context,
  }) {
    final details = error.details;
    final mergedContext = <String, Object?>{
      ...context,
      'rpcCode': details.code,
      'reason': details.reason,
      'category': details.category,
      'correlationId': details.correlationId,
      if (details.errorData != null) 'errorData': details.errorData,
    };
    return RpcFailure(
      message: details.message,
      userMessage: details.userMessage.isEmpty
          ? fallbackUserMessage
          : details.userMessage,
      rpcCode: details.codeAsInt,
      retryable: details.retryable,
      reason: details.reason,
      category: details.category,
      technicalMessage: details.technicalMessage,
      correlationId: details.correlationId,
      timestamp: details.timestamp,
      cause: error,
      stackTrace: stackTrace,
      context: mergedContext,
    );
  }

  AppFailure _socketAppErrorToFailure(
    SocketDispatchAppError error, {
    required StackTrace stackTrace,
    required String fallbackUserMessage,
    required Map<String, Object?> context,
  }) {
    if (isSocketAuthenticationFailedCode(error.code)) {
      return SessionFailure(
        message: error.message,
        userMessage:
            'Sua sessao expirou. Faca login novamente para continuar.',
        cause: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          ...context,
          'transportCode': error.code,
        },
      );
    }
    if (isSocketAuthorizationDeniedCode(error.code)) {
      return AuthorizationFailure(
        message: error.message,
        userMessage: 'Voce nao tem acesso a este agente.',
        cause: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          ...context,
          'transportCode': error.code,
        },
      );
    }
    return NetworkFailure(
      message: error.message,
      userMessage: fallbackUserMessage,
      retryAfter: error.retryAfter,
      cause: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        ...context,
        'transportCode': error.code,
      },
    );
  }
}
