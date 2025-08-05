plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
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
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Ganti applicationId sesuai dengan ID aplikasi yang unik
        applicationId = "id.ginio.infoev"
        // Pastikan ini sesuai dengan kebutuhan aplikasi Anda
        minSdk = 23
        targetSdk = 35
        versionCode = 8
        versionName = "1.0.8"
    }

    signingConfigs {
        val storePassword = System.getenv("KEYSTORE_PASSWORD")
        val keyAlias = System.getenv("KEY_ALIAS")
        val keyPassword = System.getenv("KEY_PASSWORD")

        if (!storePassword.isNullOrEmpty() && !keyAlias.isNullOrEmpty() && !keyPassword.isNullOrEmpty()) {
            val keystorePath = System.getenv("KEYSTORE_PATH") ?: "../../infoev-release.jks"

            create("release") {
                storeFile = file(keystorePath)
                this.storePassword = storePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            }
        }
    }



    buildTypes {
        release {
            // Enable these optimizations
            isMinifyEnabled = true 
            isShrinkResources = true
            
            // Recommended Play Store settings
            // signingConfig = signingConfigs.getByName("release")

            // Apply signingConfig only if it's defined
            if (signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            }

            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    } 
}

flutter {
    source = "../.." // Path ke direktori Flutter SDK
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}