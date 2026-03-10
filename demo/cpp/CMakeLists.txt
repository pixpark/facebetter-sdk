cmake_minimum_required(VERSION 3.16)
project(facebetter_demo_cpp LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ------------------------------------------------------------------------------
# Third-party dependencies: GLFW / GLAD / ImGui (all from demo/cpp/third-party)
# ------------------------------------------------------------------------------

# GLFW
add_subdirectory(third-party/glfw)

# GLAD
add_library(glad STATIC
  third-party/glad/src/glad.c
)
target_include_directories(glad PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/third-party/glad/include
)

# ImGui
set(IMGUI_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third-party/imgui)
add_library(imgui STATIC
  ${IMGUI_DIR}/imgui.cpp
  ${IMGUI_DIR}/imgui_draw.cpp
  ${IMGUI_DIR}/imgui_tables.cpp
  ${IMGUI_DIR}/imgui_widgets.cpp
  ${IMGUI_DIR}/backends/imgui_impl_glfw.cpp
  ${IMGUI_DIR}/backends/imgui_impl_opengl3.cpp
)
target_include_directories(imgui PUBLIC
  ${IMGUI_DIR}
  ${IMGUI_DIR}/backends
)
target_link_libraries(imgui PUBLIC glfw)

# ------------------------------------------------------------------------------
# Facebetter prebuilt SDK
# sdk/include: headers
# sdk/lib:     prebuilt libraries (Windows: facebetter.lib + facebetter.dll; Linux: put libfacebetter.so here)
# ------------------------------------------------------------------------------

set(FB_SDK_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk)
set(FB_SDK_INCLUDE_DIR ${FB_SDK_DIR}/include)
set(FB_SDK_LIB_DIR ${FB_SDK_DIR}/lib)

add_library(facebetter SHARED IMPORTED)

if(WIN32)
  set_target_properties(facebetter PROPERTIES
    IMPORTED_LOCATION "${FB_SDK_LIB_DIR}/facebetter.dll"
    IMPORTED_IMPLIB   "${FB_SDK_LIB_DIR}/facebetter.lib"
  )
else()
  # Linux: expect libfacebetter.so to be placed in sdk/lib
  set_target_properties(facebetter PROPERTIES
    IMPORTED_LOCATION "${FB_SDK_LIB_DIR}/libfacebetter.so"
  )
endif()

target_include_directories(facebetter INTERFACE
  ${FB_SDK_INCLUDE_DIR}
)

# ------------------------------------------------------------------------------
# Executable
# ------------------------------------------------------------------------------

add_executable(facebetter_demo
  main.cpp
)

target_include_directories(facebetter_demo PRIVATE
  ${FB_SDK_INCLUDE_DIR}
)

set(FB_EXTRA_LIBS "")
if(WIN32)
  list(APPEND FB_EXTRA_LIBS opengl32)
elseif(UNIX)
  find_package(OpenGL REQUIRED)
  list(APPEND FB_EXTRA_LIBS OpenGL::GL)
endif()

target_link_libraries(facebetter_demo PRIVATE
  facebetter
  imgui
  glad
  glfw
  ${FB_EXTRA_LIBS}
)

# Post-build steps: copy runtime dependencies next to the executable
add_custom_command(TARGET facebetter_demo POST_BUILD
  # Ensure resource directory exists next to the executable
  COMMAND ${CMAKE_COMMAND} -E make_directory
    "$<TARGET_FILE_DIR:facebetter_demo>/resource"
  # Copy resource.fbd from SDK to runtime resource folder
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${FB_SDK_DIR}/resource/resource.fbd"
    "$<TARGET_FILE_DIR:facebetter_demo>/resource/resource.fbd"
  # Copy demo.png (if present in source dir) to runtime resource folder
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_CURRENT_SOURCE_DIR}/demo.png"
    "$<TARGET_FILE_DIR:facebetter_demo>/resource/demo.png"
)

if (WIN32)
  # Copy facebetter.dll next to the executable for runtime loading
  add_custom_command(TARGET facebetter_demo POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${FB_SDK_LIB_DIR}/facebetter.dll"
      "$<TARGET_FILE_DIR:facebetter_demo>/facebetter.dll"
  )
endif()

