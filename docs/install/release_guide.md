# Guia de Release e Versionamento

Fluxo oficial de versionamento e release Windows + Android do Colmeia.

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
Variables). Compare com `flutter --version` na maquina de release.

Pastas **`build/`** e **`installer/dist/`** estao no `.gitignore` e nao devem ser
commitadas.

## Icones do launcher

Ao alterar PNGs em **`assets/icons/`** (por exemplo `colmeia-512.png`):

1. `dart run flutter_launcher_icons`
2. Revise e commit dos ficheiros gerados por plataforma (Android, iOS, Web,
   Windows, etc., conforme o diff).
3. Para o instalador Windows refletir o novo `app_icon.ico`: `python installer/build_installer.py`

**Nota:** o projeto nao inclui a pasta `macos/`; quando existir suporte macOS,
adicione o bloco `macos:` em `flutter_launcher_icons` no `pubspec.yaml` e volte a
correr o comando acima.

## Feed do auto-update no instalador local

Para embutir o URL do appcast no `.exe` gerado por `build_installer.py`, copie
**`.env.release.example`** para **`.env.release`** na raiz e ajuste se necessario.
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
flutter analyze
flutter test
flutter build apk --debug
python installer/build_installer.py
```

Para o feed oficial no `.exe` gerado localmente, veja a secao **Feed do auto-update no instalador local** acima (copie `.env.release.example` para `.env.release`).

Se a keystore Android ja estiver configurada localmente, valide tambem:

```powershell
flutter build apk --release
flutter build appbundle --release
```

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
