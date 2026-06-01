import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_query_app_failure_enrichment.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enrichAgentQueryRateLimitContext tags HTTP 429 failures', () {
    const failure = NetworkFailure(
      message: 'Too many',
      userMessage: 'Too many',
      context: <String, Object?>{'httpStatusCode': 429},
    );
    final enriched = enrichAgentQueryRateLimitContext(failure);
    check(
      enriched.context[AgentSqlRpcFailureUiKey.field],
    ).equals(AgentSqlRpcFailureUiKey.rateLimited);
  });

  test('mapAgentQueryToAppFailure merges 429 from DioException', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/agents/commands'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/agents/commands'),
        statusCode: 429,
        data: <String, dynamic>{
          'code': 'TOO_MANY_REQUESTS',
          'message': 'Too many agent commands',
        },
      ),
      type: DioExceptionType.badResponse,
    );
    final failure = mapAgentQueryToAppFailure(error);
    check(
      failure.context[AgentSqlRpcFailureUiKey.field],
    ).equals(AgentSqlRpcFailureUiKey.rateLimited);
    check(failure.context['httpStatusCode']).equals(429);
  });
}
