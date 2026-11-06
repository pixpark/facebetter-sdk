Pod::Spec.new do |s|
  s.name           = 'FacebetterCamera'
  s.version        = '0.1.0'
  s.summary        = 'Facebetter camera preview for the Expo demo'
  s.homepage       = 'https://github.com/pixpark/facebetter-sdk'
  s.license        = { :type => 'Apache-2.0' }
  s.author         = 'PixPark'
  s.platforms      = { :ios => '16.4' }
  s.swift_version  = '5.9'
  s.source         = { :git => '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'
  s.dependency 'Facebetter', '2.2.1'

  s.frameworks = 'AVFoundation', 'CoreVideo', 'OpenGLES', 'QuartzCore', 'UIKit'
  s.source_files = '**/*.{h,m,swift}'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_CFLAGS' => '$(inherited) -DGLES_SILENCE_DEPRECATION'
  }
end
