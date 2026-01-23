<h1 align="center">
  <a href="https://www.facebetter.net"><img src="./assets/logo-light.svg" alt="Facebetter Logo" width="200"></a>
</h1>
 
<p align="center">
  <a href="https://www.facebetter.net" target="_blank">Website</a>
  <span> · </span>
  <a href="https://facebetter.net/docs" target="_blank">Document</a>
</p>

## Introduction

This repository contains **Facebetter SDK** demo source code for all supported platforms.
 
## Download SDK

Before building the demo projects, you need to download the SDK libraries for the target platform(s). We provide a convenient script to automate this process:

```bash
# Download all platform SDKs with default version
./scripts/download_sdk.sh

# Download SDKs with specific version
./scripts/download_sdk.sh -v 1.1.3

# Download SDK for specific platform(s)
./scripts/download_sdk.sh -p android
./scripts/download_sdk.sh -p android,ios-arm64

# Show help
./scripts/download_sdk.sh --help
```

The script will automatically download and extract the SDK files to the correct directories:
- **Android**: `demo/android/app/src/main/libs`
- **iOS**: `demo/ios/FBExampleObjc/libs`
- **macOS**: `demo/macos/FBExampleObjc/libs`

## Documentation

For complete development documentation, API reference, and best practices, please visit:

**🌐 [Facebetter Official Documentation](https://facebetter.net/docs)**

### Platform-Specific Documentation

- **📱 [Android Documentation](https://facebetter.net/docs/android/quick-start)** - Android platform integration guide
- **🍎 [iOS Documentation](https://facebetter.net/docs/ios/quick-start)** - iOS platform integration guide
- **💻 [macOS Documentation](https://facebetter.net/docs/macos/quick-start)** - macOS platform integration guide
- **🪟 [Windows Documentation](https://facebetter.net/docs/windows/quick-start)** - Windows platform integration guide
- **🌐 [Web Documentation](https://facebetter.net/docs/web/quick-start)** - Web platform integration guide (React/Vue)

The documentation includes:
- 📖 Quick Start Guide
- 🔧 API Reference
- 💡 Best Practices
- ❓ FAQ
- 🐛 Error Handling Guide
- 📱 Platform Integration Examples

## Related Links

- **Official Website**: [https://facebetter.net](https://facebetter.net)
- **Documentation**: [https://facebetter.net/docs](https://facebetter.net/docs)
- **SDK and Resource Download**: [https://facebetter.net/download](https://facebetter.net/download)
 
---

**Facebetter** - Making beauty effects simpler and more powerful ✨
