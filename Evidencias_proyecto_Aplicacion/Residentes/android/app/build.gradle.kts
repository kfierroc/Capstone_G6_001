plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.File
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

val localPropertiesFile = rootProject.file("local.properties")
val localProperties = Properties().apply {
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}

// Raíz del proyecto Flutter (padre de la carpeta android/).
val flutterProjectRoot: File = rootProject.projectDir.parentFile!!

fun readDotenvValue(dotenvFile: File, key: String): String? {
    if (!dotenvFile.exists()) return null
    return dotenvFile.readLines()
        .asSequence()
        .map { it.trim() }
        .filter { it.isNotEmpty() && !it.startsWith("#") }
        .mapNotNull { line ->
            val idx = line.indexOf('=')
            if (idx <= 0) return@mapNotNull null
            val k = line.substring(0, idx).trim()
            val v = line.substring(idx + 1).trim()
            if (k == key) v else null
        }
        .firstOrNull()
}

fun resolveGoogleMapsApiKey(): String {
    val fromLocal = (localProperties.getProperty("MAPS_API_KEY") ?: "").trim()
    if (fromLocal.isNotEmpty()) return fromLocal
    val fromDotenv = (readDotenvValue(flutterProjectRoot.resolve(".env"), "GOOGLE_MAPS_API_KEY") ?: "").trim()
    return fromDotenv
}

android {
    namespace = "com.example.residentes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requerido por flutter_local_notifications (core library desugaring).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.residentes"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Maps SDK for Android (google_maps_flutter) requiere al menos API 21.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Maps Android SDK: key en AndroidManifest (misma que GOOGLE_MAPS_API_KEY en .env).
        val mapsApiKey = resolveGoogleMapsApiKey()
        if (mapsApiKey.isEmpty()) {
            logger.warn(
                "GOOGLE_MAPS_API_KEY no encontrada. Revisa Residentes/.env o android/local.properties (MAPS_API_KEY).",
            )
        }
        manifestPlaceholders["googleMapsApiKey"] = mapsApiKey
        resValue("string", "google_maps_api_key", mapsApiKey)
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Firma de producción: requiere android/key.properties.
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring de librerías Java para dependencias que lo requieren.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
