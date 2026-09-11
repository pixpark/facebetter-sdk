# Facebetter 2.0 — Android Demo

Kotlin + Jetpack Compose 相机 Demo。通过 **Maven Central** 安装 `net.pixpark:facebetter` **2.0.0**。

滤镜 / 贴纸 / 背景图与 `demo/web/react` 共用，请保留完整仓库再编译。

## 打开工程

用 Android Studio 打开 `demo/android`，Sync 后运行。或：

```bash
cd demo/android
./gradlew :app:installDebug
```

## 授权

Demo `applicationId` 是 `net.pixpark.fbexample`。在[控制台](https://facebetter.net)绑定该包名，或改成你自己的包名，并把 `BeautyEngine.kt` 里的 AppID / AppKey（或 license token）换成你的凭证。说明见 [License & Auth](https://facebetter.net/docs/intro/license)。

## 功能

- 相机实时美颜 / 相册静图
- 长按预览看原图
- 美肤、美型、美妆、滤镜、贴纸、虚拟背景（含色键）
- 关键点开关、中英切换、拍照导出到相册
- 系统返回：先收起面板，再退出
