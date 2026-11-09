# Cache contracts

The source interfaces below are authoritative. This guide describes their
behavior instead of duplicating signatures that can drift from the code.

## Read policies

[`AgentQueryLoadPolicy`](../../lib/features/agent_queries/domain/entities/agent_query_load_policy.dart)
controls ordinary repository fact caching:

| Policy | Behavior |
| --- | --- |
| `defaultLoad` | Read closed facts; fetch missing and open buckets remotely |
| `forceRefresh` | Bypass facts in scope, fetch remotely and rewrite closed buckets |
| `networkOnly` | Delegate without persisting facts |

Overview maps its `defaultLoad` and `forceRefresh` policies to these values.
Repositories without a caching decorator ignore the cache policy. None of these
values means local-only: PWA reads use the separate package contracts below.
`AgentSqlExecuteRequest.skipTransportCache` bypasses short-lived SQL results
when a fact repository requests fresh data.

## Fact persistence and invalidation

- [`AgentQueryFactsStore`](../../lib/features/agent_queries/domain/cache/agent_query_facts_store.dart)
  reads individual or multiple payloads, accepts an expected schema version,
  writes opaque versioned bytes and removes keys by key, prefix or user/fact kind.
  Missing or stale entries are omitted from batch results.
- [`AgentQueryCacheControl`](../../lib/features/agent_queries/domain/cache/agent_query_cache_control.dart)
  exposes invalidation for caching decorators.
- [`AgentQueryCacheInvalidateScope`](../../lib/features/agent_queries/domain/entities/agent_query_cache_invalidate_scope.dart)
  supports user, agent, fact kind and bucket scopes.

Canonical key shape:

```text
{agentQueryFactsPrefix}{userId}:{agentId}:{factKind}:{cacheScopeId}:{bucketId}
```

The bucket invalidation scope must use the same `cacheScopeId` as the write.
Filter dimensions belong in this segment, separately from dates. Strategies use
[`AgentQueryCacheScope`](../../lib/features/agent_queries/domain/cache/agent_query_cache_scope.dart)
for stable scope construction. Old keys without this segment are not read and
remain until matching eviction or session cleanup.

## Strategies and bucket plans

[`AgentQueryCacheStrategy`](../../lib/features/agent_queries/domain/cache/agent_query_cache_strategy.dart)
owns bucket planning, closure, filter slicing, scope keys and row serialization.
It declares `supportsRangeCoalesce`, `networkCoalesceFilter` and
`selectRowsForBucket` so the decorator can reduce round trips without changing
aggregate semantics. Do not coalesce or split a period aggregate unless the
strategy supports it.

[`AgentQueryBucketPlan`](../../lib/features/agent_queries/domain/cache/agent_query_bucket_plan.dart)
contains `allBucketIdsInRange`, `closedBucketIds`, `openBucketIds` and
`networkBucketIds`. It is a plan, not a report of actual cache hits.

[`ConsolidationCatalog`](../../lib/features/agent_queries/domain/cache/consolidation_catalog.dart)
controls canonical writers and `persistClosedBuckets` versus `derivedOnly`.
See [consolidation rules](consolidation_rules.md) for the current catalog and
[architecture](architecture.md#in-flight-invalidation) for cancellation fences.

## Offline package contracts

- [`OfflinePackageRepository` and `OfflineAuthorizationGateway`](../../lib/features/pwa/domain/offline_package_repository.dart)
  separate package persistence from online permission issuance.
- [`OfflinePackage`](../../lib/features/pwa/domain/offline_package.dart) carries
  prepared datasets and their period/collection metadata.
- [`OfflineAuthorization`](../../lib/features/pwa/domain/offline_authorization.dart)
  limits access by user, agent and absolute expiry.
- [`OfflineOverviewRepository`](../../lib/features/pwa/data/offline_overview_repository.dart)
  adapts a matching prepared snapshot to overview reads.

These snapshots do not change historical fact consolidation. Missing data or an
unsupported period requires connection; it is not an empty result. See the
[Web guide](../install/web_guide.md#offline-packages) for supported operations,
publication, expiry, reconnection and acceptance limitations.
