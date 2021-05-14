# Prometheus Data Model implement for C++
# https://github.com/jupp0r/prometheus-cpp

include_guard(GLOBAL)

# =========== third party prometheus-cpp ==================
macro(PROJECT_THIRD_PARTY_PROMETHEUS_CPP_IMPORT)
  if(TARGET prometheus-cpp::core)
    echowithcolor(
      COLOR GREEN
      "-- Dependency(${PROJECT_NAME}): prometheus-cpp found target prometheus-cpp::core")
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_LINK_NAME prometheus-cpp::core)
    if(TARGET prometheus-cpp::pull)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_LINK_NAME
           prometheus-cpp::pull)
    endif()
    if(TARGET prometheus-cpp::push)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_LINK_NAME
           prometheus-cpp::push)
    endif()

    project_build_tools_patch_default_imported_config(prometheus-cpp::core prometheus-cpp::pull
                                                      prometheus-cpp::push)
  endif()
endmacro()

if(NOT TARGET prometheus-cpp::core)
  find_package(prometheus-cpp QUIET CONFIG)
  project_third_party_prometheus_cpp_import()
  if(NOT TARGET prometheus-cpp::core)
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_VERSION)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_VERSION "v0.12.3")
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_GIT_URL)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_GIT_URL
          "https://github.com/jupp0r/prometheus-cpp.git")
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_DIR)
      project_third_party_get_build_dir(
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_DIR "prometheus-cpp"
        ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_VERSION})
    endif()

    if(NOT EXISTS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_DIR})
      file(MAKE_DIRECTORY ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_DIR})
    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_OPTIONS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_OPTIONS
          "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" "-DENABLE_TESTING=OFF"
          "-DUSE_THIRDPARTY_LIBRARIES=OFF" "-DRUN_IWYU=OFF" "-DENABLE_WARNINGS_AS_ERRORS=OFF")
      if(TARGET ZLIB::ZLIB)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_OPTIONS
             "-DENABLE_COMPRESSION=ON")
      endif()
      if(TARGET civetweb::civetweb-cpp OR TARGET civetweb::civetweb)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_OPTIONS
             "-DENABLE_PULL=ON")
      endif()
      if(CURL_FOUND)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_OPTIONS
             "-DENABLE_PUSH=ON")
      endif()
    endif()

    project_third_party_append_build_shared_lib_var(
      ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_OPTIONS BUILD_SHARED_LIBS)

    include(AtframeworkToolsetCommonDefinitions)
    if(ATFRAMEWORK_CMAKE_TOOLSET_SYSTEM_LINKS)
      set(PATCH_BACKUP_CMAKE_C_STANDARD_LIBRARIES ${CMAKE_C_STANDARD_LIBRARIES})
      set(PATCH_BACKUP_CMAKE_CXX_STANDARD_LIBRARIES ${CMAKE_CXX_STANDARD_LIBRARIES})
      add_compiler_flags_to_var_unique(CMAKE_C_STANDARD_LIBRARIES
                                       ${ATFRAMEWORK_CMAKE_TOOLSET_SYSTEM_LINKS})
      add_compiler_flags_to_var_unique(CMAKE_CXX_STANDARD_LIBRARIES
                                       ${ATFRAMEWORK_CMAKE_TOOLSET_SYSTEM_LINKS})
    endif()

    find_configure_package(
      PACKAGE
      prometheus-cpp
      FIND_PACKAGE_FLAGS
      CONFIG
      BUILD_WITH_CMAKE
      CMAKE_INHIRT_BUILD_ENV
      CMAKE_INHIRT_FIND_ROOT_PATH
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_OPTIONS}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "prometheus-cpp-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_VERSION}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROMETHEUS_CPP_GIT_URL}")
    if(PATCH_BACKUP_CMAKE_C_STANDARD_LIBRARIES)
      set(CMAKE_C_STANDARD_LIBRARIES ${PATCH_BACKUP_CMAKE_C_STANDARD_LIBRARIES})
      unset(PATCH_BACKUP_CMAKE_C_STANDARD_LIBRARIES)
    endif()
    if(PATCH_BACKUP_CMAKE_CXX_STANDARD_LIBRARIES)
      set(CMAKE_CXX_STANDARD_LIBRARIES ${PATCH_BACKUP_CMAKE_CXX_STANDARD_LIBRARIES})
      unset(PATCH_BACKUP_CMAKE_CXX_STANDARD_LIBRARIES)
    endif()

    project_third_party_prometheus_cpp_import()
  endif()
else()
  project_third_party_prometheus_cpp_import()
endif()

if(NOT TARGET prometheus-cpp::core)
  message(FATAL_ERROR "-- Dependency(${PROJECT_NAME}): prometheus-cpp not found")
endif()
