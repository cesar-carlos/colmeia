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

## Production deployment — 2026-11-09

The Web application is published at
`https://colmeia.se7esistemassinop.com.br` on `62.72.11.49`.
The initial deployed source was commit `04920d4e`, packaged as
`4ef1f35cb04f16cabb5e` (51 static files). The PWA follow-up below records the
current release. Reproduce the production build configuration with:

```bash
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run \
  --dart-define=API_BASE_URL=https://colmeia.se7esistemassinop.com.br/api/v1 \
  --dart-define=USE_FAKE_BACKEND=false
python tool/package_pwa.py
```

Operational locations on the host:

- Releases: `/var/www/colmeia/releases/<release-id>`; Nginx serves the
  `/var/www/colmeia/current` symlink. Upload and verify a complete release before
  switching this symlink atomically; retain previous releases for rollback.
- Virtual host: `/etc/nginx/sites-available/colmeia.se7esistemassinop.com.br`.
- Pre-deployment Nginx backup: `/root/colmeia-deploy-20261109/nginx`.
- Dedicated logs: `/var/log/nginx/colmeia-access.log` and
  `/var/log/nginx/colmeia-error.log`.
- Certificate: `/etc/letsencrypt/live/colmeia.se7esistemassinop.com.br/`.
  Certbot uses `/var/www/certbot` for webroot renewal and the existing timer;
  `renewal-hooks/deploy/colmeia-nginx-reload` validates and reloads Nginx after
  this certificate renews. Contact: `cesar_carlos@msn.com`.

The dedicated virtual host redirects HTTP to HTTPS, serves static files with
revalidation, returns 404 for missing assets, and falls back to `index.html`
for application routes. `/api/` and `/socket.io` use the existing local
`plug_server_upstream`, with no proxy cache and no-store response headers.
The proxy rejects foreign or opaque Origin values before removing Origin for
the internal request, and forwards the real client IP. Authentication remains
the backend's responsibility. The initial deployment did not change backend
environments, containers or other sites; the subsequent shared Nginx changes
are recorded below. Browser requests use the Colmeia origin;
direct cross-origin calls to the hub are not enabled by this deployment.

Deployment validation: static analysis passed; 45 tooling tests and eight
worker/browser tests passed. Chrome rendered the live login at desktop/mobile
widths without JavaScript exceptions, installed the release cache and reopened
the login offline. The protected agent and Push-key routes returned 401 without
credentials; the live WebSocket handshake succeeded. Existing sites retained
their baseline HTTP statuses, and existing containers retained their IDs.
Authenticated dashboards, complete offline packages and Push delivery still
require acceptance with an authorized account. These checks do not establish
full PWA business-flow acceptance.

### Authenticated production acceptance — 2026-11-09

Validation used the configured E2E account in an isolated Chrome profile and
the deployed Colmeia origin. Login succeeded, the authenticated agent catalog
loaded, and the overview and sales pages opened. The strict
`offline package overview returns complete bounded live data` E2E case passed
against the production proxy for the configured agent and the last 30 days.
This checks complete query results, not correctness of business totals against
an independent ledger or every report/filter combination.
The daily-sales UI was exercised through its branch selector and Apply actions;
the configured branch and November 2026 filter completed and displayed the
explicit no-sales-data state with an update timestamp. This validates the empty
result path, not charts populated with production sales.

Two acceptance blockers were reproduced:

- Offline authorization returned HTTP 200 with the correct user/agent scope
  and a 24-hour duration, but `issuedAt` was approximately 400 ms ahead of the
  client clock at receipt. `OfflineAuthorization.permits` rejects future-issued
  grants immediately. The real download button displayed the online-validation
  message, and the strict complete-package E2E failed before downloading data.
  Package publication, offline data export and full offline session restoration
  therefore remain unproven. Do not extend the absolute expiry to work around
  clock skew.
- The authenticated Push-key endpoint returned `enabled: false` with no public
  key. The real activation button displayed a generic connection error even
  though the request succeeded; this message should distinguish disabled server
  configuration. No browser subscription was created and no delivery was tested.
  Enabling server VAPID configuration is a separate operational change; no
  production access approval/revocation was performed to manufacture an event.

The complete-package test froze its clock before subsequent live authorization
requests. The corrected test uses the live clock until the
explicit expiration assertion, avoiding that artificial source of future-issued
grants; the real clock-skew failure above remained. Scoped static analysis passed.

Overview chart navigation labels saying “carregando” also describe lazy sections
that have not been opened. Those labels alone do not prove an active or stuck
request. Existing containers and the seven other sites retained their baseline
identities/statuses during these checks; no service was restarted or reconfigured.

### PWA client follow-up — 2026-11-09

