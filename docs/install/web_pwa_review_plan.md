# Web/PWA implementation review and delivery plan

Initial review: 2026-11-08; local-source documentation review: 2026-11-17. This is a status and acceptance backlog, not a declaration
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

### Distributed-agent refresh scheduling — implemented locally

The scheduler is implemented in `agent_queries`, with session integration in
`lib/app/cache_refresh_lifecycle.dart`. `CacheRefreshCoordinator` owns execution;
`PwaStatusHost` no longer owns periodic package refresh. Push reconciliation runs
independently from cache scheduling.

Schedules are isolated by authorized user, agent, report, period and normalized
filters. New schedules and selected-package enrollment default to two hours;
existing configured intervals remain unchanged. Offline agents defer their own
work while eligible agents can continue. Execution requires an executable app;
this is not an unattended server scheduler or a guarantee of background execution
with the PWA closed. No `plug_server` changes are part of this implementation.

Use [cache architecture](../cache_repo/architecture.md#local-scheduled-refresh)
for contracts, concurrency, retries and authorization, and
[cache testing](../cache_repo/testing.md#scheduled-refresh-validation-2026-11-08)
for dated scheduler evidence. These supersede the initial proposal to move
periodic work out of `PwaStatusHost`.

### Remaining platform review

The following items are acceptance/review work, not evidence that a feature is
absent. Revalidate each item against the current implementation before changing it.

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

### Shared component responsiveness review (2026-11-17)

The shared report toolbar now uses its available content width after padding
to choose the compact layout. Actions and trailing controls receive bounded
widths inside rows, allowing action groups to wrap; long grouping/selection
labels can ellipsize without pushing their remove control outside the toolbar.
`AppDialogSurface` scrolls vertically when the available height cannot contain
its header, content and actions, including short landscape windows and enlarged
text. Existing theme colors, typography, spacing and dialog width are retained.

Use logical available width rather than device identity when checking these
components. `AppBreakpoints` currently defines mobile below 600, tablet from
600 to 1199 and desktop from 1200. The current shell uses a drawer below 1200
and a persistent rail on desktop; nested report layouts use their own allocated
width, which can remain compact even in a desktop window.

The acceptance matrix for these components is:

| Viewport / condition | Check |
| --- | --- |
| Phone: 360 and 390 logical pixels wide | Search, trailing controls, long grouping labels and remove actions remain reachable |
| Tablet: 600 and 768 wide; portrait and landscape | Toolbar layout uses the inner width and actions wrap without horizontal overflow |
| Desktop: 1200 and 1440 wide; resized window | Reports remain usable inside the constrained shell content area |
| Short window / keyboard open; text scale 200% | Confirmation dialog content and buttons are reachable by scrolling |
| All sizes, light/dark themes | Preserve visual tokens, visible focus and pointer/keyboard interaction |

Static analysis and unit tests do not establish visual acceptance for every
combination above. The following evidence replaces the earlier component-review
counts; it does not replace the dated PWA/production evidence elsewhere.
The recent component changes remain local and have not been published.

#### Implemented behavior and ownership

- Card headings use `OverflowBar` to move actions below long titles when they
  do not fit. Chart action groups wrap while retaining their order and tooltips.
- KPI grids cap the configured column count by available width and a 160 logical
  pixel minimum tile width, scaled by the actual body text scale. Text is not
  reduced to fit; very narrow layouts keep at least one column.
- Numeric filter bounds and filter actions stack in narrow layouts or with
  enlarged text. Their widget identity is preserved when switching direction,
  keeping drafts and focus across resizing. Advanced filter sheets retain
  keyboard inset handling and now include the bottom safe-area padding.
- Report grids receive their allocated width from the viewer. Optional-column
  breakpoints use that width; changes in visible columns also update the data
  source and resynchronize sorting, grouping and selection.
- The UI rule navigation table now matches the implemented drawer on phone and
  tablet and persistent rail on desktop.

| Responsibility | Source |
| --- | --- |
| Breakpoints and content constraint | `lib/core/layout/` |
| Heading reflow | `lib/shared/widgets/app_section_card_with_heading.dart` |
| Chart actions | `lib/shared/widgets/charts/app_chart_header_trailing.dart` |
| KPI capacity policy | `lib/shared/widgets/metrics/resolve_metric_grid_columns.dart` |
| Stable paired form controls | `lib/shared/widgets/forms/app_responsive_field_pair.dart` |
| Local table width and synchronization | `lib/shared/widgets/reports/app_report_viewer.dart`, `lib/shared/widgets/reports/app_report_grid.dart` |
| Dialog scrolling | `lib/shared/widgets/app_dialog.dart` |

`AppResponsiveFieldPair` stacks below 480 logical pixels multiplied by the body
text scale. KPI preferred counts remain configurable; minimum tile width limits
capacity rather than forcing a fixed count. A single tile may be narrower than
160 pixels when that is all the parent can provide. `AppReportGrid.availableWidth`
is optional for compatibility; the viewer supplies its allocated width, while a
direct caller that omits it retains the window-width fallback. Keep report viewers
inside a height-constrained region: they own a scrollable body and must not be
placed unconstrained inside another vertical scrollable.

#### Validation performed on 2026-11-17

An isolated local Flutter Web preview with fictitious data was inspected in the
integrated browser at 360x740 with 200% text/dark theme, 768x1024 with default
text/light theme, and 1440x900 with a 960-wide content area/dark theme. Headers,
KPI cards and filter controls remained within their allocated widths. A typed
numeric filter value survived resizing from 768 to 390 pixels. At 600x320 and
200% text, scrolling the confirmation dialog exposed both action buttons.
These are component-preview observations, not authenticated production checks.
Physical Android keyboard behavior and exhaustive chart/table combinations
remain outside this evidence.

The metrics, forms, reports, charts and settings suites passed 523 tests,
including four new unit tests for KPI column capacity and text scaling. After
the report-width correction, the 44 report tests passed again. No new widget
tests were added.
The final analyzer run completed without errors or warnings (585 deprecation
information messages). In a second bounded report preview, an optional column
disappeared at 390 pixels and returned with its cell value at 1200 pixels.
The initial preview incorrectly nested the report's scrollable body without a
height constraint; correcting the preview container resolved that harness error.
A Flutter Web engine assertion was also observed after preview restart; its
cause was not established. Successful screenshots do not resolve that diagnostic
or establish production readiness. Physical-device and packaged-build
checks remain necessary for full platform acceptance.

### Existing platform checks

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

### Historical PWA evidence (2026-11-08)

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

### Historical scheduler evidence (2026-11-08)

The app-local distributed refresh scheduler is now implemented without changing
`plug_server`. Its architecture, states and authorization boundaries are documented
in [cache architecture](../cache_repo/architecture.md#local-scheduled-refresh), and
the current build/test evidence is in [cache testing](../cache_repo/testing.md#scheduled-refresh-validation-2026-11-08).
This later validation includes full-project analysis, native builds, hot reload,
live repository E2E and a real-browser multi-tab scheduler harness. It supersedes
the earlier review's tooling/build limitations, not its unproven external Push and
deployed offline-authorization acceptance.
