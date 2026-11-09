# Colmeia

Flutter application for corporate dashboards, reports, and agent-backed analytical
queries across stores and user scopes.

## Supported platforms

Android, Windows desktop, and Web. Native iOS development and distribution have
been discontinued. Platform dependencies are maintained in
[project_platform_dependencies.mdc](.cursor/rules/project_platform_dependencies.mdc).

## Application structure

The application includes authentication and token refresh, user/store scope,
client-agent approval and requests, agent SQL execution, overview and sales
dashboards, and sales maps. Shared report components support tabular views and
exports; a standalone reports module is not an active navigation destination.
Backend authorization remains authoritative.

Features live in `lib/features/`, with presentation, application, domain, and
data layers where needed. Shared infrastructure lives in `lib/core/`; reusable
UI lives in `lib/shared/`; shell, bootstrap and routes live in `lib/app/`.
Provider manages presentation state, GetIt wires
services, GoRouter handles navigation, and Dio/Socket.IO provide remote access.

Local storage separates opportunistic caches from explicitly selected PWA
offline packages. Packages cover 30 days and require a server-issued permission
grant valid for at most 24 hours; they do not queue new remote business actions.
Browser storage can still be evicted. See [storage architecture](docs/cache_repo/architecture.md)
and the [Web/PWA guide](docs/install/web_guide.md) for lifecycle, installation,
Push and the remaining real-server/device acceptance checks.

## Documentation

| Topic | Reference |
| --- | --- |
| Setup, installation, and releases | [Installation index](docs/install/readme.md) |
| Web/PWA build, offline use and acceptance | [Web guide](docs/install/web_guide.md) |
| Cache and persistence | [Cache index](docs/cache_repo/README.md) |
| Hub integration and transport defaults | [Plug server index](docs/plug_server_docs_index_for_colmeia.md) |
| Agent SQL contracts | [Bridge SQL options](docs/bridge_agent_sql_api_options.md) |
| Charts and reports UI | [Charts design system](docs/Features/charts_design_system.md) |
| Product analysis and design history | [Analysis index](docs/analysis/README.md) |
| Contributor rules | [Rules index](.cursor/rules/rules_index.mdc) |

## Development

Use the Flutter version in `tool/flutter_ci_version.txt`, then:

```bash
flutter pub get
python tool/install_git_hooks.py
python tool/ci_preflight.py --templates-only
flutter analyze
flutter test
flutter run -d windows
flutter run -d chrome
# Android: flutter run -d <device-id>
```

On Windows PowerShell, load `. ./tool/env_windows.ps1` when configuring the
local tool environment. Format changed Dart files with `dart format`.

`python tool/ci_preflight.py` checks environment templates, formatting, and
version synchronization before release. Use `--templates-only` while local E2E
secrets are active. Backend-dependent tests require their documented environment;
see the [cache testing guide](docs/cache_repo/testing.md) for storage and agent
SQL checks.
