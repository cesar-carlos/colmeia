import 'package:colmeia/core/socket/per_agent_concurrency_gate.dart';
import 'package:colmeia/features/agent_queries/data/datasources/agent_queries_remote_datasource.dart';
import 'package:colmeia/features/agent_queries/data/repositories/adaptive_timeout_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_queries_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/circuit_breaker_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/coalescing_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/gated_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/metrics_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/rest_inflight_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/data/repositories/retrying_agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_sql_execution_eligibility_port.dart';

class AgentQueriesRepositoryChain {
  const AgentQueriesRepositoryChain({
    required this.repository,
    required this.decorators,
    required this.metricsRepository,
    required this.cachingRepository,
  });

  final AgentQueriesRepository repository;

  /// Outermost-to-innermost chain names, useful for logs and tests.
  final List<String> decorators;

  /// Inner metrics decorator (latency / periodic logs). Same instance the
  /// chain wires below [CachingAgentQueriesRepository].
  final MetricsAgentQueriesRepository metricsRepository;

  /// In-memory SQL result cache wired outside [MetricsAgentQueriesRepository].
  final CachingAgentQueriesRepository cachingRepository;
}

abstract final class AgentQueriesRepositoryChainFactory {
  static AgentQueriesRepositoryChain build({
    required AgentQueriesRemoteDataSource remoteDataSource,
    required AgentSqlExecutionEligibilityPort eligibility,
    required int maxCacheSize,
    Duration cacheTtl = CachingAgentQueriesRepository.defaultCacheTtl,
    int agentSqlRestMaxInflightPerAgent = 0,
  }) {
    final base = AgentQueriesRepositoryImpl(remoteDataSource);

    final retryingDelegate =
        agentSqlRestMaxInflightPerAgent > 0
        ? RestInflightAgentQueriesRepository(
            delegate: base,
            gate: PerAgentConcurrencyGate(
              maxInflightPerAgent: agentSqlRestMaxInflightPerAgent,
            ),
          )
        : base;

    final retrying = RetryingAgentQueriesRepository(
      delegate: retryingDelegate,
    );

    final adaptiveTimeout = AdaptiveTimeoutAgentQueriesRepository(
      delegate: retrying,
    );

    final metrics = MetricsAgentQueriesRepository(
      delegate: adaptiveTimeout,
    );

    final coalescing = CoalescingAgentQueriesRepository(
      delegate: metrics,
    );

    final caching = CachingAgentQueriesRepository(
      delegate: coalescing,
      cacheTtl: cacheTtl,
      maxCacheSize: maxCacheSize,
    );
    metrics.sqlCache = caching;

    final circuitBreaker = CircuitBreakerAgentQueriesRepository(
      delegate: caching,
    );

    final gated = GatedAgentQueriesRepository(
      delegate: circuitBreaker,
      eligibility: eligibility,
    );

    final decorators = <String>[
      'GatedAgentQueriesRepository',
      'CircuitBreakerAgentQueriesRepository',
      'CachingAgentQueriesRepository',
      'CoalescingAgentQueriesRepository',
      'MetricsAgentQueriesRepository',
      'AdaptiveTimeoutAgentQueriesRepository',
      'RetryingAgentQueriesRepository',
      if (agentSqlRestMaxInflightPerAgent > 0)
        'RestInflightAgentQueriesRepository',
      'AgentQueriesRepositoryImpl',
    ];

    return AgentQueriesRepositoryChain(
      repository: gated,
      decorators: decorators,
      metricsRepository: metrics,
      cachingRepository: caching,
    );
  }
}
