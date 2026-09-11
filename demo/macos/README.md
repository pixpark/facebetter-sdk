# Facebetter — macOS Demo 2

SwiftUI 桌面 Demo，UI 对齐 `demo/web/react`（顶栏 + 预览 + 右侧精修控制台），引擎/相机逻辑参考 `demo/ios`。

通过 **CocoaPods** 安装 `Facebetter` **2.0.0**。打开 **`.xcworkspace`**，不要打开 `.xcodeproj`。

```bash
cd demo/macos2
pod install
open FBDemoMac.xcworkspace
```

Xcode 15+ 若遇到 `Sandbox: rsync.samba deny(1)`，确认 Build Setting **`ENABLE_USER_SCRIPT_SANDBOXING`** 为 **No**（工程已默认关闭）。

## 本地联调

```bash
cd ../../../fb && ./scripts/build_macos.sh
cd ../fb-sdk/demo/macos2
cp Podfile.local.example Podfile.local
pod install
```

## 授权

Demo Bundle ID 是 `com.pixpark.FBDemoMac`。在[控制台](https://facebetter.net)绑定该 ID，或改 Bundle ID，并把 `FBDemoMac/Resources/FacebetterConfig.plist` 里的 AppID / AppKey 换成你的凭证。说明见 [License & Auth](https://facebetter.net/docs/intro/license)。

## 功能

- 默认加载与 Web Demo 相同的 `face.jpg`
- 更换图片 / 摄像头 / 导出 PNG
- 按住预览对比原图；关键点叠加
- 美肤 / 美型 / 美妆 / 滤镜 / 贴纸 / 背景（参数面与 React 对齐）
- 中英文切换
