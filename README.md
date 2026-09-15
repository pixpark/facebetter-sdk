<h1 align="center">
  <a href="https://www.facebetter.net"><img src="./assets/logo-light.svg" alt="Facebetter Logo" width="200"></a>
</h1>
 
<p align="center">
  <a href="https://www.facebetter.net" target="_blank">Website</a>
  <span> · </span>
  <a href="https://facebetter.net/docs" target="_blank">Document</a>
</p>

## Introduction

Sample apps for the **Facebetter SDK**. Clone this repository, then open the demo for your platform. iOS and Android share filter / sticker assets with the Web demo, so keep the repo intact when you build those apps.

| Platform | Sample | Install |
| --- | --- | --- |
| iOS | `demo/ios` | `pod install` — CocoaPods `Facebetter` **2.0.1**. Open `FBDemo.xcworkspace` |
| Android | `demo/android` | Maven Central `net.pixpark:facebetter:2.0.1`. Open the folder in Android Studio |
| Web | `demo/web/react` | `npm install` — npm `facebetter@2.0.1` |
| macOS | `demo/macos` | `pod install` — CocoaPods `Facebetter` **2.0.1**. Open the `.xcworkspace` |
| Desktop C++ | `demo/cpp` | Unzip the C++ SDK into `demo/cpp/sdk/`, then `cmake -B build`. See the [Windows](https://facebetter.net/docs/windows/quick-start) / [Linux](https://facebetter.net/docs/linux/quick-start) guides |

```bash
# iOS
cd demo/ios && pod install && open FBDemo.xcworkspace

# Android — open demo/android in Android Studio, or:
cd demo/android && ./gradlew :app:installDebug

# Web
cd demo/web/react && npm install && npm run dev

# macOS
cd demo/macos && pod install
```

Replace the demo AppID / AppKey (or license token) with credentials from the [console](https://facebetter.net), and bind the sample’s bundle ID / package name. Details: [License & Auth](https://facebetter.net/docs/intro/license).

## Documentation

**[Facebetter documentation](https://facebetter.net/docs)** — quick start, API reference, and platform guides:

- [Android](https://facebetter.net/docs/android/quick-start)
- [iOS](https://facebetter.net/docs/ios/quick-start)
- [macOS](https://facebetter.net/docs/macos/quick-start)
- [Windows](https://facebetter.net/docs/windows/quick-start)
- [Linux](https://facebetter.net/docs/linux/quick-start)
- [Web](https://facebetter.net/docs/web/quick-start)

## Related links

- Website: [https://facebetter.net](https://facebetter.net)
- SDK download: [https://facebetter.net/download](https://facebetter.net/download)
