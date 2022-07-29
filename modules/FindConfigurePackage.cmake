# .rst: FindConfigurePackage
# ----------------
#
# find package, and try to configure it when not found in system.
#
# FindConfigurePackage(
#   PACKAGE <name>
#   DISABLE_PARALLEL_BUILD
#   BUILD_WITH_CONFIGURE
#   BUILD_WITH_CMAKE
#   BUILD_WITH_SCONS
#   BUILD_WITH_CUSTOM_COMMAND
#   CONFIGURE_FLAGS [configure options...]
#   CMAKE_FLAGS [cmake options...]
#   FIND_PACKAGE_FLAGS [options will be passed into find_package(...)]
#   CMAKE_INHERIT_BUILD_ENV
#   CMAKE_INHERIT_BUILD_ENV_DISABLE_C_FLAGS
#   CMAKE_INHERIT_BUILD_ENV_DISABLE_CXX_FLAGS
#   CMAKE_INHERIT_BUILD_ENV_DISABLE_ASM_FLAGS
#   CMAKE_INHERIT_FIND_ROOT_PATH
#   CMAKE_INHERIT_SYSTEM_LINKS
#   SCONS_FLAGS [scons options...]
#   CUSTOM_BUILD_COMMAND [custom build cmd...]
#   MAKE_FLAGS [make options...]
#   PREBUILD_COMMAND [run cmd before build ...]
#   AFTERBUILD_COMMAND [run cmd after build ...]
#   RESET_FIND_VARS [cmake vars]
#   WORKING_DIRECTORY <work directory>
#   BUILD_DIRECTORY <build directory>
#   PREFIX_DIRECTORY <prefix directory>
#   SRC_DIRECTORY_NAME <source directory name>
#   MSVC_CONFIGURE <Debug/Release/RelWithDebInfo/MinSizeRel>
#   AUTOGEN_CONFIGURE [autogen command and args...]
#   INSTALL_TARGET [install targets...]
#   ZIP_URL <zip url>
#   TAR_URL <tar url>
#   SVN_URL <svn url>
#   GIT_URL <git url>
#   GIT_BRANCH <git branch>
#   GIT_COMMIT <git commit sha>
#   GIT_PATCH_FILES [git patch files...]
# )
#
# ::
#
# <configure options>         - flags added to configure command
# <cmake options>             - flags added to cmake command
# <scons options>             - flags added to scons command
# <custom build cmd>          - custom commands for build
# <make options>              - flags added to make command
# <pre build cmd>             - commands to run before build tool
# <autogen command and args>  - command and arguments to run before configure.(on source directory)
# <work directory>            - work directory
# <build directory>           - where to execute configure and make
# <prefix directory>          - prefix directory(default: <work directory>)
# <source directory name>     - source directory name(default detected by download url)
# <install targets>           - which target(s) used to install package(default: install) <zip url> - from where to download zip when find package failed
# <tar url>                   - from where to download tar.* or tgz when find package failed <svn url>               - from where to svn co when find package failed
# <git url>                   - from where to git clone when find package failed
# <git branch>                - git branch or tag to fetch
# <git commit>                - git commit to fetch, server must support --deepen=<depth>. if both <git branch> and <git commit> is set, we will use <git branch>
# <fetch depth/deepen>        - --deepen or --depth for git fetch depend using <git branch> or <git commit>
# <git patch files>           - git apply [git patch files...]
#

# =============================================================================
# Copyright 2021 atframework.
#
# Distributed under the Apache License Version 2.0 (the "License"); see accompanying file LICENSE for details.

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/ProjectBuildTools.cmake")

