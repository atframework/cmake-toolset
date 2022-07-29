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

project(cmake-toolset-test)

enable_testing()

if(NOT DEFINED __COMPILER_OPTION_LOADED)
  set(CMAKE_TOOLSET_TEST_IS_TOP_LEVEL TRUE)
  if(MSVC)
    string(REGEX REPLACE "/EHsc" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(REGEX REPLACE "/GR-?" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  else()
    string(REGEX REPLACE "-f(no-)?exceptions" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(REGEX REPLACE "-f(no-)?rtti" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  endif()
endif()

set(ATFRAMEWORK_CMAKE_TOOLSET_DIR "${CMAKE_CURRENT_LIST_DIR}/..")

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/Import.cmake")

if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang|Clang|GNU")
  find_program(PROJECT_FIND_LINKER_MOLD NAMES mold mold.exe)
  if(PROJECT_FIND_LINKER_MOLD)
    get_filename_component(PROJECT_FIND_LINKER_MOLD_PREFIX_DIR "${PROJECT_FIND_LINKER_MOLD}" DIRECTORY)
    get_filename_component(PROJECT_FIND_LINKER_MOLD_PREFIX_DIR "${PROJECT_FIND_LINKER_MOLD_PREFIX_DIR}" DIRECTORY)
    if(EXISTS "${PROJECT_FIND_LINKER_MOLD_PREFIX_DIR}/libexec/mold/ld")
      try_set_linker(LINKER "${PROJECT_FIND_LINKER_MOLD}" LEGACY_LINKER_DIRECTORY
                     "${PROJECT_FIND_LINKER_MOLD_PREFIX_DIR}/libexec/mold")
    else()
      try_set_linker(LINKER "${PROJECT_FIND_LINKER_MOLD}")
    endif()
  endif()
endif()

if(CMAKE_TOOLSET_TEST_IS_TOP_LEVEL)
  if(NOT COMPILER_OPTION_DEFAULT_ENABLE_RTTI)
    if(COMPILER_OPTIONS_TEST_RTTI)
      message(FATAL_ERROR "COMPILER_OPTIONS_TEST_RTTI=ON when COMPILER_OPTION_DEFAULT_ENABLE_RTTI=OFF")
    endif()
  else()
    if(NOT COMPILER_OPTIONS_TEST_RTTI)
      message(FATAL_ERROR "COMPILER_OPTIONS_TEST_RTTI=OFF when COMPILER_OPTION_DEFAULT_ENABLE_RTTI=ON")
    endif()
  endif()

  if(NOT COMPILER_OPTION_DEFAULT_ENABLE_EXCEPTION)
    if(COMPILER_OPTIONS_TEST_EXCEPTION)
      message(FATAL_ERROR "COMPILER_OPTIONS_TEST_EXCEPTION=ON when COMPILER_OPTION_DEFAULT_ENABLE_EXCEPTION=OFF")
    endif()
  else()
    if(NOT COMPILER_OPTIONS_TEST_EXCEPTION)
      message(FATAL_ERROR "COMPILER_OPTIONS_TEST_EXCEPTION=OFF when COMPILER_OPTION_DEFAULT_ENABLE_EXCEPTION=ON")
    endif()
  endif()
endif()

foreach(COMPILER_OPTION_INHERIT_VAR_NAME
        ${PROJECT_BUILD_TOOLS_CMAKE_INHERIT_VARS_C} ${PROJECT_BUILD_TOOLS_CMAKE_INHERIT_VARS_CXX}
        ${PROJECT_BUILD_TOOLS_CMAKE_INHERIT_VARS_ASM} ${PROJECT_BUILD_TOOLS_CMAKE_INHERIT_VARS_COMMON})
  if(COMPILER_OPTION_INHERIT_${COMPILER_OPTION_INHERIT_VAR_NAME})
    message(
      STATUS
        "COMPILER_OPTION_INHERIT_${COMPILER_OPTION_INHERIT_VAR_NAME}=${COMPILER_OPTION_INHERIT_${COMPILER_OPTION_INHERIT_VAR_NAME}}"
    )
  endif()
endforeach()
message(STATUS "ATFRAMEWORK_CMAKE_TOOLSET_SYSTEM_LINKS=${ATFRAMEWORK_CMAKE_TOOLSET_SYSTEM_LINKS}")

# Ports

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/compression/import.cmake")

if(NOT ANDROID AND NOT CMAKE_HOST_APPLE)
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/jemalloc/jemalloc.cmake")
  if(NOT WIN32 AND NOT MINGW)
    #[[
    # There is a BUG in gcc 4.6-4.8 and finxed in gcc 4.9
    #   @see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=58016
    #   @see https://gcc.gnu.org/gcc-4.9/changes.html
    #]]
    if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "4.9")
      include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/libunwind/libunwind.cmake")
    endif()
  endif()
endif()

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/algorithm/xxhash.cmake")
if(COMPILER_OPTIONS_TEST_EXCEPTION)
  # tbb do not support -fno-exceptions now
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/algorithm/tbb.cmake")
endif()
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/libuv/libuv.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/lua/lua.cmake")

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "8")
    include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/gsl/ms-gsl.cmake")
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "10")
    include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/gsl/ms-gsl.cmake")
  endif()
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "10.3")
    include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/gsl/ms-gsl.cmake")
  endif()
