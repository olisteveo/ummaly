plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // Firebase
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin last
}

android {
    namespace = "com.ummaly.app"
    compileSdk = flutter.compileSdkVersion

    // ✅ Use explicit compileOptions (Java 11)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    // ✅ Kotlin JVM target 11 (matches Java above)
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        // Optional: keep incremental off for stability on low-RAM
        // freeCompilerArgs += listOf("-Xuse-k2")
    }

    defaultConfig {
        applicationId = "com.ummaly.app"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use debug signing so `flutter run --release` works locally
            signingConfig = signingConfigs.getByName("debug")
            // You can enable minify later if you want
            // isMinifyEnabled = false
        }
    }

    // Some plugins still read this flag; keep it true for legacy stability
    packaging {
        // nothing special right now
    }
}

flutter {
    source = "../.."
}

// (No toolchain config here on purpose)
