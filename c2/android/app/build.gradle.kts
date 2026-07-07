plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.c2"
    
    compileSdk = 3
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // تم تصحيح الحرف الإملائي هنا إلى Id كابيتال
        applicationId = "com.example.c2"
        
        // تم تعديل هذا السطر مباشرة إلى 21 ليتوافق مع مستشعر الـ NFC ومكتبة nfc_manager
        minSdk = 21
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// تم تحديث هذا الجزء ليصبح متوافقاً مع Gradle الحديث (AGP 9.0+) وبدون التحذيرات السابقة
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.api.dsl.CommonExtension<*, *, *, *, *, *>> {
                compileSdk = 34
            }
        }
    }
}