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

Tags oficiais:

```text
vMAJOR.MINOR.PATCH
```

Exemplo:

- `pubspec.yaml`: `1.1.0+2`
- tag: `v1.1.0`

## Pre-requisitos do CI

- repository variable `FLUTTER_CI_VERSION`
- secret `APPCAST_PUSH_TOKEN` se `main` bloquear o token padrao do Actions
- secret `ANDROID_KEYSTORE_BASE64`
- secret `ANDROID_KEYSTORE_PASSWORD`
- secret `ANDROID_KEY_ALIAS`
- secret `ANDROID_KEY_PASSWORD`

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

Se quiser injetar o feed oficial no instalador local sem depender de
variaveis globais do shell, crie `.env.release` na raiz a partir de
`.env.release.example`.

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

### 6. Aguardar o workflow

O workflow `Tagged Release`:

1. valida a tag contra `pubspec.yaml`;
2. confere sincronismo dos arquivos derivados do release Windows;
3. gera `Colmeia-Setup-{versao}.exe`;
4. gera `Colmeia-Android-{versao}.apk`;
5. gera `Colmeia-Android-{versao}.aab`;
6. cria/atualiza uma unica GitHub Release com os 3 assets;
7. atualiza `appcast.xml` em `main`.

## Token para branch protegida

Por padrao o workflow tenta atualizar `appcast.xml` com `github.token`.
Se a branch `main` bloquear esse push via Contents API, crie o secret
`APPCAST_PUSH_TOKEN` com permissao de `contents:write`.

## Feed oficial

[appcast.xml no GitHub Raw](https://raw.githubusercontent.com/cesar-carlos/colmeia/main/appcast.xml)

## Limites da v1

- Auto-update apenas para Windows
- Android distribuido por GitHub Release, sem Play Store automatizada
- Android sem in-app update nesta fase
- Sem DSA no feed
- Sem Authenticode
- Possiveis avisos de SmartScreen ate a fase de hardening
