# Facebetter 2.0 — Android Demo

Kotlin + Jetpack Compose 相机 Demo，对应 iOS 端 `demo/ios2` 和 Web 端 `demo/web/react2`。

本仓库与引擎仓 `fb` 并列。Java API 编译 `../fb/src/engine/android/facebetter` 源码，`.so` 和资源从本地 AAR 抽出。

## 打开工程

1. 在引擎仓编出 **2.0** Android AAR：

```bash
cd ../fb
./scripts/build_android.sh
```

完成后应存在：`../fb/src/engine/android/facebetter/build/outputs/aar/facebetter.aar`。

2. 配置 SDK 路径（不要提交）。可从旧 Demo 拷：

```bash
cp demo/android/local.properties demo/android2/local.properties
```

3. 用 Android Studio 打开 `demo/android2`，或：

```bash
cd demo/android2
./gradlew :app:installDebug
```

滤镜 / 贴纸 / 背景图在编译时从 `demo/web/react2/public` 拷入 assets。

## 授权

`applicationId` 是 `net.pixpark.fbexample`。凭证写在 `BeautyEngine.kt`。

## 功能

- 相机实时美颜 / 相册静图
- 长按预览看原图
- 美肤、美型、美妆、滤镜、贴纸、虚拟背景（含色键）
- 关键点开关、中英切换、拍照导出到相册
- 系统返回：先收起面板，再退出
