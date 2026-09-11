# Facebetter Desktop C++ Demo

GLFW + Dear ImGui 的 Facebetter Demo 界面，演示 C++ API。默认加载示例图，也可开摄像头、拖入图片或导出 PNG。滤镜和贴纸与 `demo/web/react` 共用，请保留完整仓库再编译。

主线程用 vsync + `glfwWaitEventsTimeout`，处理线程用条件变量背压，静止画面时 CPU 接近空闲。

## 准备 SDK

从 [下载页](https://facebetter.net/download) 获取 Windows / Linux（或 macOS）C++ 包，解压到 `demo/cpp/sdk/`：

```
demo/cpp/sdk/
├── include/facebetter/   # 头文件
├── lib/                  # facebetter.dll + .lib  /  libfacebetter.so  /  libfacebetter.dylib
└── resource/
    └── resource.fbd      # 必须指向这个文件，不能填目录
```

也可把包放到别处，配置时加 `-DFACEBETTER_SDK_DIR=/path/to/sdk`。

需要本机已安装 **CMake 3.16+**、**OpenCV**，以及 C++17 编译器。首次配置会下载 GLFW 3.4 和 Dear ImGui。详细步骤见：

- [Windows Quick Start](https://facebetter.net/docs/windows/quick-start)
- [Linux Quick Start](https://facebetter.net/docs/linux/quick-start)

## 构建

```bash
cd demo/cpp
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

Windows 请在 **Developer Command Prompt** 里执行，或加 `-G Ninja`。CMake 会把运行时库拷到可执行文件旁。

## 授权

把 `studio.cc` 里的 AppID / AppKey（或 license token）换成[控制台](https://facebetter.net)里的凭证。说明见 [License & Auth](https://facebetter.net/docs/intro/license)。
