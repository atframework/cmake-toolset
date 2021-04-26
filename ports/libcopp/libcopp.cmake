include_guard(GLOBAL)

macro(PROJECT_THIRD_PARTY_LIBCOPP_IMPORT)
  if(TARGET libcopp::cotask)
    echowithcolor(COLOR GREEN
                  "-- Dependency(${PROJECT_NAME}): libcopp using target: libcopp::cotask")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES libcopp::cotask)
  elseif(TARGET cotask)
    echowithcolor(COLOR GREEN "-- Dependency(${PROJECT_NAME}): libcopp using target: cotask")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES cotask)
  endif()
endmacro()

if(NOT TARGET libcopp::cotask AND NOT cotask)
  if(VCPKG_TOOLCHAIN)
    find_package(libcopp QUIET CONFIG)
    project_third_party_libcopp_import()
  endif()

  if(NOT TARGET libcopp::cotask AND NOT cotask)

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_VERSION)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_VERSION "v2")
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_GIT_URL)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_GIT_URL
          "https://github.com/owt5008137/libcopp.git")
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_OPTIONS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_OPTIONS
          "-DPROJECT_ENABLE_UNITTEST=OFF" "-DPROJECT_ENABLE_SAMPLE=OFF"
          "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_DIR)
      project_third_party_get_build_dir(
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_DIR "libcopp"
        ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_VERSION})
    endif()
    if(NOT EXISTS "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_DIR}")
      file(MAKE_DIRECTORY "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_DIR}")
    endif()

    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_REPOSITORY_DIR
        "${PROJECT_THIRD_PARTY_PACKAGE_DIR}/libcopp-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_VERSION}"
    )
    project_third_party_append_build_shared_lib_var(
      ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_OPTIONS LIBCOPP_USE_DYNAMIC_LIBRARY)

    find_configure_package(
      PACKAGE
      libcopp
      FIND_PACKAGE_FLAGS
      CONFIG
      BUILD_WITH_CMAKE
      CMAKE_INHIRT_BUILD_ENV
      CMAKE_INHIRT_FIND_ROOT_PATH
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_OPTIONS}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "libcopp-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_VERSION}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCOPP_GIT_URL}")

    project_third_party_libcopp_import()
  endif()
else()
  project_third_party_libcopp_import()
endif()
