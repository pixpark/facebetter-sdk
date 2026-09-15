# Facebetter 2.0 — iOS Demo

SwiftUI 相机 Demo。通过 **CocoaPods** 安装 `Facebetter` **2.0.1**。打开 **`FBDemo.xcworkspace`**，不要打开 `.xcodeproj`。

滤镜和贴纸与 `demo/web/react` 共用，请保留完整仓库再编译。

## 打开工程

```bash
cd demo/ios
pod install
open FBDemo.xcworkspace
```

选真机运行。模拟器没有相机，相册静图仍可测。

Xcode 15+ 若遇到 `Sandbox: rsync.samba deny(1)`，把 Build Setting **`ENABLE_USER_SCRIPT_SANDBOXING`** 设为 **No**（本工程已默认关掉）。

## 授权

Demo Bundle ID 是 `com.pixpark.fbdemo`。在[控制台](https://facebetter.net)绑定该 Bundle ID，或改成你自己的应用 ID，并把 `FBDemo/Resources/FacebetterConfig.plist` 里的 AppID / AppKey（或 license token）换成你的凭证。说明见 [License & Auth](https://facebetter.net/docs/intro/license)。

## 功能

- 相机实时美颜 / 相册静图
- 顶栏 **纹理** 进入外部纹理示例：相机画面以 OpenGL 纹理送入引擎，适合推流和自建渲染管线
- 长按预览看原图
- 美肤、美型、美妆、滤镜、贴纸、虚拟背景（含色键）
- 关键点开关、中英切换、拍照导出到相册
