# Facebetter — macOS Demo

AppKit 相机 Demo。通过 **CocoaPods** 安装 `Facebetter` **1.5.1**。打开 **`.xcworkspace`**，不要打开 `.xcodeproj`。

```bash
cd demo/macos
pod install
open FBExampleObjc.xcworkspace
```

Xcode 15+ 若遇到 `Sandbox: rsync.samba deny(1)`，把 Build Setting **`ENABLE_USER_SCRIPT_SANDBOXING`** 设为 **No**。

## 授权

Demo Bundle ID 是 `com.pixpark.FBExampleObjc`。在[控制台](https://facebetter.net)绑定该 ID，或改成你自己的，并把 `BeautyCameraViewController.m` 里的 AppID / AppKey 换成你的凭证。说明见 [License & Auth](https://facebetter.net/docs/intro/license)。

如果不使用 CocoaPods，把官方包里的 `Facebetter.framework` 放到 `FBExampleObjc/libs`。
