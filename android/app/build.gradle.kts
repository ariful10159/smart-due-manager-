import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Release signing credentials are read from android/key.properties, which is
// git-ignored and never committed. See android/key.properties.example for the
// expected format. Locally/CI environments without this file fall back to the
// debug signing config so `flutter run --release` keeps working during development.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.masum.smart_due_personal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 1. Enable core library desugaring here
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.masum.smart_due_personal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // ✅ Uses the dedicated release keystore when android/key.properties is
            // present (real releases / CI with secrets injected). Falls back to the
            // debug keystore only for local dev builds where no key.properties exists,
            // matching previous behavior so `flutter run --release` still works.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // ✅ R8 minification (Flutter/AGP এর ডিফল্ট) কোনো proguard keep-rules
            // ছাড়াই চালু ছিল — এটা reflection-নির্ভর প্লাগইনের (Firebase,
            // permission_handler, flutter_local_notifications ইত্যাদি) প্রয়োজনীয়
            // ক্লাস strip করে দিচ্ছিল, ফলে release build এ main() silently hang
            // করে কালো স্ক্রিনে আটকে থাকত (কোনো crash/exception ছাড়াই — profile ও
            // debug build এ minification না থাকায় ঠিকভাবে চলত)। সঠিক keep-rules
            // ছাড়া মিনিফিকেশন চালু রাখা নিরাপদ নয়, তাই বন্ধ করা হলো।
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// 2. Add this dependencies block at the bottom for Kotlin DSL
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}