# Guia de Release e Versionamento

Windows and Android release workflow. Web builds and hosting are documented
in the [Web guide](web_guide.md). Native iOS releases are discontinued.

## Version 1.6.18+41 — 2026-11-28

Corrects false offline indicators by publishing the resolved catalog presence
to dashboard filters and treating stale, malformed or incomplete cached presence
as unknown. Persisted and in-memory presence expire conservatively, including
invalid timestamps and clock rollback. Invalidation fences pending resolutions.

Protocol readiness and open circuit breakers are transient failures, not evidence
of disconnection. Presence listeners reject obsolete attachments and revisions;
controllers reject late results after newer events or logout. Polling backoff is
cancelled on session restart. Scheduler dispatch reloads work after session changes.

Regression tests cover ordering, cache integrity, session isolation and restart.
Local validation passed 807 focused regression tests, 60 release-tool tests,
the production Web build, all eight PWA worker/browser scenarios and static
analysis. These suites overlap prior focused checks and are not live SQL E2E.
Interactive authenticated production presence has not been independently verified;
no debug app was available. Publication does not change the hub or its databases.
Release validation and deployment evidence are recorded in the Web guide.

## Version 1.6.17+40 — 2026-11-23

Corrects duplicated scrollbars in the product-margin report: embedded reports
use a Column instead of a disabled ListView; the page suppresses automatic
desktop scrollbars while preserving its explicit scrollbar and the grid's own
scrolling. Other standalone report layouts retain their ListView.

