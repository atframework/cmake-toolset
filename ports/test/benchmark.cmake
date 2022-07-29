# A library to benchmark code snippets, similar to unit tests.
# https://github.com/google/benchmark
# git@github.com:google/benchmark.git

include_guard(GLOBAL)

# =========== third party benchmark ==================
macro(PROJECT_THIRD_PARTY_BENCHMARK_IMPORT)
  if(TARGET benchmark::benchmark)
    message(STATUS "Dependency(${PROJECT_NAME}): Target benchmark::benchmark found")
    project_build_tools_patch_default_imported_config(benchmark::benchmark)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_BENCHMARK_LINK_NAME benchmark::benchmark)
  endif()
  if(TARGET benchmark::benchmark_main)
    message(STATUS "Dependency(${PROJECT_NAME}): Target benchmark::benchmark_main found")
    project_build_tools_patch_default_imported_config(benchmark::benchmark_main)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_BENCHMARK_MAIN_LINK_NAME benchmark::benchmark_main)
  endif()
endmacro()

if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark::benchmark_main)
  if(VCPKG_TOOLCHAIN)
    find_package(benchmark QUIET CONFIG)
    project_third_party_benchmark_import()
  endif()

  if(NOT TARGET benchmark::benchmark AND NOT TARGET benchmark::benchmark_main)
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
          "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
          "-DBENCHMARK_ENABLE_TESTING=OFF"
          "-DBENCHMARK_ENABLE_LTO=OFF"
          "-DBENCHMARK_ENABLE_WERROR=OFF"
          "-DBENCHMARK_FORCE_WERROR=OFF"
          "-DBENCHMARK_ENABLE_INSTALL=ON"
          "-DALLOW_DOWNLOADING_GOOGLETEST=ON"
          "-DBENCHMARK_ENABLE_GTEST_TESTS=OFF")

      if(COMPILER_OPTIONS_TEST_EXCEPTION)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS "-DBENCHMARK_ENABLE_EXCEPTIONS=ON")
      else()
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS "-DBENCHMARK_ENABLE_EXCEPTIONS=OFF")
      endif()

      if(COMPILER_OPTION_CLANG_ENABLE_LIBCXX AND COMPILER_CLANG_TEST_LIBCXX)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS "-DBENCHMARK_USE_LIBCXX=ON")
      else()
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS "-DBENCHMARK_USE_LIBCXX=OFF")
      endif()

      if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_APPEND_DEFAULT_BUILD_OPTIONS)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS
             ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_APPEND_DEFAULT_BUILD_OPTIONS})
      endif()
    endif()

    # Do not use benchmark v1.7.0, which has a lot symbol exporting problems.
    project_third_party_port_declare(benchmark VERSION "v1.6.2" GIT_URL "https://github.com/google/benchmark.git")

    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_PATCH_FILE
        "${CMAKE_CURRENT_LIST_DIR}/benchmark-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_VERSION}.patch")

    project_third_party_append_build_shared_lib_var(
      "benchmark" "" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS BUILD_SHARED_LIBS)

    # Using our gtest source
    file(GLOB ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_FIND_GTEST_SRCS
         "${PROJECT_THIRD_PARTY_PACKAGE_DIR}/gtest-*")
    foreach(GOOGLETEST_PATH IN LISTS ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_FIND_GTEST_SRCS)
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

    if(WIN32
       OR MINGW
       OR CYGWIN)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS "-DCMAKE_DEBUG_POSTFIX=-dbg"
           "-DCMAKE_RELWITHDEBINFO_POSTFIX=-reldbg")
    endif()

    # CMake options end, maybe need patch files
    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_PATCH_FILE
       AND EXISTS "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_PATCH_FILE}")
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_BUILD_OPTIONS GIT_PATCH_FILES
           "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_BENCHMARK_PATCH_FILE}")
    endif()

    find_configure_package(
      PACKAGE
      benchmark
      BUILD_WITH_CMAKE
      FIND_PACKAGE_FLAGS
      CONFIG
      CMAKE_INHERIT_BUILD_ENV
      CMAKE_INHERIT_BUILD_ENV_DISABLE_C_FLAGS
      CMAKE_INHERIT_FIND_ROOT_PATH
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
