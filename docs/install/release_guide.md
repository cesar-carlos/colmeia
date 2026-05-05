# Guia de Release e Versionamento

Fluxo oficial de versionamento e release Windows do Colmeia.

## Fonte de verdade da versao

- `pubspec.yaml`: versao canonica no formato `MAJOR.MINOR.PATCH+BUILD`
- `installer/setup.iss`: derivado da versao curta
- `lib/core/constants/app_version.g.dart`: derivado da versao completa

Tags oficiais:

```text
vMAJOR.MINOR.PATCH
```

Exemplo:

- `pubspec.yaml`: `1.1.0+2`
- tag: `v1.1.0`

## Processo recomendado

### 1. Atualizar a versao

Edite `pubspec.yaml`:

```yaml
version: 1.1.1+3
```

### 2. Sincronizar arquivos derivados

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
python installer/build_installer.py
```

Se quiser injetar o feed oficial no instalador local sem depender de
variaveis globais do shell, crie `.env.release` na raiz a partir de
`.env.release.example`.

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

O workflow `Windows Release`:

1. valida a tag contra `pubspec.yaml`;
2. confere sincronismo dos arquivos derivados;
3. builda o app Windows;
4. gera `Colmeia-Setup-{versao}.exe`;
5. cria/atualiza a GitHub Release;
6. atualiza `appcast.xml` em `main`.

## Token para branch protegida

Por padrao o workflow tenta atualizar `appcast.xml` com `github.token`.
Se a branch `main` bloquear esse push via Contents API, crie o secret
`APPCAST_PUSH_TOKEN` com permissao de `contents:write`.

## Feed oficial

[appcast.xml no GitHub Raw](https://raw.githubusercontent.com/cesar-carlos/colmeia/main/appcast.xml)

## Limites da v1

- Auto-update apenas para Windows
- Sem DSA no feed
- Sem Authenticode
- Possiveis avisos de SmartScreen ate a fase de hardening
