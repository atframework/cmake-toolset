# STL like library
# https://github.com/abseil/abseil-cpp.git
# git@github.com:abseil/abseil-cpp.git

include_guard(GLOBAL)

# =========== third party abseil-cpp ==================
macro(PROJECT_THIRD_PARTY_ABSEIL_IMPORT)
  if(absl_FOUND)
    message(STATUS "Dependency(${PROJECT_NAME}): abseil-cpp found(${PROJECT_NAME})")
  endif()
endmacro()

if(NOT absl_FOUND)
  if(VCPKG_TOOLCHAIN)
    find_package(absl QUIET)
    project_third_party_abseil_import()
  endif()

  if(NOT absl_FOUND)
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_VERSION)

      if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.9.0")
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_VERSION "20200225.3")
      else()
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_VERSION "20211102.0")
      endif()

    endif()

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
                                                                          "-DBUILD_TESTING=OFF")
      # abseil do not set export, which may lead to unresolved external symbol
      if(MSVC)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS "-DBUILD_SHARED_LIBS=OFF"
             "-DABSL_BUILD_DLL=OFF")
      else()
        project_third_party_append_build_shared_lib_var(
          "abseil" "GRPC" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS BUILD_SHARED_LIBS)
      endif()

      if(WIN32
         OR MINGW
         OR CYGWIN)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS "-DCMAKE_DEBUG_POSTFIX=-dbg"
             "-DCMAKE_RELWITHDEBINFO_POSTFIX=-reldbg")
      endif()

      if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_APPEND_DEFAULT_BUILD_OPTIONS)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS
             ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_APPEND_DEFAULT_BUILD_OPTIONS})
      endif()
    endif()

    project_third_party_port_declare(abseil PORT_PREFIX "GRPC" GIT_URL "https://github.com/abseil/abseil-cpp.git")

    # Other flags for find_configure_package
    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LOW_MEMORY_MODE)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS DISABLE_PARALLEL_BUILD)
    endif()

    find_configure_package(
      PACKAGE
      absl
      BUILD_WITH_CMAKE
      CMAKE_INHERIT_BUILD_ENV
      CMAKE_INHERIT_BUILD_ENV_DISABLE_C_FLAGS
      CMAKE_INHERIT_FIND_ROOT_PATH
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_OPTIONS}
      MSVC_CONFIGURE
      ${gRPC_MSVC_CONFIGURE}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "abseil-cpp-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_VERSION}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_GRPC_ABSEIL_GIT_URL}")

    if(absl_FOUND)
      project_third_party_abseil_import()
    endif()
  endif()
else()
  project_third_party_abseil_import()
endif()
