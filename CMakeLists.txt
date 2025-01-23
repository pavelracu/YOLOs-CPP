cmake_minimum_required(VERSION 3.0.0)
project(yolo_ort)

# Define ONNX Runtime directory
set(ONNXRUNTIME_DIR "${CMAKE_SOURCE_DIR}/onnxruntime-linux-x64-1.19.2")
message(STATUS "ONNXRUNTIME_DIR: ${ONNXRUNTIME_DIR}")
message(STATUS "BUILD_IMAGE: ${BUILD_IMAGE}")
message(STATUS "BUILD_CAMERA: ${BUILD_CAMERA}")
message(STATUS "BUILD_VIDEO: ${BUILD_VIDEO}")

# Find OpenCV
find_package(OpenCV REQUIRED)

# Include directories
include_directories(
    "include/"
    "/usr/include/opencv4/"
    "${ONNXRUNTIME_DIR}/include"
    "${ONNXRUNTIME_DIR}/include/onnxruntime/core"
)

# Link directories
link_directories(${ONNXRUNTIME_DIR}/lib)

# Define executables
#set(TARGETS image_inference camera_inference video_inference)
set(TARGETS video_inference)
foreach(TARGET ${TARGETS})
    add_executable(${TARGET} src/${TARGET}.cpp)
    target_include_directories(${TARGET} PRIVATE "${ONNXRUNTIME_DIR}/include")
    target_compile_features(${TARGET} PRIVATE cxx_std_14)
endforeach()

# Link libraries
foreach(TARGET ${TARGETS})
    target_link_libraries(${TARGET} ${OpenCV_LIBS} ${ONNXRUNTIME_DIR}/lib/libonnxruntime.so -pthread)
endforeach()

# Platform-specific linking
if(WIN32)
    message(STATUS "Building on Windows!")
    foreach(TARGET ${TARGETS})
        target_link_libraries(${TARGET} "${ONNXRUNTIME_DIR}/lib/onnxruntime.lib")
    endforeach()
elseif(APPLE)
    message(STATUS "Building on macOS!")
    foreach(TARGET ${TARGETS})
        target_link_libraries(${TARGET} "${ONNXRUNTIME_DIR}/lib/libonnxruntime.dylib")
    endforeach()
elseif(UNIX)
    message(STATUS "Building on Linux!")
    # Linux already links correctly above
endif()
