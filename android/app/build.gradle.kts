plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadStore = System.getenv("ANDROID_KEYSTORE_PATH")
val testSigning = System.getenv("MENO_TEST_SIGNING") == "true"

android {
    namespace = "com.meno.app.meno"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    defaultConfig {
        applicationId = "com.meno.app.meno"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        if (!uploadStore.isNullOrBlank()) {
            create("upload") {
                storeFile = file(uploadStore)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                    ?: error("Missing Android store password")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                    ?: error("Missing Android key alias")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
                    ?: error("Missing Android key password")
            }
        }
    }
    buildTypes {
        release {
            // Unsigned by default. Debug signing is explicit and ONLY for test APKs.
            signingConfig = if (!uploadStore.isNullOrBlank()) signingConfigs.getByName("upload")
                else if (testSigning) signingConfigs.getByName("debug") else null
        }
    }
}
flutter { source = "../.." }
