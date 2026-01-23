#!/bin/bash

# Facebetter SDK Download Script
# Usage:
#   ./download_sdk.sh                    # Download all platform SDKs with default version
#   ./download_sdk.sh -v 1.1.3           # Download all platform SDKs with specified version
#   ./download_sdk.sh -p android         # Download Android SDK with default version
#   ./download_sdk.sh -v 1.1.3 -p android,ios-arm64  # Download multiple platform SDKs with specified version

# Default SDK version (can be modified in the script)
DEFAULT_VERSION="1.1.3"

# SDK download base URL
BASE_URL="https://github.com/pixpark/facebetter-sdk/releases/download"

# Supported platform list
PLATFORMS=("android" "ios-arm64" "macos-universal")

# Get the extraction directory for the platform
get_platform_dir() {
    case "$1" in
        android)
            echo "demo/android/app/src/main/libs"
            ;;
        ios-arm64)
            echo "demo/ios/FBExampleObjc/libs"
            ;;
        macos-universal)
            echo "demo/macos/FBExampleObjc/libs"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print error message
error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

# Print success message
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print info message
info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION    Specify SDK version (default: $DEFAULT_VERSION)"
    echo "  -p, --platform PLATFORM  Specify platform(s), multiple platforms separated by comma"
    echo "                           Supported platforms: android, ios-arm64, macos-universal"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Download all platform SDKs with default version"
    echo "  $0 -v 1.1.3                          # Download all platform SDKs with version 1.1.3"
    echo "  $0 -p android                        # Download Android SDK with default version"
    echo "  $0 -v 1.1.3 -p android,ios-arm64    # Download multiple platform SDKs with version 1.1.3"
}

# Parse command line arguments
VERSION="$DEFAULT_VERSION"
PLATFORMS_TO_DOWNLOAD=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -p|--platform)
            IFS=',' read -ra PLATFORM_ARRAY <<< "$2"
            for platform in "${PLATFORM_ARRAY[@]}"; do
                platform=$(echo "$platform" | xargs) # Trim whitespace
                # Validate if platform is supported
                if [[ ! " ${PLATFORMS[@]} " =~ " ${platform} " ]]; then
                    error "Unsupported platform: $platform"
                    echo "Supported platforms: ${PLATFORMS[*]}"
                    exit 1
                fi
                PLATFORMS_TO_DOWNLOAD+=("$platform")
            done
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

# If no platform is specified, download all platforms
if [ ${#PLATFORMS_TO_DOWNLOAD[@]} -eq 0 ]; then
    PLATFORMS_TO_DOWNLOAD=("${PLATFORMS[@]}")
fi

# Check if required commands exist
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Command '$1' not found, please install it first"
        exit 1
    fi
}

check_command "curl"
check_command "unzip"

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Download and extract SDK
download_and_extract() {
    local platform=$1
    local version=$2
    local filename="facebetter-sdk-${version}-${platform}.zip"
    local url="${BASE_URL}/v${version}/${filename}"
    local platform_dir=$(get_platform_dir "$platform")
    
    if [ -z "$platform_dir" ]; then
        error "Unknown platform: $platform"
        return 1
    fi
    
    local target_dir="${PROJECT_ROOT}/${platform_dir}"
    
    info "Starting download of ${platform} SDK (version: ${version})..."
    
    # Create target directory
    mkdir -p "$target_dir"
    
    # Temporary file path (use system temp directory)
    local temp_file=$(mktemp "${TMPDIR:-/tmp}/facebetter-sdk-${platform}-${version}.XXXXXX.zip")
    
    # Download file
    info "Downloading to temporary location: ${temp_file}"
    if curl -L -o "$temp_file" "$url"; then
        success "Download completed: ${filename}"
    else
        error "Download failed: ${url}"
        rm -f "$temp_file"
        return 1
    fi
    
    # Extract file (exclude __MACOSX folder)
    info "Extracting to: ${target_dir}"
    if unzip -q -o "$temp_file" -d "$target_dir" -x "__MACOSX/*" "*/__MACOSX/*"; then
        success "Extraction completed: ${platform} SDK extracted to ${target_dir}"
    else
        error "Extraction failed: ${filename}"
        rm -f "$temp_file"
        return 1
    fi
    
    # Remove temporary zip file
    rm -f "$temp_file"
    success "Cleanup completed: temporary file removed"
}

# Main function
main() {
    info "Facebetter SDK Download Tool"
    info "Version: ${VERSION}"
    info "Platforms: ${PLATFORMS_TO_DOWNLOAD[*]}"
    echo ""
    
    local failed_platforms=()
    
    for platform in "${PLATFORMS_TO_DOWNLOAD[@]}"; do
        echo "----------------------------------------"
        if download_and_extract "$platform" "$VERSION"; then
            echo ""
        else
            failed_platforms+=("$platform")
            echo ""
        fi
    done
    
    echo "========================================"
    if [ ${#failed_platforms[@]} -eq 0 ]; then
        success "All SDK downloads completed!"
        exit 0
    else
        error "Download failed for the following platforms: ${failed_platforms[*]}"
        exit 1
    fi
}

# Run main function
main
