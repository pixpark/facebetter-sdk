#include "studio.h"

// clang-format off
#include <glad/glad.h>
#include <GLFW/glfw3.h>
// clang-format on

#include <facebetter/image_frame.h>

#include <algorithm>
#include <chrono>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <opencv2/opencv.hpp>
#include <utility>

namespace demo {
namespace {

namespace fs = std::filesystem;
using facebetter::BeautyEffectEngine;
using facebetter::EngineCallbacks;
using facebetter::EngineConfig;
using facebetter::FrameType;
using facebetter::ImageFrame;
using facebetter::LogConfig;
using facebetter::LogLevel;

constexpr int kMaxEdge = 1280;

#ifndef FB_DEMO_RESOURCE_DIR
#define FB_DEMO_RESOURCE_DIR "./out"
#endif
#ifndef FB_DEMO_STICKER_DIR
#define FB_DEMO_STICKER_DIR "./assets/stickers/face"
#endif
#ifndef FB_DEMO_FILTER_DIR
#define FB_DEMO_FILTER_DIR "./assets/filters"
#endif
#ifndef FB_DEMO_BACKGROUND_PATH
#define FB_DEMO_BACKGROUND_PATH "./assets/background.jpg"
#endif
#ifndef FB_DEMO_FACE_PATH
#define FB_DEMO_FACE_PATH "./assets/face.jpg"
#endif

const char* kAppId = "dddb24155fd045ab9c2d8aad83ad3a4a";
const char* kAppKey = "-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc";

const char* kFilterIds[] = {
    "initial_heart", "first_love", "vivid",        "confession", "milk_tea",
    "mousse",        "japanese",   "dawn",         "cookie",     "lively",
    "pure",          "fair",       "snow",         "plain",      "natural",
    "rose",          "tender",     "tender_2",     "extraordinary",
};

const char* kStickerIds[] = {
    "black_glass", "pixel_glass", "fox",     "antler",    "crown",
    "hat",         "hat3",        "kiss",    "kiss2",     "mustache",
    "mustache2",
};

RgbaBuffer FromBgr(const cv::Mat& bgr) {
  RgbaBuffer out;
  if (bgr.empty())
    return out;
  cv::Mat resized = bgr;
  const int edge = std::max(bgr.cols, bgr.rows);
  if (edge > kMaxEdge) {
    const double scale = static_cast<double>(kMaxEdge) / edge;
    cv::resize(bgr, resized,
               cv::Size(std::max(1, static_cast<int>(bgr.cols * scale)),
                        std::max(1, static_cast<int>(bgr.rows * scale))),
               0, 0, cv::INTER_AREA);
  }
  cv::Mat rgba;
  cv::cvtColor(resized, rgba, cv::COLOR_BGR2RGBA);
  if (!rgba.isContinuous())
    rgba = rgba.clone();
  out.width = rgba.cols;
  out.height = rgba.rows;
  const auto* p = rgba.ptr<uint8_t>(0);
  out.rgba.assign(p, p + static_cast<size_t>(rgba.total()) * rgba.elemSize());
  return out;
}

cv::Mat DecodeImage(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  if (!in)
    return {};
  std::vector<char> bytes((std::istreambuf_iterator<char>(in)),
                          std::istreambuf_iterator<char>());
  if (bytes.empty())
    return {};
  return cv::imdecode(cv::Mat(1, static_cast<int>(bytes.size()), CV_8U, bytes.data()),
                      cv::IMREAD_COLOR);
}

RgbaBuffer CopyOutput(const ImageFrame& frame) {
  RgbaBuffer out;
  out.width = frame.Width();
  out.height = frame.Height();
  const uint8_t* src = frame.Data();
  if (!src || out.width <= 0 || out.height <= 0)
    return {};
  const size_t row = static_cast<size_t>(out.width) * 4;
  const int stride = frame.Stride();
  out.rgba.resize(row * static_cast<size_t>(out.height));
  if (stride == static_cast<int>(row)) {
    std::memcpy(out.rgba.data(), src, out.rgba.size());
  } else {
    for (int y = 0; y < out.height; ++y) {
      std::memcpy(out.rgba.data() + static_cast<size_t>(y) * row,
                  src + static_cast<size_t>(y) * stride, row);
    }
  }
  return out;
}

cv::Mat RgbaToBgr(const RgbaBuffer& buf) {
  if (buf.empty())
    return {};
  cv::Mat rgba(buf.height, buf.width, CV_8UC4);
  std::memcpy(rgba.data, buf.rgba.data(), buf.rgba.size());
  cv::Mat bgr;
  cv::cvtColor(rgba, bgr, cv::COLOR_RGBA2BGR);
  return bgr;
}

}  // namespace

Studio::~Studio() {
  Shutdown();
}

bool Studio::Init(GLFWwindow* window) {
  window_ = window;
  filter_dir_ = FB_DEMO_FILTER_DIR;
  sticker_dir_ = FB_DEMO_STICKER_DIR;
  background_path_ = FB_DEMO_BACKGROUND_PATH;
  ScanAssets();

  LogConfig log_cfg;
  log_cfg.console_enabled = true;
  log_cfg.file_enabled = false;
  log_cfg.level = LogLevel::Info;
  BeautyEffectEngine::SetLogConfig(log_cfg);

  EngineConfig eng_cfg;
  eng_cfg.app_id = kAppId;
  eng_cfg.app_key = kAppKey;
  eng_cfg.resource_path = FB_DEMO_RESOURCE_DIR;
  eng_cfg.external_context = false;

  engine_ = BeautyEffectEngine::Create(eng_cfg);
  if (!engine_) {
    SetStatus("status.initFailed");
    return false;
  }

  EngineCallbacks callbacks;
  callbacks.on_face_landmarks = [this](const std::vector<FaceDetectionResult>& results) {
    std::lock_guard<std::mutex> lock(mu_);
    pending_faces_ = results;
  };
  engine_->SetCallbacks(callbacks);
  engine_->ClearSticker();
  engine_->ClearFilter();
  engine_->ClearVirtualBackground();
  engine_->ClearChromaKey();

  shared_params_ = params_;
  running_ = true;
  worker_ = std::thread(&Studio::WorkerLoop, this);

  LoadImageFile(FB_DEMO_FACE_PATH);
  return true;
}

void Studio::Shutdown() {
  {
    std::lock_guard<std::mutex> lock(mu_);
    running_ = false;
  }
  cv_.notify_all();
  if (worker_.joinable())
    worker_.join();

  engine_.reset();
  if (original_gpu_.texture) {
    glDeleteTextures(1, &original_gpu_.texture);
    original_gpu_ = {};
  }
  if (processed_gpu_.texture) {
    glDeleteTextures(1, &processed_gpu_.texture);
    processed_gpu_ = {};
  }
}

void Studio::ScanAssets() {
  filters_.clear();
  for (const char* id : kFilterIds) {
    Asset item;
    item.id = id;
    item.path = filter_dir_ + "/" + item.id + "/" + item.id + ".fbd";
    if (fs::exists(item.path))
      filters_.push_back(std::move(item));
  }
  stickers_.clear();
  for (const char* id : kStickerIds) {
    Asset item;
    item.id = id;
    item.path = sticker_dir_ + "/" + item.id + ".fbd";
    if (fs::exists(item.path))
      stickers_.push_back(std::move(item));
  }
}

void Studio::LoadImageFile(const std::string& path) {
  cv::Mat bgr = DecodeImage(path);
  if (bgr.empty())
    bgr = cv::imread(path, cv::IMREAD_COLOR);
  if (bgr.empty()) {
    SetStatus("status.loadFailed");
    return;
  }
  RgbaBuffer rgba = FromBgr(bgr);
  {
    std::lock_guard<std::mutex> lock(mu_);
    still_original_ = std::move(rgba);
    source_ = Source::Image;
    still_dirty_ = true;
  }
  cv_.notify_one();
  SetStatus("status.imageLoaded");
}

void Studio::StartCamera() {
  {
    std::lock_guard<std::mutex> lock(mu_);
    source_ = Source::Camera;
    still_dirty_ = false;
  }
  cv_.notify_one();
}

void Studio::StopCamera() {
  {
    std::lock_guard<std::mutex> lock(mu_);
    if (source_ != Source::Camera)
      return;
    source_ = still_original_.empty() ? Source::None : Source::Image;
    still_dirty_ = !still_original_.empty();
  }
  cv_.notify_one();
}

bool Studio::ExportPng(const std::string& path) {
  RgbaBuffer copy;
  {
    std::lock_guard<std::mutex> lock(mu_);
    if (!pending_processed_.empty())
      copy = pending_processed_;
  }
  if (copy.empty()) {
    SetStatus("status.exportEmpty");
    return false;
  }
  cv::Mat bgr = RgbaToBgr(copy);
  if (bgr.empty() || !cv::imwrite(path, bgr)) {
    SetStatus("status.exportFailed");
    return false;
  }
  SetStatus("status.exported");
  return true;
}

void Studio::NotifyParamsChanged() {
  std::lock_guard<std::mutex> lock(mu_);
  shared_params_ = params_;
  if (source_ == Source::Image)
    still_dirty_ = true;
  cv_.notify_one();
}

void Studio::ResetParams() {
  const bool overlay = params_.face_overlay;
  params_ = Params{};
  params_.face_overlay = overlay;
  NotifyParamsChanged();
  SetStatus("status.reset");
}

void Studio::UploadGpu() {
  RgbaBuffer processed;
  RgbaBuffer original;
  std::vector<FaceDetectionResult> faces;
  EngineStats stats;
  {
    std::lock_guard<std::mutex> lock(mu_);
    if (!pending_ready_)
      return;
    processed = pending_processed_;
    original = pending_original_;
    faces = pending_faces_;
    stats = pending_stats_;
    pending_ready_ = false;
  }
  cv_.notify_one();
  UploadTexture(&processed_gpu_, processed);
  UploadTexture(&original_gpu_, original);
  faces_ = std::move(faces);
  stats_ = stats;
}

bool Studio::IsCamera() const {
  std::lock_guard<std::mutex> lock(mu_);
  return source_ == Source::Camera;
}

bool Studio::HasFrame() const {
  return processed_gpu_.texture != 0 && processed_gpu_.width > 0;
}

std::vector<FaceDetectionResult> Studio::Faces() const {
  return faces_;
}

EngineStats Studio::Stats() const {
  return stats_;
}

std::string Studio::Status() const {
  std::lock_guard<std::mutex> lock(mu_);
  if (status_.empty() || std::chrono::steady_clock::now() > status_until_)
    return {};
  return status_;
}

void Studio::SetStatus(std::string text) {
  std::lock_guard<std::mutex> lock(mu_);
  status_ = std::move(text);
  status_until_ = std::chrono::steady_clock::now() + std::chrono::milliseconds(2200);
}

void Studio::ApplyToEngine(const Params& p, const Params* prev) {
  engine_->SetSmoothing(p.smoothing);
  engine_->SetSmoothingStyle(p.smoothing_style);
  engine_->SetWhitening(p.whitening);
  engine_->SetWhiteningStyle(p.whitening_style);
  engine_->SetRosiness(p.rosiness);
  engine_->SetSharpening(p.sharpening);
  engine_->SetBeautySkinOnly(p.skin_only);

  for (size_t i = 0; i < p.reshape.size(); ++i) {
    engine_->SetReshape(static_cast<Reshape>(i), p.reshape[i]);
  }

  engine_->SetLipstick(p.lipstick);
  engine_->SetLipstickColor(p.lipstick_color);
  engine_->SetBlush(p.blush);
  engine_->SetBlushStyle(p.blush_style);
  engine_->SetBlushColor(p.blush_color);
  engine_->SetContour(p.contour);
  engine_->SetContourStyle(p.contour_style);
  engine_->SetEyeShadow(p.eyeshadow);
  engine_->SetEyeShadowStyle(p.eyeshadow_style);
  engine_->SetEyeShadowColor(p.eyeshadow_color);
  engine_->SetEyeLiner(p.eyeliner);
  engine_->SetEyeLinerStyle(p.eyeliner_style);
  engine_->SetEyeLinerColor(p.eyeliner_color);
  engine_->SetEyebrow(p.eyebrow);
  engine_->SetEyebrowStyle(p.eyebrow_style);
  engine_->SetEyebrowColor(p.eyebrow_color);
  engine_->SetEyelash(p.eyelash);
  engine_->SetEyelashStyle(p.eyelash_style);
  engine_->SetEyelashColor(p.eyelash_color);
  engine_->SetPupil(p.pupil);
  engine_->SetPupilColor(p.pupil_color);

  const bool filter_changed = !prev || prev->filter_id != p.filter_id;
  if (filter_changed) {
    if (p.filter_id.empty()) {
      engine_->ClearFilter();
    } else {
      engine_->SetFilter(filter_dir_ + "/" + p.filter_id + "/" + p.filter_id +
                         ".fbd");
    }
  }
  if (!p.filter_id.empty())
    engine_->SetFilterIntensity(p.filter_intensity);

  if (!prev || prev->sticker_id != p.sticker_id) {
    if (p.sticker_id.empty())
      engine_->ClearSticker();
    else
      engine_->SetSticker(sticker_dir_ + "/" + p.sticker_id + ".fbd");
  }

  const bool chroma_changed =
      !prev || prev->chroma != p.chroma ||
      prev->chroma_similarity != p.chroma_similarity ||
      prev->chroma_smoothness != p.chroma_smoothness ||
      prev->chroma_desaturation != p.chroma_desaturation;
  if (chroma_changed) {
    if (p.chroma <= 0) {
      engine_->ClearChromaKey();
    } else {
      engine_->SetChromaKey(static_cast<ChromaKeyColor>(p.chroma - 1));
      engine_->SetChromaKeySimilarity(p.chroma_similarity);
      engine_->SetChromaKeySmoothness(p.chroma_smoothness);
      engine_->SetChromaKeyDesaturation(p.chroma_desaturation);
    }
  }

  const bool bg_changed =
      !prev || prev->bg_fill != p.bg_fill || prev->bg_blur != p.bg_blur;
  if (bg_changed) {
    if (p.bg_fill == BgFill::Blur) {
      engine_->SetVirtualBackgroundBlur(p.bg_blur);
    } else if (p.bg_fill == BgFill::Preset) {
      engine_->SetVirtualBackground(background_path_);
    } else {
      engine_->ClearVirtualBackground();
    }
  }
}

void Studio::Publish(RgbaBuffer processed,
                     RgbaBuffer original,
                     std::vector<FaceDetectionResult> faces,
                     EngineStats stats) {
  {
    std::lock_guard<std::mutex> lock(mu_);
    pending_processed_ = std::move(processed);
    pending_original_ = std::move(original);
    pending_faces_ = std::move(faces);
    pending_stats_ = stats;
    pending_ready_ = true;
  }
  if (window_)
    glfwPostEmptyEvent();
}

void Studio::UploadTexture(GpuFrame* gpu, const RgbaBuffer& buf) {
  if (!gpu || buf.empty())
    return;
  if (gpu->texture == 0) {
    glGenTextures(1, &gpu->texture);
    glBindTexture(GL_TEXTURE_2D, gpu->texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, buf.width, buf.height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, buf.rgba.data());
    gpu->width = buf.width;
    gpu->height = buf.height;
    return;
  }
  glBindTexture(GL_TEXTURE_2D, gpu->texture);
  if (gpu->width != buf.width || gpu->height != buf.height) {
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, buf.width, buf.height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, buf.rgba.data());
    gpu->width = buf.width;
    gpu->height = buf.height;
  } else {
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, buf.width, buf.height, GL_RGBA,
                    GL_UNSIGNED_BYTE, buf.rgba.data());
  }
}

