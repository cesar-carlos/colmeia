# Instalador Windows - Colmeia

Scripts e arquivos do instalador Windows do Colmeia.

## Estrutura

```text
installer/
|-- build_installer.py  # sincroniza versao + flutter build windows + ISCC
|-- setup.iss           # script Inno Setup
|-- update_version.py   # sincroniza pubspec.yaml -> setup.iss/app_version.g.dart
`-- dist/               # saida local do instalador (gitignored)
```

## Saida esperada

```text
installer/dist/Colmeia-Setup-{MAJOR.MINOR.PATCH}.exe
```

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

1. sincroniza `installer/setup.iss` e `lib/core/constants/app_version.g.dart`;
2. executa `flutter build windows --release`;
3. compila o instalador via Inno Setup.

Se a variavel `AUTO_UPDATE_FEED_URL` estiver definida no ambiente do processo
ou em um arquivo de release, o build injeta:

```text
--dart-define=AUTO_UPDATE_FEED_URL=...
```

Precedencia do `installer/build_installer.py`:

1. variavel de ambiente do processo;
2. arquivo apontado por `COLMEIA_RELEASE_ENV_FILE`;
3. `.env.release` na raiz do projeto;
4. `.env` na raiz do projeto como fallback legado.

Modelo versionado na raiz do repositorio: **`.env.release.example`** (copie para
`.env.release`; nao commite o destino).

## Fluxo manual

```powershell
python installer/update_version.py
flutter build windows --release
ISCC installer/setup.iss
```

## Documentacao relacionada

- [docs/install/readme.md](../docs/install/readme.md)
- [docs/install/release_guide.md](../docs/install/release_guide.md)
- [docs/install/auto_update_setup.md](../docs/install/auto_update_setup.md)
