import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';

final class AgentQueriesTransportFailureMapper {
  const AgentQueriesTransportFailureMapper();

  AppFailure mapSocket({
    required SocketDispatchException error,
    required StackTrace stackTrace,
    required String operation,
    required String agentId,
  }) {
    final context = _socketContext(
      error: error,
      operation: operation,
      agentId: agentId,
    );

    if (error is SocketDispatchCancelled) {
      return OperationCancelledFailure(
        message: error.message,
        context: _cancelledContext(
          _withUiKey(
            context,
            AgentSqlRpcFailureUiKey.executionCancelled,
          ),
        ),
      );
    }

    if (error is SocketDispatchTimeout) {
      return NetworkFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(
          context,
          AgentSqlRpcFailureUiKey.transportTimeout,
        ),
      );
    }

    if (error is SocketDispatchNamespaceForbidden) {
      return AuthorizationFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(
          context,
          AgentSqlRpcFailureUiKey.permissionDenied,
        ),
      );
    }

    if (error is SocketDispatchUnauthorized) {
      return SessionFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(
          context,
          AgentSqlRpcFailureUiKey.authenticationFailed,
        ),
      );
    }

    if (error is SocketDispatchAppError) {
      return _appErrorToFailure(
        message: error.message,
        serverCode: error.code,
        cause: error,
        stackTrace: stackTrace,
        retryAfter: error.retryAfter,
        baseContext: context,
      );
    }

    if (error is SocketDispatchLegacyStreamingUnsupported) {
      return UnknownFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(context, AgentSqlRpcFailureUiKey.generic),
      );
    }

    return NetworkFailure(
      message: error.message,
      cause: error,
      stackTrace: stackTrace,
      context: _withUiKey(context, AgentSqlRpcFailureUiKey.networkError),
    );
  }

  AppFailure mapRelay({
    required RelayDispatchException error,
    required StackTrace stackTrace,
    required String operation,
    required String agentId,
  }) {
    final context = _relayContext(
      error: error,
      operation: operation,
      agentId: agentId,
    );

    if (error is RelayDispatcherDisposed) {
      return UnknownFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _cancelledContext(
          _withUiKey(
            context,
            AgentSqlRpcFailureUiKey.executionCancelled,
          ),
        ),
      );
    }

    if (error is RelayRequestRejected) {
      return _appErrorToFailure(
        message: error.message,
        serverCode: error.code,
        cause: error,
        stackTrace: stackTrace,
        retryAfter: error.retryAfter,
        baseContext: context,
      );
    }

    if (error is RelayRequestTimeout) {
      return NetworkFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(
          context,
          AgentSqlRpcFailureUiKey.transportTimeout,
        ),
      );
    }

    if (error is RelayRequestCancelled) {
      return OperationCancelledFailure(
        message: error.message,
        context: _cancelledContext(context),
      );
    }

    if (error is RelayConversationLost ||
        error is RelayConversationStartFailure ||
        error is RelayStreamTerminated) {
      return NetworkFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(context, AgentSqlRpcFailureUiKey.networkError),
      );
    }

    if (error is RelayDecodeFailure) {
      return NetworkFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(context, AgentSqlRpcFailureUiKey.generic),
      );
    }

    if (error is RelayDuplicateRequestId) {
      return UnknownFailure(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
        context: _withUiKey(context, AgentSqlRpcFailureUiKey.generic),
      );
    }

    return NetworkFailure(
      message: error.message,
      cause: error,
      stackTrace: stackTrace,
      context: _withUiKey(context, AgentSqlRpcFailureUiKey.networkError),
    );
  }

  void logDispatchFailure({
    required String message,
    required Object error,
    required StackTrace stackTrace,
    required AppFailure failure,
  }) {
    final context = <String, Object?>{
      ...failure.context,
      'failureType': failure.runtimeType.toString(),
    };
    if (isCancelledAgentQueryFailure(failure.context)) {
      AppLogger.debug(message, context: context);
      return;
    }
    AppLogger.warning(
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Map<String, Object?> _socketContext({
    required SocketDispatchException error,
    required String operation,
    required String agentId,
  }) {
    final context = <String, Object?>{
      'operation': operation,
      'agentId': agentId,
      AgentQueriesFailureContext.transportField: 'socket',
      AgentQueriesFailureContext.transportCodeField: error.code,
    };
    if (error is SocketDispatchNamespaceForbidden) {
      context['role'] = error.role;
      context['namespace'] = error.namespace;
    }
    if (error is SocketDispatchLegacyStreamingUnsupported) {
      context['streamId'] = error.streamId;
    }
    return context;
  }

  Map<String, Object?> _relayContext({
    required RelayDispatchException error,
    required String operation,
    required String agentId,
  }) {
    return <String, Object?>{
      'operation': operation,
      'agentId': agentId,
      AgentQueriesFailureContext.transportField: 'relay',
      AgentQueriesFailureContext.transportCodeField: error.code,
      'conversationId': error.conversationId,
      'clientRequestId': error.clientRequestId,
    };
  }

  AppFailure _appErrorToFailure({
    required String message,
    required String serverCode,
    required Object cause,
    required StackTrace stackTrace,
    required Map<String, Object?> baseContext,
    Duration? retryAfter,
  }) {
    if (isSocketAuthenticationFailedCode(serverCode)) {
      return SessionFailure(
        message: message,
        cause: cause,
        stackTrace: stackTrace,
        context: _withUiKey(
          baseContext,
          AgentSqlRpcFailureUiKey.authenticationFailed,
        ),
      );
    }
    if (isSocketAuthorizationDeniedCode(serverCode)) {
      return AuthorizationFailure(
        message: message,
        cause: cause,
        stackTrace: stackTrace,
        context: _withUiKey(
          baseContext,
          AgentSqlRpcFailureUiKey.permissionDenied,
        ),
      );
    }
    if (isSocketRateLimitedCode(serverCode)) {
      return NetworkFailure(
        message: message,
        retryAfter: retryAfter,
        cause: cause,
        stackTrace: stackTrace,
        context: _withUiKey(
          baseContext,
          AgentSqlRpcFailureUiKey.rateLimited,
        ),
      );
    }
    return NetworkFailure(
      message: message,
      retryAfter: retryAfter,
      cause: cause,
      stackTrace: stackTrace,
      context: _withUiKey(baseContext, AgentSqlRpcFailureUiKey.networkError),
    );
  }

  Map<String, Object?> _withUiKey(
    Map<String, Object?> base,
    String uiKey,
  ) {
    return <String, Object?>{
      ...base,
      AgentSqlRpcFailureUiKey.field: uiKey,
    };
  }

  Map<String, Object?> _cancelledContext(Map<String, Object?> base) {
    return <String, Object?>{
      ...base,
      AgentQueriesFailureContext.cancelledField: true,
    };
  }
}
