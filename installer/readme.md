# Instalador Windows - Colmeia

Scripts e arquivos do instalador Windows do Colmeia.

## Onde cada env entra (matriz)

| Contexto | Onde configurar | O que afeta |
|----------|-----------------|---------------|
| App em runtime (API, Sentry, socket, E2E) | `assets/env/default.env`, opcional `assets/env/local.env`, `--dart-define` | Dart `AppEnvironment` apos `loadAppDotenv()` |
| Build do instalador Windows local | processo: `AUTO_UPDATE_FEED_URL`; ou `.env.release`; ou `COLMEIA_RELEASE_ENV_FILE` → ficheiro extra | `flutter build windows --release` recebe `--dart-define=AUTO_UPDATE_FEED_URL=...` |
| CI (GitHub Actions, tag `v*.*.*`) | env do job: `AUTO_UPDATE_FEED_URL` (default aponta ao `appcast.xml` no repo); opcional variavel de repositorio **`APPCAST_FEED_URL`** para substituir o URL | Mesmo `dart-define`; **nao** usa `.env.release` no runner |
| Release checklist | Antes de distribuir um `.exe` local: verificar `assets/env/local.env` — se existir com entradas, pode ir embutido no bundle (`pubspec.yaml` assets) | Evitar fugir segredos em builds que partilha |

## Estrutura

```text
installer/
|-- build_installer.py       # sync opcional + ICO + flutter build + refresh ICO + ISCC
|-- setup_icon.ico           # gerado (gitignored); icone do Setup.exe — ver `SetupIconFile`
|-- ci_print_release_metadata.py  # saida GITHUB_OUTPUT no workflow de tag
|-- pubspec_version.py       # parsing de version em pubspec (partilhado)
|-- setup.iss                # script Inno Setup
|-- update_version.py        # sincroniza pubspec.yaml -> setup.iss/app_version.g.dart
`-- dist/                    # saida local do instalador (gitignored)
```

## Saida esperada

```text
installer/dist/Colmeia-Setup-{MAJOR.MINOR.PATCH}.exe
```

Antes do Inno Setup, `build_installer.py` remove `Colmeia-Setup-*.exe` e `.sha256`
correspondentes em `installer/dist/` para nao ficar o instalador errado por data.

## Requisitos locais

- Flutter no `PATH`
- Python 3.8+
- Inno Setup 6 com `ISCC` disponivel
- Windows com toolchain de build Flutter configurada

## Uso recomendado

```powershell
python installer/build_installer.py
```

O script:

1. sincroniza `installer/setup.iss` e `lib/core/constants/app_version.g.dart`
   (**omitido** se `COLMEIA_SKIP_VERSION_SYNC=1`, usado no CI apos `update_version.py`);
2. gera `windows/runner/resources/app_icon.ico` e `installer/setup_icon.ico` (16–256 px)
   a partir de `assets/icons/colmeia-512.png` (`tool/generate_windows_app_icon.dart`);
3. executa `flutter build windows --release`
   (emite aviso se `assets/env/local.env` tiver linhas nao comentadas — pode ir no bundle);
4. volta a gerar os ICO (o Flutter pode substituir `app_icon.ico` no runner; o Inno usa
   `installer/setup_icon.ico`, fora de `windows/`, para o icone do Setup.exe);
5. compila o instalador via Inno Setup (`SetupIconFile=setup_icon.ico`).

Observacao de seguranca: se `assets/env/local.env` tiver linhas nao comentadas,
o build local agora falha por padrao para evitar empacotar segredos no bundle.
Se voce realmente quiser seguir mesmo assim, use
`COLMEIA_ALLOW_BUNDLED_LOCAL_ENV=1` de forma explicita.

Se a variavel `AUTO_UPDATE_FEED_URL` estiver definida no ambiente do processo
ou em arquivo de release, o build injeta:

```text
--dart-define=AUTO_UPDATE_FEED_URL=...
```

Precedencia do `installer/build_installer.py`:

1. variavel de ambiente do processo;
2. arquivo apontado por `COLMEIA_RELEASE_ENV_FILE`;
3. `.env.release` na raiz do projeto.

Valores vazios (`AUTO_UPDATE_FEED_URL=`) num ficheiro **nao bloqueiam** o seguinte
na lista — o script ignora e continua.

## Troubleshooting do icone do instalador

Se so `installer/dist/Colmeia-Setup-X.Y.Z.exe` aparecer com o icone antigo no
Explorer, isso tende a ser cache do shell do Windows para o mesmo
caminho/ficheiro, nao falha do pipeline.

O build do instalador:

1. gera `installer/setup_icon.ico` a partir de `assets/icons/colmeia-512.png`;
2. recompila o ICO antes e depois do `flutter build windows`;
3. passa esse arquivo para o Inno Setup em `SetupIconFile=setup_icon.ico`.

Durante iteracoes locais na mesma versao, o Explorer pode manter o icone antigo
mesmo apos o `.exe` ser recriado. Antes de assumir regressao no build:

- teste o artefato com outro nome ou noutra maquina;
- reinicie o Explorer ou limpe o icon cache;
- gere a proxima versao quando quiser validar o nome final oficial do asset.

Modelo versionado na raiz: **`.env.example`**. Copie para **`.env.release`**
para embutir o feed no build do instalador; nao commite o destino.

### Variavel de repositorio GitHub (opcional)

No repositorio GitHub: **Settings → Secrets and variables → Actions → Variables**,
crie **`APPCAST_FEED_URL`** se quiser um URL de appcast fixo diferente do padrao
`https://raw.githubusercontent.com/<repo>/main/appcast.xml` usado no workflow
de release.

## Fluxo manual

```powershell
dart run tool/generate_windows_app_icon.dart
python installer/update_version.py
flutter build windows --release
dart run tool/generate_windows_app_icon.dart
ISCC installer/setup.iss
```

## Documentacao relacionada

- [docs/install/readme.md](../docs/install/readme.md)
- [docs/install/release_guide.md](../docs/install/release_guide.md)
- [docs/install/auto_update_setup.md](../docs/install/auto_update_setup.md)
