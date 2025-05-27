plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin") 
}

android {
    namespace = "id.ginio.infoev" // Sesuaikan dengan nama package Anda
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456" // Pastikan versi NDK sesuai dengan yang Anda perlukan

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Ganti applicationId sesuai dengan ID aplikasi yang unik
        applicationId = "id.ginio.infoev"
        // Pastikan ini sesuai dengan kebutuhan aplikasi Anda
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Konfigurasi untuk release, jika perlu tambahkan signingConfig sesuai dengan keperluan
            signingConfig = signingConfigs.getByName("debug")
        }
    } 
}

flutter {
    source = "../.." // Path ke direktori Flutter SDK
}
