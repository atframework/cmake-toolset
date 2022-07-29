# An xUnit test framework.
# https://github.com/google/googletest/
# git@github.com:google/googletest.git

include_guard(GLOBAL)

# =========== third party GTest ==================
macro(PROJECT_THIRD_PARTY_GTEST_IMPORT)
  if(TARGET GTest::gtest)
    message(STATUS "Dependency(${PROJECT_NAME}): Target GTest::gtest found")
    project_build_tools_patch_default_imported_config(GTest::gtest)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_GTEST_LINK_NAME GTest::gtest)
  elseif(TARGET GTest::GTest)
    message(STATUS "Dependency(${PROJECT_NAME}): Target GTest::GTest found")
    project_build_tools_patch_default_imported_config(GTest::GTest)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_GTEST_LINK_NAME GTest::GTest)
  endif()
  if(TARGET GTest::gtest_main)
    message(STATUS "Dependency(${PROJECT_NAME}): Target GTest::gtest_main found")
    project_build_tools_patch_default_imported_config(GTest::gtest_main)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_GTEST_MAIN_LINK_NAME GTest::gtest_main)
  elseif(TARGET GTest::Main)
    message(STATUS "Dependency(${PROJECT_NAME}): Target GTest::Main found")
    project_build_tools_patch_default_imported_config(GTest::Main)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_GTEST_MAIN_LINK_NAME GTest::Main)
  endif()
  if(TARGET GTest::gmock)
    message(STATUS "Dependency(${PROJECT_NAME}): Target GTest::gmock found")
    project_build_tools_patch_default_imported_config(GTest::gmock)
  endif()
  if(TARGET GTest::gmock_main)
    message(STATUS "Dependency(${PROJECT_NAME}): Target GTest::gmock_main found")
    project_build_tools_patch_default_imported_config(GTest::gmock_main)
  endif()
endmacro()

if(NOT TARGET GTest::gtest
   AND NOT TARGET GTest::gtest_main
   AND NOT TARGET GTest::GTest
   AND NOT TARGET GTest::Main)
  if(VCPKG_TOOLCHAIN)
    find_package(GTest QUIET CONFIG)
    project_third_party_gtest_import()
  endif()

  if(NOT TARGET GTest::gtest
     AND NOT TARGET GTest::gtest_main
     AND NOT TARGET GTest::GTest
     AND NOT TARGET GTest::Main)

    if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
      if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "5.0")
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_DEFAULT_VERSION "release-1.10.0")
      endif()
    elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
      if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "3.4")
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_DEFAULT_VERSION "release-1.10.0")
      endif()
    elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "AppleClang")
      if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "5.1")
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_DEFAULT_VERSION "release-1.10.0")
      endif()
    elseif(MSVC)
      if(MSVC_VERSION LESS 1910)
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_DEFAULT_VERSION "release-1.10.0")
      endif()
    endif()
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_DEFAULT_VERSION)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_DEFAULT_VERSION "release-1.12.1")
    endif()
    project_third_party_port_declare(
      gtest
      VERSION
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_DEFAULT_VERSION}"
      GIT_URL
      "https://github.com/google/googletest.git"
      BUILD_OPTIONS
      "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
      "-DBUILD_GMOCK=ON"
      "-DINSTALL_GTEST=ON")

    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_PATCH_FILE
        "${CMAKE_CURRENT_LIST_DIR}/gtest-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_VERSION}.patch")

    if(WIN32
       OR MINGW
       OR CYGWIN)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_BUILD_OPTIONS "-DCMAKE_DEBUG_POSTFIX=-dbg"
           "-DCMAKE_RELWITHDEBINFO_POSTFIX=-reldbg")
    endif()
    project_third_party_append_build_shared_lib_var(
      "gtest" "" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_BUILD_OPTIONS BUILD_SHARED_LIBS)

    if(EXISTS "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_PATCH_FILE}")
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_BUILD_OPTIONS GIT_PATCH_FILES
           "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_PATCH_FILE}")
    endif()

    find_configure_package(
      PACKAGE
      GTest
      BUILD_WITH_CMAKE
      FIND_PACKAGE_FLAGS
      CONFIG
      CMAKE_INHERIT_BUILD_ENV
      CMAKE_INHERIT_FIND_ROOT_PATH
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_BUILD_OPTIONS}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "gtest-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_VERSION}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GTEST_GIT_URL}")

    if(TARGET GTest::gtest
       OR TARGET GTest::gtest_main
       OR TARGET GTest::GTest
       OR TARGET GTest::Main)
      project_third_party_gtest_import()
    endif()
  endif()
else()
  project_third_party_gtest_import()
endif()

if(NOT TARGET GTest::gtest
   AND NOT TARGET GTest::gtest_main
   AND NOT TARGET GTest::GTest
   AND NOT TARGET GTest::Main
   AND NOT TARGET GTest::gmock
   AND NOT TARGET GTest::gmock_main)
  message(FATAL_ERROR "Dependency(${PROJECT_NAME}): Build GTest failed.")
endif()
