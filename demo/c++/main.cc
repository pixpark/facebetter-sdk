#include <iostream>
#include <memory>
#include <string>

#include "base/str_encrypt.h"
#include "facebetter/beauty_effect_engine.h"
#include "facebetter/image_frame.h"
#include "ghc/filesystem.hpp"

namespace fs {
using namespace ghc::filesystem;
}  // namespace fs

#ifdef _WIN32
#include <Shlwapi.h>
#include <windows.h>
#elif defined(__linux__)
#include <limits.h>
#include <unistd.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#include <stdlib.h>
#endif

std::string GetExecutablePath() {
  std::string path;
#ifdef _WIN32
  char buffer[MAX_PATH];
  GetModuleFileNameA(NULL, buffer, MAX_PATH);
  PathRemoveFileSpecA(buffer);
  path = buffer;
#elif defined(__APPLE__)
  char buffer[PATH_MAX];
  uint32_t size = sizeof(buffer);
  if (_NSGetExecutablePath(buffer, &size) == 0) {
    path = fs::path(buffer).parent_path().string();
  }
#elif defined(__linux__)
  char buffer[PATH_MAX];
  ssize_t len = readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
  if (len != -1) {
    buffer[len] = '\0';
    path = fs::path(buffer).parent_path().string();
  }
#endif
  return path;
}

void PrintUsage(const char* program_name) {
  std::cout << "Usage: " << program_name
            << " <input_image> <output_image> [options]\n"
            << "\n"
            << "Arguments:\n"
            << "  input_image    Path to input image file\n"
            << "  output_image   Path to output image file\n"
            << "\n"
            << "Options:\n"
            << "  --mode <mode>  Frame type: image (default) or video\n"
            << "  --help         Show this help message\n"
            << "\n"
            << "Example:\n"
            << "  " << program_name << " input.jpg output.jpg\n"
            << "  " << program_name << " input.jpg output.jpg --mode video\n";
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    PrintUsage(argv[0]);
    return 1;
  }

  std::string input_path = argv[1];
  std::string output_path = argv[2];
  facebetter::FrameType frame_type = facebetter::FrameType::Image;

  // Parse optional arguments
  for (int i = 3; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg == "--help" || arg == "-h") {
      PrintUsage(argv[0]);
      return 0;
    } else if (arg == "--mode" && i + 1 < argc) {
      std::string mode = argv[++i];
      if (mode == "video") {
        frame_type = facebetter::FrameType::Video;
      } else if (mode == "image") {
        frame_type = facebetter::FrameType::Image;
      } else {
        std::cerr << "Invalid mode: " << mode << ". Use 'image' or 'video'.\n";
        return 1;
      }
    }
  }

  // Check if input file exists
  if (!fs::exists(input_path)) {
    std::cerr << "Error: Input file does not exist: " << input_path
              << std::endl;
    return 1;
  }

  // Get resource path
  auto resource_path = fs::path(GetExecutablePath());
  auto resource_bundle = resource_path / "../resource" / "resource.bundle";
  std::cout << "[App] Resource path: " << resource_bundle << std::endl;

  // Configure logging
  facebetter::LogConfig log_config;
  log_config.console_enabled = true;
  log_config.file_enabled = false;
  log_config.level = facebetter::LogLevel::Info;
  facebetter::BeautyEffectEngine::SetLogConfig(log_config);

  // Initialize engine
  facebetter::EngineConfig config;
  config.resource_path = resource_bundle.string();
  
  // TODO: 替换为你的 AppId/AppKey
  std::string app_id_str = "";
  std::string app_key_str = "";
  
  // 验证 appId 和 appKey
  if (app_id_str.empty() || app_key_str.empty()) {
    std::cerr << "[Facebetter] Error: appId and appKey must be configured. Please set your appId and appKey in the code." << std::endl;
    return 1;
  }
  
  config.app_id = fb_str_crypt(app_id_str);
  config.app_key = fb_str_crypt(app_key_str);

  std::cout << "[App] Creating beauty engine..." << std::endl;
  auto beauty_engine = facebetter::BeautyEffectEngine::Create(config);
  if (!beauty_engine) {
    std::cerr << "Error: Failed to create BeautyEffectEngine" << std::endl;
    return 1;
  }

  // Enable beauty types
  std::cout << "[App] Enabling beauty types..." << std::endl;
  beauty_engine->SetBeautyTypeEnabled(facebetter::BeautyType::Basic, true);
  beauty_engine->SetBeautyTypeEnabled(facebetter::BeautyType::Reshape, true);
  beauty_engine->SetBeautyTypeEnabled(facebetter::BeautyType::Makeup, true);
  // beauty_engine->SetBeautyTypeEnabled(facebetter::BeautyType::VirtualBackground,
  //                                     true);

  // Set beauty parameters (example values)
  std::cout << "[App] Setting beauty parameters..." << std::endl;

  // Basic beauty parameters
  beauty_engine->SetBeautyParam(facebetter::beauty_params::Basic::Smoothing,
                                0.5f);
  beauty_engine->SetBeautyParam(facebetter::beauty_params::Basic::Whitening,
                                0.3f);
  beauty_engine->SetBeautyParam(facebetter::beauty_params::Basic::Rosiness,
                                0.2f);

  // Reshape parameters
  beauty_engine->SetBeautyParam(facebetter::beauty_params::Reshape::FaceThin,
                                0.9f);
  beauty_engine->SetBeautyParam(facebetter::beauty_params::Reshape::EyeSize,
                                0.2f);

  // Makeup parameters
  // beauty_engine->SetBeautyParam(facebetter::beauty_params::Makeup::Lipstick,
  // 0.4f);
  // beauty_engine->SetBeautyParam(facebetter::beauty_params::Makeup::Blush,
  // 0.3f);

  // Virtual background (blur mode)
  // facebetter::beauty_params::VirtualBackgroundOptions bg_options;
  // bg_options.mode = facebetter::beauty_params::BackgroundMode::Blur;
  // beauty_engine->SetVirtualBackground(bg_options);

  // Load input image
  std::cout << "[App] Loading input image: " << input_path << std::endl;
  auto input_frame = facebetter::ImageFrame::CreateWithFile(input_path);
  if (!input_frame) {
    std::cerr << "Error: Failed to load input image" << std::endl;
    return 1;
  }

  // Set frame type
  input_frame->type = frame_type;

  // Process image
  std::cout << "[App] Processing image..." << std::endl;
  auto processed_frame = beauty_engine->ProcessImage(input_frame);
  if (!processed_frame) {
    std::cerr << "Error: Failed to process image" << std::endl;
    return 1;
  }

  // Save output image
  std::cout << "[App] Saving output image: " << output_path << std::endl;
  int result = processed_frame->ToFile(output_path, 90);
  if (result != 0) {
    std::cerr << "Error: Failed to save output image" << std::endl;
    return 1;
  }

  std::cout << "[App] Success! Output saved to: " << output_path << std::endl;
  return 0;
}
