# Facebetter — Expo Prebuild Demo

Sample inside this repository at `demo/expo`, not a separate git repository. It captures the front camera and runs skin beauty. Android and iOS share the same screen. It cannot run in Expo Go.

## Run

Node `^22.13` or `^24.3`. Android needs the Android SDK and an arm64 device or emulator. iOS needs Xcode on a Mac.

```bash
cd demo/expo
npm install
npx expo run:android
npx expo run:ios
```

Each command generates that platform's native project and installs a debug build. Android debug embeds the JavaScript bundle. Run the command again after native or JavaScript changes.

## SDK

Android depends on Maven `net.pixpark:facebetter:2.2.1` (`arm64-v8a` and `armeabi-v7a`). iOS depends on CocoaPods `Facebetter` 2.2.1. Both packages include `resource.fbd`. This demo does not use the optional `resource_3d.fbd` or `resource_body.fbd` packs.

The Android package name is `net.pixpark.fbexample`. The iOS bundle id is `com.pixpark.fbdemo`, the same id as `demo/ios`. Credentials match the other samples. A different id must be bound in the console, then changed in `app.json`.

## UI

Front camera, portrait, mirrored. The requested size is 1920×1080. Android uses CameraX and may land on a nearby size, for example `camera 1920x1440`. iOS uses that capture preset, or 1280×720 when the device cannot. The status line prints the real buffer. The bottom panel adjusts Smooth, Tone, Rosy, Blemish, Clarity, and Skin only. The upper-right label is the latest `processTexture` time.
