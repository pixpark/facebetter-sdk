# Facebetter Desktop C++ Demo (GLFW + ImGui)

桌面端 C++ 示例：使用 GLFW + Dear ImGui 调用 FB 引擎 C++ 接口，美颜面板布局参考 [demo/macos](https://github.com/your-org/fb/tree/main/demo/macos) 的 BeautyPanelViewController。

## 依赖引入方式

- **GLFW**：使用主工程 facebetter 的依赖（`third_party/gpupixel/third_party/glfw`），不重复引入。
- **ImGui**：通过 **CPM.cmake + Git 源码仓库** 引入（配置时自动拉取 [ocornut/imgui](https://github.com/ocornut/imgui)），不放入本地。

## 构建

在引擎仓 `fb` 根目录（与本仓库并列）：

```bash
mkdir -p build && cd build
cmake .. -DFB_DEMO=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --target facebetter_demo
```

可执行文件生成在 `build/out/bin/facebetter_demo`（或 `build/bin/`，取决于 CMake 配置）。运行前确保 `resource.fbd` 在 `build/out/` 下（主工程构建时会自动打包到该目录）。

## 运行

```bash
./out/bin/facebetter_demo
```

或从 build 目录：

```bash
cd build && ./out/bin/facebetter_demo
```

## 当前功能

- 主窗口：左侧预览占位（无相机），右侧美颜面板。
- 美颜面板：Tab（beauty / reshape / makeup / filter / sticker / body / virtual_bg / quality）+ 功能按钮 + 滑条，与 macOS demo 布局一致。
- 参数通过 `BeautyEffectEngine` C++ API 设置（`SetSmoothing` / `SetWhitening` / `SetReshape` / `SetLipstick` / `SetBlush`、`SetFilter`、`SetSticker`、`SetVirtualBackgroundBlur` / `SetVirtualBackground` 等）。
- 预览区暂无相机；可后续接入 libuvc 或平台 API（Media Foundation / V4L2 / AVFoundation）实现实时画面。

## 方案说明

- **CPM + Git 引入 ImGui**：不克隆到仓库，配置时按 `GIT_TAG` 拉取，版本可锁、可复现。
- **GLFW 使用主工程**：避免与 facebetter 已链接的 glfw 重复，防止符号冲突。
