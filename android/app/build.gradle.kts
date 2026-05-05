import org.gradle.api.GradleException
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

val releaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true)
}

fun requireSigningProperty(name: String): String {
    return keystoreProperties
        .getProperty(name)
        ?.trim()
        ?.takeIf(String::isNotEmpty)
        ?: throw GradleException(
            "Android release signing is not configured. "
                + "Missing '$name' in android/key.properties. "
                + "Copy android/key.properties.example and provide a real keystore.",
        )
}

if (releaseTaskRequested) {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "Android release signing is not configured. "
                + "Expected android/key.properties before running a release build. "
                + "Copy android/key.properties.example and point storeFile to a real .jks.",
        )
    }

    val storeFilePath = requireSigningProperty("storeFile")
    val resolvedStoreFile = rootProject.file(storeFilePath)
    if (!resolvedStoreFile.exists()) {
        throw GradleException(
            "Android release signing keystore was not found at '$storeFilePath'. "
                + "Update android/key.properties with a valid relative path.",
        )
    }
}

android {
    namespace = "br.com.se7esistemas.colmeia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "br.com.se7esistemas.colmeia"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val storeFilePath = requireSigningProperty("storeFile")
                storeFile = rootProject.file(storeFilePath)
                storePassword = requireSigningProperty("storePassword")
                keyAlias = requireSigningProperty("keyAlias")
                keyPassword = requireSigningProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