void Studio::WorkerLoop() {
  cv::VideoCapture capture;
  cv::Mat camera_bgr;
  Params applied;
  bool have_applied = false;

  while (true) {
    Source source;
    Params params;
    RgbaBuffer still;
    {
      std::unique_lock<std::mutex> lock(mu_);
      cv_.wait(lock, [this] {
        if (!running_)
          return true;
        if (pending_ready_)
          return false;
        if (source_ == Source::Camera)
          return true;
        return still_dirty_;
      });
      if (!running_)
        break;
      source = source_;
      params = shared_params_;
      if (source == Source::Image && still_dirty_) {
        still = still_original_;
        still_dirty_ = false;
      }
    }

    if (source != Source::Camera && capture.isOpened())
      capture.release();

    ApplyToEngine(params, have_applied ? &applied : nullptr);
    applied = params;
    have_applied = true;

    auto process = [&](const RgbaBuffer& input, FrameType type) -> bool {
      if (input.empty())
        return false;
      auto frame = ImageFrame::CreateWithRGBA(input.rgba.data(), input.width,
                                              input.height, input.width * 4);
      if (!frame)
        return false;
      frame->type = type;
      auto output = engine_->ProcessImage(frame);
      if (!output || !output->Data())
        return false;
      std::vector<FaceDetectionResult> latest;
      {
        std::lock_guard<std::mutex> lock(mu_);
        latest = pending_faces_;
      }
      Publish(CopyOutput(*output), input, std::move(latest), engine_->GetStats());
      return true;
    };

    if (source == Source::Camera) {
      if (!capture.isOpened()) {
        capture.open(0);
        if (!capture.isOpened())
          capture.open(1);
        if (!capture.isOpened()) {
          SetStatus("status.cameraFailed");
          std::lock_guard<std::mutex> lock(mu_);
          source_ = still_original_.empty() ? Source::None : Source::Image;
          still_dirty_ = !still_original_.empty();
          continue;
        }
        capture.set(cv::CAP_PROP_FRAME_WIDTH, 1280);
        capture.set(cv::CAP_PROP_FRAME_HEIGHT, 720);
        SetStatus("status.cameraOn");
      }
      capture >> camera_bgr;
      if (camera_bgr.empty()) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        continue;
      }
      cv::flip(camera_bgr, camera_bgr, 1);
      process(FromBgr(camera_bgr), FrameType::Video);
    } else if (source == Source::Image) {
      if (!still.empty())
        process(still, FrameType::Image);
    }
  }

  if (capture.isOpened())
    capture.release();
}

}  // namespace demo
