#include "studio.h"
#include "ui.h"

// clang-format off
#include <glad/glad.h>
#include <GLFW/glfw3.h>
// clang-format on
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <cstdio>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

using demo::Studio;

static float FramebufferScale(GLFWwindow* window) {
  int fb_w = 0;
  int fb_h = 0;
  int win_w = 0;
  int win_h = 0;
  glfwGetFramebufferSize(window, &fb_w, &fb_h);
  glfwGetWindowSize(window, &win_w, &win_h);
  if (win_w <= 0)
    return 1.f;
  return static_cast<float>(fb_w) / static_cast<float>(win_w);
}

static void OnDrop(GLFWwindow* window, int count, const char** paths) {
  auto* studio = static_cast<Studio*>(glfwGetWindowUserPointer(window));
  if (!studio || count <= 0 || !paths || !paths[0])
    return;
  studio->StopCamera();
  studio->LoadImageFile(paths[0]);
}

int main() {
#ifdef _WIN32
  SetProcessDPIAware();
#endif
  if (!glfwInit())
    return 1;
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  glfwWindowHint(GLFW_SAMPLES, 4);
#ifdef _WIN32
  glfwWindowHint(GLFW_SCALE_TO_MONITOR, GLFW_TRUE);
#endif
  GLFWwindow* window =
      glfwCreateWindow(1440, 860, "Facebetter Demo", nullptr, nullptr);
  if (!window) {
    glfwTerminate();
    return 1;
  }
  glfwSetWindowSizeLimits(window, 1100, 700, GLFW_DONT_CARE, GLFW_DONT_CARE);
  glfwMakeContextCurrent(window);
  glfwSwapInterval(1);
  if (!gladLoadGLLoader(reinterpret_cast<GLADloadproc>(glfwGetProcAddress))) {
    glfwDestroyWindow(window);
    glfwTerminate();
    return 1;
  }
  glEnable(GL_MULTISAMPLE);

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  ImGuiIO& io = ImGui::GetIO();
  io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
  io.IniFilename = nullptr;
  demo::ApplyStudioTheme();
  demo::LoadStudioFonts(FramebufferScale(window));
  ImGui_ImplGlfw_InitForOpenGL(window, true);
  ImGui_ImplOpenGL3_Init("#version 330");

  Studio studio;
  if (!studio.Init(window)) {
    std::fprintf(stderr, "Failed to create Facebetter engine\n");
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();
    return 1;
  }
  glfwSetWindowUserPointer(window, &studio);
  glfwSetDropCallback(window, OnDrop);

  while (!glfwWindowShouldClose(window)) {
    glfwWaitEventsTimeout(studio.IsCamera() ? 0.016 : 0.25);
    studio.UploadGpu();

    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();
    demo::DrawStudio(studio, window);
    ImGui::Render();

    int fb_w = 0;
    int fb_h = 0;
    glfwGetFramebufferSize(window, &fb_w, &fb_h);
    glViewport(0, 0, fb_w, fb_h);
    glClearColor(11 / 255.f, 12 / 255.f, 16 / 255.f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    glfwSwapBuffers(window);
  }

  studio.Shutdown();
  ImGui_ImplOpenGL3_Shutdown();
  ImGui_ImplGlfw_Shutdown();
  ImGui::DestroyContext();
  glfwDestroyWindow(window);
  glfwTerminate();
  return 0;
}
