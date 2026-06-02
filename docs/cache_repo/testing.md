# Testing strategy

## Unit tests (required per phase)

| Area | Path suggestion | Focus |
| ---- | --------------- | ----- |
| Closure helpers | `test/features/agent_queries/domain/cache/` | Day/month closed vs open |
| Strategy plan | `test/.../strategies/resumo_total_diario_vendas_cache_strategy_test.dart` | Bucket lists, filter slice |
| Facts store | `test/.../facts/hive_agent_query_facts_store_test.dart` | Fake `AppCacheStore`, envelope |
| Base decorator | `test/.../caching/base_cached_agent_query_repository_test.dart` | Fake delegate + store; policies |
| Catalog | `test/.../consolidation_catalog_test.dart` | Writer enforcement |

Use `fake_async` or injected `clock` for day/month boundaries.

### Decorator scenarios

1. `defaultLoad` — all closed buckets hit store → delegate not called.
2. `defaultLoad` — partial miss → delegate called once per miss bucket.
3. `defaultLoad` — open bucket (today) → delegate called, store not written.
4. `forceRefresh` — store ignored, delegate called, closed buckets rewritten.
5. `networkOnly` — delegate only, no writes.
6. Plain `RepositoryImpl` — `cachePolicy` ignored.

## E2E ([`project_agent_sql.mdc`](../../.cursor/rules/project_agent_sql.mdc))

Every `*RepositoryImpl` that calls `executeSql` / `executeSqlBatch` needs `test/integration/e2e/*_repository_e2e_test.dart`.

For caching decorators:

- E2E targets the **registered port** (`getIt<ResumoTotalDiarioVendasRepository>()`), which may be the decorator.
- First run populates store; optional second run in same test can assert success (do not assert zero network without controlled env).

Follow existing patterns:

- `missingE2eRepositoryKeys()` skip
- `e2eSetupDependencies` / tearDown
- `isAcceptableE2eAgentSqlRepositoryFailure`
- `tags: ['e2e']`

## Overview tests

After Phase 4, add or extend repository tests for `OverviewRepositoryImpl` with fake across-agents ports (unit), not widget tests.

## What not to add

- Widget tests (`testWidgets`) unless explicitly requested.
- Tests that only assert encode/decode roundtrip without behavior value.

## Analyzer

Run `dart analyze` on touched packages after each phase.
