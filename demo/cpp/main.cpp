/*
 * Facebetter Desktop C++ Demo (GLFW + ImGui)
 * Beauty panel: collapsible groups for Basic / Face Reshape / Makeup / Sticker, each with sliders.
 */

#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <facebetter/beauty_effect_engine.h>
#include <facebetter/beauty_params.h>
#include <facebetter/image_frame.h>
#include <facebetter/type_defines.h>

#include <memory>
#include <string>
#include <vector>
#include <filesystem>

using namespace facebetter;
using namespace facebetter::beauty_params;

int main(int argc, char* argv[]) {
  (void)argc;
  (void)argv;

  if (!glfwInit()) return 1;
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
  GLFWwindow* window =
      glfwCreateWindow(1920, 1080, "Facebetter Demo (GLFW + ImGui)", nullptr, nullptr);
  if (!window) {
    glfwTerminate();
    return 1;
  }
  glfwMakeContextCurrent(window);
  glfwSwapInterval(1);
  if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
    glfwDestroyWindow(window);
    glfwTerminate();
    return 1;
  }

  float scale_x = 1.f, scale_y = 1.f;
  glfwGetWindowContentScale(window, &scale_x, &scale_y);
  float ui_scale = (scale_x > scale_y) ? scale_x : scale_y;
  if (ui_scale < 1.f) ui_scale = 1.f;

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  ImGuiIO& io = ImGui::GetIO();
  io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
  io.FontGlobalScale = ui_scale;
  ImGui::StyleColorsDark();
  ImGui::GetStyle().ScaleAllSizes(ui_scale);
  ImGui_ImplGlfw_InitForOpenGL(window, true);
  ImGui_ImplOpenGL3_Init("#version 130");

  LogConfig log_cfg;
  log_cfg.console_enabled = true;
  log_cfg.file_enabled = false;
  log_cfg.level = LogLevel::Info;
  BeautyEffectEngine::SetLogConfig(log_cfg);

  EngineConfig eng_cfg;
  eng_cfg.app_id = "dddb24155fd045ab9c2d8aad83ad3a4a";
  eng_cfg.app_key = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";
  try {
    std::filesystem::path base = std::filesystem::current_path();
    eng_cfg.resource_path = (base / "resource" / "resource.fbd").string();
  } catch (...) {
    eng_cfg.resource_path = "resource/resource.fbd";
  }
  eng_cfg.external_context = false;

  std::shared_ptr<BeautyEffectEngine> engine = BeautyEffectEngine::Create(eng_cfg);
  if (!engine) {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();
    return 1;
  }
  engine->SetBeautyTypeEnabled(BeautyType::Basic, true);
  engine->SetBeautyTypeEnabled(BeautyType::Reshape, true);
  engine->SetBeautyTypeEnabled(BeautyType::Makeup, true);
  engine->SetBeautyTypeEnabled(BeautyType::Sticker, true);
  engine->SetSticker("");  // Sticker disabled by default

  // Basic beauty
  float smoothing_ = 0.0f;
  float whitening_ = 0.0f;
  float rosiness_ = 0.0f;
  float sharpening_ = 0.0f;

  // Face reshape
  float face_thin_ = 0.0f;
  float face_vshape_ = 0.0f;
  float face_narrow_ = 0.0f;
  float face_short_ = 0.0f;
  float cheekbone_ = 0.0f;
  float jawbone_ = 0.0f;
  float chin_ = 0.0f;
  float nose_slim_ = 0.0f;
  float eye_size_ = 0.0f;
  float eye_distance_ = 0.0f;

  // Makeup
  float lipstick_ = 0.0f;
  float blush_ = 0.0f;

  // Sticker: options "Off", "rabbit", current selected index
  static const std::vector<std::string> kStickerOptions = {"Off", "rabbit"};
  int sticker_index_ = 0;

  std::string demo_path;
  {
    const std::string& r = eng_cfg.resource_path;
    size_t pos = r.find_last_of("/\\");
    demo_path = (pos != std::string::npos) ? r.substr(0, pos + 1) + "demo.png" : "demo.png";
  }
  bool has_demo_image = false;
  std::vector<uint8_t> demo_rgba;
  int demo_width = 0, demo_height = 0, demo_stride = 0;
  {
    auto probe = ImageFrame::CreateWithFile(demo_path);
    if (probe && probe->Width() > 0 && probe->Height() > 0 && probe->Data()) {
      demo_width = probe->Width();
      demo_height = probe->Height();
      demo_stride = probe->Stride();
      size_t size = static_cast<size_t>(demo_stride) * static_cast<size_t>(demo_height);
      demo_rgba.assign(probe->Data(), probe->Data() + size);
      has_demo_image = true;
    }
  }
  GLuint preview_tex = 0;
  int preview_w = 0, preview_h = 0;
  double last_process_time = 0.0;
  const double kProcessInterval = 1.0 / 30.0;

  while (!glfwWindowShouldClose(window)) {
    glfwPollEvents();
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    double now = glfwGetTime();
    bool should_process = has_demo_image && !demo_rgba.empty() &&
                          (now - last_process_time >= kProcessInterval);
    if (should_process) {
      auto input_frame = ImageFrame::CreateWithRGBA(
          demo_rgba.data(), demo_width, demo_height, demo_stride);
      if (input_frame) {
        input_frame->type = FrameType::Video;
        auto output_frame = engine->ProcessImage(input_frame);
        if (output_frame && output_frame->Data()) {
          int w = output_frame->Width(), h = output_frame->Height();
          if (preview_tex == 0) {
            glGenTextures(1, &preview_tex);
            glBindTexture(GL_TEXTURE_2D, preview_tex);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
          }
          glBindTexture(GL_TEXTURE_2D, preview_tex);
          glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, output_frame->Data());
          preview_w = w;
          preview_h = h;
        }
      }
      last_process_time = now;
    }

    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(ImVec2(1920, 1080));
    ImGui::Begin("Main", nullptr,
                 ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
                     ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoScrollbar);

    const float panel_width = 500.f;
    const float preview_width = ImGui::GetContentRegionAvail().x - panel_width - 8.f;

    ImGui::BeginChild("Preview", ImVec2(preview_width, -1), true,
                      ImGuiWindowFlags_NoScrollbar);
    if (has_demo_image && preview_tex != 0 && preview_w > 0 && preview_h > 0) {
      float avail_w = ImGui::GetContentRegionAvail().x;
      float avail_h = ImGui::GetContentRegionAvail().y;
      float scale = (avail_w / static_cast<float>(preview_w) < avail_h / static_cast<float>(preview_h))
                        ? (avail_w / static_cast<float>(preview_w))
                        : (avail_h / static_cast<float>(preview_h));
      if (scale > 1.f) scale = 1.f;
      float img_w = static_cast<float>(preview_w) * scale;
      float img_h = static_cast<float>(preview_h) * scale;
      float offset_x = (avail_w - img_w) * 0.5f;
      if (offset_x > 0.f) ImGui::SetCursorPosX(ImGui::GetCursorPosX() + offset_x);
      ImGui::Image(static_cast<ImTextureID>(static_cast<intptr_t>(preview_tex)),
                  ImVec2(img_w, img_h));
    } else {
      ImGui::SetCursorPosY(ImGui::GetCursorPosY() + 200);
      if (has_demo_image)
        ImGui::TextWrapped("Loading demo.png...");
      else
        ImGui::TextWrapped("Put demo.png in the same folder as resource.fbd to preview.");
    }
    ImGui::EndChild();

    ImGui::SameLine();

    ImGui::BeginChild("BeautyPanel", ImVec2(panel_width, -1), true);
    ImGui::Text("Beauty Control Panel");
    ImGui::Separator();

    // Group 1: Basic beauty (expanded by default)
    if (ImGui::CollapsingHeader("Basic Beauty", ImGuiTreeNodeFlags_DefaultOpen)) {
      if (ImGui::SliderFloat("Smoothing", &smoothing_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Basic::Smoothing, smoothing_);
      if (ImGui::SliderFloat("Whitening", &whitening_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Basic::Whitening, whitening_);
      if (ImGui::SliderFloat("Rosiness", &rosiness_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Basic::Rosiness, rosiness_);
      if (ImGui::SliderFloat("Sharpening", &sharpening_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Basic::Sharpening, sharpening_);
    }

    // Group 2: Face reshape
    if (ImGui::CollapsingHeader("Face Reshape")) {
      if (ImGui::SliderFloat("Face Thin", &face_thin_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::FaceThin, face_thin_);
      if (ImGui::SliderFloat("V Face", &face_vshape_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::FaceVShape, face_vshape_);
      if (ImGui::SliderFloat("Narrow Face", &face_narrow_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::FaceNarrow, face_narrow_);
      if (ImGui::SliderFloat("Short Face", &face_short_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::FaceShort, face_short_);
      if (ImGui::SliderFloat("Cheekbone", &cheekbone_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::Cheekbone, cheekbone_);
      if (ImGui::SliderFloat("Jawbone", &jawbone_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::Jawbone, jawbone_);
      if (ImGui::SliderFloat("Chin", &chin_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::Chin, chin_);
      if (ImGui::SliderFloat("Nose Slim", &nose_slim_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::NoseSlim, nose_slim_);
      if (ImGui::SliderFloat("Eye Size", &eye_size_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::EyeSize, eye_size_);
      if (ImGui::SliderFloat("Eye Distance", &eye_distance_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Reshape::EyeDistance, eye_distance_);
    }

    // Group 3: Makeup
    if (ImGui::CollapsingHeader("Makeup")) {
      if (ImGui::SliderFloat("Lipstick", &lipstick_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Makeup::Lipstick, lipstick_);
      if (ImGui::SliderFloat("Blush", &blush_, 0.0f, 1.0f, "%.2f"))
        engine->SetBeautyParam(Makeup::Blush, blush_);
    }

    // Group 4: Sticker (combo box)
    if (ImGui::CollapsingHeader("Sticker")) {
      const char* current = sticker_index_ < (int)kStickerOptions.size()
                                ? kStickerOptions[sticker_index_].c_str()
                                : "Off";
      if (ImGui::BeginCombo("##sticker", current)) {
        for (int i = 0; i < (int)kStickerOptions.size(); ++i) {
          bool selected = (sticker_index_ == i);
          if (ImGui::Selectable(kStickerOptions[i].c_str(), selected)) {
            sticker_index_ = i;
            if (i == 0)
              engine->SetSticker("");
            else
              engine->SetSticker(kStickerOptions[i]);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
    }

    ImGui::Spacing();
    ImGui::Separator();
    if (ImGui::Button("Reset All")) {
      smoothing_ = whitening_ = rosiness_ = sharpening_ = 0.f;
      face_thin_ = face_vshape_ = face_narrow_ = face_short_ = 0.f;
      cheekbone_ = jawbone_ = chin_ = nose_slim_ = eye_size_ = eye_distance_ = 0.f;
      lipstick_ = blush_ = 0.f;
      sticker_index_ = 0;
      engine->SetBeautyParam(Basic::Smoothing, 0.f);
      engine->SetBeautyParam(Basic::Whitening, 0.f);
      engine->SetBeautyParam(Basic::Rosiness, 0.f);
      engine->SetBeautyParam(Basic::Sharpening, 0.f);
      engine->SetBeautyParam(Reshape::FaceThin, 0.f);
      engine->SetBeautyParam(Reshape::FaceVShape, 0.f);
      engine->SetBeautyParam(Reshape::FaceNarrow, 0.f);
      engine->SetBeautyParam(Reshape::FaceShort, 0.f);
      engine->SetBeautyParam(Reshape::Cheekbone, 0.f);
      engine->SetBeautyParam(Reshape::Jawbone, 0.f);
      engine->SetBeautyParam(Reshape::Chin, 0.f);
      engine->SetBeautyParam(Reshape::NoseSlim, 0.f);
      engine->SetBeautyParam(Reshape::EyeSize, 0.f);
      engine->SetBeautyParam(Reshape::EyeDistance, 0.f);
      engine->SetBeautyParam(Makeup::Lipstick, 0.f);
      engine->SetBeautyParam(Makeup::Blush, 0.f);
      engine->SetSticker("");
    }
    ImGui::EndChild();
    ImGui::End();

    ImGui::Render();
    int w, h;
    glfwGetFramebufferSize(window, &w, &h);
    glViewport(0, 0, w, h);
    glClearColor(0.12f, 0.12f, 0.14f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    glfwSwapBuffers(window);
  }

  if (preview_tex != 0) {
    glDeleteTextures(1, &preview_tex);
  }
  engine.reset();
  ImGui_ImplOpenGL3_Shutdown();
  ImGui_ImplGlfw_Shutdown();
  ImGui::DestroyContext();
  glfwDestroyWindow(window);
  glfwTerminate();
  return 0;
}
