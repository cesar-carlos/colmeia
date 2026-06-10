# Guia iOS — Colmeia

Guia prático para build, upload no TestFlight e manutenção do app **Colmeia** no iOS.

## Pré-requisitos

- **macOS** com **Xcode** instalado (versão compatível com o Flutter do projeto).
- **Flutter** alinhado ao pin do repositório: compare `flutter --version` com
  `tool/flutter_ci_version.txt` (e com a variável `FLUTTER_CI_VERSION` no GitHub
  Actions, quando configurada).
- Conta **Apple Developer** com acesso ao app no App Store Connect.
- **Team ID** `3D667WT85U` configurado no projeto Xcode (`DEVELOPMENT_TEAM`).

## Identidade do aplicativo

| Item | Valor |
| --- | --- |
| Bundle ID | `br.com.se7esistemas.colmeia` |
| Display name | Colmeia |
| Deployment target | iOS 13.0 |

Versão exposta no app: **`version`** + build em `pubspec.yaml` (`version: x.y.z+build`).

## Executar e depurar

Na raiz do projeto:

```bash
flutter pub get
flutter devices
flutter run
```

## Artefato de release (App Store / TestFlight)

### Fluxo local recomendado

```bash
python tool/build_ios_release.py
```

Saídas em `installer/dist/`:

- `Colmeia-iOS-X.Y.Z.ipa`
- `Colmeia-iOS-X.Y.Z.ipa.sha256`

O script executa:

```bash
flutter build ipa --export-options-plist=ios/ExportOptions-appstore.plist
```

### Build manual equivalente

```bash
flutter build ipa --export-options-plist=ios/ExportOptions-appstore.plist
```

IPA gerado em `build/ios/ipa/colmeia.ipa`.

## Upload para o TestFlight

Após o build:

1. **Transporter** (Mac App Store): arraste `colmeia.ipa` ou o artefato em
   `installer/dist/`.
2. **Xcode Organizer**: abra o archive em
   `build/ios/archive/Colmeia.xcarchive` → **Distribute App** →
   **App Store Connect** → **Upload**.
3. **CLI** (com API Key do App Store Connect):

   ```bash
   xcrun altool --upload-app --type ios \
     -f build/ios/ipa/colmeia.ipa \
     --apiKey YOUR_KEY_ID \
     --apiIssuer YOUR_ISSUER_ID
   ```

## Pós-upload no App Store Connect

1. Aguarde o processamento do build (TestFlight → iOS builds).
2. Responda **Export Compliance** quando solicitado.
3. Adicione o build a um grupo de **Internal Testing** ou **External Testing**.
4. Teste externo pode exigir **Beta App Review** na primeira publicação.

Link direto (substitua o app id se mudar):

https://appstoreconnect.apple.com/apps/6762572007/testflight/ios

## Validação antes do release

```bash
flutter analyze --fatal-warnings --no-fatal-infos
flutter test test/app test/core test/features test/shared \
  test/integration/dart_test_config_contract_test.dart \
  --exclude-tags e2e
python tool/build_ios_release.py
```

## Notas

- O CI do repositório valida compilação iOS com
  `flutter build ios --release --no-codesign` em runner macOS (sem assinatura).
- Upload e distribuição TestFlight permanecem manuais nesta fase; use API Key
  ou Transporter para automação futura.
- Pastas `build/` e `installer/dist/` estão no `.gitignore` e não devem ser
  commitadas.
