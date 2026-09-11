/*
 * Facebetter Desktop C++ Demo (GLFW + ImGui + OpenCV)
 * 使用 OpenCV 采集相机数据，实时美颜处理，ImGui 显示和控制界面
 */

// clang-format off
// glad 必须排在任何 OpenGL / GLFW 头之前，否则会撞上系统 gl.h。
#include <glad/glad.h>
#include <GLFW/glfw3.h>
// clang-format on
#include <facebetter/beauty_effect_engine.h>
#include <facebetter/beauty_params.h>
#include <facebetter/image_frame.h>
#include <facebetter/type_defines.h>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <atomic>
#include <chrono>
#include <cstring>
#include <memory>
#include <mutex>
#include <opencv2/opencv.hpp>
#include <string>
#include <thread>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#endif

using namespace facebetter;
using namespace facebetter::beauty_params;

struct ProcessedFrame {
  GLuint texture = 0;
  int width = 0;
  int height = 0;
};

void DrawLandmarks(cv::Mat& img,
                   const std::vector<FaceDetectionResult>& results) {
  // 引擎回调中的关键点/人脸框已经过 EMA 平滑并归一化到 [0, 1]
  const float img_w = static_cast<float>(img.cols);
  const float img_h = static_cast<float>(img.rows);

  for (const auto& result : results) {
    cv::Rect face_rect(static_cast<int>(result.rect.x * img_w),
                       static_cast<int>(result.rect.y * img_h),
                       static_cast<int>(result.rect.width * img_w),
                       static_cast<int>(result.rect.height * img_h));
    cv::rectangle(img, face_rect, cv::Scalar(0, 255, 0, 255), 2);

    for (size_t i = 0; i < result.key_points.size(); ++i) {
      const auto& point = result.key_points[i];
      int x = static_cast<int>(point.x * img_w);
      int y = static_cast<int>(point.y * img_h);
      if (x < 0 || x >= img.cols || y < 0 || y >= img.rows) {
        continue;
      }

      const bool visible =
          i < result.visibility.size() && result.visibility[i] > 0.5f;
      if (visible) {
        cv::circle(img, cv::Point(x, y), 3, cv::Scalar(255, 0, 0, 255), -1);
        cv::circle(img, cv::Point(x, y), 3, cv::Scalar(255, 255, 255, 255), 1);
      } else {
        cv::circle(img, cv::Point(x, y), 2, cv::Scalar(0, 255, 255, 255), -1);
      }
    }

    std::string info = "Score: " + std::to_string(result.score).substr(0, 4);
    cv::putText(img, info,
                cv::Point(face_rect.x, std::max(0, face_rect.y - 10)),
                cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0, 255, 255, 255), 1);
  }
}

int main(int argc, char* argv[]) {
  (void)argc;
  (void)argv;

  cv::VideoCapture capture(1);
  if (!capture.isOpened()) {
    printf("Error: Cannot open camera\n");
    return 1;
  }
  capture.set(cv::CAP_PROP_FRAME_WIDTH, 1280);
  capture.set(cv::CAP_PROP_FRAME_HEIGHT, 720);
  printf("Camera opened: %dx720\n", (int)capture.get(cv::CAP_PROP_FRAME_WIDTH));

  // 初始化 GLFW
  if (!glfwInit())
    return 1;
  // macOS 需要使用 OpenGL Core Profile
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
  glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, GLFW_FALSE);
#endif
  GLFWwindow* window = glfwCreateWindow(
      1280, 720, "Facebetter Demo (GLFW + ImGui)", nullptr, nullptr);
  if (!window) {
    glfwTerminate();
    return 1;
  }
  glfwMakeContextCurrent(window);
  // 0 才是关掉 vsync；传 2 是「每 2 次场消隐才交换一次」，主线程会在 swap 里
  // 一直等（60Hz 屏上等到 33ms），期间引擎那条 GL 线程要跟它抢驱动，量出来的
  // 单帧处理耗时会被这段等待放大。
  glfwSwapInterval(0);
  if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
    glfwDestroyWindow(window);
    glfwTerminate();
    return 1;
  }

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  ImGuiIO& io = ImGui::GetIO();
  io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
  ImGui::StyleColorsDark();
  ImGui_ImplGlfw_InitForOpenGL(window, true);
  ImGui_ImplOpenGL3_Init("#version 330");

  LogConfig log_cfg;
  log_cfg.console_enabled = true;
  log_cfg.file_enabled = false;
  log_cfg.level = LogLevel::Info;
  BeautyEffectEngine::SetLogConfig(log_cfg);

  EngineConfig eng_cfg;
  eng_cfg.app_id = "dddb24155fd045ab9c2d8aad83ad3a4a";
  eng_cfg.app_key = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";
#ifdef FB_DEMO_RESOURCE_DIR
  eng_cfg.resource_path = FB_DEMO_RESOURCE_DIR;
#else
  eng_cfg.resource_path = "./out";
#endif
  eng_cfg.external_context = false;

  std::shared_ptr<BeautyEffectEngine> engine =
      BeautyEffectEngine::Create(eng_cfg);
  if (!engine) {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    glfwDestroyWindow(window);
    glfwTerminate();
    return 1;
  }
#ifdef FB_DEMO_STICKER_DIR
  const std::string sticker_dir = FB_DEMO_STICKER_DIR;
#else
  const std::string sticker_dir = "./assets/stickers/face";
#endif
#ifdef FB_DEMO_FILTER_DIR
  const std::string filter_dir = FB_DEMO_FILTER_DIR;