The authorization gateway now waits for a future issuance timestamp only when
the difference is at most five seconds. It does not modify the grant, relax
`permits`, or extend expiration; larger differences remain invalid. This addresses
the small clock skew reproduced above without granting an extra offline window.
Push activation now distinguishes disabled server configuration, malformed key
responses and denied browser permission. Invalid/disabled configuration does not
request browser permission. These corrections do not enable VAPID or establish
live package/Push acceptance. Deployment evidence is recorded below.

The corrections were published from commit `4eddd745` as release
`c3241ce5fdc51a131aab` (51 files, 50,106,008 bytes). The archive SHA-256 is
`8c15004bb60802ba87299b2192b2c4fb382d8103f757cbdf3f48d9723151fc6b`.
All packaged file hashes were verified before atomically switching
`/var/www/colmeia/current`. The previous release remains available at
`/var/www/colmeia/releases/4ef1f35cb04f16cabb5e`; rollback is an atomic symlink
switch to that directory, not an overwrite of live files. Deployment evidence,
the previous target and container identities are stored under
`/root/colmeia-pwa-deploy-20261109-130223/`.

The 32 PWA tests passed again before publication. Earlier review validation
passed 45 tooling tests, six worker tests and both production-build browser
scenarios (root/subdirectory); focused analysis was clean. On the published
release, isolated Chrome login succeeded and Push activation displayed the
specific server-not-configured message. The nine domains retained their HTTP
baselines, TLS and both WebSocket handshakes passed, and container IDs were
unchanged. No application or Nginx restart was needed for the static release.
Full live package preparation and actual Push delivery remain acceptance gaps.
Existing PWA tabs should accept the application's update prompt to activate the
new worker when tracked work is idle.

### Avatar CORS correction — 2026-11-09

The profile returned a valid thumbnail URL on the Plug Server origin, but that
image response lacked CORS headers. Flutter Web could therefore fall back to
initials despite the image returning HTTP 200. The Plug Server Nginx virtual host
now has a dedicated `/uploads/client-thumbnails/` location, aliased to
`/var/lib/plug_server/uploads/client-thumbnails/`, with
`Access-Control-Allow-Origin: https://colmeia.se7esistemassinop.com.br`.
This applies only to already-public avatars; API authentication and other upload
routes are unchanged. The location preserves seven-day expiration and adds HSTS
and nosniff. No credentials or wildcard origin allowance was introduced.

After `nginx -t` and a graceful reload, Chrome on the Colmeia origin successfully
fetched and decoded the configured account's 256-by-256 WebP avatar. Existing
cached responses may require a hard reload. The original virtual host is backed
up under `/root/avatar-cors-20261109-125906/`.

### Shared Nginx and firewall review — 2026-11-09

These changes apply to the shared production host, not to the Flutter artifact.
Nginx configuration was backed up, checked with `nginx -t`, and gracefully
reloaded. Applications, Docker containers and the Plug Server environment were
not restarted or changed.

**Nginx corrections**

- Aligned TLS listeners on HTTP/2 and removed redundant `text/html` from
  `gzip_types`; configuration validation now completes without the prior warnings.
- Added `$upstream_connection`: ordinary HTTP requests omit the Connection header
  so the existing Plug Server and Evolution upstream keepalive pools can be used;
  WebSocket requests retain `Connection: upgrade`.
- Reduced Evolution's connection-establishment timeout from 86,400 to 15 seconds.
  Its long-running read/send timeouts remain unchanged.
- Restored security headers lost through location-level `add_header` inheritance
  in Colmeia, MCP and Plug Server static locations. Colmeia API responses avoid
  duplicate security headers and retain `Referrer-Policy: no-referrer`.
- Swagger CSS/JS filenames are not versioned: they now require revalidation
  instead of 30-day immutable caching. Uploads retain their seven-day expiration
  without a duplicate Cache-Control header.
- Active access logs use the JSON `safe_main` format, defined before its first
  use in `nginx.conf`. Fields include host, source IP, method, path, status,
  response size, request/upstream duration, upstream status, request ID and
  rate-limit outcome. Query strings, Referer, cookies and authorization headers
  are omitted. Paths and IP addresses remain operational data; this is not
  full anonymization or client-side error collection. Existing error logs and
  historical access entries were not rewritten or sanitized.

**Request limits**

`/etc/nginx/conf.d/01-plug-rate-limit.conf` defines shared per-source-IP zones.
`/etc/nginx/snippets/plug_edge_limits.conf` applies them to the HTTPS servers for
both `plug-server.se7esistemassinop.com.br` and
`colmeia.se7esistemassinop.com.br`. Switching between those origins does not
create a fresh bucket.

| Zone | Matched URI paths | Sustained rate | Excess burst |
| --- | --- | --- | --- |
| `plug_api` | Paths beginning `/api/` or `/auth/` | 150 requests/second | 300 |
| `plug_login` | `/auth/login` or `/client-auth/login`, optionally prefixed by `/api/v1` | 60 requests/minute | 60 |
| `plug_sensitive` | Same auth prefixes, ending in `/register` or `/password-recovery/request` | 90 requests/minute | 30 |

