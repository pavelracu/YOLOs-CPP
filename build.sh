#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)

# Default ONNXRUNTIME version
ONNXRUNTIME_VERSION="1.19.2"
ONNXRUNTIME_GPU=0

# Help function
usage() {
    echo "Usage: $0 [-b <video|camera|image>] [-g] [-v <onnxruntime_version>]"
    echo "Options:"
    echo "  -b <video|camera|image>  Specify what to build (video, camera, image)."
    echo "  -g                       Enable GPU support."
    echo "  -v <version>             Specify ONNXRUNTIME version. Default is ${ONNXRUNTIME_VERSION}."
    exit 1
}

# Parse command-line arguments
while getopts ":b:gv:" opt; do
    case ${opt} in
        b )
            BUILD_TARGET=$OPTARG
            ;;
        g )
            ONNXRUNTIME_GPU=1
            ;;
        v )
            ONNXRUNTIME_VERSION=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

if [ -z "$BUILD_TARGET" ]; then
    echo "Error: You must specify a build target using -b."
    usage
fi

# Platform detection
platform="$(uname -s)"
case "$platform" in
    Darwin*)
        ONNXRUNTIME_PLATFORM="osx"
        ONNXRUNTIME_GPU=0
        ;;
    Linux*)
        ONNXRUNTIME_PLATFORM="linux"
        ;;
    MINGW32_NT*|MINGW64_NT*)
        ONNXRUNTIME_PLATFORM="win"
        ;;
    *)
        echo "Unsupported platform: $platform"
        exit 1
        ;;
esac

# Architecture detection
architecture="$(uname -m)"
case "$architecture" in
    x86_64)
        ONNXRUNTIME_ARCH="x64"
        ;;
    armv7l)
        ONNXRUNTIME_ARCH="arm"
        ;;
    aarch64|arm64)
        ONNXRUNTIME_ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $architecture"
        exit 1
        ;;
esac

echo "ONNX Architecture GPU?" ${ONNXRUNTIME_GPU}

# GPU
if [ ${ONNXRUNTIME_GPU} == 1 ]; then
    ONNXRUNTIME_PATH="onnxruntime-${ONNXRUNTIME_PLATFORM}-${ONNXRUNTIME_ARCH}-gpu-${ONNXRUNTIME_VERSION}"
else
    ONNXRUNTIME_PATH="onnxruntime-${ONNXRUNTIME_PLATFORM}-${ONNXRUNTIME_ARCH}-${ONNXRUNTIME_VERSION}"
fi

# Download onnxruntime
if [ ! -d "${CURRENT_DIR}/${ONNXRUNTIME_PATH}" ]; then
    echo "Downloading onnxruntime ..." 
    curl -L -O -C - https://github.com/microsoft/onnxruntime/releases/download/v${ONNXRUNTIME_VERSION}/${ONNXRUNTIME_PATH}.tgz
    tar -zxvf ${ONNXRUNTIME_PATH}.tgz
fi

ONNXRUNTIME_DIR="${CURRENT_DIR}/${ONNXRUNTIME_PATH}"

# Remove previous build directory
if [ -d "${CURRENT_DIR}/build" ]; then
    rm -rf build
fi

mkdir build 
cd build
echo "Build Code ..."

# CMake configuration based on the build target
case "$BUILD_TARGET" in
    video)
        echo "Building for video processing..."
        cmake .. -D ONNXRUNTIME_DIR="${ONNXRUNTIME_DIR}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native" -DBUILD_VIDEO=ON
        ;;
    camera)
        echo "Building for camera processing..."
        cmake .. -D ONNXRUNTIME_DIR="${ONNXRUNTIME_DIR}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native" -DBUILD_CAMERA=ON
        ;;
    image)
        echo "Building for image processing..."
        cmake .. -D ONNXRUNTIME_DIR="${ONNXRUNTIME_DIR}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native" -DBUILD_IMAGE=ON
        ;;
    *)
        echo "Invalid build target: $BUILD_TARGET"
        usage
        ;;
esac

# Build the project
cmake --build .