#else
  const std::string filter_dir = "./assets/filters";
#endif
#ifdef FB_DEMO_BACKGROUND_PATH
  const std::string background_path = FB_DEMO_BACKGROUND_PATH;
#else
  const std::string background_path = "./assets/background.jpg";
#endif
  engine->ClearSticker();
  engine->ClearFilter();
  engine->ClearVirtualBackground();

  bool show_landmarks_ = false;
  std::vector<FaceDetectionResult> latest_landmarks;
  std::mutex landmarks_mutex;
  EngineCallbacks callbacks;
  callbacks.on_face_landmarks =
      [&latest_landmarks,
       &landmarks_mutex](const std::vector<FaceDetectionResult>& results) {
        std::lock_guard<std::mutex> lock(landmarks_mutex);
        latest_landmarks = results;
      };
  engine->SetCallbacks(callbacks);

  // 基础美颜
  float smoothing_ = 0.0f;
  float whitening_ = 0.0f;
  float rosiness_ = 0.0f;
  float sharpening_ = 0.0f;
  bool skin_only_ = false;

  static const std::vector<std::pair<WhiteningStyle, std::string>>
      kWhiteningOptions = {
          {WhiteningStyle::ColdWhite, "Cold White"},
          {WhiteningStyle::PinkWhite, "Pink White"},
          {WhiteningStyle::WarmWhite, "Warm White"},
          {WhiteningStyle::Wheat, "Wheat"},
          {WhiteningStyle::Tan, "Tan"},
      };
  int whitening_style_index_ = 0;

  static const std::vector<std::pair<SmoothingStyle, std::string>>
      kSmoothingOptions = {
          {SmoothingStyle::Natural, "Natural"},
          {SmoothingStyle::Texture, "Texture"},
          {SmoothingStyle::Smooth, "Smooth"},
      };
  int smoothing_style_index_ = 0;

  // Face Reshape：按部位分组，组内自上而下排。所有效果都接受 [-1, 1]，滑杆
  // 两端是互为反向的两种效果，标签用 "正向 / 反向" 标出。新增效果只要在对应
  // 组里加一行。
  struct ReshapeItem {
    Reshape param;
    const char* label;
  };
  struct ReshapeGroup {
    const char* name;
    std::vector<ReshapeItem> items;
  };
  static const std::vector<ReshapeGroup> kReshapeGroups = {
      {"Face Shape",
       {
           {Reshape::FaceThin, "Thin / Full Cheek"},
           {Reshape::FaceNarrow, "Narrow / Wide"},
           {Reshape::FaceSmall, "Small / Large"},
           {Reshape::FaceShort, "Short / Long"},
           {Reshape::FaceVShape, "V Shape / Square Jaw"},
           {Reshape::Cheekbone, "Cheekbone In / Out"},
           {Reshape::Jawbone, "Jawbone In / Out"},
           {Reshape::Chin, "Chin Long / Short"},
       }},
      {"Forehead & Brow",
       {
           {Reshape::Forehead, "Forehead Full / Low"},
           {Reshape::BrowPosition, "Brow Up / Down"},
           {Reshape::BrowDistance, "Brow Distance +/-"},
           {Reshape::BrowThickness, "Brow Thick / Thin"},
       }},
      {"Eye",
       {
           {Reshape::EyeSize, "Size +/-"},
           {Reshape::EyeRound, "Round / Narrow"},
           {Reshape::EyeDistance, "Distance +/-"},
           {Reshape::EyePosition, "Position Down / Up"},
           {Reshape::EyeAngle, "Outer Corner Up / Down"},
           {Reshape::EyeCornerOpen, "Corner Open / Close"},
           {Reshape::LowerEyelid, "Lower Eyelid Down / Up"},
       }},
      {"Nose",
       {
           {Reshape::NoseSlim, "Slim / Wide"},
           {Reshape::NoseLong, "Long / Short"},
       }},
      {"Mouth",
       {
           {Reshape::Philtrum, "Philtrum Short / Long"},
           {Reshape::MouthSize, "Size +/-"},
           {Reshape::MouthPosition, "Position Down / Up"},
           {Reshape::MouthSmile, "Corner Up / Down"},
           {Reshape::LipThickness, "Lip Thick / Thin"},
       }},
  };
  std::vector<float> reshape_levels_(
      static_cast<size_t>(Reshape::BrowThickness) + 1, 0.0f);

  // 美妆
  float lipstick_ = 0.0f;
  float blush_ = 0.0f;
  float contour_ = 0.0f;
  float eyeshadow_ = 0.0f;
  float eyeliner_ = 0.0f;
  float eyebrow_ = 0.0f;
  float eyelash_ = 0.0f;
  float pupil_ = 0.0f;

  // 美妆色号（单贴图 + 染色，切换无需换素材）
  static const std::vector<std::pair<LipstickColor, std::string>>
      kLipstickOptions = {
          {LipstickColor::Rouge, "Rouge"},
          {LipstickColor::RetroRed, "Retro Red"},
          {LipstickColor::Peach, "Peach"},
          {LipstickColor::CoralOrange, "Coral Orange"},
          {LipstickColor::GentlePink, "Gentle Pink"},
          {LipstickColor::VitalityOrange, "Vitality Orange"},
      };
  int lipstick_style_index_ = 0;

  static const std::vector<std::pair<BlushStyle, std::string>> kBlushOptions = {
      {BlushStyle::SunKissed, "Sun Kissed"},
      {BlushStyle::Igari, "Igari"},
      {BlushStyle::Soft, "Soft"},
      {BlushStyle::Apple, "Apple"},
      {BlushStyle::Classic, "Classic"},
      {BlushStyle::Doll, "Doll"},
      {BlushStyle::Rose, "Rose"},
  };
  int blush_style_index_ = 0;

  static const std::vector<std::pair<BlushColor, std::string>>
      kBlushColorOptions = {
          {BlushColor::CoralPink, "Coral Pink"},
          {BlushColor::DustyRose, "Dusty Rose"},
          {BlushColor::VividRed, "Vivid Red"},
          {BlushColor::Berry, "Berry"},
          {BlushColor::SunsetOrange, "Sunset Orange"},
      };
  int blush_color_index_ = 0;

  static const std::vector<std::pair<ContourStyle, std::string>>
      kContourOptions = {
          {ContourStyle::Natural, "Natural"}, {ContourStyle::Sculpt, "Sculpt"},
          {ContourStyle::Glow, "Glow"},       {ContourStyle::Slim, "Slim"},
          {ContourStyle::Nose, "Nose"},       {ContourStyle::Glam, "Glam"},
      };
  int contour_style_index_ = 0;

  static const std::vector<std::pair<EyeShadowStyle, std::string>>
      kEyeShadowStyleOptions = {
          {EyeShadowStyle::Soft, "Soft"},   {EyeShadowStyle::Crease, "Crease"},
          {EyeShadowStyle::Smoky, "Smoky"}, {EyeShadowStyle::Halo, "Halo"},
          {EyeShadowStyle::Glow, "Glow"},   {EyeShadowStyle::Drama, "Drama"},
          {EyeShadowStyle::Warm, "Warm"},
      };
  int eyeshadow_style_index_ = 0;

  static const std::vector<std::pair<EyeShadowColor, std::string>>
      kEyeShadowOptions = {
          {EyeShadowColor::Plum, "Plum"},
          {EyeShadowColor::Brown, "Brown"},
          {EyeShadowColor::Gold, "Gold"},
          {EyeShadowColor::Pink, "Pink"},
      };
  int eyeshadow_style_index_ = 0;

  static const std::vector<std::pair<EyeLinerStyle, std::string>>
      kEyeLinerStyleOptions = {
          {EyeLinerStyle::Classic, "Classic"},
          {EyeLinerStyle::Flick, "Flick"},
          {EyeLinerStyle::CatEye, "Cat Eye"},
          {EyeLinerStyle::Natural, "Natural"},
          {EyeLinerStyle::Bold, "Bold"},
          {EyeLinerStyle::Soft, "Soft"},
      };
  int eyeliner_style_index_ = 0;

  static const std::vector<std::pair<EyeLinerColor, std::string>>
      kEyeLinerOptions = {
          {EyeLinerColor::Burgundy, "Burgundy"},
          {EyeLinerColor::Plum, "Plum"},
          {EyeLinerColor::Chocolate, "Chocolate"},
          {EyeLinerColor::Coffee, "Coffee"},
          {EyeLinerColor::Mauve, "Mauve"},
      };
  int eyeliner_style_index_ = 0;

  static const std::vector<std::pair<EyebrowStyle, std::string>>
      kEyebrowStyleOptions = {
          {EyebrowStyle::Natural, "Natural"},
          {EyebrowStyle::Soft, "Soft"},
          {EyebrowStyle::Feathered, "Feathered"},
          {EyebrowStyle::Mist, "Mist"},
          {EyebrowStyle::Arched, "Arched"},
          {EyebrowStyle::Powder, "Powder"},
          {EyebrowStyle::Wild, "Wild"},
          {EyebrowStyle::Full, "Full"},
          {EyebrowStyle::Straight, "Straight"},
      };
  int eyebrow_style_index_ = 0;

  static const std::vector<std::pair<EyebrowColor, std::string>>
      kEyebrowOptions = {
          {EyebrowColor::DarkBrown, "Dark Brown"},
          {EyebrowColor::Black, "Black"},
          {EyebrowColor::SoftBrown, "Soft Brown"},
      };
  int eyebrow_style_index_ = 0;

  static const std::vector<std::pair<EyelashStyle, std::string>>
      kEyelashStyleOptions = {
          {EyelashStyle::Classic, "Classic"},
          {EyelashStyle::Manga, "Manga"},
          {EyelashStyle::Winged, "Winged"},
          {EyelashStyle::Wispy, "Wispy"},
          {EyelashStyle::Clustered, "Clustered"},
          {EyelashStyle::Doll, "Doll"},
      };
  int eyelash_style_index_ = 0;

  static const std::vector<std::pair<EyelashColor, std::string>>
      kEyelashOptions = {
          {EyelashColor::Black, "Black"},
          {EyelashColor::Brown, "Brown"},
          {EyelashColor::SoftBlack, "Soft Black"},
      };
  int eyelash_style_index_ = 0;

  static const std::vector<std::pair<PupilColor, std::string>> kPupilOptions = {
      {PupilColor::Hazel, "Hazel"}, {PupilColor::Ice, "Ice"},
      {PupilColor::Mocha, "Mocha"}, {PupilColor::Olive, "Olive"},
      {PupilColor::Gloss, "Gloss"}, {PupilColor::Moss, "Moss"},
      {PupilColor::Sand, "Sand"},   {PupilColor::Glow, "Glow"},
      {PupilColor::Slate, "Slate"},
  };
  int pupil_style_index_ = 0;

  // 滤镜：下拉选择 Off / LUT（直接传 .fbd 路径）
  static const std::vector<std::string> kFilterLabels = {
      "Off", "vivid", "natural", "japanese", "milk_tea", "rose", "fair"};
  const std::vector<std::string> kFilterPaths = {
      "",
      filter_dir + "/vivid/vivid.fbd",
      filter_dir + "/natural/natural.fbd",
      filter_dir + "/japanese/japanese.fbd",
      filter_dir + "/milk_tea/milk_tea.fbd",
      filter_dir + "/rose/rose.fbd",
      filter_dir + "/fair/fair.fbd",
  };
  int filter_index_ = 0;
  float filter_intensity_ = 0.8f;

  // 贴纸：下拉选择 Off / 眼镜贴纸（直接传 .fbd 路径）
  static const std::vector<std::string> kStickerLabels = {
      "Off", "black_glass", "pixel_glass"};
  const std::vector<std::string> kStickerPaths = {
      "", sticker_dir + "/black_glass.fbd", sticker_dir + "/pixel_glass.fbd"};
  int sticker_index_ = 0;

  // 虚拟背景：Fill Off / Blur / Preset；Mask Portrait / Green / Blue / Red
  static const std::vector<std::string> kVirtualBgLabels = {"Off", "Blur",
                                                            "Preset"};
  int virtual_bg_index_ = 0;
  float virtual_bg_blur_ = 0.5f;
  static const std::vector<std::string> kChromaKeyLabels = {
      "Portrait", "Green", "Blue", "Red"};
  int chroma_key_index_ = 0;
  float chroma_similarity_ = 0.4f;
  float chroma_smoothness_ = 0.1f;
  float chroma_desaturation_ = 0.5f;

  ProcessedFrame current_frame;
  std::mutex frame_mutex;
  std::atomic<bool> processing_active{true};

  // 共享缓冲区：用于从处理线程传递图像数据到主线程
  struct PendingFrame {
    std::vector<uint8_t> data;
    int width = 0;
    int height = 0;
    bool ready = false;
  };
  PendingFrame pending_frame;
  std::mutex pending_mutex;
  // 主线程上传纹理时复用，避免每帧 Gen/Delete
  std::vector<uint8_t> upload_buffer;

  std::thread processing_thread([&]() {
    cv::Mat camera_frame;
    cv::Mat rgba_frame;
    auto last_frame_time = std::chrono::steady_clock::now();
    const auto target_frame_interval = std::chrono::milliseconds(33);  // ~30fps

    while (processing_active) {
      auto now = std::chrono::steady_clock::now();
      auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
          now - last_frame_time);
      if (elapsed < target_frame_interval) {
        std::this_thread::sleep_for(target_frame_interval - elapsed);
      }
      last_frame_time = std::chrono::steady_clock::now();

      capture >> camera_frame;
      if (camera_frame.empty()) {
        continue;
      }
      cv::flip(camera_frame, camera_frame, 1);

      cv::cvtColor(camera_frame, rgba_frame, cv::COLOR_BGR2RGBA);

      auto input_frame =
          ImageFrame::CreateWithRGBA(rgba_frame.data, rgba_frame.cols,
                                     rgba_frame.rows, rgba_frame.step[0]);
      if (!input_frame) {
        continue;
      }

      input_frame->type = FrameType::Video;
      auto output_frame = engine->ProcessImage(input_frame);
      if (!output_frame || !output_frame->Data()) {
        continue;
      }

      int w = output_frame->Width();
      int h = output_frame->Height();
      const size_t row_bytes = static_cast<size_t>(w) * 4;
      const size_t data_size = row_bytes * static_cast<size_t>(h);
      const int stride = output_frame->Stride();
      const uint8_t* src = output_frame->Data();

      std::vector<FaceDetectionResult> landmarks_copy;
      if (show_landmarks_) {
        std::lock_guard<std::mutex> landmarks_lock(landmarks_mutex);
        landmarks_copy = latest_landmarks;
      }

      // 直接写入共享缓冲区，去掉中间 Mat 拷贝
      {
        std::lock_guard<std::mutex> lock(pending_mutex);
        // 只有在没有待处理帧时才写入（丢帧策略）
        if (pending_frame.ready) {
          continue;
        }

        pending_frame.data.resize(data_size);
        if (stride == static_cast<int>(row_bytes)) {
          memcpy(pending_frame.data.data(), src, data_size);
        } else {
          for (int row = 0; row < h; ++row) {
            memcpy(pending_frame.data.data() + row * row_bytes,
                   src + row * stride, row_bytes);
          }
        }

        if (!landmarks_copy.empty()) {
          cv::Mat overlay(h, w, CV_8UC4, pending_frame.data.data());
          DrawLandmarks(overlay, landmarks_copy);
        }

        pending_frame.width = w;
        pending_frame.height = h;
        pending_frame.ready = true;
      }
    }
  });

  while (!glfwWindowShouldClose(window)) {
    glfwPollEvents();

    // 取出待渲染帧后在锁外上传，复用同一张 GL 纹理
    bool has_upload = false;
    int upload_w = 0;
    int upload_h = 0;
    {
      std::lock_guard<std::mutex> lock(pending_mutex);
      if (pending_frame.ready && pending_frame.width > 0 &&
          pending_frame.height > 0) {
        upload_buffer.swap(pending_frame.data);
        upload_w = pending_frame.width;
        upload_h = pending_frame.height;
        pending_frame.ready = false;
        has_upload = true;
      }
    }
    if (has_upload) {
      std::lock_guard<std::mutex> lock(frame_mutex);
      if (current_frame.texture == 0) {
        glGenTextures(1, &current_frame.texture);
        glBindTexture(GL_TEXTURE_2D, current_frame.texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, upload_w, upload_h, 0, GL_RGBA,
                     GL_UNSIGNED_BYTE, upload_buffer.data());
        current_frame.width = upload_w;
        current_frame.height = upload_h;
      } else if (current_frame.width != upload_w ||
                 current_frame.height != upload_h) {
        glBindTexture(GL_TEXTURE_2D, current_frame.texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, upload_w, upload_h, 0, GL_RGBA,
                     GL_UNSIGNED_BYTE, upload_buffer.data());
        current_frame.width = upload_w;
        current_frame.height = upload_h;
      } else {
        glBindTexture(GL_TEXTURE_2D, current_frame.texture);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, upload_w, upload_h, GL_RGBA,
                        GL_UNSIGNED_BYTE, upload_buffer.data());
      }
    }

    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(ImVec2(1280, 720));
    ImGui::Begin("Main", nullptr,
                 ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
                     ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoScrollbar);

    const float panel_width = 300.f;
    const float preview_width =
        ImGui::GetContentRegionAvail().x - panel_width - 8.f;

    ImGui::BeginChild("Preview", ImVec2(preview_width, -1), true,
                      ImGuiWindowFlags_NoScrollbar);
    {
      std::lock_guard<std::mutex> lock(frame_mutex);
      if (current_frame.texture != 0 && current_frame.width > 0 &&
          current_frame.height > 0) {
        float avail_w = ImGui::GetContentRegionAvail().x;
        float avail_h = ImGui::GetContentRegionAvail().y;
        float scale =
            (avail_w / static_cast<float>(current_frame.width) <
             avail_h / static_cast<float>(current_frame.height))
                ? (avail_w / static_cast<float>(current_frame.width))
                : (avail_h / static_cast<float>(current_frame.height));
        if (scale > 1.f)
          scale = 1.f;
        float img_w = static_cast<float>(current_frame.width) * scale;
        float img_h = static_cast<float>(current_frame.height) * scale;
        float offset_x = (avail_w - img_w) * 0.5f;
        float offset_y = (avail_h - img_h) * 0.5f;
        if (offset_x > 0.f)
          ImGui::SetCursorPosX(ImGui::GetCursorPosX() + offset_x);
        if (offset_y > 0.f)
          ImGui::SetCursorPosY(ImGui::GetCursorPosY() + offset_y);
        ImGui::Image((ImTextureID)(void*)(uintptr_t)current_frame.texture,
                     ImVec2(img_w, img_h));
      } else {
        ImGui::SetCursorPosY(ImGui::GetCursorPosY() + 200);
        ImGui::TextWrapped("Camera loading...");
      }
    }
    ImGui::EndChild();

    ImGui::SameLine();

    ImGui::BeginChild("BeautyPanel", ImVec2(panel_width, -1), true);
    ImGui::Text("Statistics");
    ImGui::Separator();
    if (ImGui::Checkbox("Show Landmarks", &show_landmarks_)) {
      // toggle only updates overlay drawing
    }
    ImGui::Separator();
    // 性能统计
    {
      auto stats = engine->GetStats();
      ImGui::Text("FPS: %.1f", stats.fps);
      ImGui::Text("Processing Time: %.2f ms", stats.avg_process_time_ms);
      // 格式化显示时分秒
      {
        int64_t total_seconds = static_cast<int64_t>(stats.session_time_s);
        int hours = total_seconds / 3600;
        int minutes = (total_seconds % 3600) / 60;
        int seconds = total_seconds % 60;
        if (hours > 0) {
          ImGui::Text("Session: %02d:%02d:%02d", hours, minutes, seconds);
        } else {
          ImGui::Text("Session: %02d:%02d", minutes, seconds);
        }
      }
    }
    ImGui::Separator();
    ImGui::Text("Beauty Control Panel");
    ImGui::Separator();

    // 分组一：基础美颜（默认展开）
    if (ImGui::CollapsingHeader("Basic Beauty",
                                ImGuiTreeNodeFlags_DefaultOpen)) {
      if (ImGui::SliderFloat("Smoothing", &smoothing_, 0.0f, 1.0f, "%.2f"))
        engine->SetSmoothing(smoothing_);
      if (ImGui::BeginCombo(
              "Smoothing Style",
              kSmoothingOptions[smoothing_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kSmoothingOptions.size(); ++i) {
          bool selected = (smoothing_style_index_ == i);
          if (ImGui::Selectable(kSmoothingOptions[i].second.c_str(),
                                selected)) {
            smoothing_style_index_ = i;
            engine->SetSmoothingStyle(kSmoothingOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (ImGui::SliderFloat("Whitening", &whitening_, 0.0f, 1.0f, "%.2f"))
        engine->SetWhitening(whitening_);
      if (ImGui::BeginCombo(
              "Whitening Style",
              kWhiteningOptions[whitening_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kWhiteningOptions.size(); ++i) {
          bool selected = (whitening_style_index_ == i);
          if (ImGui::Selectable(kWhiteningOptions[i].second.c_str(),
                                selected)) {
            whitening_style_index_ = i;
            engine->SetWhiteningStyle(kWhiteningOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (ImGui::SliderFloat("Rosiness", &rosiness_, 0.0f, 1.0f, "%.2f"))
        engine->SetRosiness(rosiness_);
      if (ImGui::SliderFloat("Sharpening", &sharpening_, 0.0f, 1.0f, "%.2f"))
        engine->SetSharpening(sharpening_);
      if (ImGui::Checkbox("Skin Only", &skin_only_))
        engine->SetBeautySkinOnly(skin_only_);
    }

    // 分组二：Face Reshape
    if (ImGui::CollapsingHeader("Face Reshape")) {
      if (ImGui::Button("Reset Reshape")) {
        for (const ReshapeGroup& group : kReshapeGroups) {
          for (const ReshapeItem& item : group.items) {
            reshape_levels_[static_cast<size_t>(item.param)] = 0.0f;
            engine->SetReshape(item.param, 0.0f);
          }
        }
      }
      for (const ReshapeGroup& group : kReshapeGroups) {
        ImGui::SeparatorText(group.name);
        // ImGui 用标签算控件 ID，"Size +/-" 这类短标签在 Eye 和 Mouth 两组里
        // 重名，不隔开的话两个滑杆会共用同一个 ID、一起联动。
        ImGui::PushID(group.name);
        for (const ReshapeItem& item : group.items) {
          float& level = reshape_levels_[static_cast<size_t>(item.param)];
          if (ImGui::SliderFloat(item.label, &level, -1.0f, 1.0f, "%.2f")) {
            engine->SetReshape(item.param, level);
          }
        }
        ImGui::PopID();
      }
    }

    // 分组三：美妆
    if (ImGui::CollapsingHeader("Makeup")) {
      if (ImGui::SliderFloat("Lipstick", &lipstick_, 0.0f, 1.0f, "%.2f"))
        engine->SetLipstick(lipstick_);
      if (ImGui::BeginCombo(
              "Lipstick Style",
              kLipstickOptions[lipstick_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kLipstickOptions.size(); ++i) {
          bool selected = (lipstick_style_index_ == i);
          if (ImGui::Selectable(kLipstickOptions[i].second.c_str(), selected)) {
            lipstick_style_index_ = i;
            engine->SetLipstickColor(kLipstickOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }

      if (ImGui::SliderFloat("Blush", &blush_, 0.0f, 1.0f, "%.2f"))
        engine->SetBlush(blush_);
      if (ImGui::BeginCombo("Blush Style",
                            kBlushOptions[blush_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kBlushOptions.size(); ++i) {
          bool selected = (blush_style_index_ == i);
          if (ImGui::Selectable(kBlushOptions[i].second.c_str(), selected)) {
            blush_style_index_ = i;
            engine->SetBlushStyle(kBlushOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (ImGui::BeginCombo(
              "Blush Color",
              kBlushColorOptions[blush_color_index_].second.c_str())) {
        for (int i = 0; i < (int)kBlushColorOptions.size(); ++i) {
          bool selected = (blush_color_index_ == i);
          if (ImGui::Selectable(kBlushColorOptions[i].second.c_str(),
                                selected)) {
            blush_color_index_ = i;
            engine->SetBlushColor(kBlushColorOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }

      if (ImGui::SliderFloat("Contour", &contour_, 0.0f, 1.0f, "%.2f"))
        engine->SetContour(contour_);
      if (ImGui::BeginCombo(
              "Contour Style",
              kContourOptions[contour_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kContourOptions.size(); ++i) {
          bool selected = (contour_style_index_ == i);
          if (ImGui::Selectable(kContourOptions[i].second.c_str(), selected)) {
            contour_style_index_ = i;
            engine->SetContourStyle(kContourOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }

      if (ImGui::SliderFloat("Eye Shadow", &eyeshadow_, 0.0f, 1.0f, "%.2f"))
        engine->SetEyeShadow(eyeshadow_);
      if (ImGui::BeginCombo(
              "Eye Shadow Style",
              kEyeShadowStyleOptions[eyeshadow_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyeShadowStyleOptions.size(); ++i) {
          bool selected = (eyeshadow_style_index_ == i);
          if (ImGui::Selectable(kEyeShadowStyleOptions[i].second.c_str(),
                                selected)) {
            eyeshadow_style_index_ = i;
            engine->SetEyeShadowStyle(kEyeShadowStyleOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (ImGui::BeginCombo(
              "Eye Shadow Color",
              kEyeShadowOptions[eyeshadow_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyeShadowOptions.size(); ++i) {
          bool selected = (eyeshadow_style_index_ == i);
          if (ImGui::Selectable(kEyeShadowOptions[i].second.c_str(),
                                selected)) {
            eyeshadow_style_index_ = i;
            engine->SetEyeShadowColor(kEyeShadowOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }

      if (ImGui::SliderFloat("Pupil", &pupil_, 0.0f, 1.0f, "%.2f"))
        engine->SetPupil(pupil_);
      if (ImGui::BeginCombo("Pupil Style",
                            kPupilOptions[pupil_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kPupilOptions.size(); ++i) {
          bool selected = (pupil_style_index_ == i);
          if (ImGui::Selectable(kPupilOptions[i].second.c_str(), selected)) {
            pupil_style_index_ = i;
            engine->SetPupilColor(kPupilOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }

      if (ImGui::SliderFloat("Eye Liner", &eyeliner_, 0.0f, 1.0f, "%.2f"))
        engine->SetEyeLiner(eyeliner_);
      if (ImGui::BeginCombo(
              "Eye Liner Style",
              kEyeLinerStyleOptions[eyeliner_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyeLinerStyleOptions.size(); ++i) {
          bool selected = (eyeliner_style_index_ == i);
          if (ImGui::Selectable(kEyeLinerStyleOptions[i].second.c_str(),
                                selected)) {
            eyeliner_style_index_ = i;
            engine->SetEyeLinerStyle(kEyeLinerStyleOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (ImGui::BeginCombo(
              "Eye Liner Color",
              kEyeLinerOptions[eyeliner_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyeLinerOptions.size(); ++i) {
          bool selected = (eyeliner_style_index_ == i);
          if (ImGui::Selectable(kEyeLinerOptions[i].second.c_str(), selected)) {
            eyeliner_style_index_ = i;
            engine->SetEyeLinerColor(kEyeLinerOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }

      if (ImGui::SliderFloat("Eyelash", &eyelash_, 0.0f, 1.0f, "%.2f"))
        engine->SetEyelash(eyelash_);
      if (ImGui::BeginCombo(
              "Eyelash Style",
              kEyelashStyleOptions[eyelash_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyelashStyleOptions.size(); ++i) {
          bool selected = (eyelash_style_index_ == i);
          if (ImGui::Selectable(kEyelashStyleOptions[i].second.c_str(),
                                selected)) {
            eyelash_style_index_ = i;
            engine->SetEyelashStyle(kEyelashStyleOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (ImGui::BeginCombo(
              "Eyelash Color",
              kEyelashOptions[eyelash_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyelashOptions.size(); ++i) {
          bool selected = (eyelash_style_index_ == i);
          if (ImGui::Selectable(kEyelashOptions[i].second.c_str(), selected)) {
            eyelash_style_index_ = i;
            engine->SetEyelashColor(kEyelashOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }

      if (ImGui::SliderFloat("Eyebrow", &eyebrow_, 0.0f, 1.0f, "%.2f"))
        engine->SetEyebrow(eyebrow_);
      if (ImGui::BeginCombo(
              "Eyebrow Style",
              kEyebrowStyleOptions[eyebrow_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyebrowStyleOptions.size(); ++i) {
          bool selected = (eyebrow_style_index_ == i);
          if (ImGui::Selectable(kEyebrowStyleOptions[i].second.c_str(),
                                selected)) {
            eyebrow_style_index_ = i;
            engine->SetEyebrowStyle(kEyebrowStyleOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (ImGui::BeginCombo(
              "Eyebrow Color",
              kEyebrowOptions[eyebrow_style_index_].second.c_str())) {
        for (int i = 0; i < (int)kEyebrowOptions.size(); ++i) {
          bool selected = (eyebrow_style_index_ == i);
          if (ImGui::Selectable(kEyebrowOptions[i].second.c_str(), selected)) {
            eyebrow_style_index_ = i;
            engine->SetEyebrowColor(kEyebrowOptions[i].first);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
    }

    // 分组四：滤镜（下拉选择 + 强度）
    if (ImGui::CollapsingHeader("Filter")) {
      const char* current = filter_index_ < (int)kFilterLabels.size()
                                ? kFilterLabels[filter_index_].c_str()
                                : "Off";
      if (ImGui::BeginCombo("##filter", current)) {
        for (int i = 0; i < (int)kFilterLabels.size(); ++i) {
          bool selected = (filter_index_ == i);
          if (ImGui::Selectable(kFilterLabels[i].c_str(), selected)) {
            filter_index_ = i;
            if (i == 0) {
              engine->ClearFilter();
            } else {
              engine->SetFilter(kFilterPaths[i]);
              engine->SetFilterIntensity(filter_intensity_);
            }
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (filter_index_ > 0 &&
          ImGui::SliderFloat("Intensity", &filter_intensity_, 0.f, 1.f)) {
        engine->SetFilterIntensity(filter_intensity_);
      }
    }

    // 分组五：贴纸（下拉选择）
    if (ImGui::CollapsingHeader("Sticker")) {
      const char* current = sticker_index_ < (int)kStickerLabels.size()
                                ? kStickerLabels[sticker_index_].c_str()
                                : "Off";
      if (ImGui::BeginCombo("##sticker", current)) {
        for (int i = 0; i < (int)kStickerLabels.size(); ++i) {
          bool selected = (sticker_index_ == i);
          if (ImGui::Selectable(kStickerLabels[i].c_str(), selected)) {
            sticker_index_ = i;
            if (i == 0)
              engine->ClearSticker();
            else
              engine->SetSticker(kStickerPaths[i]);
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
    }

    // 分组六：虚拟背景（Fill + Mask）
    if (ImGui::CollapsingHeader("Virtual Background")) {
      const char* current =
          virtual_bg_index_ < (int)kVirtualBgLabels.size()
              ? kVirtualBgLabels[virtual_bg_index_].c_str()
              : "Off";
      if (ImGui::BeginCombo("Fill", current)) {
        for (int i = 0; i < (int)kVirtualBgLabels.size(); ++i) {
          bool selected = (virtual_bg_index_ == i);
          if (ImGui::Selectable(kVirtualBgLabels[i].c_str(), selected)) {
            virtual_bg_index_ = i;
            if (i == 0) {
              engine->ClearVirtualBackground();
            } else if (i == 1) {
              engine->SetVirtualBackgroundBlur(virtual_bg_blur_);
            } else {
              engine->SetVirtualBackground(background_path);
            }
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (virtual_bg_index_ == 1 &&
          ImGui::SliderFloat("Blur Level", &virtual_bg_blur_, 0.f, 1.f,
                             "%.2f")) {
        engine->SetVirtualBackgroundBlur(virtual_bg_blur_);
      }

      const char* mask_current =
          chroma_key_index_ < (int)kChromaKeyLabels.size()
              ? kChromaKeyLabels[chroma_key_index_].c_str()
              : "Portrait";
      if (ImGui::BeginCombo("Mask", mask_current)) {
        for (int i = 0; i < (int)kChromaKeyLabels.size(); ++i) {
          bool selected = (chroma_key_index_ == i);
          if (ImGui::Selectable(kChromaKeyLabels[i].c_str(), selected)) {
            chroma_key_index_ = i;
            if (i == 0) {
              engine->ClearChromaKey();
            } else {
              engine->SetChromaKey(static_cast<ChromaKeyColor>(i - 1));
              engine->SetChromaKeySimilarity(chroma_similarity_);
              engine->SetChromaKeySmoothness(chroma_smoothness_);
              engine->SetChromaKeyDesaturation(chroma_desaturation_);
            }
          }
          if (selected)
            ImGui::SetItemDefaultFocus();
        }
        ImGui::EndCombo();
      }
      if (chroma_key_index_ > 0) {
        if (ImGui::SliderFloat("Similarity", &chroma_similarity_, 0.f, 1.f,
                               "%.2f")) {
          engine->SetChromaKeySimilarity(chroma_similarity_);
        }
        if (ImGui::SliderFloat("Smoothness", &chroma_smoothness_, 0.f, 1.f,
                               "%.2f")) {
          engine->SetChromaKeySmoothness(chroma_smoothness_);
        }
        if (ImGui::SliderFloat("Spill", &chroma_desaturation_, 0.f, 1.f,
                               "%.2f")) {
          engine->SetChromaKeyDesaturation(chroma_desaturation_);
        }
      }
    }

    ImGui::Spacing();
    ImGui::Separator();
    if (ImGui::Button("Reset All")) {
      smoothing_ = whitening_ = rosiness_ = sharpening_ = 0.f;
      whitening_style_index_ = 0;
      smoothing_style_index_ = 0;
      lipstick_ = blush_ = contour_ = eyeshadow_ = eyeliner_ = eyebrow_ =
          eyelash_ = pupil_ = 0.f;
      lipstick_style_index_ = 0;
      blush_style_index_ = 0;
      blush_color_index_ = 0;
      contour_style_index_ = 0;
      eyeshadow_style_index_ = 0;
      eyeshadow_style_index_ = 0;
      eyeliner_style_index_ = 0;
      eyeliner_style_index_ = 0;
      eyebrow_style_index_ = 0;
      eyebrow_style_index_ = 0;
      eyelash_style_index_ = 0;
      eyelash_style_index_ = 0;
      pupil_style_index_ = 0;
      filter_index_ = 0;
      filter_intensity_ = 0.8f;
      sticker_index_ = 0;
      virtual_bg_index_ = 0;
      virtual_bg_blur_ = 0.5f;
      chroma_key_index_ = 0;
      chroma_similarity_ = 0.4f;
      chroma_smoothness_ = 0.1f;
      chroma_desaturation_ = 0.5f;
      skin_only_ = false;
      engine->SetSmoothing(0.f);
      engine->SetSmoothingStyle(SmoothingStyle::Natural);
      engine->SetWhitening(0.f);
      engine->SetWhiteningStyle(WhiteningStyle::ColdWhite);
      engine->SetRosiness(0.f);
      engine->SetSharpening(0.f);
      engine->SetBeautySkinOnly(false);
      for (const ReshapeGroup& group : kReshapeGroups) {
        for (const ReshapeItem& item : group.items) {
          reshape_levels_[static_cast<size_t>(item.param)] = 0.f;
          engine->SetReshape(item.param, 0.f);
        }
      }
      engine->SetLipstick(0.f);
      engine->SetBlush(0.f);
      engine->SetContour(0.f);
      engine->SetEyeShadow(0.f);
      engine->SetEyeLiner(0.f);
      engine->SetEyebrow(0.f);
      engine->SetEyelash(0.f);
      engine->SetPupil(0.f);
      engine->SetLipstickColor(LipstickColor::Rouge);
      engine->SetBlushStyle(BlushStyle::SunKissed);
      engine->SetBlushColor(BlushColor::CoralPink);
      engine->SetContourStyle(ContourStyle::Natural);
      engine->SetEyeShadowStyle(EyeShadowStyle::Soft);
      engine->SetEyeShadowColor(EyeShadowColor::Plum);
      engine->SetEyeLinerStyle(EyeLinerStyle::Classic);
      engine->SetEyeLinerColor(EyeLinerColor::Burgundy);
      engine->SetEyebrowStyle(EyebrowStyle::Natural);
      engine->SetEyebrowColor(EyebrowColor::DarkBrown);
      engine->SetEyelashStyle(EyelashStyle::Classic);
      engine->SetEyelashColor(EyelashColor::Black);
      engine->SetPupilColor(PupilColor::Hazel);
      engine->ClearFilter();
      engine->ClearSticker();
      engine->ClearVirtualBackground();
      engine->ClearChromaKey();
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

  processing_active = false;
  if (processing_thread.joinable()) {
    processing_thread.join();
  }

  {
    std::lock_guard<std::mutex> lock(frame_mutex);
    if (current_frame.texture != 0) {
      glDeleteTextures(1, &current_frame.texture);
    }
  }

  engine.reset();
  capture.release();
  ImGui_ImplOpenGL3_Shutdown();
  ImGui_ImplGlfw_Shutdown();
  ImGui::DestroyContext();
  glfwDestroyWindow(window);
  glfwTerminate();
  return 0;
}