Auth patterns also accept a trailing slash. Matching is path-based, regardless
of HTTP method. Applicable limits accumulate; the general API limit also covers
the normal versioned login and registration routes. Bursts use `nodelay`: requests
within burst capacity are served immediately and excess requests return HTTP 429.
No edge Retry-After header was added. Rejections use notice-level error logging;
access logs expose `$limit_req_status`.

Socket.IO handshakes and established WebSockets are excluded from these URI
limits. Token refresh is subject to the general API limit, not the narrower login
limit. This is edge protection, not per-account brute-force protection or a
replacement for backend business-operation limits. Several backend limits remain
disabled in the existing environment. The observed recent peak was 54 API
requests/IP/second; this short sample does not establish all NAT/reconnection
peaks. Monitor 429 outcomes before tightening thresholds.

**Network exposure**

| TCP port | Service | External IPv4 check before → after | Local access |
| --- | --- | --- | --- |
| 3000 | Chatwoot | Reachable → blocked | Preserved for Nginx |
| 5433 | Docker-published Plug MCP PostgreSQL | Reachable → blocked | Preserved |
| 8081 | Docker-published Evolution | Reachable → blocked | Preserved for Nginx |

UFW's first rule denies incoming TCP traffic on `eth0` to these three ports for
IPv4 and IPv6. Existing broader allow rules remain below it. Docker forwarding
can bypass UFW INPUT rules, so IPv4/IPv6 `DOCKER-USER` also drops new incoming
connections on `eth0` whose original destination port is 5433 or 8081. Matching
uses conntrack's original destination port, before Docker port translation.
Established connections, loopback and traffic originating on container bridges
are not targeted. No containers were recreated or port bindings changed.

Persistence is provided by:

- `/usr/local/sbin/se7e-edge-firewall` (idempotent Docker rules).
- `/etc/systemd/system/se7e-edge-firewall.service` (enabled, after Docker/UFW).
- `/etc/systemd/system/docker.service.d/50-se7e-edge-firewall.conf`
  (`ExecStartPost` reapplies the rules on Docker startup).

SSH 22, HTTP 80, HTTPS 443 and existing RustDesk rules were preserved. External
TCP probes succeeded for 22/80/443 and RustDesk 21116/21117. Ports
3010/4000/5432/6379/7433 were already unreachable from the test client and remained
so. Old UFW allowances for 3036/5432/6379 were not removed; services must not be
rebound publicly without another exposure review. IPv6 rules were inspected,
but external IPv6 reachability and reboot persistence were not exercised.

**Evidence and recovery**

All nine configured domains retained their previous root status: Chatwoot,
dev-chat, Colmeia, Evolution QR, n8n, Plug Server and support returned 200;
Evolution and MCP retained their existing root 404 responses. TLS validation
passed. Plug Server and Colmeia WebSocket handshakes returned 101, the protected
Colmeia agent route returned 401 without credentials, and a missing asset returned
404. Container IDs were unchanged. These checks do not establish every service's
authenticated workflow or continuous zero downtime.

An isolated Nginx process using the deployed rate-limit definitions handled 85
test requests: 61 returned 200 and 24 returned 429. No burst was sent to a business
backend. A synthetic query/Referer marker was absent from the new access-log
entries. Firewall rollback was armed during the change and cancelled after
external and application checks succeeded.

- Pre-Nginx-review backup: `/root/nginx-audit-20261109-123926/` contains the
  previous `nginx/` tree and before/after HTTP evidence.
- Pre-rate-limit/firewall backup: `/root/edge-hardening-20261109-124402/` contains
  `nginx/`, `ufw/`, IPv4/IPv6 rule snapshots and container identities.
- The latter directory's `rollback.sh` reverses only this firewall change and
  removes its persistence files; it does not restore Nginx. Running it reopens
  the previously exposed ports. Use it only for a confirmed connectivity regression.
- To revert the rate limits, restore the backed-up `nginx.conf`,
  `conf.d/01-plug-rate-limit.conf` and the Colmeia/Plug Server site files, then
  remove the newly added `snippets/plug_edge_limits.conf`. Review differences
  first so newer changes are not overwritten. Run `nginx -t` before
  `systemctl reload nginx`, then repeat domain, API and WebSocket checks.

The backups and active configuration live on the server; this repository records
the operational state, not an automated provisioning or restore system.
Reference behavior: [Nginx rate limiting](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html),
[header inheritance](https://nginx.org/en/docs/http/ngx_http_headers_module.html),
and [Docker firewall rules](https://docs.docker.com/engine/network/firewall-iptables/).

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