elseif(MSVC)
  if(MSVC_VERSION GREATER_EQUAL 1916)
    include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/gsl/ms-gsl.cmake")
  endif()
endif()
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/gsl/gsl-lite.cmake")

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/fmtlib/fmtlib.cmake")
if(COMPILER_OPTIONS_TEST_EXCEPTION)
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/yaml-cpp/yaml-cpp.cmake")
endif()
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/json/rapidjson.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/json/nlohmann_json.cmake")

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/test/gtest.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/test/benchmark.cmake")

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/flatbuffers/flatbuffers.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/ssl/port.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/redis/hiredis.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/cares/c-ares.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/re2/re2.cmake")
include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/libcurl/libcurl.cmake")

if(COMPILER_OPTIONS_TEST_EXCEPTION)
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/web/civetweb.cmake")
endif()
if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_BORINGSSL)
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/web/libwebsockets.cmake")
endif()

if(VCPKG_TOOLCHAIN
   AND MSVC
   AND MSVC_VERSION GREATER_EQUAL 1929)
  message(STATUS "Current protobuf in vcpkg is too old to support MSVC 1929(VS 16.10)")
else()
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/protobuf/protobuf.cmake")
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/grpc/abseil-cpp.cmake")
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/grpc/upb.cmake")
  include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/grpc/import.cmake")

  if(COMPILER_OPTIONS_TEST_EXCEPTION)
    include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/telemetry/prometheus-cpp.cmake")
  endif()
  if(MSVC AND MSVC_VERSION LESS 1920)
    message(
      STATUS "Opentelemetry-cpp only support Visual Studio 2019 and upper. Skip it for MSVC_VERSION=${MSVC_VERSION}")
  else()
    include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/telemetry/opentelemetry-cpp.cmake")
  endif()
endif()

include("${ATFRAMEWORK_CMAKE_TOOLSET_DIR}/ports/libcopp/libcopp.cmake")

# Test protobuf generator
if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC)
  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/test_pb.pb.h" "${CMAKE_CURRENT_BINARY_DIR}/test_pb.pb.cc"
           "${CMAKE_CURRENT_BINARY_DIR}/test_pb.pb"
    COMMAND
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC} --proto_path "${CMAKE_CURRENT_LIST_DIR}" -o
      "${CMAKE_CURRENT_BINARY_DIR}/test_pb.pb" "--cpp_out=${CMAKE_CURRENT_BINARY_DIR}/"
      "${CMAKE_CURRENT_LIST_DIR}/test_pb.proto"
    DEPENDS "${CMAKE_CURRENT_LIST_DIR}/test_pb.proto"
    COMMENT "Generate test_pb.pb,test_pb.pb.h,test_pb.pb.cc into ${CMAKE_CURRENT_BINARY_DIR}")

  add_executable(cmake-toolset-test "${CMAKE_CURRENT_BINARY_DIR}/test_pb.pb.cc"
                                    "${CMAKE_CURRENT_BINARY_DIR}/test_pb.pb.h" main.cpp)
  target_include_directories(cmake-toolset-test PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
  target_compile_definitions(cmake-toolset-test PRIVATE "HAVE_PROTOBUF=1")
else()
  add_executable(cmake-toolset-test main.cpp)
endif()

if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_OPENTELEMETRY_CPP_LINK_NAMES)
  target_compile_definitions(cmake-toolset-test PRIVATE "HAVE_OPENTELEMETRY_CPP=1")
