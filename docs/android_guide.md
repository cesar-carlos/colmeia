# Guia Android — Colmeia

Guia prático para build, publicação e manutenção do app **Colmeia** no Android.
Para iOS/TestFlight, veja [ios_guide.md](install/ios_guide.md). Valores abaixo refletem o estado atual do repositório (Flutter + Gradle Kotlin DSL).

## Pré-requisitos

- **Flutter** compatível com `pubspec.yaml` (`sdk: ^3.11.0`). Confira com `flutter doctor -v`.
- **JDK 17** — o módulo `:app` define Java 17 em `compileOptions` e alinha o Kotlin com `tasks.withType<KotlinCompile> { compilerOptions.jvmTarget = JVM_17 }` em `android/app/build.gradle.kts`. Plugins Flutter legados em outros subprojetos herdam o alinhamento via `android/build.gradle.kts`.
- **Android SDK** instalado (via Android Studio ou `sdkmanager`). O `compileSdk`, `minSdk` e `targetSdk` seguem as versões definidas pelo **Flutter** (`flutter.compileSdkVersion`, `flutter.minSdkVersion`, `flutter.targetSdkVersion` no `build.gradle.kts` do app).
- Arquivo **`android/local.properties`** gerado pelo Flutter/Android Studio com `sdk.dir` e `flutter.sdk` (não versionar credenciais ou caminhos sensíveis se a política do time exigir).

## Identidade do aplicativo

| Item | Valor |
| --- | --- |
| Application ID | `br.com.se7esistemas.colmeia` |
| Namespace (Gradle) | `br.com.se7esistemas.colmeia` |
| Classe principal | `br.com.se7esistemas.colmeia.MainActivity` (Flutter embedding v2) |

Versão exposta no app: **`version`** + **`versionCode`** em `pubspec.yaml` (`version: x.y.z+build` → `versionName` / `versionCode`).

## Stack de build (referência)

- **Android Gradle Plugin:** `8.11.1` (`android/settings.gradle.kts`)
- **Kotlin:** `2.2.20`
- **Gradle Wrapper:** `8.14` (`android/gradle/wrapper/gradle-wrapper.properties`)
- **Desugaring:** habilitado; dependência `desugar_jdk_libs:2.1.4` no `app/build.gradle.kts`

## Executar e depurar

Na raiz do projeto:

```bash
flutter pub get
flutter devices
flutter run
```

Release local (útil para testar performance):

```bash
flutter run --release
```

## Artefatos de release

- **Fluxo local recomendado para exportar para `installer/dist`:**

  ```bash
  python tool/build_android_release.py --apk
  python tool/build_android_release.py --aab
  ```

  Saídas:
  - `installer/dist/Colmeia-Android-X.Y.Z.apk`
  - `installer/dist/Colmeia-Android-X.Y.Z.apk.sha256`
  - `installer/dist/Colmeia-Android-X.Y.Z.aab`
  - `installer/dist/Colmeia-Android-X.Y.Z.aab.sha256`

- **APK:**

  ```bash
  flutter build apk --release
  ```

  Saída bruta do Flutter: `build/app/outputs/flutter-apk/app-release.apk`.

- **App Bundle (Play Store):**

  ```bash
  flutter build appbundle --release
  ```

  Saída bruta do Flutter: `build/app/outputs/bundle/release/app-release.aab`.

## Assinatura (release)

`flutter build apk --release` e `flutter build appbundle --release` exigem `android/key.properties` com keystore válido. O Gradle valida o arquivo antes de compilar release (caminho relativo a `android/`, keystore dentro de `android/`).

Para produção local:

