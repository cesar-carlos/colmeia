import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
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
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
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
abstract base class BaseCachedAgentQueryRepository<Filter, Row>
    implements AgentQueryCacheControl {
  BaseCachedAgentQueryRepository({
    required AgentQuerySingleLoad<Filter, Row> delegateLoad,
    required AgentQueryFactsStore factsStore,
    required AgentQueryCacheStrategy<Filter, Row> strategy,
    DateTime Function()? clock,
  }) : _delegateLoad = delegateLoad,
       _factsStore = factsStore,
       _strategy = strategy,
       _clock = clock ?? DateTime.now;

  final AgentQuerySingleLoad<Filter, Row> _delegateLoad;
  final AgentQueryFactsStore _factsStore;
  final AgentQueryCacheStrategy<Filter, Row> _strategy;
  final DateTime Function() _clock;

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

    final bucketResults = await Future.wait(
      plan.allBucketIdsInRange.map(
        (bucketId) => _loadBucket(
          userId: userId,
          agentId: agentId,
          rangeFilter: filter,
          bucketId: bucketId,
          plan: plan,
          cachePolicy: cachePolicy,
          clock: clock,
          prefetchedPayload: prefetchedPayloads[
            _strategy.storageKey(
              userId: userId,
              agentId: agentId,
              bucketId: bucketId,
              rangeFilter: filter,
            )
          ],
          clientToken: clientToken,
          bridgeTimeoutMs: bridgeTimeoutMs,
          hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
          hubConnectedFromApprovedCatalogRow:
              hubConnectedFromApprovedCatalogRow,
          cancelScope: cancelScope,
        ),
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
        await _factsStore.removeMatching(AgentQueryFactsKeyPrefix.forUser(userId));
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

  Future<AppResult<List<Row>>> _loadBucket({
    required String userId,
    required String agentId,
    required Filter rangeFilter,
    required String bucketId,
    required AgentQueryBucketPlan plan,
    required AgentQueryLoadPolicy cachePolicy,
    required DateTime clock,
    List<int>? prefetchedPayload,
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
