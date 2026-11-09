# Web guide — Colmeia

Supported application targets are Android, Windows desktop, and Web. Native
iOS development, CI builds, and App Store/TestFlight distribution are discontinued.

For the current implementation inventory, corrections and ordered backlog, see
the [Web/PWA review plan](web_pwa_review_plan.md).

## Run and build

Use the Flutter version in `tool/flutter_ci_version.txt` (or the repository
`FLUTTER_CI_VERSION` override), then run:

```bash
flutter pub get
flutter run -d chrome
flutter build web --release --no-web-resources-cdn
python tool/package_pwa.py
```

The supported production build is the default JavaScript target. WebAssembly
is not part of the validated target; the current Socket.IO dependency emits a
Wasm compatibility warning during Flutter's optional dry run.

The production output is `build/web/`. Flutter CI builds this target and uploads
it as the `colmeia-web` workflow artifact. Hosting deployment is separate from
Windows/Android GitHub Releases and is not automatic.

For a subdirectory deployment, build with its base path, including both slashes:

```bash
flutter build web --release --no-web-resources-cdn --base-href /colmeia/
python tool/package_pwa.py
```

## Hosting and API configuration

- Serve the entire `build/web/` directory over HTTPS (localhost is suitable for
  development). Secure browser storage requires a secure context.
- The app uses path-based routes. Configure the server to serve `index.html`
  for application routes such as `/login`, while serving existing assets normally.
  Apply the same fallback under the chosen base path for subdirectory deployments.
- Configure `API_BASE_URL` using the existing environment/dart-define mechanism.
  An HTTPS application must connect to HTTPS APIs and secure WebSockets.
- Allow the Web origin in the API/Socket server configuration. REST preflight
  requests must allow the authentication and content headers used by the app.
  Browser restrictions cannot be bypassed by Flutter code.
- Treat bundled environment assets and dart-defines as public. Never include
  backend credentials, private signing keys, or local E2E secrets in a Web build.
- Deploy assets together and avoid long-lived caching of `index.html` and bootstrap
  files so releases do not leave users loading stale application code.

## Browser behavior

