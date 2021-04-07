if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.10")
  include_guard(GLOBAL)
endif()

# =========== third party zstd ==================
# force to use prebuilt when using mingw
macro(PROJECT_THIRD_PARTY_ZSTD_IMPORT)
  if(TARGET zstd::libzstd_shared)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME zstd::libzstd_shared)
    echowithcolor(COLOR GREEN
                  "-- Dependency(${PROJECT_NAME}): zstd found target: zstd::libzstd_shared")
    # list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES zstd::libzstd_shared)
  elseif(TARGET zstd::libzstd_static)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME zstd::libzstd_static)
    echowithcolor(COLOR GREEN
                  "-- Dependency(${PROJECT_NAME}): zstd found target: zstd::libzstd_static")
    # list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES zstd::libzstd_static)
  elseif(TARGET zstd::libzstd)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME zstd::libzstd)
    echowithcolor(COLOR GREEN "-- Dependency(${PROJECT_NAME}): zstd found target: zstd::libzstd")
    # list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES zstd::libzstd)
  else()
    unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME)
  endif()
  if(TARGET zstd::zstd)
    project_build_tools_get_imported_location(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_BIN
                                              zstd::zstd)
    echowithcolor(
      COLOR
      GREEN
      "-- Dependency(${PROJECT_NAME}): zstd found exec: ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_BIN}"
    )
  elseif(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME)
    # Maybe zstd executable not exported, find it by library target
    project_build_tools_get_imported_location(
      ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LIB_PATH
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME})
    get_filename_component(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LIB_DIR
                           ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LIB_PATH} DIRECTORY)
    get_filename_component(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_ROOT_DIR
                           ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LIB_DIR} DIRECTORY)
    find_program(
      ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_BIN
      NAMES zstd
      NO_DEFAULT_PATH
      PATHS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_ROOT_DIR}
      PATH_SUFFIXES "." "bin")
    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_BIN)
      echowithcolor(
        COLOR
        GREEN
        "-- Dependency(${PROJECT_NAME}): zstd found exec: ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_BIN}"
      )
    endif()
  endif()

  if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_ZSTD_LINK_NAME)
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_COPY_EXECUTABLE_PATTERN
         "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR}/bin/zstd*")
  endif()
endmacro()

if(NOT TARGET zstd::libzstd_shared
   AND NOT TARGET zstd::libzstd_static
   AND NOT TARGET zstd::libzstd
   AND NOT TARGET zstd::zstd)
  if(VCPKG_TOOLCHAIN)
    find_package(zstd QUIET)
    project_third_party_zstd_import()
  endif()

  if(NOT TARGET zstd::libzstd_shared
     AND NOT TARGET zstd::libzstd_static
     AND NOT TARGET zstd::libzstd
     AND NOT TARGET zstd::zstd)
    set(PROJECT_THIRD_PARTY_ZSTD_DEFAULT_VERSION "v1.4.9")

    findconfigurepackage(
      PACKAGE
      zstd
      BUILD_WITH_CMAKE
      CMAKE_INHIRT_BUILD_ENV
      CMAKE_INHIRT_BUILD_ENV_DISABLE_CXX_FLAGS
      CMAKE_FLAGS
      "-DCMAKE_POSITION_INDEPENDENT_CODE=YES"
      "-DBUILD_SHARED_LIBS=OFF"
      "-DZSTD_BUILD_TESTS=OFF"
      "-DZSTD_PROGRAMS_LINK_SHARED=OFF"
      "-DZSTD_BUILD_STATIC=ON"
      "-DZSTD_BUILD_SHARED=OFF"
      "-DZSTD_BUILD_CONTRIB=0"
      "-DCMAKE_DEBUG_POSTFIX=d"
      "-DZSTD_BUILD_PROGRAMS=ON"
      "-DZSTD_MULTITHREAD_SUPPORT=ON"
      "-DZSTD_ZLIB_SUPPORT=ON"
      "-DZSTD_LZ4_SUPPORT=ON"
      "-DLZ4_ROOT_DIR=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR}"
      "-DZLIB_ROOT=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR}"
      WORKING_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PACKAGE_DIR}"
      PREFIX_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "zstd-${PROJECT_THIRD_PARTY_ZSTD_DEFAULT_VERSION}"
      PROJECT_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PACKAGE_DIR}/zstd-${PROJECT_THIRD_PARTY_ZSTD_DEFAULT_VERSION}/build/cmake"
      BUILD_DIRECTORY
      "${CMAKE_CURRENT_BINARY_DIR}/deps/zstd-${PROJECT_THIRD_PARTY_ZSTD_DEFAULT_VERSION}/build_jobs_${PROJECT_PREBUILT_PLATFORM_NAME}"
      GIT_BRANCH
      "${PROJECT_THIRD_PARTY_ZSTD_DEFAULT_VERSION}"
      GIT_URL
      "https://github.com/facebook/zstd.git")

    if(NOT TARGET zstd::libzstd_shared
       AND NOT TARGET zstd::libzstd_static
       AND NOT TARGET zstd::libzstd
       AND NOT TARGET zstd::zstd)
      echowithcolor(COLOR YELLOW "-- Dependency: zstd not found")
    endif()
    project_third_party_zstd_import()
  endif()
else()
  project_third_party_zstd_import()
endif()
