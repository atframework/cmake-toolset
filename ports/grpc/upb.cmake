# μpb (often written 'upb') is a small protobuf implementation written in C.
# https://github.com/protocolbuffers/upb.git
# git@github.com:protocolbuffers/upb.git

include_guard(GLOBAL)

# It's already included in grpc/third_party/upb , there is no need to import it again.

# The version is the same as in gRPC e4635f223e7d36dfbea3b722a4ca4807a7e882e2

macro(PROJECT_THIRD_PARTY_UPB_IMPORT)
  if(TARGET upb::upb)
    message(STATUS "Dependency(${PROJECT_NAME}): upb using target upb::upb")
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_LINK_NAME upb::upb)

    if(CMAKE_CROSSCOMPILING)
      find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB protoc-gen-upb)
      find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS protoc-gen-upbdefs)
      find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA protoc-gen-lua)
      message(
        STATUS
          "Dependency(${PROJECT_NAME}): upb executables for crosscompiling:
  ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB}
  ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS}
  ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA}
          ")
    else()
      if(TARGET upb::protoc-gen-upb)
        project_build_tools_get_imported_location(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB
                                                  upb::protoc-gen-upb)
      else()
        find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB protoc-gen-upb)
      endif()
      if(TARGET upb::protoc-gen-upbdefs)
        project_build_tools_get_imported_location(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS
                                                  upb::protoc-gen-upbdefs)
      else()
        find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS protoc-gen-upbdefs)
      endif()
      if(TARGET upb::protoc-gen-lua)
        project_build_tools_get_imported_location(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA
                                                  upb::protoc-gen-lua)
      else()
        find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA protoc-gen-lua)
      endif()
    endif()
  endif()
endmacro()

