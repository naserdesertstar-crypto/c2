plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.c2"
    
    // تم التصحيح هنا مباشرة إلى 34 ليفهمها السيرفر فوراً
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.c2"
        
        // متوافق مع مستشعر الـ NFC
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

// تم تنظيف وتصحيح هذا الجزء بالكامل ليتوافق مع أحدث إصدارات Gradle بدون أي أخطاء تجميع
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            val androidExtension = extensions.findByName("android")
            if (androidExtension != null) {
                (androidExtension as? com.android.build.api.dsl.CommonExtension<*, *, *, *, *, *>)?.apply {
                    compileSdk = 34
                }
            }
        }
    }
}