function(FindConfigurePackageDownloadFile from to)
  find_program(WGET_FULL_PATH wget)
  if(WGET_FULL_PATH)
    execute_process(
      COMMAND "${WGET_FULL_PATH}" "--no-check-certificate" "-t" "${PROJECT_BUILD_TOOLS_DOWNLOAD_RETRY_TIMES}" "-v"
              "${from}" "-O" "${to}" ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
  else()
    find_program(CURL_FULL_PATH curl)
    if(CURL_FULL_PATH)
      execute_process(COMMAND "${CURL_FULL_PATH}" "--insecure" "--retry" "${PROJECT_BUILD_TOOLS_DOWNLOAD_RETRY_TIMES}"
                              "-L" "${from}" "-o" "${to}" ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
    else()
      set(FindConfigurePackageDownloadFile_RETRY_TIMES 0)
      while(FindConfigurePackageDownloadFile_RETRY_TIMES LESS_EQUAL PROJECT_BUILD_TOOLS_DOWNLOAD_RETRY_TIMES)
        if(FindConfigurePackageDownloadFile_RETRY_TIMES GREATER 0)
          message(
            STATUS
              "Retry to download file from ${from} for the ${FindConfigurePackageDownloadFile_RETRY_TIMES} time(s).")
        endif()
        math(EXPR FindConfigurePackageDownloadFile_RETRY_TIMES "${FindConfigurePackageDownloadFile_RETRY_TIMES} + 1"
             OUTPUT_FORMAT DECIMAL)
        file(
          DOWNLOAD "${from}" "${to}"
          SHOW_PROGRESS
          TLS_VERIFY OFF)
        if(EXISTS "${to}")
          break()
        endif()
      endwhile()
    endif()
  endif()
endfunction()

function(FindConfigurePackageUnzip src work_dir)
  if(CMAKE_HOST_UNIX)
    find_program(FindConfigurePackage_UNZIP_BIN unzip)
    if(FindConfigurePackage_UNZIP_BIN)
      execute_process(COMMAND ${FindConfigurePackage_UNZIP_BIN} -uo ${src}
                      WORKING_DIRECTORY ${work_dir} ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      return()
    endif()
  endif()
  # fallback
  execute_process(COMMAND ${CMAKE_COMMAND} -E tar xvf ${src}
                  WORKING_DIRECTORY ${work_dir} ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
endfunction()

function(FindConfigurePackageTarXV src work_dir)
  if(CMAKE_HOST_UNIX)
    find_program(FindConfigurePackage_TAR_BIN tar)
    if(FindConfigurePackage_TAR_BIN)
      execute_process(COMMAND ${FindConfigurePackage_TAR_BIN} -xvf ${src}
                      WORKING_DIRECTORY ${work_dir} ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      return()
    endif()
  endif()
  # fallback
  execute_process(COMMAND ${CMAKE_COMMAND} -E tar xvf ${src}
                  WORKING_DIRECTORY ${work_dir} ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
endfunction()

function(FindConfigurePackageRemoveEmptyDir DIR)
  if(EXISTS ${DIR})
    file(GLOB RESULT "${DIR}/*")
    list(LENGTH RESULT RES_LEN)
    if(${RES_LEN} EQUAL 0)
      file(REMOVE_RECURSE ${DIR})
    endif()
  endif()
endfunction()

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.12")
  set(FindConfigurePackageCMakeBuildMultiJobs
      "--parallel"
      CACHE INTERNAL "Build options for multi-jobs")
  unset(CPU_CORE_NUM)
elseif(
  (CMAKE_MAKE_PROGRAM STREQUAL "make")
  OR (CMAKE_MAKE_PROGRAM STREQUAL "gmake")
  OR (CMAKE_MAKE_PROGRAM STREQUAL "ninja"))
  cmake_host_system_information(RESULT CPU_CORE_NUM QUERY NUMBER_OF_PHYSICAL_CORES)
  set(FindConfigurePackageCMakeBuildMultiJobs
      "--" "-j${CPU_CORE_NUM}"
      CACHE INTERNAL "Build options for multi-jobs")
  unset(CPU_CORE_NUM)
elseif(CMAKE_MAKE_PROGRAM STREQUAL "xcodebuild")
  cmake_host_system_information(RESULT CPU_CORE_NUM QUERY NUMBER_OF_PHYSICAL_CORES)
  set(FindConfigurePackageCMakeBuildMultiJobs
      "--" "-jobs" ${CPU_CORE_NUM}
      CACHE INTERNAL "Build options for multi-jobs")
  unset(CPU_CORE_NUM)
elseif(CMAKE_VS_MSBUILD_COMMAND)
  set(FindConfigurePackageCMakeBuildMultiJobs
      "--" "/m"
      CACHE INTERNAL "Build options for multi-jobs")
endif()

if(NOT FindConfigurePackageGitFetchDepth)
  set(FindConfigurePackageGitFetchDepth
      100
      CACHE STRING "Defalut depth of git clone/fetch")
endif()

macro(FindConfigurePackage)
  set(optionArgs
      DISABLE_PARALLEL_BUILD
      BUILD_WITH_CONFIGURE
      BUILD_WITH_CMAKE
      BUILD_WITH_SCONS
      BUILD_WITH_CUSTOM_COMMAND
      CMAKE_INHERIT_BUILD_ENV
      CMAKE_INHERIT_BUILD_ENV_DISABLE_C_FLAGS
      CMAKE_INHERIT_BUILD_ENV_DISABLE_CXX_FLAGS
      CMAKE_INHERIT_BUILD_ENV_DISABLE_ASM_FLAGS
      CMAKE_INHERIT_FIND_ROOT_PATH
      CMAKE_INHERIT_SYSTEM_LINKS
      GIT_ENABLE_SUBMODULE
      GIT_SUBMODULE_RECURSIVE)
  set(oneValueArgs
      PACKAGE
      PORT_PREFIX
      WORKING_DIRECTORY
      BUILD_DIRECTORY
      PREFIX_DIRECTORY
      SRC_DIRECTORY_NAME
      PROJECT_DIRECTORY
      MSVC_CONFIGURE
      ZIP_URL
      TAR_URL
      SVN_URL
      GIT_URL
      GIT_BRANCH
      GIT_COMMIT
      GIT_FETCH_DEPTH)
  set(multiValueArgs
      AUTOGEN_CONFIGURE
      CONFIGURE_CMD
      CONFIGURE_FLAGS
      CMAKE_FLAGS
      FIND_PACKAGE_FLAGS
      RESET_FIND_VARS
      SCONS_FLAGS
      MAKE_FLAGS
      CUSTOM_BUILD_COMMAND
      PREBUILD_COMMAND
      AFTERBUILD_COMMAND
      INSTALL_TARGET
      GIT_PATCH_FILES
      GIT_SUBMODULE_PATHS
      GIT_RESET_SUBMODULE_URLS)
  foreach(RESTORE_VAR IN LISTS optionArgs oneValueArgs multiValueArgs)
    unset(FindConfigurePackage_${RESTORE_VAR})
  endforeach()

  cmake_parse_arguments(FindConfigurePackage "${optionArgs}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT FindConfigurePackage_INSTALL_TARGET)
    set(FindConfigurePackage_INSTALL_TARGET "install")
  endif()
  # some module is not match standard, using upper case but package name
  string(TOUPPER "${FindConfigurePackage_PACKAGE}_FOUND" FIND_CONFIGURE_PACKAGE_UPPER_NAME)

  unset(FindConfigurePackage_BACKUP_CMAKE_FIND_ROOT_PATH)
  unset(FindConfigurePackage_BACKUP_CMAKE_PREFIX_PATH)

  if(FindConfigurePackage_PORT_PREFIX AND NOT "${FindConfigurePackage_PORT_PREFIX}" STREQUAL "")
    string(
      TOUPPER
        "ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_PORT_PREFIX}_${FindConfigurePackage_PACKAGE}"
        FindConfigurePackage_FULL_PORT_NAME)
  else()
    string(TOUPPER "ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_PACKAGE}"
                   FindConfigurePackage_FULL_PORT_NAME)
  endif()

  # step 1. find using standard method
  find_package(${FindConfigurePackage_PACKAGE} QUIET ${FindConfigurePackage_FIND_PACKAGE_FLAGS})
  if(NOT ${FindConfigurePackage_PACKAGE}_FOUND AND NOT ${FIND_CONFIGURE_PACKAGE_UPPER_NAME})
    if(NOT FindConfigurePackage_PREFIX_DIRECTORY)
      # prefix
      set(FindConfigurePackage_PREFIX_DIRECTORY ${FindConfigurePackage_WORK_DIRECTORY})
    endif()

    if(NOT "${FindConfigurePackage_PREFIX_DIRECTORY}" IN_LIST CMAKE_FIND_ROOT_PATH)
      set(FindConfigurePackage_BACKUP_CMAKE_FIND_ROOT_PATH ${CMAKE_FIND_ROOT_PATH})
      list(APPEND CMAKE_FIND_ROOT_PATH ${FindConfigurePackage_PREFIX_DIRECTORY})
    endif()
    if(NOT "${FindConfigurePackage_PREFIX_DIRECTORY}" IN_LIST CMAKE_PREFIX_PATH)
      set(FindConfigurePackage_BACKUP_CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH})
      list(APPEND CMAKE_PREFIX_PATH ${FindConfigurePackage_PREFIX_DIRECTORY})
    endif()

    # step 2. find in prefix
    find_package(${FindConfigurePackage_PACKAGE} QUIET ${FindConfigurePackage_FIND_PACKAGE_FLAGS})

    # step 3. build
    if(NOT ${FindConfigurePackage_PACKAGE}_FOUND AND NOT ${FIND_CONFIGURE_PACKAGE_UPPER_NAME})
      set(FindConfigurePackage_UNPACK_SOURCE NO)

      # tar package
      if(NOT FindConfigurePackage_UNPACK_SOURCE AND FindConfigurePackage_TAR_URL)
        get_filename_component(DOWNLOAD_FILENAME "${FindConfigurePackage_TAR_URL}" NAME)
        if(NOT FindConfigurePackage_SRC_DIRECTORY_NAME)
          string(REGEX REPLACE "\\.tar\\.[A-Za-z0-9]+$" "" FindConfigurePackage_SRC_DIRECTORY_NAME
                               "${DOWNLOAD_FILENAME}")
        endif()
        set(FindConfigurePackage_DOWNLOAD_SOURCE_DIR
            "${FindConfigurePackage_WORKING_DIRECTORY}/${FindConfigurePackage_SRC_DIRECTORY_NAME}")
        findconfigurepackageremoveemptydir(${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})

        if(NOT EXISTS "${FindConfigurePackage_WORKING_DIRECTORY}/${DOWNLOAD_FILENAME}")
          message(STATUS "start to download ${DOWNLOAD_FILENAME} from ${FindConfigurePackage_TAR_URL}")
          findconfigurepackagedownloadfile("${FindConfigurePackage_TAR_URL}"
                                           "${FindConfigurePackage_WORKING_DIRECTORY}/${DOWNLOAD_FILENAME}")
        endif()

        findconfigurepackagetarxv("${FindConfigurePackage_WORKING_DIRECTORY}/${DOWNLOAD_FILENAME}"
                                  ${FindConfigurePackage_WORKING_DIRECTORY})

        if(EXISTS ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
          set(FindConfigurePackage_UNPACK_SOURCE YES)
        endif()
      endif()

      # zip package
      if(NOT FindConfigurePackage_UNPACK_SOURCE AND FindConfigurePackage_ZIP_URL)
        get_filename_component(DOWNLOAD_FILENAME "${FindConfigurePackage_ZIP_URL}" NAME)
        if(NOT FindConfigurePackage_SRC_DIRECTORY_NAME)
          string(REGEX REPLACE "\\.zip$" "" FindConfigurePackage_SRC_DIRECTORY_NAME "${DOWNLOAD_FILENAME}")
        endif()
        set(FindConfigurePackage_DOWNLOAD_SOURCE_DIR
            "${FindConfigurePackage_WORKING_DIRECTORY}/${FindConfigurePackage_SRC_DIRECTORY_NAME}")
        findconfigurepackageremoveemptydir(${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})

        if(NOT EXISTS "${FindConfigurePackage_WORKING_DIRECTORY}/${DOWNLOAD_FILENAME}")
          message(STATUS "start to download ${DOWNLOAD_FILENAME} from ${FindConfigurePackage_ZIP_URL}")
          findconfigurepackagedownloadfile("${FindConfigurePackage_ZIP_URL}"
                                           "${FindConfigurePackage_WORKING_DIRECTORY}/${DOWNLOAD_FILENAME}")
        endif()

        if(NOT EXISTS ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
          findconfigurepackageunzip("${FindConfigurePackage_WORKING_DIRECTORY}/${DOWNLOAD_FILENAME}"
                                    ${FindConfigurePackage_WORKING_DIRECTORY})
        endif()

        if(EXISTS ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
          set(FindConfigurePackage_UNPACK_SOURCE YES)
        endif()
      endif()

      # git package
      if(NOT FindConfigurePackage_UNPACK_SOURCE AND FindConfigurePackage_GIT_URL)
        get_filename_component(DOWNLOAD_FILENAME "${FindConfigurePackage_GIT_URL}" NAME)
        if(NOT FindConfigurePackage_SRC_DIRECTORY_NAME)
          get_filename_component(FindConfigurePackage_SRC_DIRECTORY_FULL_NAME "${DOWNLOAD_FILENAME}" NAME)
          string(REGEX REPLACE "\\.git$" "" FindConfigurePackage_SRC_DIRECTORY_NAME
                               "${FindConfigurePackage_SRC_DIRECTORY_FULL_NAME}")
        endif()
        set(FindConfigurePackage_DOWNLOAD_SOURCE_DIR
            "${FindConfigurePackage_WORKING_DIRECTORY}/${FindConfigurePackage_SRC_DIRECTORY_NAME}")
        if(NOT FindConfigurePackage_GIT_FETCH_DEPTH)
          set(FindConfigurePackage_GIT_FETCH_DEPTH ${FindConfigurePackageGitFetchDepth})
        endif()
        set(FindConfigurePackage_GIT_CLONE_ARGS
            URL "${FindConfigurePackage_GIT_URL}" REPO_DIRECTORY "${FindConfigurePackage_DOWNLOAD_SOURCE_DIR}" DEPTH
            ${FindConfigurePackage_GIT_FETCH_DEPTH})
        if(FindConfigurePackage_GIT_BRANCH)
          list(APPEND FindConfigurePackage_GIT_CLONE_ARGS BRANCH "${FindConfigurePackage_GIT_BRANCH}")
        elseif(FindConfigurePackage_GIT_COMMIT)
          list(APPEND FindConfigurePackage_GIT_CLONE_ARGS COMMIT "${FindConfigurePackage_GIT_FETCH_DEPTH}")
        endif()
        if(FindConfigurePackage_GIT_ENABLE_SUBMODULE)
          list(APPEND FindConfigurePackage_GIT_CLONE_ARGS ENABLE_SUBMODULE)
        endif()
        if(FindConfigurePackage_GIT_SUBMODULE_RECURSIVE)
          list(APPEND FindConfigurePackage_GIT_CLONE_ARGS SUBMODULE_RECURSIVE)
        endif()
        if(FindConfigurePackage_GIT_SUBMODULE_PATHS)
          list(APPEND FindConfigurePackage_GIT_CLONE_ARGS SUBMODULE_PATH "${FindConfigurePackage_GIT_SUBMODULE_PATHS}")
        endif()
        if(FindConfigurePackage_GIT_RESET_SUBMODULE_URLS)
          list(APPEND FindConfigurePackage_GIT_CLONE_ARGS RESET_SUBMODULE_URLS
               "${FindConfigurePackage_GIT_RESET_SUBMODULE_URLS}")
        endif()
        if(FindConfigurePackage_GIT_PATCH_FILES)
          list(APPEND FindConfigurePackage_GIT_CLONE_ARGS PATCH_FILES "${FindConfigurePackage_GIT_PATCH_FILES}")
        endif()

        project_git_clone_repository(${FindConfigurePackage_GIT_CLONE_ARGS})
        unset(FindConfigurePackage_GIT_CLONE_ARGS)

        if(EXISTS ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
          set(FindConfigurePackage_UNPACK_SOURCE YES)
        endif()
      endif()

      # svn package
      if(NOT FindConfigurePackage_UNPACK_SOURCE AND FindConfigurePackage_SVN_URL)
        get_filename_component(DOWNLOAD_FILENAME "${FindConfigurePackage_SVN_URL}" NAME)
        if(NOT FindConfigurePackage_SRC_DIRECTORY_NAME)
          get_filename_component(FindConfigurePackage_SRC_DIRECTORY_NAME "${DOWNLOAD_FILENAME}" NAME)
        endif()
        set(FindConfigurePackage_DOWNLOAD_SOURCE_DIR
            "${FindConfigurePackage_WORKING_DIRECTORY}/${FindConfigurePackage_SRC_DIRECTORY_NAME}")
        findconfigurepackageremoveemptydir(${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})

        if(NOT EXISTS ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
          find_package(Subversion)
          if(SUBVERSION_FOUND)
            execute_process(
              COMMAND ${Subversion_SVN_EXECUTABLE} co "${FindConfigurePackage_SVN_URL}"
                      "${FindConfigurePackage_SRC_DIRECTORY_NAME}"
              WORKING_DIRECTORY "${FindConfigurePackage_WORKING_DIRECTORY}"
                                ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
          else()
            message(STATUS "svn not found, skip ${FindConfigurePackage_SVN_URL}")
          endif()
        endif()

        if(EXISTS ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
          set(FindConfigurePackage_UNPACK_SOURCE YES)
        endif()
      endif()

      if(NOT FindConfigurePackage_UNPACK_SOURCE)
        message(FATAL_ERROR "Can not download source for ${FindConfigurePackage_PACKAGE}")
      endif()

      # init build dir
      if(NOT FindConfigurePackage_BUILD_DIRECTORY)
        set(FindConfigurePackage_BUILD_DIRECTORY ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
      endif()
      if(NOT EXISTS ${FindConfigurePackage_BUILD_DIRECTORY})
        file(MAKE_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY})
      endif()

      # prebuild commands
      if(FindConfigurePackage_PREBUILD_COMMAND)
        execute_process(
          COMMAND ${FindConfigurePackage_PREBUILD_COMMAND}
          WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      endif()

      # build using configure and make
      if(FindConfigurePackage_BUILD_WITH_CONFIGURE)
        if(FindConfigurePackage_PROJECT_DIRECTORY)
          file(RELATIVE_PATH CONFIGURE_EXEC_FILE ${FindConfigurePackage_BUILD_DIRECTORY}
               "${FindConfigurePackage_PROJECT_DIRECTORY}/configure")
          set(FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN
              "${FindConfigurePackage_PROJECT_DIRECTORY}/load-envs-run.sh")
          project_build_tools_generate_load_env_bash("${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}")
          if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_VISIBILITY_HIDDEN)
            if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang|Clang|GNU")
              file(APPEND "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}"
                   "export CFLAGS=\"\$CFLAGS -fvisibility=hidden\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}")
            endif()
          endif()
          file(APPEND "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}" "\"$@\"")
          if(FindConfigurePackage_AUTOGEN_CONFIGURE)
            execute_process(
              COMMAND "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}"
                      ${FindConfigurePackage_AUTOGEN_CONFIGURE}
              WORKING_DIRECTORY "${FindConfigurePackage_PROJECT_DIRECTORY}"
                                ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
          endif()
        else()
          file(RELATIVE_PATH CONFIGURE_EXEC_FILE ${FindConfigurePackage_BUILD_DIRECTORY}
               "${FindConfigurePackage_WORKING_DIRECTORY}/${FindConfigurePackage_SRC_DIRECTORY_NAME}/configure")
          set(FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN
              "${FindConfigurePackage_WORKING_DIRECTORY}/${FindConfigurePackage_SRC_DIRECTORY_NAME}/load-envs-run.sh")
          project_build_tools_generate_load_env_bash("${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}")
          if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_VISIBILITY_HIDDEN)
            if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang|Clang|GNU")
              file(APPEND "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}"
                   "export CFLAGS=\"\$CFLAGS -fvisibility=hidden\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}")
            endif()
          endif()
          file(APPEND "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}" "\"$@\"")
          if(FindConfigurePackage_AUTOGEN_CONFIGURE)
            execute_process(
              COMMAND "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}"
                      ${FindConfigurePackage_AUTOGEN_CONFIGURE}
              WORKING_DIRECTORY "${FindConfigurePackage_WORKING_DIRECTORY}/${FindConfigurePackage_SRC_DIRECTORY_NAME}"
                                ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
          endif()
        endif()
        if(${CONFIGURE_EXEC_FILE} STREQUAL "configure")
          set(CONFIGURE_EXEC_FILE "./configure")
        endif()
        execute_process(
          COMMAND "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}" ${CONFIGURE_EXEC_FILE}
                  "--prefix=${FindConfigurePackage_PREFIX_DIRECTORY}" ${FindConfigurePackage_CONFIGURE_FLAGS}
          WORKING_DIRECTORY "${FindConfigurePackage_BUILD_DIRECTORY}"
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})

        if(FindConfigurePackage_DISABLE_PARALLEL_BUILD)
          unset(FindConfigurePackageCMakeBuildParallelFlags)
        elseif(PROJECT_FIND_CONFIGURE_PACKAGE_PARALLEL_BUILD)
          set(FindConfigurePackageCMakeBuildParallelFlags "-j${PROJECT_FIND_CONFIGURE_PACKAGE_PARALLEL_BUILD}")
        else()
          set(FindConfigurePackageCMakeBuildParallelFlags "-j")
        endif()
        project_build_tools_find_make_program(FindConfigurePackage_BUILD_WITH_CONFIGURE_MAKE)
        execute_process(
          COMMAND
            "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}"
            "${FindConfigurePackage_BUILD_WITH_CONFIGURE_MAKE}" ${FindConfigurePackage_MAKE_FLAGS}
            ${FindConfigurePackage_INSTALL_TARGET} ${FindConfigurePackageCMakeBuildParallelFlags}
          WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
          RESULT_VARIABLE RUN_MAKE_RESULT)
        if(NOT RUN_MAKE_RESULT EQUAL 0 AND FindConfigurePackageCMakeBuildParallelFlags)
          execute_process(
            COMMAND
              "${FindConfigurePackage_BUILD_WITH_CONFIGURE_LOAD_ENVS_RUN}"
              "${FindConfigurePackage_BUILD_WITH_CONFIGURE_MAKE}" ${FindConfigurePackage_MAKE_FLAGS}
              ${FindConfigurePackage_INSTALL_TARGET}
            WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                              ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
            RESULT_VARIABLE RUN_MAKE_RESULT)
        endif()
        unset(FindConfigurePackage_BUILD_WITH_CONFIGURE_MAKE)
        unset(FindConfigurePackageCMakeBuildParallelFlags)
        unset(RUN_MAKE_RESULT)

        # build using cmake and make
      elseif(FindConfigurePackage_BUILD_WITH_CMAKE)
        if(FindConfigurePackage_PROJECT_DIRECTORY)
          file(RELATIVE_PATH BUILD_WITH_CMAKE_PROJECT_DIR ${FindConfigurePackage_BUILD_DIRECTORY}
               ${FindConfigurePackage_PROJECT_DIRECTORY})
        else()
          file(RELATIVE_PATH BUILD_WITH_CMAKE_PROJECT_DIR ${FindConfigurePackage_BUILD_DIRECTORY}
               ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
        endif()
        if(NOT BUILD_WITH_CMAKE_PROJECT_DIR)
          set(BUILD_WITH_CMAKE_PROJECT_DIR ".")
        endif()

        set(FindConfigurePackage_BUILD_WITH_CMAKE_GENERATOR
            -Wno-dev "-DCMAKE_INSTALL_PREFIX=${FindConfigurePackage_PREFIX_DIRECTORY}")

        if(FindConfigurePackage_CMAKE_INHERIT_BUILD_ENV)
          set(FindConfigurePackage_CMAKE_INHERIT_BUILD_ENV OFF)
          set(project_build_tools_append_cmake_inherit_options_CALL_VARS
              FindConfigurePackage_BUILD_WITH_CMAKE_GENERATOR)
          if(FindConfigurePackage_CMAKE_INHERIT_BUILD_ENV_DISABLE_C_FLAGS)
            list(APPEND project_build_tools_append_cmake_inherit_options_CALL_VARS DISABLE_C_FLAGS)
          endif()
          if(FindConfigurePackage_CMAKE_INHERIT_BUILD_ENV_DISABLE_CXX_FLAGS)
            list(APPEND project_build_tools_append_cmake_inherit_options_CALL_VARS DISABLE_CXX_FLAGS)
          endif()
          if(FindConfigurePackage_CMAKE_INHERIT_BUILD_ENV_DISABLE_ASM_FLAGS)
            list(APPEND project_build_tools_append_cmake_inherit_options_CALL_VARS DISABLE_ASM_FLAGS)
          endif()
          if(FindConfigurePackage_CMAKE_INHERIT_SYSTEM_LINKS)
            list(APPEND project_build_tools_append_cmake_inherit_options_CALL_VARS APPEND_SYSTEM_LINKS)
          endif()

          # project_build_tools_append_cmake_inherit_options(
          # ${project_build_tools_append_cmake_inherit_options_CALL_VARS})
          # project_build_tools_append_cmake_cxx_standard_options(
          # ${project_build_tools_append_cmake_inherit_options_CALL_VARS}) Special patchs
          if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_VISIBILITY_HIDDEN)
            if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang|Clang|GNU")
              set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_C_FLAGS
                  "${PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_C_FLAGS}")
              set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_CXX_FLAGS
                  "${PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_CXX_FLAGS}")
              set(PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_C_FLAGS
                  "${PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_C_FLAGS} -fvisibility=hidden")
              set(PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_CXX_FLAGS
                  "${PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_CXX_FLAGS} -fvisibility=hidden")
            endif()
          endif()
          project_build_tools_append_cmake_options_for_lib(
            ${project_build_tools_append_cmake_inherit_options_CALL_VARS})
          unset(project_build_tools_append_cmake_inherit_options_CALL_VARS)
          if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_VISIBILITY_HIDDEN)
            if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang|Clang|GNU")
              if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_C_FLAGS)
                set(PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_C_FLAGS
                    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_C_FLAGS}"
                )
              else()
                unset(PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_C_FLAGS)
              endif()
              if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_CXX_FLAGS)
                set(PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_CXX_FLAGS
                    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_CXX_FLAGS}"
                )
              else()
                unset(PROJECT_BUILD_TOOLS_CMAKE_PATCH_INHERIT_CMAKE_CXX_FLAGS)
              endif()
              unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_C_FLAGS)
              unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_${FindConfigurePackage_FULL_PORT_NAME}_BACKUP_CMAKE_CXX_FLAGS)
            endif()
          endif()

        endif()
        if(FindConfigurePackage_CMAKE_INHERIT_FIND_ROOT_PATH)
          list_append_unescape(FindConfigurePackage_BUILD_WITH_CMAKE_GENERATOR
                               "-DCMAKE_FIND_ROOT_PATH=${CMAKE_FIND_ROOT_PATH}")
          list_append_unescape(FindConfigurePackage_BUILD_WITH_CMAKE_GENERATOR
                               "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")
        endif()

        if(EXISTS "${FindConfigurePackage_BUILD_DIRECTORY}/CMakeCache.txt")
          file(REMOVE "${FindConfigurePackage_BUILD_DIRECTORY}/CMakeCache.txt")
        endif()
        execute_process(
          COMMAND "${CMAKE_COMMAND}" "${BUILD_WITH_CMAKE_PROJECT_DIR}"
                  ${FindConfigurePackage_BUILD_WITH_CMAKE_GENERATOR} ${FindConfigurePackage_CMAKE_FLAGS}
          WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})

        # cmake --build and install
        if(FindConfigurePackage_DISABLE_PARALLEL_BUILD)
          unset(FindConfigurePackageCMakeBuildParallelFlags)
        elseif(PROJECT_FIND_CONFIGURE_PACKAGE_PARALLEL_BUILD)
          set(FindConfigurePackageCMakeBuildParallelFlags "-j${PROJECT_FIND_CONFIGURE_PACKAGE_PARALLEL_BUILD}")
        else()
          set(FindConfigurePackageCMakeBuildParallelFlags "-j")
        endif()
        if(MSVC)
          if(FindConfigurePackage_MSVC_CONFIGURE)
            execute_process(
              COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config
                      ${FindConfigurePackage_MSVC_CONFIGURE} ${FindConfigurePackageCMakeBuildParallelFlags}
              WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
              RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
            if(NOT RUN_CMAKE_BUILD_RESULT EQUAL 0)
              execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config
                        ${FindConfigurePackage_MSVC_CONFIGURE}
                WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                  ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
                RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
            endif()
          else()
            execute_process(
              COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config Debug
                      ${FindConfigurePackageCMakeBuildParallelFlags}
              WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
              RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
            if(NOT RUN_CMAKE_BUILD_RESULT EQUAL 0)
              execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config Debug
                WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                  ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
                RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
            endif()
            execute_process(
              COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config Release
                      ${FindConfigurePackageCMakeBuildParallelFlags}
              WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
              RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
            if(NOT RUN_CMAKE_BUILD_RESULT EQUAL 0)
              execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config Release
                WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                  ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
                RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
            endif()
            if(CMAKE_BUILD_TYPE AND NOT CMAKE_BUILD_TYPE STREQUAL "Release")
              execute_process(
                COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config
                        ${CMAKE_BUILD_TYPE} ${FindConfigurePackageCMakeBuildParallelFlags}
                WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                  ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
                RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
              if(NOT RUN_CMAKE_BUILD_RESULT EQUAL 0)
                execute_process(
                  COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET} --config
                          ${CMAKE_BUILD_TYPE}
                  WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                    ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
                  RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
              endif()
            endif()
          endif()

        else()
          execute_process(
            COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET}
                    ${FindConfigurePackageCMakeBuildParallelFlags}
            WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                              ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
            RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
          if(NOT RUN_CMAKE_BUILD_RESULT EQUAL 0)
            execute_process(
              COMMAND ${CMAKE_COMMAND} --build . --target ${FindConfigurePackage_INSTALL_TARGET}
              WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS}
              RESULT_VARIABLE RUN_CMAKE_BUILD_RESULT)
          endif()
        endif()
        unset(FindConfigurePackageCMakeBuildParallelFlags)
        unset(RUN_CMAKE_BUILD_RESULT)

        # adaptor for new cmake module
        set("${FindConfigurePackage_PACKAGE}_ROOT" ${FindConfigurePackage_PREFIX_DIRECTORY})

        # build using scons
      elseif(FindConfigurePackage_BUILD_WITH_SCONS)
        if(FindConfigurePackage_PROJECT_DIRECTORY)
          file(RELATIVE_PATH BUILD_WITH_SCONS_PROJECT_DIR ${FindConfigurePackage_BUILD_DIRECTORY}
               ${FindConfigurePackage_PROJECT_DIRECTORY})
        else()
          file(RELATIVE_PATH BUILD_WITH_SCONS_PROJECT_DIR ${FindConfigurePackage_BUILD_DIRECTORY}
               ${FindConfigurePackage_DOWNLOAD_SOURCE_DIR})
        endif()
        if(NOT BUILD_WITH_SCONS_PROJECT_DIR)
          set(BUILD_WITH_SCONS_PROJECT_DIR ".")
        endif()

        set(OLD_ENV_PREFIX $ENV{prefix})
        set(ENV{prefix} ${FindConfigurePackage_PREFIX_DIRECTORY})
        execute_process(
          COMMAND "scons" ${FindConfigurePackage_SCONS_FLAGS} ${BUILD_WITH_SCONS_PROJECT_DIR}
          WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
        set(ENV{prefix} ${OLD_ENV_PREFIX})

        # build using custom commands(such as gyp)
      elseif(FindConfigurePackage_BUILD_WITH_CUSTOM_COMMAND)
        foreach(cmd ${FindConfigurePackage_CUSTOM_BUILD_COMMAND})
          execute_process(COMMAND ${cmd} WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                                                           ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
        endforeach()

      else()
        message(FATAL_ERROR "build type is required")
      endif()

      # afterbuild commands
      if(FindConfigurePackage_AFTERBUILD_COMMAND)
        execute_process(
          COMMAND ${FindConfigurePackage_AFTERBUILD_COMMAND}
          WORKING_DIRECTORY ${FindConfigurePackage_BUILD_DIRECTORY}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      endif()

      # reset vars before retry to find package
      foreach(RESET_VAR ${FindConfigurePackage_RESET_FIND_VARS})
        unset(${RESET_VAR} CACHE)
        unset(${RESET_VAR})
      endforeach()
      unset(${FindConfigurePackage_PACKAGE}_FOUND CACHE)
      unset(${FindConfigurePackage_PACKAGE}_FOUND)
      find_package(${FindConfigurePackage_PACKAGE} ${FindConfigurePackage_FIND_PACKAGE_FLAGS})
    endif()
  endif()

  # Cleanup vars
  unset(FindConfigurePackage_INSTALL_TARGET)
  if(DEFINED FindConfigurePackage_BACKUP_CMAKE_FIND_ROOT_PATH)
    set(CMAKE_FIND_ROOT_PATH ${FindConfigurePackage_BACKUP_CMAKE_FIND_ROOT_PATH})
    unset(FindConfigurePackage_BACKUP_CMAKE_FIND_ROOT_PATH)
  endif()
  if(DEFINED FindConfigurePackage_BACKUP_CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH ${FindConfigurePackage_BACKUP_CMAKE_PREFIX_PATH})
    unset(FindConfigurePackage_BACKUP_CMAKE_PREFIX_PATH)
  endif()
endmacro(FindConfigurePackage)

macro(FIND_CONFIGURE_PACKAGE)
  findconfigurepackage(${ARGN})
endmacro(FIND_CONFIGURE_PACKAGE)
