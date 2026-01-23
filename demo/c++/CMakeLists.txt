# ---- Application project definition ----
# Simple command-line image processing application using Facebetter SDK
set(fb_app_name "fb_app")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(app_src_files "${CMAKE_CURRENT_SOURCE_DIR}/main.cc")

# ---- Build configuration ----
# create executable from source files
add_executable(${fb_app_name} ${app_src_files})

# ---- Platform-specific configuration ----
# Each platform requires different compiler flags and linked libraries
if(APPLE)
  # macOS specific configuration
  set_target_properties(
    ${fb_app_name}
    PROPERTIES MACOSX_BUNDLE FALSE
               INSTALL_RPATH "@executable_path/../lib"
               BUILD_WITH_INSTALL_RPATH TRUE)

  target_link_libraries(
    ${fb_app_name} PRIVATE "-framework CoreFoundation" dl
                           facebetter::facebetter ghc::filesystem)
elseif(WIN32)
  # Windows specific configuration
  target_link_libraries(${fb_app_name} PRIVATE shlwapi facebetter::facebetter
                                               ghc::filesystem)

  # set delayed DLL loading
  if(MSVC)
    set_target_properties(${fb_app_name} PROPERTIES LINK_FLAGS
                                                    "/DELAYLOAD:facebetter.dll")
  endif()

else()
  # Linux specific configuration
  set_target_properties(${fb_app_name} PROPERTIES INSTALL_RPATH "$ORIGIN/../lib"
                                                  BUILD_WITH_INSTALL_RPATH TRUE)

  target_link_libraries(${fb_app_name} PRIVATE dl facebetter ghc::filesystem
                                               stdc++fs)
endif()

# ---- Installation configuration ----
# Define where and how files should be installed
if(FB_INSTALL)
  install(
    TARGETS ${fb_app_name}
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin)
endif()