Payment-method summaries now allocate change once for mixed payments, validate
calendar-date ranges consistently, and reject potentially incomplete aggregates.
SQL caps match the existing transport limits (5,000 summary groups; 10,000 daily
rows). Monthly/weekday parcel facts use schema 2 to invalidate old allocations.
Details and caveats are in [Agent SQL options](../bridge_agent_sql_api_options.md#revisão-de-vendas-por-forma-de-pagamento-2026-11-23).

Local evidence: 189 query/repository/cache tests, 66 overview data tests, 69
report/product-margin tests and five SQL arithmetic tests passed (some suites
overlap). Static analysis passed. Live E2E remains unproven: the daily query
returned HTTP 503 after 120 seconds; the numeric fixture returned `Not authorized`,
including via relay. No interactive debug app was available for visual validation.
These limitations are retained in the release; they are not counted as successful
live-data acceptance. Native artifacts remain gated by exact-commit CI.

## Version 1.6.16+39 — 2026-11-21

Product margin now scrolls as a page with a taller table instead of compressing
rows below the header. The replacement-cost selector is directly visible, with
All, With cost (default) and Without cost options. Existing query filtering,
pagination reset and theme components are preserved. The report viewer's embedded
layout is opt-in; other reports retain their existing scroll behavior.

Local validation: 25 existing controller, grid sizing and dropdown tests passed;
Flutter analysis reported no issues. Interactive visual validation was not performed
because no debug app was available. Release CI validates the tagged commit before
publishing native installers.

## Release validation — 2026-11-21

The intermediate tags `v1.6.12`, `v1.6.13` and `v1.6.14` did not publish native installers.
Linux CI caught export tests treating an in-memory XFile as a path-backed file,
then expecting a name that the native implementation explicitly ignores. Empty
cleanup paths could resolve to the checkout directory. The code now restricts
cleanup to UUID directories under the application's temporary export root;
regressions cover empty/relative paths and preservation of unrelated files.
The Web deployment is recorded in the [Web guide](web_guide.md).

## CI performance and local preparation

The previous single Linux test job took about ten minutes on completed runs;
Android debug took roughly six minutes and Web about five. Flutter SDK and pub
caches already existed, but Gradle, npm and Playwright browser caches did not.

- Four test jobs now divide the same 664 test files by sorted filename, with no
  overlap. Every shard must pass. Splitting files avoids recompiling every suite
  in every job. The CI suite still excludes remote E2E tests.
- Gradle caches dependencies/build state for Android. Pull requests and tagged
  releases read caches; main CI writes them. Signing files are not cached.
- npm and Playwright caches use the dependency lockfile. The supported JavaScript
  Web build skips the redundant Wasm compatibility dry run.
- Native release compilation runs alongside the exact-commit CI verification.
  Publishing still requires successful verification plus both native builds;
  appcast publication still requires the completed release. Building in parallel
  reduces the critical path but may spend build minutes on a commit that fails CI.
- Jobs have bounded timeouts. Main runs are not automatically cancelled by later
  commits, because a release must validate the exact commit of its tag.

Prepare locally before pushing:

```powershell
flutter pub get
python tool/ci_preflight.py --templates-only --analyze --tests
python -m unittest discover -s installer/tests -p '*_test.py'
python -m unittest discover -s tool/tests -p '*_test.py'
```

`--templates-only` leaves local test credentials in the ignored configuration;
it is not permission to bundle that file. Release packaging still rejects private
configuration. The version check compares generated content, so a synchronized
but uncommitted version bump is valid. `tool/release_windows.py` uses the same
suite runner as CI, including documentation tests.

For focused investigation, use `python tool/run_ci_tests.py --shards 4 --shard 0`.
`--list` enumerates that shard without running Flutter. Windows executes long file
lists in bounded batches. Running all four shards covers the full CI suite.

Local preprocessing finds failures earlier and reuses the developer machine's
warm caches; it does not replace Linux CI or approve a different tagged commit.
Artifacts built on a developer machine are not automatically trusted as signed
GitHub release assets. Full E2E tests remain separate and require the real agent.

Measured on the successful [v1.6.15 CI run](https://github.com/cesar-carlos/colmeia/actions/runs/44931350895): all four shards passed, with 4,030 tests passing and one skipped. Including runner setup, shard durations were 2m40s, 4m07s, 4m24s and 4m38s. The previous single-job runs took approximately 10–12 minutes. Android debug completed in 4m14s (previous run: 6m44s), Web in 4m10s and Android release smoke in 6m24s. Analyze plus all dependent jobs completed in 7m53s. These are observed runs, not a controlled benchmark; runner load and cache warmth vary.

The local workflow tooling has 86 passing Python tests. Actionlint 1.7.12 accepts the changed workflows after excluding its outdated diagnostic for the existing `concurrency.queue: max` key, which is supported by GitHub. Documentation UTF-8 is validated in preflight and before CI builds. No lint warning for changed workflow logic was suppressed.

Cold caches and runner capacity still affect wall-clock time. Compare Actions job
start/end times after the optimized run; do not treat expected savings as measured
results. No additional paid runners or always-on local runners are configured.

## Fonte de verdade da versao

- `pubspec.yaml`: versao canonica no formato `MAJOR.MINOR.PATCH+BUILD`
- `installer/setup.iss`: derivado da versao curta
- `lib/core/constants/app_version.g.dart`: derivado da versao completa

## Assets oficiais por tag

Toda tag `vX.Y.Z` publica uma unica GitHub Release com:

- `Colmeia-Setup-X.Y.Z.exe`
- `Colmeia-Android-X.Y.Z.apk`
- `Colmeia-Android-X.Y.Z.aab`
- `Colmeia-Setup-X.Y.Z.exe.sha256`
- `Colmeia-Android-X.Y.Z.apk.sha256`
- `Colmeia-Android-X.Y.Z.aab.sha256`

Tags oficiais:

```text
vMAJOR.MINOR.PATCH
```

Exemplo:

- `pubspec.yaml`: `1.1.0+2`
- tag: `v1.1.0`

## Pre-requisitos do CI

- repository variable `FLUTTER_CI_VERSION`
- environment `production` no GitHub, idealmente com reviewers obrigatorios
- secret `APPCAST_PUSH_TOKEN` se `main` bloquear o token padrao do Actions
- secret `ANDROID_KEYSTORE_BASE64`
- secret `ANDROID_KEYSTORE_PASSWORD`
- secret `ANDROID_KEY_ALIAS`
- secret `ANDROID_KEY_PASSWORD`

## Alinhamento Flutter local e CI

Use a mesma versao do Flutter que o repositorio fixa na variavel de Actions
**`FLUTTER_CI_VERSION`** (GitHub: Settings > Secrets and variables > Actions >
Variables). Quando a variavel estiver vazia, o fallback versionado do repo vem
de **`tool/flutter_ci_version.txt`**. Compare sempre esse valor com
`flutter --version` na maquina de release.

Pastas **`build/`** e **`installer/dist/`** estao no `.gitignore` e nao devem ser
commitadas.

## Icones do launcher

Ao alterar PNGs em **`assets/icons/`** (por exemplo `colmeia-512.png`):

1. `dart run flutter_launcher_icons` (Android, Web; Windows esta desativado
   no `pubspec.yaml` para evitar ICO de uma unica resolucao).
2. Para atualizar **`windows/runner/resources/app_icon.ico`** e gerar
   **`installer/setup_icon.ico`** (icone dedicado do Inno Setup, fora de `windows/`):
   `dart run tool/generate_windows_app_icon.dart`. Este passo corre **automaticamente**
   dentro de `python installer/build_installer.py` **antes e depois** do
   `flutter build windows` (o segundo evita que o Setup.exe fique com ICO substituido
   pelo tooling do Flutter).
3. Revise e commit dos ficheiros gerados (Android, Web e `app_icon.ico`).
   **`installer/setup_icon.ico`** e gerado e esta **gitignored** — nao commite.
4. Para o instalador Windows completo: `python installer/build_installer.py`

Se `assets/env/local.env` tiver linhas nao comentadas, o build local do
instalador troca o arquivo temporariamente por uma copia sanitizada durante o
build e restaura o original no fim. So use `COLMEIA_ALLOW_BUNDLED_LOCAL_ENV=1`
quando isso for intencional.

### Troubleshooting do icone do Setup.exe

Se apenas `installer/dist/Colmeia-Setup-X.Y.Z.exe` aparecer com o icone antigo
no Explorer, mas o app instalado e `colmeia.exe` estiverem corretos, o problema
normalmente e **cache de icones do Windows**, nao o build do instalador.

O fluxo atual ja:

- gera `installer/setup_icon.ico` a partir de `assets/icons/colmeia-512.png`;
- recompila esse `.ico` antes e depois do `flutter build windows`;
- injeta o arquivo no Inno Setup via `SetupIconFile=setup_icon.ico`.

Na pratica, recriar o mesmo ficheiro `Colmeia-Setup-X.Y.Z.exe` durante testes
locais pode fazer o Explorer continuar a mostrar o icone anterior para o mesmo
caminho/nome.

Validacoes e workarounds:

- confirmar o recurso embutido abrindo o `.exe` noutra maquina ou com outro nome;
- gerar a proxima versao para mudar o nome final do asset;
- reiniciar o Explorer ou limpar o icon cache local antes de concluir que o
  build saiu com icone errado.

## Feed do auto-update no instalador local

Para embutir o URL do appcast no `.exe` gerado por `build_installer.py`, copie
**`.env.example`** para **`.env.release`** na raiz e ajuste se necessario.
O ficheiro `.env.release` nao e versionado. Ver tambem [auto_update_setup.md](auto_update_setup.md).

## Signing Android local

O build Android de release exige:

- `android/key.properties`
- um keystore `.jks` real referenciado por `storeFile`

Arquivo-base:

```text
android/key.properties.example
```

Copie para `android/key.properties` e ajuste:

```properties
storeFile=app/upload-keystore.jks
storePassword=preencher
keyAlias=preencher
keyPassword=preencher
```

`storeFile` e resolvido relativo a `android/`.

### Cenario 1: usar um keystore existente

1. Copie o `.jks` para um local seguro fora do versionamento
2. Aponte `storeFile` para esse caminho relativo dentro de `android/`
3. Preencha `storePassword`, `keyAlias` e `keyPassword`
4. Converta o `.jks` para base64 para o secret `ANDROID_KEYSTORE_BASE64`

### Cenario 2: gerar a primeira keystore oficial

Exemplo com `keytool`:

```powershell
keytool -genkeypair `
  -v `
  -keystore upload-keystore.jks `
  -alias upload `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

Depois:

1. mova o arquivo para `android/app/upload-keystore.jks` localmente
2. preencha `android/key.properties`
3. converta o arquivo para base64 e grave em `ANDROID_KEYSTORE_BASE64`
4. guarde a keystore fora do repositorio e com backup seguro

## Processo recomendado

### Atalho automatizado

Para rodar o fluxo local de bump, validacao, build do instalador, commit e tag
num unico comando:

```powershell
python tool/release_windows.py --dry-run
python tool/release_windows.py
```

Sem `--version`, o script calcula a proxima patch version com base na ultima
tag `v*.*.*` e incrementa o build atual do `pubspec.yaml`.

O release script roda `python tool/ci_preflight.py` antes dos testes (env
templates, `dart format`, sync de versao). Use `--skip-preflight` so em
emergencia.

### Gates locais (evitar falhas do Flutter CI)

Antes de push em `main` ou de criar a tag, rode:

```powershell
# Garante Flutter no PATH para subprocessos Python no Windows
. .\tool\env_windows.ps1

python tool/ci_preflight.py
```

Instale o hook de pre-push (uma vez por clone):

```powershell
python tool/install_git_hooks.py
```

O hook roda `python tool/ci_preflight.py --templates-only` ao empurrar
`main`/`master` ou tags `v*.*.*` (nao bloqueia por secrets ativos em
`local.env`).

Isso espelha os gates baratos do job `analyze`:

1. `python tool/validate_env.py` — toda chave em `EnvKeys` precisa existir em
   `assets/env/default.env` e `assets/env/.env.example`
2. `dart format --set-exit-if-changed lib test` — se falhar:
   `dart format lib test`
3. sync `installer/setup.iss` + `app_version.g.dart` com `pubspec.yaml`

Para checar so templates (ignorando secrets em `local.env`):

```powershell
python tool/ci_preflight.py --templates-only
```

Opcional (mais lento, igual ao CI):

```powershell
python tool/ci_preflight.py --analyze
```

### Branch protection e release gate

- O workflow **Tagged Release** espera Flutter CI verde no commit da tag
  (`installer/ci_require_flutter_ci.py`) antes de gerar artefatos.
- Recomendado: proteger `main` no GitHub exigindo os checks `analyze` e
  `test` do Flutter CI em PRs. Com admin, pode aplicar assim:

```powershell
gh api -X PUT repos/cesar-carlos/colmeia/branches/main/protection --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context": "analyze"},
      {"context": "test"}
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

Ou via UI: Settings → Branches → Add rule → Require status checks to pass
(`analyze`, `test`).

### 1. Atualizar a versao

Edite `pubspec.yaml`:

```yaml
version: 1.1.1+3
```

### 2. Sincronizar arquivos derivados do release Windows

```powershell
python installer/update_version.py
```

Revise o diff esperado em:

- `installer/setup.iss`
- `lib/core/constants/app_version.g.dart`

### 3. Validar localmente

```powershell
python tool/ci_preflight.py --analyze
flutter test
flutter build apk --debug
python installer/build_installer.py
```

Para o feed oficial no `.exe` gerado localmente, veja a secao **Feed do auto-update no instalador local** acima (copie `.env.example` para `.env.release`).

Se a keystore Android ja estiver configurada localmente, valide tambem:

```powershell
python tool/build_android_release.py --apk
python tool/build_android_release.py --aab
```

Esses comandos exportam os artefatos versionados para `installer/dist/` e
tambem geram os arquivos `.sha256`.

For Web validation, run `flutter build web --release`; see [Web hosting](web_guide.md).

### 4. Commitar

```powershell
git add pubspec.yaml installer/setup.iss lib/core/constants/app_version.g.dart
git commit -m "chore: bump version to 1.1.1"
git push origin main
```

### 5. Criar a tag

```powershell
git tag v1.1.1
git push origin v1.1.1
```

A tag precisa apontar para um commit ja alcancavel a partir de `main`.
O workflow falha se a tag for criada em um commit fora da historia de `main`.

### 6. Aguardar o workflow

O workflow `Tagged Release`:

1. valida a tag contra `pubspec.yaml`;
2. confere sincronismo dos arquivos derivados do release Windows;
3. gera `Colmeia-Setup-{versao}.exe`;
4. gera `Colmeia-Android-{versao}.apk`;
5. gera `Colmeia-Android-{versao}.aab`;
6. gera os arquivos `.sha256` para os 3 assets;
7. aguarda a aprovacao do environment `production`, quando configurado;
8. cria/atualiza uma unica GitHub Release com os 6 arquivos;
9. usa o horario real da GitHub Release para atualizar `appcast.xml` em `main`.

## Token para branch protegida

Por padrao o workflow tenta atualizar `appcast.xml` com `github.token`.
Se a branch `main` bloquear esse push via Contents API, crie o secret
`APPCAST_PUSH_TOKEN` com permissao de `contents:write`.

## Checksums dos assets

Cada binario oficial recebe um arquivo `.sha256` na mesma GitHub Release.

Exemplo de validacao local no Windows:

```powershell
Get-FileHash .\Colmeia-Setup-1.1.1.exe -Algorithm SHA256
```

Compare o hash calculado com o conteudo de `Colmeia-Setup-1.1.1.exe.sha256`.

## Rollback de release

Se uma tag publicar uma release incorreta:

1. desative distribuicao do asset ruim removendo os downloads da GitHub Release
2. se o problema afetar Windows, reverta `appcast.xml` para a ultima versao valida
3. corrija o commit em `main`
4. publique uma nova versao corrigida no ciclo normal, por exemplo `vX.Y.(Z+1)`, sem reaproveitar binarios antigos

Se a tag foi criada no commit errado antes da aprovacao do environment
`production`, prefira rejeitar a aprovacao, apagar a tag remota e recria-la no
commit correto.

## Feed oficial

[appcast.xml no GitHub Raw](https://raw.githubusercontent.com/cesar-carlos/colmeia/main/appcast.xml)

## Limites da v1

- Auto-update apenas para Windows
- Android distribuido por GitHub Release, sem Play Store automatizada
- Android sem in-app update nesta fase
- Sem DSA no feed
- Sem Authenticode
- Possiveis avisos de SmartScreen ate a fase de hardening
