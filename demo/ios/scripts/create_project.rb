#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "xcodeproj"

root = File.expand_path("..", __dir__)
project_path = File.join(root, "FBDemo.xcodeproj")
FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes["LastSwiftUpdateCheck"] = "1600"
project.root_object.attributes["LastUpgradeCheck"] = "1600"

target = project.new_target(:application, "FBDemo", :ios, "16.0")
app_group = project.main_group.new_group("FBDemo", "FBDemo")

SOURCE_DIRS = {
  "" => File.join(root, "FBDemo"),
  "App" => File.join(root, "FBDemo", "App"),
  "Beauty" => File.join(root, "FBDemo", "Beauty"),
  "Engine" => File.join(root, "FBDemo", "Engine"),
  "Camera" => File.join(root, "FBDemo", "Camera"),
  "Studio" => File.join(root, "FBDemo", "Studio")
}.freeze

def add_sources(project_group, target, absolute_directory, relative_directory)
  current_group = project_group
  unless relative_directory.empty?
    relative_directory.split("/").each do |component|
      current_group = current_group.groups.find { |group| group.display_name == component } ||
        current_group.new_group(component, component)
    end
  end

  Dir.children(absolute_directory).sort.each do |entry|
    absolute_path = File.join(absolute_directory, entry)
    next if File.directory?(absolute_path)
    next unless %w[.swift .m .h].include?(File.extname(entry))
    next if entry.end_with?("-Bridging-Header.h")

    reference = current_group.new_file(entry)
    target.source_build_phase.add_file_reference(reference) if %w[.swift .m].include?(File.extname(entry))
  end
end

SOURCE_DIRS.each do |relative, absolute|
  add_sources(app_group, target, absolute, relative)
end

app_group.new_file("FBDemo-Bridging-Header.h")
app_group.new_file("Info.plist")

assets_reference = app_group.new_file("Assets.xcassets")
target.resources_build_phase.add_file_reference(assets_reference)

resources_group = app_group.new_group("Resources", "Resources")
config_reference = resources_group.new_file("FacebetterConfig.plist")
target.resources_build_phase.add_file_reference(config_reference)
background_reference = resources_group.new_file("background.jpg")
target.resources_build_phase.add_file_reference(background_reference)

copy_assets = target.new_shell_script_build_phase("Copy Facebetter Demo Assets")
copy_assets.shell_script = <<~SCRIPT
  set -e
  DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Facebetter"
  SRC="${SRCROOT}/../web/react/public"
  mkdir -p "${DEST}/filters" "${DEST}/stickers"
  rsync -a "${SRC}/assets/filters/" "${DEST}/filters/"
  rsync -a "${SRC}/stickers/" "${DEST}/stickers/"
  cp "${SRC}/background.jpg" "${DEST}/background.jpg"
  if [ -f "${SRC}/assets/filters/filter_mapping.json" ]; then
    cp "${SRC}/assets/filters/filter_mapping.json" "${DEST}/filter_mapping.json"
  fi
SCRIPT

copy_assets.always_out_of_date = "1"

# Keep the copy phase before Compile Sources so resources exist at runtime.
target.build_phases.delete(copy_assets)
target.build_phases.unshift(copy_assets)

%w[AVFoundation UIKit CoreMedia CoreVideo OpenGLES QuartzCore Metal CoreML Accelerate].each do |name|
  target.add_system_framework(name)
end

target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = "AccentColor"
  settings["CLANG_ENABLE_MODULES"] = "YES"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["DEVELOPMENT_TEAM"] = "QFCE3TAQXQ"
  settings["ENABLE_USER_SCRIPT_SANDBOXING"] = "NO"
  settings["GENERATE_INFOPLIST_FILE"] = "NO"
  settings["INFOPLIST_FILE"] = "FBDemo/Info.plist"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "16.0"
  settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/Frameworks"
  settings["MARKETING_VERSION"] = "2.0"
  settings["OTHER_LDFLAGS"] = "$(inherited) -ObjC"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.pixpark.fbdemo"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  settings["SUPPORTS_MACCATALYST"] = "NO"
  settings["SWIFT_OBJC_BRIDGING_HEADER"] = "FBDemo/FBDemo-Bridging-Header.h"
  settings["SWIFT_VERSION"] = "5.0"
  settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  if configuration.name == "Debug"
    settings["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone"
    settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
  end
end

project.build_configurations.each do |configuration|
  configuration.build_settings["ENABLE_USER_SCRIPT_SANDBOXING"] = "NO"
  configuration.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "16.0"
  configuration.build_settings["SDKROOT"] = "iphoneos"
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project_path, "FBDemo", true)

puts "Generated #{project_path}"

Dir.chdir(root) do
  if system("pod", "install")
    puts "pod install completed. Open FBDemo.xcworkspace"
  else
    warn "pod install failed. Install CocoaPods and run it from #{root}"
  end
end
