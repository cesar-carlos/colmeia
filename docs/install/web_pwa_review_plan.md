# Web/PWA implementation review and delivery plan

Review date: 2026-11-08. This is an implementation backlog, not a declaration
of production readiness. Hosting and server deployment remain separate actions.
Use the [Web guide](web_guide.md) for build, hosting and acceptance commands and
the [integration index](../plug_server_docs_index_for_colmeia.md) for external
integration contracts.

## Scope boundary

`plug_server` is an external communication bridge to the data sources. Its
implementation, database, deployment and operational backlog are outside the
Colmeia scope. Do not add report-result persistence to that bridge as part of
this plan. Reading its contracts and testing the Colmeia integration remain
within scope.

The current offline authorization and Push adapters call hub endpoints. They
remain external dependencies, not authorization to implement backend features
in `plug_server`. If those contracts are unavailable, record the limitation and
decide the backend owner before changing the integration; do not manufacture
an offline permission grant locally.

Current report caches are client-side. A shared server cache would require a
separately scoped Colmeia backend; static Web hosting alone cannot provide it.
See [cache location and server feasibility](../cache_repo/architecture.md#cache-location-and-server-feasibility).

## Existing structure to retain

| Responsibility | Current owner |
| --- | --- |
| Static shell, version integrity and Push events | `web/pwa-worker.js`, `web/pwa-client.js`, `tool/package_pwa.py` |
| Browser capabilities and inactive native alternatives | `lib/core/pwa/` |
| Offline authorization, package and subscription contracts | `lib/features/pwa/domain/` |
| Download orchestration, cancellation and publication | `lib/features/pwa/application/pwa_package_service.dart` |
| Existing query reuse, offline projections and persistence | `lib/features/pwa/data/` |
| Installation, package management and status UI | `lib/features/pwa/presentation/` |
| IndexedDB on Web and Hive on native platforms | `lib/core/cache/` through `AppCacheStore` |
| Shared reports and responsive layout primitives | `lib/shared/widgets/reports/`, `lib/core/layout/` |
| Registration and composition | `lib/core/di/injector_pwa.dart` |

Do not create a second Web feature tree, database or report renderer. Keep
Android and Windows adapters compatible. Product limits remain owned by the
project rules: 30-day selected packages, server-issued permission for at most
24 hours, and no new queue of remote business writes.

## Corrections applied in this review

- Explicit `index.html` navigation now uses the offline shell, including under
  a hosting subdirectory. Other document-like assets keep their error semantics.
- Missing assets from a retained old tab no longer fall through to a newer
  deployment for intercepted static requests. Available old assets remain usable.
- IndexedDB prefix deletion now bounds the key request to the prefix range,
  preserving predicate filtering and Unicode boundary behavior. This reduces
  unrelated key materialization; no latency benchmark has been claimed.
- The PWA status host keeps the application subtree under a stable keyed child
  when the connectivity/update banner appears or disappears.
- The offline page uses shared responsive spacing and a width-constrained
  dataset selector with ellipsis for long labels.
- Worker regression tests run through the existing browser-test CI command.

## Ordered implementation backlog

### Distributed-agent refresh scheduling

Each `agentId` identifies a distributed server/database; a client can access
several independent agents. Schedule reads by authorization scope, agent,
report/version, period and normalized filters. Store the refresh policy,
last successful collection, next eligible attempt, failure category and retry
count separately from the cached result. Relative periods such as "last 30 days"
must be resolved again when a job runs; fixed periods keep their original bounds.

Existing implementation: `PwaStatusHost` checks selected packages every 30
seconds and refreshes snapshots older than 15 minutes. This is package-level,
not a persisted per-report scheduler. Its outer error handler means one failed
agent can stop the remaining agents in that pass; Push reconciliation can also
prevent the package loop from running. Address this isolation before expanding
the scheduling feature.

Proposed application-layer scheduler behavior (not implemented yet):

- Reuse `AgentPresenceStream`, catalog reconciliation and the existing REST
  presence fallback rather than adding a health request for every report.
- Distinguish browser/network outage, unavailable hub, disconnected agent and
  query/database failure. Hub connection does not prove database readiness;
  a single SQL timeout does not prove the server is offline.
- Defer only the affected agent on an agent-specific outage. Hub/network
  outages defer all remote work. Authorization denial stops affected work
  and invokes existing revocation handling instead of retrying indefinitely.
- Preserve the last complete generation, subject to permission expiry. Show
  collection time and stale/deferred status; failures never replace data with
  empty results. Consolidated reports identify unavailable agents and different
  collection times instead of presenting a partial aggregate as complete.
- Reconcile availability on reconnect, then resume due jobs after permission
  validation. Use bounded backoff with jitter for transient failures, one
  in-flight refresh per key, existing concurrency gates and cross-tab locks.
  Missed timer ticks coalesce into one refresh rather than replaying every tick.
- Persist refresh intent for reads only; never persist access tokens with jobs
  or extend the existing queues to new remote business writes. Logout cancels
  work and removes user-owned schedules.
- Test that offline agent A cannot block online agent B, recovery does not
  duplicate downloads, stale events cannot revive revoked jobs, and restart,
  cancellation and publication failures preserve valid previous generations.

Client scheduling runs while the application is executable. A hidden or closed
PWA cannot guarantee a fixed execution time; browser periodic synchronization
is opportunistic ([Chrome documentation](https://developer.chrome.com/docs/capabilities/periodic-background-sync)).
Reliable unattended scheduling requires a separately scoped Colmeia backend
worker and server cache. That worker would query the distributed agents through
the existing `plug_server` integration, without implementing scheduling there.

| Priority | Work | Completion evidence |
| --- | --- | --- |
| P0 | Validate Colmeia adapters against available external authorization/Push contracts; reconcile REST/Socket SQL cancellation identities on the client | Record external capability gaps without changing `plug_server`; live acceptance requires available contracts and remote cancellation acknowledgments |
| P0 | Strengthen private-data deletion: separate best-effort disposable cache operations from confirmed offline deletion, and reconcile failed cleanup after restart | Injected quota/transaction failures cannot report successful removal; two-tab logout cannot republish stale private data |
| P1 | Review package selection plus generation publication as one consistency boundary; current selection and package writes are separate operations | Interrupted first download, retry, cancellation, logout and revocation leave explicit recoverable state and preserve valid prior generations |
| P1 | Review connectivity policy for an unreachable hub while `navigator.onLine` stays true; distinguish agent failure and authorization rejection | Transient hub failure permits only previously authorized local reads; no remote call uses an expired token |
| P1 | Reduce repeated whole-package decoding in status refresh; introduce metadata access only if workload measurements justify it | Same-workload measurements for many stores, with unchanged expiry/revocation behavior and no stale in-memory authorization |
| P1 | Review async ownership in the offline page and move loading/export orchestration into a presentation controller in a separate refactoring step | Out-of-order loads, account changes, failed catalog refresh and disposal cannot publish obsolete view state |
| P1 | Validate real IndexedDB upgrade, eviction, quota and cross-tab contention beyond the memory backend | Browser tests exercise actual transactions and verify preserved previous generations and explicit storage failure |
| P1 | Validate responsive package actions, report grids, keyboard focus and large text; extract feature-local sections before considering shared promotion | Chrome Android and Chrome/Edge Windows checks at narrow, tablet and desktop widths; no overflow or lost route/form state after banner transitions |
| P1 | Complete installed-PWA acceptance and real Push delivery | Reopen installed app offline, approve update with multiple tabs, receive generic approval/revocation notification with app closed, authenticate on click |

Follow this order in small steps: establish regression coverage, fix behavior,
then extract components/controllers without changing behavior. Reuse current
queries and transport concurrency controls. Follow the repository restriction
on widget tests; use unit tests and browser/runtime checks unless explicitly
requested otherwise.

## Validation matrix

- Dart: cache and PWA tests, then analyzer; expand to affected authentication,
  shared component and repository suites when their behavior changes.
- Worker: `node --test tool/pwa-tests/worker.test.mjs` covers index navigation,
  old-version asset isolation and API/missing-asset behavior at root/subpath.
- Production browser: build with `--no-web-resources-cdn`, package, then run
  `npm test` in `tool/pwa-tests`. Mocked worker tests alone are insufficient.
- Native: rebuild Android and Windows when shared contracts, dependencies or
  platform adapters change. Record release/debug modes explicitly.
- External acceptance: record actual endpoint/browser/provider results;
  unavailable infrastructure and skipped checks are not successful acceptance.

The existing historical results and external limitations remain documented in
the Web guide. New results must be reported separately from those older runs.

### Evidence from this review

- `flutter test --no-pub test/core/cache test/features/pwa`: 30 passed.
- Focused `flutter analyze --no-pub` on the four changed Dart files: no issues.
  The broader analysis and MCP attempt did not complete and were stopped;
  this is not a full-project analyzer result. No debug app/DTD was available
  for hot reload or widget inspection.
- PWA packaging Python tests: two passed.
- `npm test` in `tool/pwa-tests`: eight passed, including two real Chromium
  production-build scenarios at root/subpath and six isolated worker tests.
- Web JavaScript release build and packaging succeeded: release
  `21b5284f14cf9d609e29`, 51 files. The optional Wasm dry run still reports the
  existing Socket.IO dependency incompatibility; Wasm is not validated.
- Browser scenarios cover offline direct `index.html`, route loading, update
  interruption and cross-tab update/work coordination. They do not establish
  authenticated dashboard visual correctness, mobile installation or Push delivery.
- Android/Windows builds and live server acceptance were not rerun in this review.

### Local scheduler follow-up (2026-11-08)

The app-local distributed refresh scheduler is now implemented without changing
`plug_server`. Its architecture, states and authorization boundaries are documented
in [cache architecture](../cache_repo/architecture.md#local-scheduled-refresh), and
the current build/test evidence is in [cache testing](../cache_repo/testing.md#scheduled-refresh-validation-2026-11-08).
This later validation includes full-project analysis, native builds, hot reload,
live repository E2E and a real-browser multi-tab scheduler harness. It supersedes
the earlier review's tooling/build limitations, not its unproven external Push and
deployed offline-authorization acceptance.
