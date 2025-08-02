plugins {
    id("com.android.application")
    id("kotlin-android")
    // ✅ Google Services plugin for Firebase
    id("com.google.gms.google-services")
    // ✅ Flutter Gradle Plugin must be applied last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ummaly.app"   // ✅ MATCHES Firebase & Manifest
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"   // ✅ Ensures NDK version matches plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.ummaly.app"   // ✅ MUST MATCH google-services.json
        minSdk = 23                        // ✅ Needed for Firebase
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ✅ Debug signing so flutter run --release works
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ✅ Google Services must be applied AFTER everything else
apply(plugin = "com.google.gms.google-services")
