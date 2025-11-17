import java.util.Properties
import java.io.FileInputStream

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
    println("--- KEY PROPERTIES FOUND ---")
}


val storeFilePath = keyProperties["storeFile"]?.toString()

val fileName: File = storeFilePath?.let { path ->
    val fileObject = project.file(path) 
    
    
    if (!fileObject.exists()) {
        error("Keystore file not found! File object does not exist at: ${fileObject.absolutePath}")
    }
    return@let fileObject
}?: error("Keystore file not found! Check key.properties path.")
val passwordName = keyProperties["storePassword"]?.toString() ?: error("storePassword missing in key.properties")
val aliasName = keyProperties["keyAlias"]?.toString() ?: error("keyAlias missing in key.properties")
val keyPasswordName = keyProperties["keyPassword"]?.toString() ?: error("keyPassword missing in key.properties")

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.2" apply false
}

android {
    namespace = "com.fsolutions.travellog3"
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
        applicationId = "com.fsolutions.travellog3"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
    create("release") {
        keyAlias = aliasName
        keyPassword = keyPasswordName
        storeFile = fileName
        storePassword = passwordName
    }
}

    buildTypes {
        debug {
          
        }
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
apply(plugin = "com.google.gms.google-services")

flutter {
    source = "../.."
}
