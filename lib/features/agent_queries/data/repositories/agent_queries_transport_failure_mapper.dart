import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/socket/relay/relay_dispatch_exception.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';

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
      return UnknownFailure(
        message: error.message,
        userMessage: 'A consulta foi cancelada.',
        cause: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          ...context,
          AgentQueriesFailureContext.cancelledField: true,
        },
      );
    }

    if (error is SocketDispatchNamespaceForbidden) {
      return AuthorizationFailure(
        message: error.message,
        userMessage:
            'Servidor indisponivel para o seu perfil de acesso. '
            'Contate o administrador (perfil "${error.role ?? '?'}" '
            'nao autorizado em ${error.namespace ?? '/consumers'}).',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    if (error is SocketDispatchUnauthorized) {
      return SessionFailure(
        message: error.message,
        userMessage: 'Sua sessao expirou. Faca login novamente para continuar.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
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
        userMessage:
            'Esta consulta precisa do canal relay ou REST. '
            'Use relay (useRelay) ou altere o transporte do bridge.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    return NetworkFailure(
      message: error.message,
      userMessage: 'Falha de comunicacao com o servidor. Tente novamente.',
      cause: error,
      stackTrace: stackTrace,
      context: context,
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
        userMessage: 'A consulta foi cancelada.',
        cause: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          ...context,
          AgentQueriesFailureContext.cancelledField: true,
        },
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
        userMessage:
            'A consulta demorou mais do que o esperado. Tente novamente.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    if (error is RelayRequestCancelled) {
      return OperationCancelledFailure(
        message: error.message,
        context: <String, Object?>{
          ...context,
          AgentQueriesFailureContext.cancelledField: true,
        },
      );
    }

    if (error is RelayConversationLost) {
      return NetworkFailure(
        message: error.message,
        userMessage:
            'A conexao com o servidor caiu durante a consulta. '
            'Tente novamente.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    if (error is RelayConversationStartFailure) {
      return NetworkFailure(
        message: error.message,
        userMessage:
            'Nao foi possivel abrir o canal com o servidor para esta '
            'consulta. Tente novamente.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    if (error is RelayStreamTerminated) {
      return NetworkFailure(
        message: error.message,
        userMessage:
            'A consulta foi interrompida antes de terminar. Tente novamente.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    if (error is RelayDecodeFailure) {
      return NetworkFailure(
        message: error.message,
        userMessage:
            'A resposta do servidor chegou em formato invalido. '
            'Tente novamente.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    if (error is RelayDuplicateRequestId) {
      return UnknownFailure(
        message: error.message,
        userMessage:
            'Ocorreu um erro inesperado ao consultar o agente. Tente novamente.',
        cause: error,
        stackTrace: stackTrace,
        context: context,
      );
    }

    return NetworkFailure(
      message: error.message,
      userMessage: 'Falha de comunicacao com o servidor. Tente novamente.',
      cause: error,
      stackTrace: stackTrace,
      context: context,
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
        userMessage: 'Sua sessao expirou. Faca login novamente para continuar.',
        cause: cause,
        stackTrace: stackTrace,
        context: baseContext,
      );
    }
    if (isSocketAuthorizationDeniedCode(serverCode)) {
      return AuthorizationFailure(
        message: message,
        userMessage: 'Voce nao tem acesso a este agente.',
        cause: cause,
        stackTrace: stackTrace,
        context: baseContext,
      );
    }
    return NetworkFailure(
      message: message,
      userMessage:
          'O servidor nao conseguiu processar a consulta agora. '
          'Tente novamente.',
      retryAfter: retryAfter,
      cause: cause,
      stackTrace: stackTrace,
      context: baseContext,
    );
  }
}
