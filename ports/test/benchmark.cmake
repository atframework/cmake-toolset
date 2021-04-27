# A library to benchmark code snippets, similar to unit tests.
# https://github.com/google/benchmark
# git@github.com:google/benchmark.git

include_guard(GLOBAL)

# =========== third party benchmark ==================
macro(PROJECT_THIRD_PARTY_BENCHMARK_IMPORT)
  if(TARGET benchmark::benchmark)
    message(STATUS "Dependency(${PROJECT_NAME}): Target benchmark::benchmark found")
    if(NOT MSVC)
      project_build_tools_move_imported_location_out_of_config(benchmark::benchmark)
    endif()
  endif()
  if(TARGET benchmark::benchmark_main)
    message(STATUS "Dependency(${PROJECT_NAME}): Target benchmark::benchmark_main found")
    project_build_tools_move_imported_location_out_of_config(benchmark::benchmark_main)
  endif()
endmacro()

if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark::benchmark_main)
  if(VCPKG_TOOLCHAIN)
    find_package(benchmark QUIET CONFIG)
    project_third_party_benchmark_import()
  endif()

  if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark::benchmark_main)
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_VERSION)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_VERSION "v1.5.3")
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_GIT_URL)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_GIT_URL
          "https://github.com/google/benchmark.git")
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_DIR)
      project_third_party_get_build_dir(
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_DIR "benchmark"
        ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_VERSION})
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
          "-DCMAKE_POSITION_INDEPENDENT_CODE=YES" "-DBENCHMARK_ENABLE_TESTING=OFF"
          "-DBENCHMARK_ENABLE_LTO=OFF" "-DBENCHMARK_ENABLE_INSTALL=ON"
          "-DALLOW_DOWNLOADING_GOOGLETEST=ON" "-DBENCHMARK_ENABLE_GTEST_TESTS=OFF")

      if(COMPILER_OPTIONS_TEST_EXCEPTION)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
             "-DBENCHMARK_ENABLE_EXCEPTIONS=ON")
      else()
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
             "-DBENCHMARK_ENABLE_EXCEPTIONS=OFF")
      endif()

      if(COMPILER_OPTION_CLANG_ENABLE_LIBCXX AND COMPILER_CLANG_TEST_LIBCXX)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
             "-DBENCHMARK_USE_LIBCXX=ON")
      else()
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
             "-DBENCHMARK_USE_LIBCXX=OFF")
      endif()
    endif()
    project_third_party_append_find_root_args(
      ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS)
    project_third_party_append_build_shared_lib_var(
      ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS BUILD_SHARED_LIBS)

    # Using our gtest source
    file(GLOB ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_FIND_GTEST_SRCS
         "${PROJECT_THIRD_PARTY_PACKAGE_DIR}/gtest-*")
    foreach(GOOGLETEST_PATH IN
            LISTS ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_FIND_GTEST_SRCS)
      if(EXISTS "${GOOGLETEST_PATH}"
         AND IS_DIRECTORY "${GOOGLETEST_PATH}"
         AND EXISTS "${GOOGLETEST_PATH}/CMakeLists.txt"
         AND EXISTS "${GOOGLETEST_PATH}/googletest"
         AND IS_DIRECTORY "${GOOGLETEST_PATH}/googletest"
         AND EXISTS "${GOOGLETEST_PATH}/googletest/CMakeLists.txt"
         AND EXISTS "${GOOGLETEST_PATH}/googlemock"
         AND IS_DIRECTORY "${GOOGLETEST_PATH}/googlemock"
         AND EXISTS "${GOOGLETEST_PATH}/googlemock/CMakeLists.txt")
        message(STATUS "Building benchmark: Found Google Test source ${GOOGLETEST_PATH}")

        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
             "-DGOOGLETEST_PATH=${GOOGLETEST_PATH}")
        break()
      endif()
    endforeach()

    if(MSVC)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
           "-DCMAKE_DEBUG_POSTFIX=d")
    endif()

    if(ANDROID OR CMAKE_OSX_ARCHITECTURES)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
           "-DCMAKE_DEBUG_POSTFIX=d")
    endif()

    find_configure_package(
      PACKAGE
      benchmark
      BUILD_WITH_CMAKE
      FIND_PACKAGE_FLAGS
      CONFIG
      CMAKE_INHIRT_BUILD_ENV
      CMAKE_INHIRT_BUILD_ENV_DISABLE_C_FLAGS
      CMAKE_INHIRT_FIND_ROOT_PATH
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "benchmark-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_VERSION}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_GIT_URL}")

    if(TARGET benchmark::benchmark OR TARGET benchmark::benchmark_main)
      project_third_party_benchmark_import()
    endif()
  endif()
else()
  project_third_party_benchmark_import()
endif()

if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark::benchmark_main)
  message(FATAL_ERROR "Dependency(${PROJECT_NAME}): Build benchmark failed.")
endif()
