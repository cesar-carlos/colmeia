import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_failure_codes.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:dio/dio.dart';

/// Merges rate-limit UI metadata when [failure] originated from a hub HTTP 429
/// or already carries a transport rate-limit code.
AppFailure enrichAgentQueryRateLimitContext(AppFailure failure) {
  if (_hasRateLimitUiKey(failure.context)) {
    return failure;
  }

  final statusCode = failure.context['httpStatusCode'];
  if (statusCode == 429) {
    return appFailureWithMergedContext(
      failure,
      <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
      },
    );
  }

  final transportCode =
      failure.context[AgentQueriesFailureContext.transportCodeField];
  if (transportCode is String && isSocketRateLimitedCode(transportCode)) {
    return appFailureWithMergedContext(
      failure,
      <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
      },
    );
  }

  if (failure is RpcFailure && failure.rpcCode == -32013) {
    return appFailureWithMergedContext(
      failure,
      <String, Object?>{
        AgentSqlRpcFailureUiKey.field: AgentSqlRpcFailureUiKey.rateLimited,
      },
    );
  }

  return failure;
}

/// Like [mapToAppFailure] but tags HTTP 429 / transport rate limits for query UX.
AppFailure mapAgentQueryToAppFailure(
  Object error, {
  StackTrace? stackTrace,
  String? fallbackMessage,
  String? fallbackUserMessage,
  Map<String, Object?> context = const <String, Object?>{},
}) {
  final mapped = mapToAppFailure(
    error,
    stackTrace: stackTrace,
    fallbackMessage: fallbackMessage,
    fallbackUserMessage: fallbackUserMessage,
    context: error is DioException
        ? <String, Object?>{
            ...context,
            'httpStatusCode': error.response?.statusCode,
          }
        : context,
  );
  return enrichAgentQueryRateLimitContext(mapped);
}

bool _hasRateLimitUiKey(Map<String, Object?> context) {
  return context[AgentSqlRpcFailureUiKey.field] ==
      AgentSqlRpcFailureUiKey.rateLimited;
}
