# Implementation phases

Separate PRs per phase ([`general_rules.mdc`](../../.cursor/rules/general_rules.mdc): do not mix large docs + feature in one commit).

## Phase 0 — Documentation (this folder)

Deliverable: `docs/cache_repo/*.md` (English).

Optional: one-line link from `docs/analysis/README.md` under caching evolution.

## Phase 1 — Foundation

**Goal:** Ports, facts store, base decorator, catalog skeleton, prefix, DI for store.

| Add | Purpose |
| --- | ------- |
| `domain/entities/agent_query_load_policy.dart` | Policy enum |
| `domain/entities/agent_query_cache_invalidate_scope.dart` | Invalidate scopes |
| `domain/cache/agent_query_fact_kind.dart` | Fact kind enum |
| `domain/cache/consolidation_storage_mode.dart` | persist vs derived |
| `domain/cache/agent_query_facts_store.dart` | Store port |
| `domain/cache/agent_query_cache_strategy.dart` | Strategy port |
| `domain/cache/agent_query_bucket_plan.dart` | Plan DTO |
| `domain/cache/agent_query_cache_control.dart` | Invalidate port |
| `domain/cache/consolidation_catalog.dart` | Registry |
| `data/facts/hive_agent_query_facts_store.dart` | Hive implementation |
| `data/repositories/caching/base_cached_agent_query_repository.dart` | Shared decorator |
| `AppKvCacheKeyPrefixes.agentQueryFacts` | Key prefix |

**Tests:** `test/features/agent_queries/data/facts/`, `test/features/agent_queries/data/repositories/caching/`.

## Phase 2 — Pilot: daily sales

| Add / change | |
| ------------ | -- |
| `ResumoTotalDiarioVendasCacheStrategy` | Day buckets |
| `CachingResumoTotalDiarioVendasRepositoryImpl` | Decorator |
| `ResumoTotalDiarioVendasRepository.load` | `cachePolicy` param |
| `LoadResumoTotalDiarioVendasUseCase` | Pass policy |
| `AgentQueryListReportAcrossAgentsCoordinator` | Optional `cachePolicy` on callback |
| DI | Wrap daily repo |
| E2E | `resumo_total_diario_vendas_repository_e2e_test.dart` |

**Verify:** Second load same closed range does not increase agent SQL count (log / mock).

## Phase 3 — Pilot: monthly parcels

Same pattern for `ResumoParcelasMensal` + across-agents.

## Phase 4 — Overview + transport (done)

1. `AgentSqlExecuteRequest.skipTransportCache` + honor in `CachingAgentQueriesRepository`.
2. `OverviewRepositoryImpl`: map `OverviewLoadPolicy` → `AgentQueryLoadPolicy` when calling migrated loaders.
3. `OverviewBatchLoader`: daily/monthly via cached use cases; section SQL batch excludes those queries when use cases are wired.
4. `OverviewLocalDataSource` removed — facts store + live batch are the only overview persistence paths.

**Success:** Home filter change over closed days uses store; pull-to-refresh uses `forceRefresh` on facts and transport cache.

## Phase 5 — In-app prefetch (done)

`application/sync/agent_query_facts_prefetch_coordinator.dart`:

- Runs while app process is alive (no WorkManager).
- `prefetchForPlannedTargets` with concurrency 1–2; respects shared `RetryAfterGate` with overview.
- Trigger: after successful final overview batch load (`OverviewRepositoryImpl`).
- Gated by `AppEnvironment.agentQueryFactsPrefetchEnabled`.

## Post-MVP improvements (rollout)

| Item | Status |
| ---- | ------ |
| Prefix delete + invalidate scopes + schema version miss | Done |
| Metrics (`factsHits` / `factsMisses` / `factsWrites`) in socket appendix | Done |
| Batch `readPayloadsForKeys` in decorator | Done |
| `lucratividadeMensal` catalog entry removed until `AgentQueryKey` exists | Done |

## Rollback

- DI: register plain `*RepositoryImpl` again to disable business cache per report.
- Clear Hive / `AppCacheStore` for corrupted payloads.

## Non-goals

See [README.md](README.md); OS background, server MVs, replacing 3s SQL cache.
