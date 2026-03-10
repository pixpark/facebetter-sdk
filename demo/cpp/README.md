# Facebetter Desktop C++ Demo (GLFW + ImGui)

Standalone desktop C++ demo using GLFW + Dear ImGui with the prebuilt Facebetter SDK.

The UI shows a static image preview on the left and a beauty parameter panel on the right, with sliders for basic beauty, face reshape, makeup and sticker.

## Directory layout

- `demo/cpp/main.cpp` – demo source code.
- `demo/cpp/third-party/` – embedded third-party dependencies:
  - `glfw` – window + OpenGL context.
  - `glad` – OpenGL function loader.
  - `imgui` – Dear ImGui and backends for GLFW + OpenGL3.
- `demo/cpp/sdk/` – Facebetter prebuilt SDK for this demo:
  - `include/facebetter/*.h` – C++ headers.
  - `lib/` – platform-specific libraries.
  - `resource/resource.fbd` – model/resource file used by the engine.

## Preparing the SDK

Place your Facebetter SDK files in `demo/cpp/sdk`. A typical setup is:

- **Windows SDK**: unzip `facebetter-sdk-win.zip` directly into `demo/cpp/sdk`, so that you get:
  - `demo/cpp/sdk/include/facebetter/*.h`
  - `demo/cpp/sdk/lib/facebetter.lib`
  - `demo/cpp/sdk/lib/facebetter.dll`
  - `demo/cpp/sdk/resource/resource.fbd`
- **Linux SDK**: copy the Linux version libraries into:
  - `demo/cpp/sdk/lib/libfacebetter.so`

The CMake project is already configured to use these locations.

## Build on Windows (Ninja)

From the repository root:

```bash
cd demo/cpp
mkdir -p build && cd build
cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

Notes:

- You need `ninja` on your PATH.
- After the build, CMake automatically copies `sdk/lib/facebetter.dll`
next to the executable so it can be loaded at runtime.

## Build on Linux (Ninja)

From `demo/cpp`:

```bash
cd demo/cpp
mkdir -p build && cd build
cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

Requirements: 

- A C++17 compiler (e.g. gcc or clang).
- `ninja` (if you use the Ninja generator).
- OpenGL development files (CMake will find `OpenGL::GL`).

Make sure `demo/cpp/sdk/lib/libfacebetter.so` exists before building.

## Run

### Windows (Ninja build)

After building with Ninja, the executable will be in:

- `demo/cpp/build/facebetter_demo.exe`

You can run it directly from the build directory:

```bash
cd demo/cpp/build
./facebetter_demo.exe
```

`facebetter.dll` will be in the same directory (copied automatically by CMake).

### Linux (Ninja build)

After building with Ninja:

```bash
cd demo/cpp/build
./facebetter_demo
```

Make sure `libfacebetter.so` is either:

- In the same directory as the executable, or
- In a directory listed in `LD_LIBRARY_PATH`, or
- Installed in a standard library path (e.g. `/usr/lib`).

## Runtime behavior

- The engine loads `resource.fbd` from `demo/cpp/sdk/resource/resource.fbd`
through the `FB_DEMO_RESOURCE_DIR` macro defined in `CMakeLists.txt`.
- If `demo.png` is placed next to `resource.fbd`, the demo loads it,
sends it through the Facebetter engine, and displays the processed result.

