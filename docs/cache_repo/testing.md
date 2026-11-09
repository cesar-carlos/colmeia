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

- `missingE2eRepositoryKeys()` credential guard
- `e2eSetupDependencies` / tearDown
- `isAcceptableE2eAgentSqlRepositoryFailure`
- `tags: ['e2e']`

A credential guard may return early rather than register a framework skip.
Likewise, resilience tests may accept selected transport failures. Neither
outcome proves a successful live query. Record credentials availability and
actual results when reporting acceptance. Strict package acceptance commands
and known external gaps live in the [Web guide](../install/web_guide.md#automated-validation-and-remaining-acceptance).

## Overview tests

When changing overview integration, add or extend repository tests for `OverviewRepositoryImpl` with fake across-agents ports (unit), not widget tests.

## What not to add

- Widget tests (`testWidgets`) unless explicitly requested.
- Tests that only assert encode/decode roundtrip without behavior value.

## Analyzer

Run `dart analyze` on touched packages after each phase.

## Scheduled refresh validation (2026-11-08)

- Static analysis: no issues in `dart analyze`.
- Affected-area regression: 1,614 tests passed across agent queries, overview,
  authentication, PWA and cache storage. No new widget tests were introduced.
- Focused scheduler suite: 69 tests passed, including all 20 catalog adapters,
  isolated slow/offline agents, retry timing, logout, quota failures, two competing
  coordinators, snapshot reuse/bypass and independent package cancellation.
- Existing live repository E2E: 30 tests passed across the ten report repositories. These
  retain the project's accepted transient/policy failure contract; a pass alone
  does not prove every production agent returned a complete dataset.
- Chrome integration: the real IndexedDB store and Web Locks passed two-tab
  deduplication, offline-agent isolation, recovery, persisted reload and overdue
  refresh. The real settings page was inspected at 390 and 1440 px. Query results
  in this harness are deterministic, not a live distributed-server acceptance run.
- Production PWA: eight worker/browser tests passed at root and subdirectory paths,
  including offline routes and interrupted updates. The packaged release contains
  51 static files; authenticated query results remain outside Cache Storage.
- Web release, Android debug and Windows release builds succeeded. The Web debug
  harness also completed hot reload without reported runtime errors.

Primary regression files are `cache_refresh_coordinator_test.dart`,
`scheduled_report_adapters_test.dart`, `scheduled_query_snapshots_test.dart` and
`offline_package_test.dart`. Browser commands and artifacts are documented in the
[Web guide](../install/web_guide.md#operational-signals). The CI Web job builds the
scheduler harness separately; only `build/web` is uploaded as the production app.

This validation does not claim execution while the app is closed, deployment of
server-side offline authorization, or real-provider Push delivery. Those boundaries
remain unchanged by the scheduler.

### Follow-up: storage, diagnostics and shared capacity

- Affected-area regression: 1,624 tests passed. The expanded focused suite passed
  77 tests, covering metadata-only reads, version-1 migration, failed migration and
  failed pointer publication, quarantine, canonical defaults and global slot limits.
- A deterministic I/O check stores more than 100 KB of results and verifies that
  listing reads less than 2 KB of metadata and zero snapshot keys. This is a reduction
  in data read/decoded, not a wall-clock benchmark across hardware configurations.
- The browser harness passed with both global capacity slots occupied by separate
  tabs: no query started until a slot was released. Persistence, deduplication,
  recovery and the 390/1440 px layouts also passed.
- `cache_refresh_scheduler_e2e_test.dart` passed against the configured live hub and
  agent. It exercises the production report adapter, actual catalog/permission checks
  and SQL, successful publication, injected client-side presence loss, preservation
  of the previous generation, recovery and persisted reread. It does not stop a
  production server or claim a multi-server outage test.
- Runtime storage failures remain visible even when the failure state itself cannot
  be persisted. The previous snapshot is retained; tests assert both behaviors.
- Full-project analysis reported no issues. Web release, Android debug and Windows
  release builds succeeded for the updated schema and locking implementation.

The record namespace remains `refresh/v1`, with record format **2** and separate
immutable snapshot generations. Do not treat an unsupported format as an empty
report or overwrite it automatically. The UI preserves and isolates incompatible
records, and offers explicit removal/recreation.

## Platform storage regressions

Native/unit regressions cover two independent IndexedDB adapter connections,
legacy Hive Web data layout, cache invalidation, blocked storage, session errors,
and catalog migration. The Web-only entry point
`test/integration/web_storage_smoke.dart` exposes `colmeiaStorageSmoke` for browser
automation. Build it separately (never deploy this test entry point):

```bash
flutter build web --release --target test/integration/web_storage_smoke.dart --output build/storage_web_smoke
```

Use isolated browser profiles and synthetic values to verify reload persistence,
cross-tab cache writes/deletions/clearing, encrypted session persistence, and
storage quota/security failures. Production builds continue to use `lib/main.dart`.

Sources: [Hive CE](https://pub.dev/packages/hive_ce),
[idb_shim](https://pub.dev/packages/idb_shim),
[shared_preferences cache behavior](https://pub.dev/packages/shared_preferences),
[Flutter secure storage Web requirements](https://pub.dev/packages/flutter_secure_storage),
and [IndexedDB transactions](https://developer.mozilla.org/en-US/docs/Web/API/IDBTransaction).
