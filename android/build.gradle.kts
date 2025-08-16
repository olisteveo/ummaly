// ✅ Top-level Gradle build file for Ummaly (Project-level)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Google Services Gradle plugin for Firebase support
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Keep your custom build directory logic
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// -------------------------------------------------------------------------------------
// 🔧 THE IMPORTANT BIT: unify Kotlin/Java targets for *all* subprojects (plugins too)
// - We DO NOT use Java toolchains (avoids the '--release' error in Android builds)
// - We set the JavaCompile tasks to 11 and Kotlin jvmTarget to 11
// - Done via task configuration so we don't mutate Android DSL after it's finalized
// -------------------------------------------------------------------------------------
subprojects {
    // All Java compile tasks -> 11 (no --release)
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "11"
        targetCompatibility = "11"
        // Make sure the Android bootclasspath mechanism is used, not --release
        if (options.release.isPresent) {
            options.release.set(null as Int?)
        }
    }

    // All Kotlin compile tasks -> jvmTarget 11
    plugins.withId("org.jetbrains.kotlin.android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = "11"
        }
    }
}

// ✅ Clean task (keeps project tidy)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
