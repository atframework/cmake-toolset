include_guard(GLOBAL)
# =========== third_party redis ==================

macro(PROJECT_THIRD_PARTY_REDIS_HIREDIS_IMPORT)
  if(TARGET hiredis::hiredis_ssl_static)
    message(STATUS "hiredis using target: hiredis::hiredis_ssl_static")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES hiredis::hiredis_ssl_static)
    if(TARGET hiredis::hiredis_static)
      project_build_tools_patch_imported_link_interface_libraries(
        hiredis::hiredis_ssl_static REMOVE_LIBRARIES hiredis::hiredis ADD_LIBRARIES
        hiredis::hiredis_static)
    endif()
  elseif(TARGET hiredis::hiredis_static)
    message(STATUS "hiredis using target: hiredis::hiredis_static")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES hiredis::hiredis_static)
  elseif(TARGET hiredis::hiredis_ssl)
    message(STATUS "hiredis using target: hiredis::hiredis_ssl")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES hiredis::hiredis_ssl)
    if(TARGET hiredis::hiredis)
      project_build_tools_patch_imported_link_interface_libraries(
        hiredis::hiredis_ssl REMOVE_LIBRARIES hiredis::hiredis_ssl_static ADD_LIBRARIES
        hiredis::hiredis)
    endif()
  elseif(TARGET hiredis::hiredis)
    message(STATUS "hiredis using target: hiredis::hiredis")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES hiredis::hiredis)
  else()
    message(STATUS "hiredis support disabled")
  endif()
endmacro()

if(VCPKG_TOOLCHAIN)
  find_package(hiredis QUIET CONFIG)
  project_third_party_redis_hiredis_import()
endif()

if(NOT TARGET hiredis::hiredis_ssl_static
   AND NOT TARGET hiredis::hiredis_static
   AND NOT TARGET hiredis::hiredis_ssl
   AND NOT TARGET hiredis::hiredis)

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_VERSION)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_VERSION
        "2a5a57b90a57af5142221aa71f38c08f4a737376") # v1.0.0 with some patch
  endif()

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_GIT_URL)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_GIT_URL
        "https://github.com/redis/hiredis.git")
  endif()

  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_REDIS_HIREDIS_DIR
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}/hiredis-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_VERSION}"
  )

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_BUILD_OPTIONS)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_BUILD_OPTIONS "-DDISABLE_TESTS=YES"
                                                                    "-DENABLE_EXAMPLES=OFF")
  endif()

  project_third_party_append_find_root_args(
    ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_BUILD_OPTIONS)

  if(OPENSSL_FOUND)
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_BUILD_OPTIONS "-DENABLE_SSL=ON")
  endif()

  findconfigurepackage(
    PACKAGE
    hiredis
    BUILD_WITH_CMAKE
    CMAKE_INHIRT_BUILD_ENV
    CMAKE_INHIRT_BUILD_ENV_DISABLE_CXX_FLAGS
    CMAKE_FLAGS
    ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_BUILD_OPTIONS}
    "-DCMAKE_POSITION_INDEPENDENT_CODE=YES"
    WORKING_DIRECTORY
    "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
    BUILD_DIRECTORY
    "${CMAKE_CURRENT_BINARY_DIR}/dependency-buildtree/hiredis-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_VERSION}/build_jobs_${PROJECT_PREBUILT_PLATFORM_NAME}"
    PREFIX_DIRECTORY
    "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
    SRC_DIRECTORY_NAME
    "hiredis-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_VERSION}"
    GIT_COMMIT
    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_VERSION}"
    GIT_URL
    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_HIREDIS_GIT_URL}")

  if(NOT hiredis_FOUND)
    echowithcolor(
      COLOR
      RED
      "-- Dependency(${PROJECT_NAME}): hiredis is required, we can not find prebuilt for hiredis and can not build from the sources"
    )
    message(FATAL_ERROR "hiredis not found")
  endif()

  if(TARGET hiredis::hiredis_static OR TARGET hiredis::hiredis)
    find_package(hiredis_ssl QUIET CONFIG)
  endif()

  project_third_party_redis_hiredis_import()
endif()

if(NOT hiredis_FOUND)
  echowithcolor(COLOR RED "-- Dependency(${PROJECT_NAME}): hiredis is required")
  message(FATAL_ERROR "hiredis not found")
endif()