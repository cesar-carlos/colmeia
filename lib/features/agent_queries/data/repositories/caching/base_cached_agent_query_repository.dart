import 'dart:math' as math;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_read_only_batch_options.dart';
import 'package:colmeia/features/agent_queries/data/repositories/agent_sql_repository_execution.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/agent_query_facts_bucket_batch_support.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_bucket_plan.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_cache_control.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_key_prefix.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_catalog.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_storage_mode.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_cache_invalidate_scope.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:result_dart/result_dart.dart';

typedef AgentQuerySingleLoad<Filter, Row> =
    Future<AppResult<List<Row>>> Function({
      required String userId,
      required String agentId,
      required Filter filter,
      String? clientToken,
      int? bridgeTimeoutMs,
      Set<String>? hubPresenceOnlineAgentIdsSnapshot,
      bool? hubConnectedFromApprovedCatalogRow,
      AgentQueriesCancelScope? cancelScope,
      AgentQueryLoadPolicy cachePolicy,
    });

/// Shared read-through / write-behind logic for per-bucket fact caching.
abstract base class BaseCachedAgentQueryRepository<Filter, Row extends Object>
    implements AgentQueryCacheControl {
  BaseCachedAgentQueryRepository({
    required AgentQuerySingleLoad<Filter, Row> delegateLoad,
    required AgentQueryFactsStore factsStore,
    required AgentQueryCacheStrategy<Filter, Row> strategy,
    AgentQueriesRepository? agentQueriesRepository,
    AgentQueryFactsBucketBatchSupport<Filter, Row>? bucketBatchSupport,
    DateTime Function()? clock,
    int? bucketLoadConcurrency,
    bool? useExecuteBatchForBuckets,
  }) : _delegateLoad = delegateLoad,
       _factsStore = factsStore,
       _strategy = strategy,
       _agentQueriesRepository = agentQueriesRepository,
       _bucketBatchSupport = bucketBatchSupport,
       _clock = clock ?? DateTime.now,
       _bucketLoadConcurrency =
           bucketLoadConcurrency ??
           AppEnvironment.agentQueryFactsBucketLoadConcurrency,
       _useExecuteBatchForBuckets =
           useExecuteBatchForBuckets ??
           AppEnvironment.agentQueryFactsBucketUseExecuteBatch;

  final AgentQuerySingleLoad<Filter, Row> _delegateLoad;
  final AgentQueryFactsStore _factsStore;
  final AgentQueryCacheStrategy<Filter, Row> _strategy;
  final AgentQueriesRepository? _agentQueriesRepository;
  final AgentQueryFactsBucketBatchSupport<Filter, Row>? _bucketBatchSupport;
  final DateTime Function() _clock;
  final int _bucketLoadConcurrency;
  final bool _useExecuteBatchForBuckets;

  AgentQueryCacheStrategy<Filter, Row> get strategy => _strategy;

  AgentQueryFactsStore get factsStore => _factsStore;

  @override
  AgentQueryFactKind get factKind => _strategy.factKind;

  Future<AppResult<List<Row>>> loadWithCache({
    required String userId,
    required String agentId,
    required Filter filter,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (cachePolicy == AgentQueryLoadPolicy.networkOnly ||
        _strategy.storageMode == ConsolidationStorageMode.derivedOnly) {
      return _delegateLoad(
        userId: userId,
        agentId: agentId,
        filter: filter,
        clientToken: clientToken,
        bridgeTimeoutMs: bridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
        cachePolicy: cachePolicy,
      );
    }

    final clock = _clock();
    final plan = _strategy.planBuckets(
      filter: filter,
      clock: clock,
      policy: cachePolicy,
    );

    final prefetchedPayloads = await _readClosedBucketPayloads(
      userId: userId,
      agentId: agentId,
      rangeFilter: filter,
      plan: plan,
      cachePolicy: cachePolicy,
    );

    final networkBucketIds = plan.allBucketIdsInRange
        .where(plan.networkBucketIds.contains)
        .toList(growable: false);
    final batchedNetworkResults = await _loadNetworkBucketsViaExecuteBatch(
      userId: userId,
      agentId: agentId,
      rangeFilter: filter,
      networkBucketIds: networkBucketIds,
      plan: plan,
      cachePolicy: cachePolicy,
      clock: clock,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );

    final bucketResults = await _loadBucketsInWaves(
      bucketIds: plan.allBucketIdsInRange,
      loadBucket: (bucketId) => _loadBucket(
        userId: userId,
        agentId: agentId,
        rangeFilter: filter,
        bucketId: bucketId,
        plan: plan,
        cachePolicy: cachePolicy,
        clock: clock,
        prefetchedPayload:
            prefetchedPayloads[_strategy.storageKey(
              userId: userId,
              agentId: agentId,
              bucketId: bucketId,
              rangeFilter: filter,
            )],
        prefetchedNetworkResult: batchedNetworkResults[bucketId],
        clientToken: clientToken,
        bridgeTimeoutMs: bridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
      ),
    );

    final rows = <Row>[];
    for (final bucketResult in bucketResults) {
      final bucketRows = bucketResult.getOrNull();
      if (bucketRows == null) {
        return Failure<List<Row>, AppFailure>(bucketResult.exceptionOrNull()!);
      }
      rows.addAll(bucketRows);
    }

    return Success<List<Row>, AppFailure>(rows);
  }

  @override
  Future<void> invalidateCache(AgentQueryCacheInvalidateScope scope) async {
    switch (scope) {
      case AgentQueryCacheInvalidateBucket(
        :final userId,
        :final agentId,
        :final factKind,
        :final cacheScopeId,
        :final bucketId,
      ):
        if (factKind != _strategy.factKind) {
          return;
        }
        await _factsStore.removeKey(
          _storageKeyForScope(
            userId: userId,
            agentId: agentId,
            cacheScopeId: cacheScopeId,
            bucketId: bucketId,
          ),
        );
      case AgentQueryCacheInvalidateUser(:final userId):
        await _factsStore.removeMatching(
          AgentQueryFactsKeyPrefix.forUser(userId),
        );
      case AgentQueryCacheInvalidateAgent(:final userId, :final agentId):
        await _factsStore.removeMatching(
          AgentQueryFactsKeyPrefix.forAgent(userId: userId, agentId: agentId),
        );
      case AgentQueryCacheInvalidateFactKind(:final userId, :final factKind):
        if (factKind != _strategy.factKind) {
          return;
        }
        await _factsStore.removeMatchingFactKind(
          userId: userId,
          factKind: factKind,
        );
    }
  }

  String _storageKeyForScope({
    required String userId,
    required String agentId,
    required String cacheScopeId,
    required String bucketId,
  }) {
    return '${AgentQueryFactsKeyPrefix.forAgent(userId: userId, agentId: agentId)}${_strategy.factKind.name}:$cacheScopeId:$bucketId';
  }

  Future<List<AppResult<List<Row>>>> _loadBucketsInWaves({
    required List<String> bucketIds,
    required Future<AppResult<List<Row>>> Function(String bucketId) loadBucket,
  }) async {
    if (bucketIds.isEmpty) {
      return <AppResult<List<Row>>>[];
    }
    final waveSize = math.max(1, _bucketLoadConcurrency);
    final results = <AppResult<List<Row>>>[];
    for (var start = 0; start < bucketIds.length; start += waveSize) {
      final end = math.min(start + waveSize, bucketIds.length);
      final chunk = await Future.wait(
        List<Future<AppResult<List<Row>>>>.generate(
          end - start,
          (offset) => loadBucket(bucketIds[start + offset]),
        ),
      );
      results.addAll(chunk);
    }
    return results;
  }

  Future<Map<String, List<int>>> _readClosedBucketPayloads({
    required String userId,
    required String agentId,
    required Filter rangeFilter,
    required AgentQueryBucketPlan plan,
    required AgentQueryLoadPolicy cachePolicy,
  }) async {
    if (cachePolicy == AgentQueryLoadPolicy.forceRefresh) {
      return const <String, List<int>>{};
    }
    final storageKeys = <String>[];
    for (final bucketId in plan.allBucketIdsInRange) {
      if (plan.networkBucketIds.contains(bucketId)) {
        continue;
      }
      storageKeys.add(
        _strategy.storageKey(
          userId: userId,
          agentId: agentId,
          bucketId: bucketId,
          rangeFilter: rangeFilter,
        ),
      );
    }
    if (storageKeys.isEmpty) {
      return const <String, List<int>>{};
    }
    return _factsStore.readPayloadsForKeys(
      storageKeys: storageKeys,
      expectedSchemaVersion: _strategy.schemaVersion,
    );
  }

  bool get _canBatchNetworkBuckets {
    return _useExecuteBatchForBuckets &&
        _agentQueriesRepository != null &&
        _bucketBatchSupport != null;
  }

  Future<Map<String, AppResult<List<Row>>>> _loadNetworkBucketsViaExecuteBatch({
    required String userId,
    required String agentId,
    required Filter rangeFilter,
    required List<String> networkBucketIds,
    required AgentQueryBucketPlan plan,
    required AgentQueryLoadPolicy cachePolicy,
    required DateTime clock,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (networkBucketIds.isEmpty || !_canBatchNetworkBuckets) {
      return <String, AppResult<List<Row>>>{};
    }

    final batchSupport = _bucketBatchSupport!;
    final agentQueriesRepository = _agentQueriesRepository!;

    final validationError = batchSupport.validationError(rangeFilter);
    if (validationError != null) {
      final failure = AgentSqlRepositoryExecution.invalidFilters<List<Row>>(
        message: validationError,
        operation: batchSupport.operation,
        agentId: agentId.trim(),
      );
      return {
        for (final bucketId in networkBucketIds) bucketId: failure,
      };
    }

    final networkPolicy = cachePolicy == AgentQueryLoadPolicy.defaultLoad
        ? AgentQueryLoadPolicy.forceRefresh
        : cachePolicy;
    final effectiveBridgeTimeoutMs = batchSupport.resolveBridgeTimeoutMs(
      bridgeTimeoutMs,
    );
    final results = <String, AppResult<List<Row>>>{};

    for (
      var chunkStart = 0;
      chunkStart < networkBucketIds.length;
      chunkStart += kAgentSqlExecuteBatchMaxCommands
    ) {
      final chunkEnd = math.min(
        chunkStart + kAgentSqlExecuteBatchMaxCommands,
        networkBucketIds.length,
      );
      final chunkBucketIds = networkBucketIds.sublist(chunkStart, chunkEnd);
      final bucketIdsByExecutionIndex = <int, String>{};
      final commands = <AgentSqlExecuteBatchCommand>[];

      for (var i = 0; i < chunkBucketIds.length; i++) {
        final bucketId = chunkBucketIds[i];
        bucketIdsByExecutionIndex[i] = bucketId;
        final bucketFilter = _strategy.filterForBucket(
          rangeFilter: rangeFilter,
          bucketId: bucketId,
        );
        commands.add(
          batchSupport.commandForBucket(
            bucketFilter: bucketFilter,
            agentId: agentId,
            executionOrder: i,
          ),
        );
      }

      final batchRequest = AgentSqlExecuteBatchRequest(
        agentId: agentId,
        requestingUserId: userId,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        commands: commands,
        clientToken: clientToken,
        bridgeTimeoutMs: effectiveBridgeTimeoutMs,
        options: AgentSqlReadOnlyBatchOptions.dashboard(
          sqlTimeoutMs: effectiveBridgeTimeoutMs,
          maxRows: batchSupport.batchMaxRows,
        ),
        skipTransportCache: batchSupport.bypassTransportCache(networkPolicy),
      );

      final batchResult = await agentQueriesRepository.executeSqlBatch(
        batchRequest,
        cancelScope: cancelScope,
      );
      final execution = batchResult.getOrNull();
      if (execution == null) {
        final failure = batchResult.exceptionOrNull()!;
        for (final bucketId in chunkBucketIds) {
          results[bucketId] = Failure<List<Row>, AppFailure>(failure);
        }
        continue;
      }

      final byIndex = <int, AgentSqlBatchExecutionItem>{
        for (final item in execution.items) item.index: item,
      };

      for (var i = 0; i < chunkBucketIds.length; i++) {
        final bucketId = bucketIdsByExecutionIndex[i]!;
        final mapped = AgentSqlBatchItemRowsMapper.mapRowsForIndex<Row>(
          byIndex,
          i,
          batchSupport.mapRow,
          operation: batchSupport.operation,
        );
        if (mapped.failure != null) {
          results[bucketId] = Failure<List<Row>, AppFailure>(mapped.failure!);
          continue;
        }

        final rows = mapped.rows;
        final bucketResult = Success<List<Row>, AppFailure>(rows);
        results[bucketId] = bucketResult;

        if (_strategy.isBucketClosed(bucketId: bucketId, clock: clock) &&
            ConsolidationCatalog.mayPersist(
              factKind: _strategy.factKind,
              writer: _strategy.queryKey,
            )) {
          await _factsStore.writePayload(
            storageKey: _strategy.storageKey(
              userId: userId,
              agentId: agentId,
              bucketId: bucketId,
              rangeFilter: rangeFilter,
            ),
            payload: _strategy.encodePayload(rows),
            schemaVersion: _strategy.schemaVersion,
          );
        }
      }
    }

    return results;
  }

  Future<AppResult<List<Row>>> _loadBucket({
    required String userId,
    required String agentId,
    required Filter rangeFilter,
    required String bucketId,
    required AgentQueryBucketPlan plan,
    required AgentQueryLoadPolicy cachePolicy,
    required DateTime clock,
    List<int>? prefetchedPayload,
    AppResult<List<Row>>? prefetchedNetworkResult,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final needsNetwork = plan.networkBucketIds.contains(bucketId);
    final isClosed = _strategy.isBucketClosed(bucketId: bucketId, clock: clock);
    final storageKey = _strategy.storageKey(
      userId: userId,
      agentId: agentId,
      bucketId: bucketId,
      rangeFilter: rangeFilter,
    );

    if (!needsNetwork && cachePolicy != AgentQueryLoadPolicy.forceRefresh) {
      final cached =
          prefetchedPayload ??
          await _factsStore.readPayload(
            storageKey: storageKey,
            expectedSchemaVersion: _strategy.schemaVersion,
          );
      if (cached != null) {
        return Success<List<Row>, AppFailure>(_strategy.decodePayload(cached));
      }
    }

    if (prefetchedNetworkResult != null) {
      return prefetchedNetworkResult;
    }

    final bucketFilter = _strategy.filterForBucket(
      rangeFilter: rangeFilter,
      bucketId: bucketId,
    );
    final networkPolicy = cachePolicy == AgentQueryLoadPolicy.defaultLoad
        ? AgentQueryLoadPolicy.forceRefresh
        : cachePolicy;
    final result = await _delegateLoad(
      userId: userId,
      agentId: agentId,
      filter: bucketFilter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
      cachePolicy: networkPolicy,
    );

    final rows = result.getOrNull();
    if (rows == null) {
      return Failure<List<Row>, AppFailure>(result.exceptionOrNull()!);
    }

    if (isClosed &&
        ConsolidationCatalog.mayPersist(
          factKind: _strategy.factKind,
          writer: _strategy.queryKey,
        )) {
      await _factsStore.writePayload(
        storageKey: storageKey,
        payload: _strategy.encodePayload(rows),
        schemaVersion: _strategy.schemaVersion,
      );
    }
    return Success<List<Row>, AppFailure>(rows);
  }
}
