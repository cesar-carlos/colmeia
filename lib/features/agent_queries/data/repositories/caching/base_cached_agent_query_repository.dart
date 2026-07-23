import 'dart:math' as math;

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
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
import 'package:colmeia/features/agent_queries/domain/cache/calendar_bucket_closure.dart';
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

    final needNetworkBucketIds = _resolveNeedNetworkBucketIds(
      userId: userId,
      agentId: agentId,
      rangeFilter: filter,
      plan: plan,
      prefetchedPayloads: prefetchedPayloads,
    );

    final Map<String, AppResult<List<Row>>> prefetchedNetworkResults;
    if (needNetworkBucketIds.isEmpty) {
      prefetchedNetworkResults = <String, AppResult<List<Row>>>{};
    } else if (_strategy.supportsRangeCoalesce) {
      prefetchedNetworkResults =
          await _loadNetworkBucketsPreferringContiguousCoalesce(
            userId: userId,
            agentId: agentId,
            rangeFilter: filter,
            needNetworkBucketIds: needNetworkBucketIds,
            plan: plan,
            cachePolicy: cachePolicy,
            clock: clock,
            clientToken: clientToken,
            bridgeTimeoutMs: bridgeTimeoutMs,
            hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                hubConnectedFromApprovedCatalogRow,
            cancelScope: cancelScope,
          );
    } else {
      prefetchedNetworkResults = await _loadNetworkBucketsViaExecuteBatch(
        userId: userId,
        agentId: agentId,
        rangeFilter: filter,
        networkBucketIds: needNetworkBucketIds,
        plan: plan,
        cachePolicy: cachePolicy,
        clock: clock,
        clientToken: clientToken,
        bridgeTimeoutMs: bridgeTimeoutMs,
        hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
        hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
        cancelScope: cancelScope,
      );
    }

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
        forceNetwork: needNetworkBucketIds.contains(bucketId),
        prefetchedPayload:
            prefetchedPayloads[_strategy.storageKey(
              userId: userId,
              agentId: agentId,
              bucketId: bucketId,
              rangeFilter: filter,
            )],
        prefetchedNetworkResult: prefetchedNetworkResults[bucketId],
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

  List<String> _resolveNeedNetworkBucketIds({
    required String userId,
    required String agentId,
    required Filter rangeFilter,
    required AgentQueryBucketPlan plan,
    required Map<String, List<int>> prefetchedPayloads,
  }) {
    final needNetwork = <String>[];
    for (final bucketId in plan.allBucketIdsInRange) {
      if (plan.networkBucketIds.contains(bucketId)) {
        needNetwork.add(bucketId);
        continue;
      }
      final storageKey = _strategy.storageKey(
        userId: userId,
        agentId: agentId,
        bucketId: bucketId,
        rangeFilter: rangeFilter,
      );
      if (!prefetchedPayloads.containsKey(storageKey)) {
        needNetwork.add(bucketId);
      }
    }
    return needNetwork;
  }

  /// Coalesce contiguous day-bucket runs; load isolated misses via batch/unary
  /// so sparse holes do not re-download days already in cache.
  Future<Map<String, AppResult<List<Row>>>>
  _loadNetworkBucketsPreferringContiguousCoalesce({
    required String userId,
    required String agentId,
    required Filter rangeFilter,
    required List<String> needNetworkBucketIds,
    required AgentQueryBucketPlan plan,
    required AgentQueryLoadPolicy cachePolicy,
    required DateTime clock,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final results = <String, AppResult<List<Row>>>{};
    final singles = <String>[];
    for (final run in _contiguousDayRuns(needNetworkBucketIds)) {
      if (run.length >= 2) {
        results.addAll(
          await _loadNetworkBucketsViaRangeCoalesce(
            userId: userId,
            agentId: agentId,
            rangeFilter: rangeFilter,
            needNetworkBucketIds: run,
            cachePolicy: cachePolicy,
            clock: clock,
            clientToken: clientToken,
            bridgeTimeoutMs: bridgeTimeoutMs,
            hubPresenceOnlineAgentIdsSnapshot:
                hubPresenceOnlineAgentIdsSnapshot,
            hubConnectedFromApprovedCatalogRow:
                hubConnectedFromApprovedCatalogRow,
            cancelScope: cancelScope,
          ),
        );
      } else {
        singles.addAll(run);
      }
    }
    if (singles.isNotEmpty) {
      results.addAll(
        await _loadNetworkBucketsViaExecuteBatch(
          userId: userId,
          agentId: agentId,
          rangeFilter: rangeFilter,
          networkBucketIds: singles,
          plan: plan,
          cachePolicy: cachePolicy,
          clock: clock,
          clientToken: clientToken,
          bridgeTimeoutMs: bridgeTimeoutMs,
          hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
          hubConnectedFromApprovedCatalogRow:
              hubConnectedFromApprovedCatalogRow,
          cancelScope: cancelScope,
        ),
      );
    }
    return results;
  }

  /// Prefer per-bucket batch when misses are sparse inside a wide span, so a
  /// range coalesce does not re-download many days already in cache.
  List<List<String>> _contiguousDayRuns(List<String> needNetworkBucketIds) {
    if (needNetworkBucketIds.isEmpty) {
      return const <List<String>>[];
    }
    final sorted = List<String>.from(needNetworkBucketIds)..sort();
    final runs = <List<String>>[];
    var current = <String>[sorted.first];
    var previousDay = CalendarBucketClosure.parseDayBucketId(sorted.first);
    for (var i = 1; i < sorted.length; i++) {
      final bucketId = sorted[i];
      final day = CalendarBucketClosure.parseDayBucketId(bucketId);
      final isContiguous =
          previousDay != null &&
          day != null &&
          day.difference(previousDay).inDays == 1;
      if (isContiguous) {
        current.add(bucketId);
      } else {
        runs.add(current);
        current = <String>[bucketId];
      }
      previousDay = day;
    }
    runs.add(current);
    return runs;
  }

  List<Row>? _tryDecodePayload(List<int> bytes, {required String storageKey}) {
    try {
      return _strategy.decodePayload(bytes);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Agent query facts row decode failed; treating as miss',
        context: <String, Object?>{
          'operation': 'decodePayload',
          'queryKey': _strategy.queryKey.name,
          'storageKeyHash': storageKey.hashCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<Map<String, AppResult<List<Row>>>>
  _loadNetworkBucketsViaRangeCoalesce({
    required String userId,
    required String agentId,
    required Filter rangeFilter,
    required List<String> needNetworkBucketIds,
    required AgentQueryLoadPolicy cachePolicy,
    required DateTime clock,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final networkPolicy = cachePolicy == AgentQueryLoadPolicy.defaultLoad
        ? AgentQueryLoadPolicy.forceRefresh
        : cachePolicy;
    final coalesceFilter = _strategy.networkCoalesceFilter(
      rangeFilter: rangeFilter,
      needNetworkBucketIds: needNetworkBucketIds,
    );
    final result = await _delegateLoad(
      userId: userId,
      agentId: agentId,
      filter: coalesceFilter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
      cachePolicy: networkPolicy,
    );

    final rows = result.getOrNull();
    if (rows == null) {
      final failure = result.exceptionOrNull()!;
      return {
        for (final bucketId in needNetworkBucketIds)
          bucketId: Failure<List<Row>, AppFailure>(failure),
      };
    }

    final results = <String, AppResult<List<Row>>>{};
    final writes = <Future<void>>[];
    for (final bucketId in needNetworkBucketIds) {
      final bucketRows = _strategy.selectRowsForBucket(
        rows: rows,
        bucketId: bucketId,
        rangeFilter: rangeFilter,
      );
      results[bucketId] = Success<List<Row>, AppFailure>(bucketRows);

      if (bucketRows.isEmpty) {
        // Match overview: do not persist empty closed buckets (flaky empty
        // success must not poison the facts store).
        continue;
      }

      if (_strategy.isBucketClosed(bucketId: bucketId, clock: clock) &&
          ConsolidationCatalog.mayPersist(
            factKind: _strategy.factKind,
            writer: _strategy.queryKey,
          )) {
        writes.add(
          _factsStore.writePayload(
            storageKey: _strategy.storageKey(
              userId: userId,
              agentId: agentId,
              bucketId: bucketId,
              rangeFilter: rangeFilter,
            ),
            payload: _strategy.encodePayload(bucketRows),
            schemaVersion: _strategy.schemaVersion,
          ),
        );
      }
    }
    if (writes.isNotEmpty) {
      await Future.wait(writes);
    }
    return results;
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

      final writes = <Future<void>>[];
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

        if (rows.isEmpty) {
          continue;
        }

        if (_strategy.isBucketClosed(bucketId: bucketId, clock: clock) &&
            ConsolidationCatalog.mayPersist(
              factKind: _strategy.factKind,
              writer: _strategy.queryKey,
            )) {
          writes.add(
            _factsStore.writePayload(
              storageKey: _strategy.storageKey(
                userId: userId,
                agentId: agentId,
                bucketId: bucketId,
                rangeFilter: rangeFilter,
              ),
              payload: _strategy.encodePayload(rows),
              schemaVersion: _strategy.schemaVersion,
            ),
          );
        }
      }
      if (writes.isNotEmpty) {
        await Future.wait(writes);
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
    bool forceNetwork = false,
    List<int>? prefetchedPayload,
    AppResult<List<Row>>? prefetchedNetworkResult,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    final needsNetwork =
        forceNetwork || plan.networkBucketIds.contains(bucketId);
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
        final decoded = _tryDecodePayload(cached, storageKey: storageKey);
        if (decoded != null) {
          return Success<List<Row>, AppFailure>(decoded);
        }
        await _factsStore.removeKey(storageKey);
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

    if (rows.isNotEmpty &&
        isClosed &&
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
