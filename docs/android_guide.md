# Guia Android — Colmeia

Guia prático para build, publicação e manutenção do app **Colmeia** no Android. Valores abaixo refletem o estado atual do repositório (Flutter + Gradle Kotlin DSL).

## Pré-requisitos

- **Flutter** compatível com `pubspec.yaml` (`sdk: ^3.11.0`). Confira com `flutter doctor -v`.
- **JDK 17** — o módulo Android usa `sourceCompatibility` / `targetCompatibility` e `jvmTarget` em **17** (`android/app/build.gradle.kts`).
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

- **APK:**

  ```bash
  flutter build apk --release
  ```

  Saída típica: `build/app/outputs/flutter-apk/app-release.apk`.

- **App Bundle (Play Store):**

  ```bash
  flutter build appbundle --release
  ```

  Saída típica: `build/app/outputs/bundle/release/app-release.aab`.

## Assinatura (release)

No `android/app/build.gradle.kts`, o bloco `release` ainda aponta para **`signingConfigs.debug`** com comentário de TODO. Isso serve para `flutter run --release` em desenvolvimento, **não** para publicação na Play Store.

Para produção:

1. Gere um keystore (ou use o keystore da empresa).
2. Crie `android/key.properties` (ou equivalente seguro no CI) com `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
3. Configure `signingConfigs.release` no `app/build.gradle.kts` e associe `buildTypes.release` a essa config.
4. **Nunca** commite senhas ou arquivos `.jks` em repositório público.

Consulte a documentação oficial do Flutter: [Sign the app](https://docs.flutter.dev/deployment/android#sign-the-app).

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