if(NOT TARGET upb::upb)
  find_package(upb QUIET)
  project_third_party_upb_import()

  if(NOT TARGET upb::upb AND NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_LINK_NAME)
    find_package(PythonInterp)
    if(PYTHONINTERP_FOUND AND NOT Python_EXECUTABLE)
      set(Python_EXECUTABLE ${PYTHON_EXECUTABLE})
    endif()
    if(NOT Python_EXECUTABLE)
      message(FATAL_ERROR "Python is required to build upb")
    endif()
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_LINK_NAME
       OR NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC
       OR NOT absl_FOUND)
      message(FATAL_ERROR "abseil-cpp and protobuf is required to build upb")
    endif()

    project_third_party_port_declare(
      upb
      VERSION
      "e4635f223e7d36dfbea3b722a4ca4807a7e882e2"
      GIT_URL
      "https://github.com/protocolbuffers/upb.git"
      BUILD_OPTIONS
      "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PATCH_FILE
        "${CMAKE_CURRENT_LIST_DIR}/upb-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_VERSION}.patch")

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS "-DBUILD_SHARED_LIBS=OFF")
    else()
      project_third_party_append_build_shared_lib_var("upb" "" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS
                                                      BUILD_SHARED_LIBS)
    endif()
    if(WIN32
       OR MINGW
       OR CYGWIN)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS "-DCMAKE_DEBUG_POSTFIX=-dbg"
           "-DCMAKE_RELWITHDEBINFO_POSTFIX=-reldbg")
    endif()

    if(ATFRAMEWORK_CMAKE_TOOLSET_PWSH AND (CMAKE_HOST_WIN32 OR CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows"))
      file(WRITE "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.ps1"
           "$PSDefaultParameterValues['*:Encoding'] = 'UTF-8'${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}")
      file(APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.ps1"
           "$OutputEncoding = [System.Text.UTF8Encoding]::new()${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}")
      file(
        APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.ps1"
        "Set-Location \"${PROJECT_THIRD_PARTY_PACKAGE_DIR}/${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_SRC_DIRECTORY_NAME}\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
      )
      file(
        APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.ps1"
        "& \"${Python_EXECUTABLE}\" cmake/make_cmakelists.py cmake/CMakeLists.txt${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
      )
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_GENERATE_CMAKELISTS_SCRIPT
          "${ATFRAMEWORK_CMAKE_TOOLSET_PWSH}"
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.ps1")
      project_make_writable("${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.ps1")
    else()
      file(WRITE "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.sh"
           "#!/bin/bash${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}")
      file(
        APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.sh"
        "cd \"${PROJECT_THIRD_PARTY_PACKAGE_DIR}/${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_SRC_DIRECTORY_NAME}\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
      )
      file(
        APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.sh"
        "\"${Python_EXECUTABLE}\" cmake/make_cmakelists.py cmake/CMakeLists.txt${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
      )
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_GENERATE_CMAKELISTS_SCRIPT
          "${ATFRAMEWORK_CMAKE_TOOLSET_BASH}"
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.sh")
      project_make_writable("${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}/run-generate-cmakelists.sh")
    endif()

    # Build host architecture upb first
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_HOST_BUILDING OR CMAKE_CROSSCOMPILING)
      project_third_party_get_host_build_dir(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_DIR "upb"
                                             ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_VERSION})
      get_filename_component(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR
                             "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_DIR}" DIRECTORY)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}/crosscompiling-upb-host")
      file(MAKE_DIRECTORY "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}")

      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS
          "${CMAKE_COMMAND}" "${CMAKE_CURRENT_LIST_DIR}/crosscompiling-upb-host")
      message(STATUS "Dependency(${PROJECT_NAME}): Try to build upb fo host architecture when crossing compiling")
      project_build_tools_append_cmake_host_options(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS)
      # Vcpkg
      if(DEFINED VCPKG_HOST_CRT_LINKAGE OR DEFINED CACHE{VCPKG_HOST_CRT_LINKAGE})
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS
             "-DVCPKG_CRT_LINKAGE=${VCPKG_HOST_CRT_LINKAGE}")
      elseif(DEFINED VCPKG_CRT_LINKAGE OR DEFINED CACHE{VCPKG_CRT_LINKAGE})
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS
             "-DVCPKG_CRT_LINKAGE=${VCPKG_CRT_LINKAGE}")
      endif()
      # Shared or static
      if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS "-DBUILD_SHARED_LIBS=OFF")
      else()
        project_third_party_append_build_shared_lib_var(
          "upb" "" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS BUILD_SHARED_LIBS)
      endif()

      # cmake-toolset
      list(
        APPEND
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS
        "-DPROJECT_THIRD_PARTY_INSTALL_DIR=${PROJECT_THIRD_PARTY_HOST_INSTALL_DIR}"
        "-DPROJECT_THIRD_PARTY_HOST_INSTALL_DIR=${PROJECT_THIRD_PARTY_HOST_INSTALL_DIR}"
        "-DPROJECT_THIRD_PARTY_PACKAGE_DIR=${PROJECT_THIRD_PARTY_PACKAGE_DIR}")
      if(DEFINED ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LOW_MEMORY_MODE
         OR DEFINED CACHE{ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LOW_MEMORY_MODE})
        list(
          APPEND
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS
          "-DATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LOW_MEMORY_MODE=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LOW_MEMORY_MODE}"
        )
      endif()

      foreach(CMD_ARG IN LISTS ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS)
        string(REPLACE ";" "\\;" CMD_ARG_UNESCAPE "${CMD_ARG}")
        add_compiler_flags_to_var(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_BUILD_FLAGS_CMD
                                  "\"${CMD_ARG_UNESCAPE}\"")
      endforeach()
      unset(CMD_ARG_UNESCAPE)

      # Build host
      if(NOT ATFRAMEWORK_CMAKE_TOOLSET_PWSH
         OR CMAKE_HOST_UNIX
         OR MSYS)
        configure_file(
          "${CMAKE_CURRENT_LIST_DIR}/crosscompiling-upb-host/run-build-host.sh.in"
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}/run-build-host.sh" @ONLY NEWLINE_STYLE LF)

        # build
        execute_process(
          COMMAND "${ATFRAMEWORK_CMAKE_TOOLSET_BASH}"
                  "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}/run-build-host.sh"
          WORKING_DIRECTORY "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}"
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      else()
        configure_file(
          "${CMAKE_CURRENT_LIST_DIR}/crosscompiling-upb-host/run-build-host.ps1.in"
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}/run-build-host.ps1" @ONLY
          NEWLINE_STYLE CRLF)
        configure_file(
          "${CMAKE_CURRENT_LIST_DIR}/crosscompiling-upb-host/run-build-host.bat.in"
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}/run-build-host.bat" @ONLY
          NEWLINE_STYLE CRLF)

        # build
        execute_process(
          COMMAND
            "${ATFRAMEWORK_CMAKE_TOOLSET_PWSH}" -NoProfile -InputFormat None -ExecutionPolicy Bypass -NonInteractive
            -NoLogo -File "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}/run-build-host.ps1"
          WORKING_DIRECTORY "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_HOST_TOOL_BUILD_DIR}"
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      endif()

      find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB protoc-gen-upb)
      find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS protoc-gen-upbdefs)
      find_program(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA protoc-gen-lua)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS "-DUPB_BUILD_CODEGEN=OFF"
           "-DPROTOC_GEN_UPB_PROGRAM=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB}"
           "-DPROTOC_GEN_UPBDEFS_PROGRAM=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS}")
      message(
        STATUS
          "Dependency(${PROJECT_NAME}): upb using PROTOC_GEN_UPB_PROGRAM=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPB}"
      )
      message(
        STATUS
          "Dependency(${PROJECT_NAME}): upb using PROTOC_GEN_UPBDEFS_PROGRAM=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_UPBDEFS}"
      )
      message(
        STATUS
          "Dependency(${PROJECT_NAME}): upb using ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PROTOC_GEN_LUA}"
      )
    else()
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS "-DUPB_BUILD_CODEGEN=ON")
    endif()
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS
         "-DUPB_HOST_INCLUDE_DIR=${PROJECT_THIRD_PARTY_HOST_INSTALL_DIR}/include"
         "-DPROTOC_PROGRAM=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC}")
    message(
      STATUS
        "Dependency(${PROJECT_NAME}): upb using UPB_HOST_INCLUDE_DIR=${PROJECT_THIRD_PARTY_HOST_INSTALL_DIR}/include")
    message(
      STATUS
        "Dependency(${PROJECT_NAME}): upb using PROTOC_PROGRAM=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PROTOBUF_BIN_PROTOC}"
    )

    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PATCH_FILE
       AND EXISTS "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PATCH_FILE}")
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS GIT_PATCH_FILES
           "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_PATCH_FILE}")
    endif()

    find_configure_package(
      PACKAGE
      upb
      PREBUILD_COMMAND
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_GENERATE_CMAKELISTS_SCRIPT}
      BUILD_WITH_CMAKE
      CMAKE_INHERIT_BUILD_ENV
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_OPTIONS}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_SRC_DIRECTORY_NAME}"
      PROJECT_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}/${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_SRC_DIRECTORY_NAME}/cmake"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_VERSION}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_UPB_GIT_URL}")

    if(TARGET upb::upb)
      project_third_party_upb_import()
      if(EXISTS "${PROJECT_THIRD_PARTY_INSTALL_DIR}/share/upb/upb/bindings/lua")
        execute_process(
          COMMAND
            "${CMAKE_COMMAND}" -E copy_if_different "${CMAKE_CURRENT_LIST_DIR}/upb-lua-binding/CMakeLists.txt"
            "${PROJECT_THIRD_PARTY_INSTALL_DIR}/share/upb/upb/bindings/lua"
            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      endif()
    endif()
  endif()
else()
  project_third_party_upb_import()
endif()

if(NOT TARGET upb::upb)
  message(FATAL_ERROR "Dependency(${PROJECT_NAME}): Can not build upb.")
endif()
