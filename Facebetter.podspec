Pod::Spec.new do |spec|
  spec.name         = "Facebetter"
  spec.version      = "1.2.2"
  spec.summary      = "A high-performance face beauty and effect engine for iOS and macOS."
  spec.description  = <<-DESC
                   Facebetter is a powerful beauty engine that provides
                   real-time face retouching, reshaping, filters, and stickers for iOS and macOS.
                   DESC
  spec.homepage     = "https://github.com/pixpark/facebetter-sdk"
  spec.license      = { :type => "Apache License, Version 2.0", :text => <<-LICENSE
    Copyright 2023 PixPark Team

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    LICENSE
  }
  spec.author       = { "PixPark Team" => "hello@pixpark.net" }

  spec.platforms    = { :ios => "12.0", :osx => "10.13" }
  spec.ios.deployment_target = "12.0"
  spec.osx.deployment_target = "10.13"
  
  spec.source       = { 
    :http => "https://github.com/pixpark/facebetter-sdk/releases/download/v#{spec.version}/facebetter-sdk-#{spec.version}-apple.zip" 
  }

  spec.vendored_frameworks = "Facebetter.xcframework"

  spec.libraries = "c++", "z"
  
  spec.ios.frameworks = "AVFoundation", "UIKit", "CoreMedia", "CoreVideo", "OpenGLES", "QuartzCore", "Metal", "CoreML", "Accelerate"
  spec.osx.frameworks = "AVFoundation", "AppKit", "CoreMedia", "CoreVideo", "OpenGL", "QuartzCore", "Metal", "CoreML", "Accelerate"
  
  spec.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
  }
end
