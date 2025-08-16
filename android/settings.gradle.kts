pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // Prefer project repositories but don’t hard-fail; keeps Flutter/plugins happy
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    // ✅ Keep Kotlin aligned with your environment; matches what you’ve been using
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // ✅ Expose Google Services plugin via the modern plugins DSL (app module will `apply false` / `apply plugin`)
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
