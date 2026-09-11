# Facebetter 2.0 — iOS Demo

SwiftUI 相机 Demo，对应 Web 端 `demo/web/react2` 的 2.0 能力目录。全屏预览 + 底部调参。

本仓库与引擎仓 `fb` 并列。本地联调链 `../fb/build/ios/Facebetter.xcframework`。

**不使用 CocoaPods。**

## 打开工程

1. 在引擎仓编出 **2.0** iOS SDK：

```bash
cd ../fb
./scripts/build_ios.sh          # 默认只编真机 arm64
./scripts/build_ios.sh --full   # 含模拟器，发版或跑模拟器用
```

完成后应存在：`../fb/build/ios/Facebetter.xcframework`。

2. 生成并打开 Xcode 工程：

```bash
cd demo/ios2
ruby scripts/create_project.rb
open FBDemo.xcodeproj
```

3. 选真机运行。模拟器没有相机，相册静图仍可测。

头文件走 `../fb/src/engine/objc`（2.0 API），二进制走上面的 xcframework。改完引擎后重新跑 `../fb/scripts/build_ios.sh`，再编译 Demo。

客户集成请用 `scripts/download_sdk.sh` 把官方包解到 `demo/ios2/libs`。

## 授权

默认 Bundle ID 是 `com.pixpark.fbdemo`。凭证在 `FBDemo/Resources/FacebetterConfig.plist`。

## 功能

- 相机实时美颜 / 相册静图
- 长按预览看原图
- 美肤、美型、美妆、滤镜、贴纸、虚拟背景（含色键）
- 关键点开关、中英切换、拍照导出到相册

滤镜和贴纸在编译时从 `demo/web/react2/public` 拷入，与 Web Demo 共用同一套资源。
