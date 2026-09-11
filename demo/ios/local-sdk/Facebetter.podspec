# frozen_string_literal: true

# Used only when demo/ios/Podfile.local exists. CocoaPods :path needs the
# xcframework next to this spec; the Podfile symlinks the sibling fb build.

Pod::Spec.new do |spec|
  spec.name         = "Facebetter"
  spec.version      = "0.0.1-local"
  spec.summary      = "Local Facebetter.xcframework from the sibling fb repo."
  spec.homepage     = "https://github.com/pixpark/facebetter-sdk"
  spec.license      = { :type => "Apache License, Version 2.0" }
  spec.author       = { "PixPark Team" => "hello@pixpark.net" }
  spec.platform     = :ios, "12.0"
  spec.source       = { :path => "." }
  spec.vendored_frameworks = "Facebetter.xcframework"
  spec.libraries = "c++", "z"
  spec.frameworks = "AVFoundation", "UIKit", "CoreMedia", "CoreVideo", "OpenGLES", "QuartzCore", "Metal", "CoreML", "Accelerate"
  spec.pod_target_xcconfig = {
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++17",
    "CLANG_CXX_LIBRARY" => "libc++",
  }
end