- Browser data can be evicted or cleared by the user. HTTPS is required for
  secure storage. PWA logout is broadcast to other tabs and package downloads use browser Web Locks. See [storage architecture](../cache_repo/architecture.md#platform-storage)
  for persistence, session errors, and legacy-data migration.
- Socket payloads retain gzip and signature validation compatibility. Browser
  gzip/JSON processing runs on the main thread; persistent Dart isolates are
  enabled only in native builds.
- Report/chart exports use in-memory files and the browser share/download flow.
  Browser support and user-gesture requirements can affect sharing. Local file
  opening and Windows automatic updates are native-only features.
- Native address geocoding and the optional HERE provider remain disabled on Web.
  Map resolution can use coordinates and the existing local geographic data.
- Touch, keyboard, mouse, and portrait/landscape browser layouts are supported.
  Browser platform detection may still identify the host operating system; those
  Flutter enum values do not imply a maintained native iOS/macOS/Linux runner.

## Validation before publishing

Run `flutter analyze`, relevant unit tests, and the release build plus
`tool/package_pwa.py` from [Run and build](#run-and-build).
Serve the production output with the route fallback and verify login, session
restoration, API and Socket requests, dashboards, map data, exports, and a direct
route reload against the intended backend and origin.

Storage-specific checks and the test-only browser entry point are documented in
[cache testing](../cache_repo/testing.md#platform-storage-regressions).

## PWA lifecycle

`web/pwa-worker.js` is the shared static-cache and Push worker. The Flutter-generated worker is not registered. `tool/package_pwa.py` must run after every release build; it injects the release identity and hashes every precached file. Do not edit the output after packaging. CanvasKit and fonts are bundled locally. Only static files are cached; API, Socket, credentials and authenticated responses never enter the shell cache.

The initial installation verifies all file hashes before becoming usable offline. A failed update leaves the previous generation intact. The UI offers an explicit update action; all open application tabs must acknowledge that their tracked work is idle. Existing documents keep their release's assets until they reload. SPA fallback applies only to navigation inside the application's scope, not missing assets or API routes.

Serve `pwa-worker.js`, `index.html`, `flutter_bootstrap.js`, `pwa-client.js`, and `manifest.json` with `Cache-Control: no-cache` (or `no-store`). File URLs are not content-addressed, so do not mark them immutable. Publish the complete directory atomically. The worker verifies release hashes even when an intermediary serves stale files. Set JavaScript and WASM MIME types correctly. Never rewrite a missing `.js`, `.wasm`, font or image to `index.html`. Use `Service-Worker-Allowed` only if hosting the worker outside its intended scope; the normal build requires no wider scope.

## Offline packages

Open **Perfil → Disponível offline**, select an approved store/agent, and download its package. The page reports authorization, download, revalidation and saving stages, serialized package size, and browser storage estimates when available. Cancellation, unavailable storage and incomplete agent data have distinct messages. Preparation uses existing overview and branch-sales queries for a bounded 30-day period. It includes the current day as partial, context, summary/payment/user/day/month/profitability snapshots and branch totals. Derived weekday-user values are included only in this explicit snapshot, not in normal historical fact consolidation.

The local report selector supports search, ordering, pagination and CSV export over downloaded rows. Other query combinations must show “Requer conexão”; absence of a dataset is not an empty business result. The overview adapter requires the exact prepared period and agent. The package does not make every arbitrary report parameter or report drilldown available offline.

Packages are isolated by user and agent in IndexedDB through `AppCacheStore`. A complete payload is published with one transactional key write and read back to confirm persistence, including when the generic cache adapter treats write errors as misses. Interrupted downloads retain the previously published payload. A server permission grant is checked before loading and again before publication, and limits local access to 24 hours. Expired grants block reads; expired access tokens do not authenticate remote requests. Network failure during session refresh retains persisted credentials. Confirmed authorization rejection and logout remove private data and cancel pending package work.

Synchronization runs only while the application is open. New selected-package schedules default to two hours; reconnect/focus resumes overdue work. Existing configured intervals are preserved and can be edited under **Atualização de dados**. Agent unavailability is reported as a failed download, not as absence of internet. An explicit storage-persistence request is optional; denial, quota exhaustion and browser eviction are surfaced without silently pruning user-selected packages. Revalidate online to recover expired access or rebuild evicted data. No new queue of remote business mutations is introduced.

## Web Push

The server implementation and VAPID configuration are documented in `plug_server/docs/pwa.md`. The client uses the following additive authenticated routes (including the
`/api/v1` prefix):

| Method | Route | Purpose |
| --- | --- | --- |
| POST | `/api/v1/client/me/pwa/offline-authorization` | Issue a scoped offline grant |
| GET | `/api/v1/client/me/pwa/push-key` | Read enabled state and public VAPID key |
| PUT | `/api/v1/client/me/pwa/subscriptions/:installationId` | Register/update this installation |
| DELETE | `/api/v1/client/me/pwa/subscriptions/:installationId` | Remove this installation |

Apply the server migration and configure VAPID before enabling notifications. Only the public key reaches the browser. Access decisions and delivery records commit in one server transaction; a queue-write failure rolls back the decision, and committed deliveries are recovered after restart.

Notification permission is requested by the explicit **Ativar notificações** action. Refusal or unsupported browser behavior does not block the app. Notifications contain generic access-change text and open `/agents` through the normal auth guards. Disabling notifications or logout revokes local consent, unsubscribes the browser, and retains a user-scoped pending server-removal marker when the network is unavailable. Reconciliation uses the authenticated identity on the next online access.

## Automated validation and remaining acceptance

```bash
python -m unittest discover -s tool/tests -p '*_test.py'
flutter test test/features/pwa test/core/network/auth_interceptor_test.dart
cd tool/pwa-tests
npm ci
npx playwright install chromium
npm test
```

The browser suite uses the production output, verifies offline reloads at root/subpath, missing-file errors, multi-tab update coordination and preservation after failed installation. Set `PWA_CHROME_PATH` to an installed Chrome executable to avoid a browser download. CI runs these checks before uploading the publishable Web artifact.

Optional real-provider smoke: set `PWA_SERVER_ROOT` to the server checkout (with dependencies installed), then run `node tool/pwa-tests/push-smoke.mjs`. The script uses temporary keys and a temporary browser profile and never writes subscription secrets. A sender mock or a successful queue test does not establish real Push delivery.

### Recorded validation and acceptance gaps

The results below were recorded on **2026-10-28**. They were not rerun during
the documentation review on **2026-11-08** and do not establish current production
availability.

| Check | Recorded result |
| --- | --- |
| Static analysis | Clean |
| Focused PWA/auth tests | 33 passed |
| Tooling tests | 45 passed |
| Production-browser scenarios | Both passed |
| Builds | Web release, Android debug and Windows debug succeeded |
| Server tests | 2,306 passed, 25 skipped; lint and type checking passed |
| Isolated PostgreSQL integration | Five tests passed, covering queue rollback, ownership, deduplication and access transactions |
| Strict 30-day overview query | Passed against the configured live hub/agent |
| Full package via live authorization | Hub returned `Route not found` |
| Real-provider Push subscription | Automated Chrome returned `permission denied`; delivery unproven |

Complete package preparation through deployed server routes, installed-browser
reopening, Android device installation and closed-app notification delivery remain
acceptance work. No production domain was published and no shared database
migration was applied by that validation. Android toolchain details belong in the
[Android guide](../android_guide.md#sdk-37-build-compatibility).

### Connectivity limitation

The Web platform currently derives connectivity from `navigator.onLine`.
`canRestoreOffline` and the overview adapter select their offline path when that
flag is false. An unreachable hub while the browser still reports online is not
an automatic offline fallback. Include that case in acceptance checks; retaining
credentials after transient failures alone does not prove successful offline
session restoration.

### Operational signals

Local scheduled report refresh is available under **Configurações > Atualização de
dados**, also on Android and Windows. See the [cache architecture](../cache_repo/architecture.md#local-scheduled-refresh)
for scheduling, agent isolation, snapshot publication and authorization boundaries.
It requires the application to be executing; installing a PWA does not enable an
always-running background scheduler. No change to `plug_server` is required.

The browser integration harness exercises the real coordinator, IndexedDB, Web
Locks and settings page with deterministic query responses:

```bash
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --target test/integration/cache_refresh_browser.dart --output build/cache_refresh_browser
node --test tool/pwa-tests/cache-refresh.test.mjs
```

Use `PWA_CHROME_PATH` when running an installed Chrome instead of Playwright's
bundled Chromium. The harness tests two-tab deduplication, an offline agent alongside
an online agent, recovery, persisted restart and overdue foreground refresh. It
captures 390 px and 1440 px layouts under `build/cache_refresh_browser/evidence`.
It also holds both global capacity slots from separate tabs and verifies that jobs
remain deferred until a slot is released. Schedule metadata is stored separately
from result generations, with automatic migration of supported older records and
individual quarantine of incompatible entries.
These deterministic browser checks complement, rather than replace, live SQL E2E
tests and the deployed offline-authorization acceptance described below.

Strict live scheduler acceptance uses the existing authenticated hub catalog and
product-sales repository, publishes a snapshot and checks recovery after an injected
client-side presence loss:

```bash
flutter test test/integration/e2e/cache_refresh_scheduler_e2e_test.dart
```

The configured agent is never stopped. Missing E2E credentials are reported as a
skip; runtime permission, query or publication failures fail this test rather than
being counted as successful refreshes. This proves the flow for the configured live
agent, not a production outage across multiple independent servers.

The worker emits `pwa.cache.installed` with release, static-file count and duration,
and `pwa.cache.install_failed` on incomplete releases. Package work records
`pwa.package.synchronization` through `AppLogger` with publication outcome and duration.
The server records `pwa_push_delivery`, access-transaction failures and worker failures.
These signals exclude tokens, subscription endpoints, user identity and financial rows.
Route them through the existing observability integration; browser console events are
local diagnostics unless the deployment explicitly collects them.

For strict live query acceptance, configure the existing E2E credentials and run:

```bash
flutter test test/integration/e2e/overview_repository_e2e_test.dart --plain-name "offline package overview returns complete bounded live data"
```

This test fails on missing credentials or incomplete datasets. Unlike the broader
transport-resilience tests, it does not accept expected RPC/network failures as
proof of usable offline data. It still does not exercise publication through the
new permission endpoint or browser Push delivery.

Full live package acceptance (requires the new server routes to be deployed):

```bash
flutter test test/integration/e2e/overview_repository_e2e_test.dart --plain-name "complete package uses live authorization" --dart-define=PWA_LIVE_ACCEPTANCE=true
```

This opt-in test uses real HTTP authorization and SQL queries, publishes the package,
blocks subsequent HTTP calls, checks every local projection, user isolation and
absolute expiration. Its local cache and browser platform are test adapters; it
complements rather than replaces installed-browser acceptance. On 2026-10-28 the
configured live hub returned `Route not found` for the authorization endpoint.
Deploying the server or hosting the application is a separate operational step.