1. Gere um keystore (ou use o keystore da empresa).
2. Copie `android/key.properties.example` para `android/key.properties` e preencha `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
3. **Nunca** commite senhas ou arquivos `.jks` em repositório público.

No **CI** (`flutter_ci.yml`), o job `android_release_smoke` gera um keystore efêmero só para compilar release e detectar erros de build; não substitui os secrets de assinatura usados em `windows_release.yml` para artefatos de loja.

Consulte a documentação oficial do Flutter: [Sign the app](https://docs.flutter.dev/deployment/android#sign-the-app).

## Páginas de 16 KB (Android 15+ / Galaxy S24)

A partir do Android 15, dispositivos com **page size de 16 KB** (ex.: Galaxy S24 em builds recentes) exigem que bibliotecas nativas (`.so`) estejam alinhadas para 16 KB. Builds Flutter recentes e o NDK do projeto já endereçam isso na maioria dos casos; valide em hardware ou emulador 16 KB antes de publicar.

**Como testar:**

1. Use um emulador Android 15+ com imagem **16 KB page size** (Android Studio → Device Manager → criar AVD com system image marcada como 16 KB), ou um Galaxy S24 (ou equivalente) com Android 15+.
2. Instale um build release assinado: `flutter build apk --release` (com `key.properties`) e `adb install`.
3. Abra o app, exercite fluxos com plugins nativos (câmera, arquivos, notificações) e monitore `adb logcat` por falhas de carregamento de `.so` ou crashes na inicialização.

**Verificação automatizada (CI e local):**

`ash
python tool/check_apk_native_alignment.py build/app/outputs/flutter-apk/app-release.apk
`

O job ndroid_release_smoke em .github/workflows/flutter_ci.yml executa esse script após lutter build apk --release.

Se o app falhar só em 16 KB, atualize Flutter/NDK/plugins para versões compatíveis e recompile; consulte [Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes) na documentação Android.


## Backup e extração de dados

O app define ndroid:allowBackup="false" e regras explícitas em:

- ndroid/app/src/main/res/xml/backup_rules.xml (ndroid:fullBackupContent)
- ndroid/app/src/main/res/xml/data_extraction_rules.xml (ndroid:dataExtractionRules)

Isso evita backup em nuvem ou transferência entre dispositivos de dados locais (Hive, preferências, cache).
## Deep links e App Links

O `AndroidManifest.xml` declara `intent-filter` com `android:autoVerify="true"` para URLs HTTPS do host **`plug-server.se7esistemassinop.com.br`**, incluindo prefixos de revisão de recuperação de senha e registro (com e sem prefixo `/api/v1`).

Para links abrirem o app automaticamente no dispositivo:

- O domínio precisa servir o **Digital Asset Links** correto apontando para o app com o `applicationId` acima e o fingerprint do certificado de **release** (ou o que a Play Store assina com App Signing).
- Teste com `adb` e o verificador de links do sistema após instalar um build assinado como na loja.

## Permissões e rede

- **`INTERNET`** declarada no manifest — necessária para API e recursos remotos.
- Sem permissões de armazenamento amplas no manifest principal; plugins (ex.: `image_picker`) podem adicionar regras ou usages em tempo de execução conforme a versão do Android.

## Limpeza e problemas comuns

```bash
flutter clean
flutter pub get
cd android
./gradlew clean   # ou gradlew.bat clean no Windows
```

- **Erro de SDK / Flutter path:** confira `local.properties` (`sdk.dir`, `flutter.sdk`).
- **Incompatibilidade de Java:** use JDK 17 alinhado ao `build.gradle.kts`.
- **Falha de plugin:** rode `flutter pub get` e, se necessário, invalide caches no Android Studio.

## Onde está cada coisa

| Assunto | Arquivo / pasta |
| --- | --- |
| App ID, Kotlin, desugaring, signing | `android/app/build.gradle.kts` |
| Versões AGP / Kotlin | `android/settings.gradle.kts` |
| Manifest, label, ícone, deep links | `android/app/src/main/AndroidManifest.xml` |
| Activity | `android/app/src/main/kotlin/br/com/se7esistemas/colmeia/MainActivity.kt` |
| Recursos (ícones, temas) | `android/app/src/main/res/` |

## Checklist rápido antes da Play Store

- [ ] `version` + build em `pubspec.yaml` atualizados
- [ ] Build release assinado com keystore de produção
- [ ] App Links / deep links validados com asset links e certificado correto
- [ ] Teste em dispositivo físico (`profile`/`release`) para jank e rede
- [ ] Política de privacidade e permissões alinhadas ao que o app realmente usa
