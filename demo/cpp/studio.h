#pragma once

#include <array>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include <facebetter/beauty_effect_engine.h>
#include <facebetter/beauty_params.h>
#include <facebetter/type_defines.h>

struct GLFWwindow;

namespace demo {

using facebetter::EngineStats;
using facebetter::FaceDetectionResult;
using facebetter::beauty_params::BlushColor;
using facebetter::beauty_params::BlushStyle;
using facebetter::beauty_params::ChromaKeyColor;
using facebetter::beauty_params::ContourStyle;
using facebetter::beauty_params::EyeLinerColor;
using facebetter::beauty_params::EyeLinerStyle;
using facebetter::beauty_params::EyeShadowColor;
using facebetter::beauty_params::EyeShadowStyle;
using facebetter::beauty_params::EyebrowColor;
using facebetter::beauty_params::EyebrowStyle;
using facebetter::beauty_params::EyelashColor;
using facebetter::beauty_params::EyelashStyle;
using facebetter::beauty_params::LipstickColor;
using facebetter::beauty_params::PupilColor;
using facebetter::beauty_params::Reshape;
using facebetter::beauty_params::SmoothingStyle;
using facebetter::beauty_params::WhiteningStyle;

constexpr size_t kReshapeCount =
    static_cast<size_t>(Reshape::BrowThickness) + 1;

enum class Source { None, Image, Camera };

enum class BgFill { Off, Blur, Preset };

struct Params {
  float smoothing = 0.f;
  SmoothingStyle smoothing_style = SmoothingStyle::Texture;
  float whitening = 0.f;
  WhiteningStyle whitening_style = WhiteningStyle::ColdWhite;
  float rosiness = 0.f;
  float sharpening = 0.f;
  bool skin_only = false;

  std::array<float, kReshapeCount> reshape{};

  float lipstick = 0.f;
  LipstickColor lipstick_color = LipstickColor::Rouge;
  float blush = 0.f;
  BlushStyle blush_style = BlushStyle::Soft;
  BlushColor blush_color = BlushColor::CoralPink;
  float contour = 0.f;
  ContourStyle contour_style = ContourStyle::Natural;
  float eyeshadow = 0.f;
  EyeShadowStyle eyeshadow_style = EyeShadowStyle::Soft;
  EyeShadowColor eyeshadow_color = EyeShadowColor::Plum;
  float eyeliner = 0.f;
  EyeLinerStyle eyeliner_style = EyeLinerStyle::Classic;
  EyeLinerColor eyeliner_color = EyeLinerColor::Coffee;
  float eyebrow = 0.f;
  EyebrowStyle eyebrow_style = EyebrowStyle::Natural;
  EyebrowColor eyebrow_color = EyebrowColor::DarkBrown;
  float eyelash = 0.f;
  EyelashStyle eyelash_style = EyelashStyle::Classic;
  EyelashColor eyelash_color = EyelashColor::Black;
  float pupil = 0.f;
  PupilColor pupil_color = PupilColor::Hazel;

  std::string filter_id;
  float filter_intensity = 0.8f;
  std::string sticker_id;

  BgFill bg_fill = BgFill::Off;
  float bg_blur = 0.5f;
  int chroma = 0;  // 0 portrait, 1 green, 2 blue, 3 red
  float chroma_similarity = 0.4f;
  float chroma_smoothness = 0.1f;
  float chroma_desaturation = 0.1f;

  bool face_overlay = false;
};

struct Asset {
  std::string id;
  std::string path;
};

struct GpuFrame {
  unsigned int texture = 0;
  int width = 0;
  int height = 0;
};

struct RgbaBuffer {
  int width = 0;
  int height = 0;
  std::vector<uint8_t> rgba;
  bool empty() const { return rgba.empty() || width <= 0 || height <= 0; }
};

class Studio {
 public:
  Studio() = default;
  ~Studio();

  Studio(const Studio&) = delete;
  Studio& operator=(const Studio&) = delete;

  bool Init(GLFWwindow* window);
  void Shutdown();

  void LoadImageFile(const std::string& path);
  void StartCamera();
  void StopCamera();
  bool ExportPng(const std::string& path);

  Params& params() { return params_; }
  void NotifyParamsChanged();
  void ResetParams();

  // Main thread: copy a published CPU frame into GL textures.
  void UploadGpu();

  bool IsCamera() const;
  bool HasFrame() const;
  const GpuFrame& OriginalGpu() const { return original_gpu_; }
  const GpuFrame& ProcessedGpu() const { return processed_gpu_; }
  std::vector<FaceDetectionResult> Faces() const;
  EngineStats Stats() const;
  std::string Status() const;  // empty if expired
  const std::vector<Asset>& Filters() const { return filters_; }
  const std::vector<Asset>& Stickers() const { return stickers_; }

 private:
  void WorkerLoop();
  void ScanAssets();
  void ApplyToEngine(const Params& p, const Params* prev);
  void Publish(RgbaBuffer processed,
               RgbaBuffer original,
               std::vector<FaceDetectionResult> faces,
               EngineStats stats);
  void SetStatus(std::string text);
  static void UploadTexture(GpuFrame* gpu, const RgbaBuffer& buf);

  GLFWwindow* window_ = nullptr;
  std::shared_ptr<facebetter::BeautyEffectEngine> engine_;

  Params params_;
  std::vector<Asset> filters_;
  std::vector<Asset> stickers_;
  std::string filter_dir_;
  std::string sticker_dir_;
  std::string background_path_;

  std::thread worker_;
  mutable std::mutex mu_;
  std::condition_variable cv_;
  std::atomic<bool> running_{false};

  Source source_ = Source::None;
  RgbaBuffer still_original_;
  bool still_dirty_ = false;
  bool pending_ready_ = false;  // worker published, GPU not yet uploaded
  Params shared_params_;

  RgbaBuffer pending_processed_;
  RgbaBuffer pending_original_;
  std::vector<FaceDetectionResult> pending_faces_;
  EngineStats pending_stats_;

  GpuFrame original_gpu_;
  GpuFrame processed_gpu_;
  std::vector<FaceDetectionResult> faces_;
  EngineStats stats_;
  std::string status_;
  std::chrono::steady_clock::time_point status_until_{};
};

}  // namespace demo