endif()

add_test(NAME cmake-toolset.main-test COMMAND cmake-toolset-test)

target_link_libraries(
  cmake-toolset-test
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_OPENTELEMETRY_CPP_LINK_NAMES}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CIVETWEB_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FLAT_BUFFERS_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CARES_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RE2_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_NLOHMANN_JSON_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_YAML_CPP_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MICROSOFT_GSL_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GSL_LITE_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBUV_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LUA_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_XXHASH_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TBB_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_SNAPPY_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LZ4_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZLIB_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBUNWIND_LINK_NAME}
  ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_JEMALLOC_LINK_NAME})

get_target_property(CMAKE_TOOLSE_TEST_LINK_LIBRARIES cmake-toolset-test LINK_LIBRARIES)
message(STATUS "CMAKE_TOOLSE_TEST_LINK_LIBRARIES=${CMAKE_TOOLSE_TEST_LINK_LIBRARIES}")

if(TARGET GTest::gtest_main)
  add_executable(cmake-toolset-gtest gtest.cpp)
  target_link_libraries(cmake-toolset-gtest GTest::gtest_main)
  add_test(NAME cmake-toolset.gtest-test COMMAND cmake-toolset-test)
else()
  message(FATAL_ERROR "Build GTest failed")
endif()

if(TARGET benchmark::benchmark)
  add_executable(cmake-toolset-benchmark benchmark.cpp)
  target_link_libraries(cmake-toolset-benchmark benchmark::benchmark)
  add_test(NAME cmake-toolset.benchmark-test COMMAND cmake-toolset-test)
else()
  message(FATAL_ERROR "Build benchmark failed")
endif()

if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA
   AND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_LINK_NAME
   AND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC
   AND EXISTS "${PROJECT_THIRD_PARTY_INSTALL_DIR}/share/upb/upb/bindings/lua/CMakeLists.txt")

  add_subdirectory("${PROJECT_THIRD_PARTY_INSTALL_DIR}/share/upb/upb/bindings/lua")

  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upb.h" "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upb.c"
           "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upbdefs.h" "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upbdefs.c"
           "${CMAKE_CURRENT_BINARY_DIR}/test_pb.lua"
    COMMAND
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC}" --proto_path "${CMAKE_CURRENT_LIST_DIR}"
      "--plugin=protoc-gen-upb=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB}"
      "--plugin=protoc-gen-upbdefs=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS}"
      "--plugin=protoc-gen-lua=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA}"
      "--upb_out=${CMAKE_CURRENT_BINARY_DIR}" "--upbdefs_out=${CMAKE_CURRENT_BINARY_DIR}"
      "--lua_out=${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_LIST_DIR}/test_pb.proto"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${PROJECT_THIRD_PARTY_INSTALL_DIR}/share/upb/upb/bindings/lua/upb.lua" "${CMAKE_CURRENT_BINARY_DIR}"
    DEPENDS "${CMAKE_CURRENT_LIST_DIR}/test_pb.proto"
    COMMENT
      "Generate test_pb.lua,test_pb.upb.h,test_pb.upb.c,test_pb.upbdefs.h,test_pb.upbdefs.c into ${CMAKE_CURRENT_BINARY_DIR}"
  )

  add_executable(
    cmake-toolset-upb-and-lua-binding-test
    "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upb.h" "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upb.c"
    "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upbdefs.h" "${CMAKE_CURRENT_BINARY_DIR}/test_pb.upbdefs.c"
    upb-and-lua-binding.cpp)

  target_include_directories("cmake-toolset-upb-and-lua-binding-test" PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")

  target_link_libraries("cmake-toolset-upb-and-lua-binding-test" ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_LINK_NAME}
                        upb::lupb ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LUA_LINK_NAME})

  target_compile_options("cmake-toolset-upb-and-lua-binding-test"
                         PRIVATE "${PROJECT_BUILD_TOOLS_PATCH_PROTOBUF_SOURCES_OPTIONS}")
endif()
