// ✅ Top-level Gradle build file for Ummaly (Project-level)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Add the Google Services Gradle plugin for Firebase support
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

subprojects {
    project.evaluationDependsOn(":app")
}

// ✅ Clean task (keeps project tidy)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
