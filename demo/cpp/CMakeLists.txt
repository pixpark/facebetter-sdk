# Facebetter Desktop C++ Demo (GLFW + ImGui + OpenCV)
# - GLFW/ImGui: 使用主工程 third_party（gpupixel 提供 glfw，third_party/imgui 提供 imgui）。
# - OpenCV: 用于相机采集

cmake_minimum_required(VERSION 3.16)
project(facebetter_demo_cpp LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)

# OpenCV 依赖
find_package(OpenCV REQUIRED)
message(STATUS "OpenCV found: ${OpenCV_VERSION}")
message(STATUS "OpenCV include dirs: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV libraries: ${OpenCV_LIBS}")

# ImGui 由主工程 third_party/CMakeLists.txt 在存在 third_party/imgui 时提供；若无则 CPM 拉取
if(NOT TARGET imgui)
  include(${CMAKE_SOURCE_DIR}/cmake/CPM.cmake)
  CPMAddPackage(NAME imgui GITHUB_REPOSITORY ocornut/imgui GIT_TAG v1.90.2)
  set(IMGUI_DIR ${imgui_SOURCE_DIR})
  add_library(imgui STATIC
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
    ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
  )
  target_include_directories(imgui PUBLIC ${IMGUI_DIR} ${IMGUI_DIR}/backends)
  target_link_libraries(imgui PUBLIC glfw::glfw)
endif()

# 桌面 Demo 可执行文件
add_executable(facebetter_demo
  main.cpp
)
target_include_directories(facebetter_demo PRIVATE
  ${CMAKE_SOURCE_DIR}/src
  ${CMAKE_SOURCE_DIR}/src/include
  ${OpenCV_INCLUDE_DIRS}
)
target_link_libraries(facebetter_demo PRIVATE
  facebetter
  imgui
  glad::glad
  ${OpenCV_LIBS}
)
# 资源路径：传 resource.fbd 的完整路径（引擎用 fopen 直接打开该文件）
target_compile_definitions(facebetter_demo PRIVATE
  FB_DEMO_RESOURCE_DIR="${CMAKE_BINARY_DIR}/out/resource/resource.fbd"
  FB_DEMO_STICKER_DIR="${CMAKE_CURRENT_SOURCE_DIR}/assets/stickers/face"
  FB_DEMO_FILTER_DIR="${CMAKE_CURRENT_SOURCE_DIR}/assets/filters"
  FB_DEMO_BACKGROUND_PATH="${CMAKE_CURRENT_SOURCE_DIR}/assets/background.jpg"
)
