# Facebetter Desktop C++ Demo (GLFW + ImGui)
#
# 客户默认：解压官方包到 sdk/（或 -DFACEBETTER_SDK_DIR=），然后
#   cmake -B build && cmake --build build
# 内部连编：fb 工程 -DFB_DEMO=ON，此时已存在 facebetter 目标，走 in-tree。

cmake_minimum_required(VERSION 3.16)
project(facebetter_demo_cpp LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenCV REQUIRED)
message(STATUS "OpenCV ${OpenCV_VERSION}")

# ---------------------------------------------------------------------------
# 共享素材：与 iOS/Android/Web Demo 共用 demo/web/react/public
# ---------------------------------------------------------------------------
set(FB_DEMO_WEB_PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/../web/react/public")
if(NOT EXISTS "${FB_DEMO_WEB_PUBLIC}/background.jpg")
  message(FATAL_ERROR
    "Shared demo assets not found:\n  ${FB_DEMO_WEB_PUBLIC}\n"
    "Clone the full facebetter-sdk repository. Filters, stickers, and "
    "background.jpg live under demo/web/react/public.")
endif()
set(FB_DEMO_STICKER_DIR "${FB_DEMO_WEB_PUBLIC}/stickers/face")
set(FB_DEMO_FILTER_DIR "${FB_DEMO_WEB_PUBLIC}/assets/filters/portrait")
set(FB_DEMO_BACKGROUND_PATH "${FB_DEMO_WEB_PUBLIC}/background.jpg")

# ---------------------------------------------------------------------------
# SDK：in-tree（fb -DFB_DEMO=ON）或客户包 sdk/
# ---------------------------------------------------------------------------
if(TARGET facebetter)
  set(FB_DEMO_IN_TREE ON)
  if(DEFINED BUNDLE_OUTPUT AND NOT BUNDLE_OUTPUT STREQUAL "")
    set(FB_DEMO_RESOURCE_FILE "${BUNDLE_OUTPUT}")
  else()
    set(FB_DEMO_RESOURCE_FILE "${CMAKE_BINARY_DIR}/out/resource/resource.fbd")
  endif()
  message(STATUS "facebetter_demo: in-tree (linking target facebetter)")
else()
  set(FB_DEMO_IN_TREE OFF)
  set(FACEBETTER_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/sdk" CACHE PATH
      "Unpacked Facebetter C++ SDK (include/, lib/, resource/resource.fbd)")

  set(_fb_inc "${FACEBETTER_SDK_DIR}/include")
  set(_fb_hdr "${_fb_inc}/facebetter/beauty_effect_engine.h")
  set(FB_DEMO_RESOURCE_FILE "${FACEBETTER_SDK_DIR}/resource/resource.fbd")
  if(NOT EXISTS "${_fb_hdr}" OR NOT EXISTS "${FB_DEMO_RESOURCE_FILE}")
    message(FATAL_ERROR
      "Facebetter C++ SDK not found under:\n  ${FACEBETTER_SDK_DIR}\n"
      "Unzip the official package there, or pass -DFACEBETTER_SDK_DIR=...\n"
      "Expected:\n"
      "  include/facebetter/*.h\n"
      "  lib/facebetter.lib + facebetter.dll   (Windows)\n"
      "  lib/libfacebetter.so                  (Linux)\n"
      "  lib/libfacebetter.dylib               (macOS)\n"
      "  resource/resource.fbd")
  endif()

  if(WIN32)
    set(_fb_implib "${FACEBETTER_SDK_DIR}/lib/facebetter.lib")
    set(_fb_runtime "${FACEBETTER_SDK_DIR}/lib/facebetter.dll")
    if(NOT EXISTS "${_fb_implib}" OR NOT EXISTS "${_fb_runtime}")
      message(FATAL_ERROR "Need ${_fb_implib} and ${_fb_runtime}")
    endif()
    add_library(facebetter SHARED IMPORTED)
    set_target_properties(facebetter PROPERTIES
      IMPORTED_IMPLIB "${_fb_implib}"
      IMPORTED_LOCATION "${_fb_runtime}"
      INTERFACE_INCLUDE_DIRECTORIES "${_fb_inc}")
  elseif(APPLE)
    if(EXISTS "${FACEBETTER_SDK_DIR}/lib/libfacebetter.dylib")
      set(_fb_runtime "${FACEBETTER_SDK_DIR}/lib/libfacebetter.dylib")
      add_library(facebetter SHARED IMPORTED)
    elseif(EXISTS "${FACEBETTER_SDK_DIR}/lib/libfacebetter.a")
      set(_fb_runtime "${FACEBETTER_SDK_DIR}/lib/libfacebetter.a")
      add_library(facebetter STATIC IMPORTED)
    else()
      message(FATAL_ERROR
        "Need ${FACEBETTER_SDK_DIR}/lib/libfacebetter.dylib or libfacebetter.a")
    endif()
    set_target_properties(facebetter PROPERTIES
      IMPORTED_LOCATION "${_fb_runtime}"
      INTERFACE_INCLUDE_DIRECTORIES "${_fb_inc}")
  else()
    set(_fb_runtime "${FACEBETTER_SDK_DIR}/lib/libfacebetter.so")
    if(NOT EXISTS "${_fb_runtime}")
      message(FATAL_ERROR "Need ${_fb_runtime}")
    endif()
    add_library(facebetter SHARED IMPORTED)
    set_target_properties(facebetter PROPERTIES
      IMPORTED_LOCATION "${_fb_runtime}"
      INTERFACE_INCLUDE_DIRECTORIES "${_fb_inc}")
  endif()
  set(FB_DEMO_RUNTIME_LIB "${_fb_runtime}")
  message(STATUS "facebetter_demo: SDK ${FACEBETTER_SDK_DIR}")
endif()

# ---------------------------------------------------------------------------
# GLFW / ImGui / glad / OpenGL（in-tree 用引擎 third_party，否则 FetchContent）
# ---------------------------------------------------------------------------
if(NOT TARGET imgui OR NOT TARGET glad::glad)
  include(FetchContent)
  if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
  endif()

  find_package(OpenGL REQUIRED)

  if(NOT TARGET glfw AND NOT TARGET glfw::glfw)
    set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
    set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(
      glfw
      URL https://github.com/glfw/glfw/archive/refs/tags/3.4.zip)
    FetchContent_MakeAvailable(glfw)
  endif()
  if(NOT TARGET glfw::glfw)
    add_library(glfw::glfw ALIAS glfw)
  endif()

  if(NOT TARGET glad::glad)
    add_library(fb_demo_glad STATIC
      "${CMAKE_CURRENT_SOURCE_DIR}/third_party/glad/src/glad.c")
    add_library(glad::glad ALIAS fb_demo_glad)
    set_target_properties(fb_demo_glad PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_include_directories(fb_demo_glad PUBLIC
      "${CMAKE_CURRENT_SOURCE_DIR}/third_party/glad/include")
  endif()

  if(NOT TARGET imgui)
    FetchContent_Declare(
      imgui
      URL https://github.com/ocornut/imgui/archive/refs/tags/v1.90.2.zip)
    FetchContent_GetProperties(imgui)
    if(NOT imgui_POPULATED)
      FetchContent_Populate(imgui)
    endif()
    add_library(imgui STATIC
      ${imgui_SOURCE_DIR}/imgui.cpp
      ${imgui_SOURCE_DIR}/imgui_draw.cpp
      ${imgui_SOURCE_DIR}/imgui_tables.cpp
      ${imgui_SOURCE_DIR}/imgui_widgets.cpp
      ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
      ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp)
    target_include_directories(imgui PUBLIC
      ${imgui_SOURCE_DIR} ${imgui_SOURCE_DIR}/backends)
    target_link_libraries(imgui PUBLIC glfw::glfw OpenGL::GL)
  endif()
endif()

# ---------------------------------------------------------------------------
# 可执行文件
# ---------------------------------------------------------------------------
add_executable(facebetter_demo
  main.cpp
  studio.cc
  ui.cc)
target_include_directories(facebetter_demo PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${OpenCV_INCLUDE_DIRS})
find_package(Threads REQUIRED)
target_link_libraries(facebetter_demo PRIVATE
  facebetter
  imgui
  glad::glad
  ${OpenCV_LIBS}
  Threads::Threads)
if(WIN32)
  target_link_libraries(facebetter_demo PRIVATE comdlg32)
endif()
if(MSVC)
  target_compile_options(facebetter_demo PRIVATE /utf-8)
endif()

if(FB_DEMO_IN_TREE AND TARGET pack_bundle)
  add_dependencies(facebetter_demo pack_bundle)
endif()

# 资源路径：引擎 fopen 直接打开 resource.fbd 文件
file(TO_CMAKE_PATH "${FB_DEMO_RESOURCE_FILE}" _fb_res)
file(TO_CMAKE_PATH "${FB_DEMO_STICKER_DIR}" _fb_sticker)
file(TO_CMAKE_PATH "${FB_DEMO_FILTER_DIR}" _fb_filter)
file(TO_CMAKE_PATH "${FB_DEMO_BACKGROUND_PATH}" _fb_bg)
set(FB_DEMO_FACE_PATH "${FB_DEMO_WEB_PUBLIC}/face.jpg")
file(TO_CMAKE_PATH "${FB_DEMO_FACE_PATH}" _fb_face)
set(FB_DEMO_ICON_FONT
    "${CMAKE_CURRENT_SOURCE_DIR}/fonts/MaterialIcons-Regular.ttf")
file(TO_CMAKE_PATH "${FB_DEMO_ICON_FONT}" _fb_icon_font)
target_compile_definitions(facebetter_demo PRIVATE
  FB_DEMO_RESOURCE_DIR="${_fb_res}"
  FB_DEMO_STICKER_DIR="${_fb_sticker}"
  FB_DEMO_FILTER_DIR="${_fb_filter}"
  FB_DEMO_BACKGROUND_PATH="${_fb_bg}"
  FB_DEMO_FACE_PATH="${_fb_face}"
  FB_DEMO_ICON_FONT="${_fb_icon_font}")

# 客户包：把运行时库拷到可执行文件旁，并设 RPATH
if(NOT FB_DEMO_IN_TREE AND FB_DEMO_RUNTIME_LIB)
  get_filename_component(_fb_runtime_ext "${FB_DEMO_RUNTIME_LIB}" EXT)
  if(NOT _fb_runtime_ext STREQUAL ".a")
    add_custom_command(
      TARGET facebetter_demo
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FB_DEMO_RUNTIME_LIB}"
        "$<TARGET_FILE_DIR:facebetter_demo>"
      COMMENT "Copy Facebetter runtime next to facebetter_demo")
    if(APPLE)
      set_target_properties(facebetter_demo PROPERTIES
        BUILD_RPATH "@loader_path" INSTALL_RPATH "@loader_path")
    elseif(UNIX)
      set_target_properties(facebetter_demo PROPERTIES
        BUILD_RPATH "$ORIGIN" INSTALL_RPATH "$ORIGIN")
    endif()
  endif()
endif()
