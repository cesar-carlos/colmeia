import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_chain_factory.dart';
import 'package:colmeia/features/agent_queries/data/repositories/gated_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_eligibility_evaluation.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAgentQueriesRemoteDataSource
    implements AgentQueriesRemoteDataSource {
  @override
  Future<Map<String, dynamic>> postSqlExecute(
    AgentSqlExecuteRequest request,
  ) async {
    return const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> postSqlExecuteBatch(
    AgentSqlExecuteBatchRequest request,
  ) async {
    return const <String, dynamic>{};
  }
}

final class _AllowingEligibility implements AgentSqlExecutionEligibilityPort {
  @override
  Future<AgentSqlExecutionEligibilityEvaluation> evaluate({
    required String userId,
    required String agentId,
    bool? isHubConnected,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
  }) async {
    return const AgentSqlExecutionEligibilityEvaluation.allowed();
  }
}

void main() {
  test('builds AgentQueriesRepository decorator chain in expected order', () {
    final chain = AgentQueriesRepositoryChainFactory.build(
      remoteDataSource: _FakeAgentQueriesRemoteDataSource(),
      eligibility: _AllowingEligibility(),
      maxCacheSize: 50,
    );

    check(chain.repository).isA<GatedAgentQueriesRepository>();
    check(chain.decorators).deepEquals(<String>[
      'GatedAgentQueriesRepository',
      'CircuitBreakerAgentQueriesRepository',
      'CachingAgentQueriesRepository',
      'CoalescingAgentQueriesRepository',
      'MetricsAgentQueriesRepository',
      'AdaptiveTimeoutAgentQueriesRepository',
      'RetryingAgentQueriesRepository',
      'AgentQueriesRepositoryImpl',
    ]);
  });
}
