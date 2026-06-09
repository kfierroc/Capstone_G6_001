plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun leerGoogleMapsApiKeyDesdeEnv(): String {
    val envFile = rootProject.file("../.env")
    if (!envFile.exists()) return ""
    envFile.readLines().forEach { line ->
        val trimmed = line.trim()
        if (trimmed.startsWith("GOOGLE_MAPS_API_KEY=")) {
            return trimmed.removePrefix("GOOGLE_MAPS_API_KEY=").trim()
        }
    }
    return ""
}

android {
    namespace = "com.capstone.g6.bomberos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.capstone.g6.bomberos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val mapsKey = leerGoogleMapsApiKeyDesdeEnv()
        if (mapsKey.isNotEmpty()) {
            resValue("string", "google_maps_api_key", mapsKey)
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
