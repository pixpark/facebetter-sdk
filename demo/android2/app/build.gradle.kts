plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "net.pixpark.fbexample"
    compileSdk = 34

    defaultConfig {
        applicationId = "net.pixpark.fbexample"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "2.0"
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = libs.versions.composeCompiler.get()
    }
    packaging {
        jniLibs {
            pickFirsts += setOf("**/libc++_shared.so")
        }
    }
}

val engineRoot = rootProject.file("../../../fb")
val facebetterAar = engineRoot.resolve("src/engine/android/facebetter/build/outputs/aar/facebetter.aar")
val facebetterJava = engineRoot.resolve("src/engine/android/facebetter/src/main/java")
println("[fb] android2 dep: ${if (facebetterAar.exists()) "local aar + 2.0 java sources" else "missing local aar — run ./scripts/build_android.sh"}")

val copyFacebetterAssets by tasks.registering(Copy::class) {
    val publicDir = rootProject.file("../web/react2/public")
    into(layout.buildDirectory.dir("generated/facebetterAssets"))
    from(publicDir.resolve("assets/filters")) {
        into("facebetter/filters")
    }
    from(publicDir.resolve("stickers")) {
        into("facebetter/stickers")
    }
    from(publicDir.resolve("background.jpg")) {
        into("facebetter")
    }
    from(publicDir.resolve("assets/filters/filter_mapping.json")) {
        into("facebetter")
    }
}

val extractFacebetterAar by tasks.registering(Copy::class) {
    onlyIf { facebetterAar.exists() }
    from(zipTree(facebetterAar)) {
        include("jni/**", "assets/**")
    }
    into(layout.buildDirectory.dir("extractedFacebetter"))
}

android.sourceSets.getByName("main").apply {
    java.srcDir(facebetterJava)
    assets.srcDir(layout.buildDirectory.dir("generated/facebetterAssets"))
    assets.srcDir(layout.buildDirectory.dir("extractedFacebetter/assets"))
    jniLibs.srcDir(layout.buildDirectory.dir("extractedFacebetter/jni"))
}

tasks.named("preBuild").configure {
    dependsOn(copyFacebetterAssets, extractFacebetterAar)
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(libs.lifecycle.runtime.ktx)
    implementation(libs.lifecycle.viewmodel.compose)
    implementation(libs.lifecycle.runtime.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.graphics)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons)
    implementation(libs.camera.core)
    implementation(libs.camera.camera2)
    implementation(libs.camera.lifecycle)
}
