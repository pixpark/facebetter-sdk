import java.util.Properties

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

val localProps = Properties()
rootProject.file("local.properties").takeIf { it.exists() }?.reader()?.use { localProps.load(it) }

fun sdkProp(name: String): String? =
    (findProperty(name) as String?) ?: localProps.getProperty(name)

val useLocalSdk = sdkProp("facebetter.local").equals("true", ignoreCase = true)
val engineRoot = rootProject.file("../../../fb")
val defaultLocalAar = engineRoot.resolve("src/engine/android/facebetter/build/outputs/aar/facebetter.aar")
val localAar = sdkProp("facebetter.localAar")?.let { rootProject.file(it) } ?: defaultLocalAar

if (useLocalSdk) {
    require(localAar.isFile) {
        "facebetter.local=true but AAR not found:\n  ${localAar.absolutePath}\n" +
            "Build it with: cd ${engineRoot.absolutePath} && ./scripts/build_android.sh"
    }
    println("[fb] android demo: local AAR ${localAar.absolutePath}")
} else {
    println("[fb] android demo: Maven net.pixpark:facebetter:${libs.versions.facebetter.get()}")
}

val copyFacebetterAssets by tasks.registering(Copy::class) {
    val publicDir = rootProject.file("../web/react/public")
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

android.sourceSets.getByName("main").apply {
    assets.srcDir(layout.buildDirectory.dir("generated/facebetterAssets"))
}

tasks.named("preBuild").configure {
    dependsOn(copyFacebetterAssets)
}

dependencies {
    if (useLocalSdk) {
        implementation(files(localAar))
        implementation(libs.appcompat)
        implementation(libs.material)
    } else {
        implementation(libs.facebetter)
    }
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
