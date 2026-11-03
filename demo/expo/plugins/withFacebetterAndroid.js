const { withAppBuildGradle } = require("expo/config-plugins");

/** The AAR ships arm ABIs only. Drop x86 so an x86 emulator fails at install, not at runtime. */
function withFacebetterAndroid(config) {
  return withAppBuildGradle(config, (config) => {
    if (config.modResults.language !== "groovy") {
      return config;
    }
    let contents = config.modResults.contents;
    if (!contents.includes("abiFilters")) {
      contents = contents.replace(
        /defaultConfig\s*\{/,
        `defaultConfig {
        ndk {
            abiFilters "armeabi-v7a", "arm64-v8a"
        }`,
      );
    }
    // Debug otherwise skips the JS bundle and loads it from Metro.
    if (!/^\s*debuggableVariants\s*=/m.test(contents)) {
      contents = contents.replace(
        /react\s*\{/,
        `react {
    debuggableVariants = []`,
      );
    }
    config.modResults.contents = contents;
    return config;
  });
}

module.exports = withFacebetterAndroid;
