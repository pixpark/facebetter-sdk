# Facebetter — Expo Prebuild Android Demo

Sample inside this repository at `demo/expo`, not a separate git repository. It captures the camera and runs skin beauty through the Android SDK. It cannot run in Expo Go. Prebuild the native project, then compile it.

## Run

Node `^22.13` or `^24.3`, plus the Android SDK. Use an arm64 device or an arm64 emulator. The AAR ships `arm64-v8a` and `armeabi-v7a` only.

```bash
cd demo/expo
npm install
npx expo run:android
```

`expo run:android` generates `android/` and installs a debug build with the JavaScript bundle inside the APK. The phone does not need Metro. Run it again after Kotlin or JavaScript changes.

## SDK

The native module depends on Maven `net.pixpark:facebetter:2.2.1`. That package contains `libfacebetter.so` (`arm64-v8a`, `armeabi-v7a`) and `assets/resource.fbd`. Skin beauty reads its models and lookup images from that pack. This demo does not use the optional `resource_3d.fbd` or `resource_body.fbd` packs.

The package name is `net.pixpark.fbexample`. Credentials live in `modules/facebetter-camera/.../SkinEngine.kt` and match the Android demo. A different package name must be bound in the console, and `android.package` in `app.json` must change with it.

## UI

Front camera. The requested size is 1920×1080. If the device has no exact match, CameraX picks the closest higher size. The status line prints the real buffer, for example `camera 1920x1440`. The bottom panel adjusts Smooth, Tone, Rosy, Blemish, Clarity, and Skin only.
