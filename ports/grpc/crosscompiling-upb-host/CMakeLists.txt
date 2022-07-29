cmake_minimum_required(VERSION 3.16)
cmake_policy(SET CMP0022 NEW)
cmake_policy(SET CMP0054 NEW)
cmake_policy(SET CMP0067 NEW)
cmake_policy(SET CMP0074 NEW)
cmake_policy(SET CMP0077 NEW)
cmake_policy(SET CMP0091 NEW)
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19.0")
  cmake_policy(SET CMP0111 NEW)
endif()

# MSVC RTTI flag /GR should not be not added to CMAKE_CXX_FLAGS by default. @see
# https://cmake.org/cmake/help/latest/policy/CMP0117.html
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.20.0")
  cmake_policy(SET CMP0117 NEW)
endif()

project(cmake-toolset-upb-host)

if(NOT CMAKE_PARENT_LIST_FILE OR CMAKE_PARENT_LIST_FILE STREQUAL CMAKE_CURRENT_LIST_FILE)
  if(MSVC)
    string(REGEX REPLACE "/EHsc" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(REGEX REPLACE "/GR-?" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  else()
    string(REGEX REPLACE "-f(no-)?exceptions" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(REGEX REPLACE "-f(no-)?rtti" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  endif()
endif()

set(ATFRAMEWORK_CMAKE_TOOLSET_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../")
set(ATFRAMEWORK_CMAKE_TOOLSET_HOST_BUILDING TRUE)

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/Import.cmake")

# Ports
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/protobuf/protobuf.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/grpc/abseil-cpp.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/grpc/upb.cmake")

message(
  STATUS
    "Dependency(${PROJECT_NAME}): ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB}"
)
message(
  STATUS
    "Dependency(${PROJECT_NAME}): ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS}"
)

# Test protobuf generator
add_custom_command(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upb.c" "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upb.h"
         "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upbdefs.c" "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upbdefs.h"
  COMMAND
    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC}" --proto_path
    "${CMAKE_CURRENT_LIST_DIR}/../crosscompiling-grpc-host"
    "--plugin=protoc-gen-upb=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB}"
    "--plugin=protoc-gen-upbdefs=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS}"
    "--upb_out=${CMAKE_CURRENT_BINARY_DIR}" "--upbdefs_out=${CMAKE_CURRENT_BINARY_DIR}"
    "${CMAKE_CURRENT_LIST_DIR}/../crosscompiling-grpc-host/helloworld.proto"
  DEPENDS "${CMAKE_CURRENT_LIST_DIR}/../crosscompiling-grpc-host/helloworld.proto"
  COMMENT "Generate helloworld.* into ${CMAKE_CURRENT_BINARY_DIR}")

add_executable(
  "${PROJECT_NAME}-client-test"
  "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upb.c" "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upb.h"
  "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upbdefs.c" "${CMAKE_CURRENT_BINARY_DIR}/helloworld.upbdefs.h" client-main.cpp)
target_include_directories("${PROJECT_NAME}-client-test" PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")

target_link_libraries("${PROJECT_NAME}-client-test" ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_LINK_NAME})

target_compile_options("${PROJECT_NAME}-client-test" PRIVATE "${PROJECT_BUILD_TOOLS_PATCH_PROTOBUF_SOURCES_OPTIONS}")
