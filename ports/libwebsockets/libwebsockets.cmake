include_guard(GLOBAL)

# =========== third party libwebsockets ==================
function(PROJECT_THIRD_PARTY_LIBWEBSOCKETS_PATCH_IMPORTED_TARGET TARGET_NAME)
  unset(PATCH_REMOVE_RULES)
  unset(PATCH_ADD_TARGETS)
  if(TARGET OpenSSL::SSL
     OR TARGET OpenSSL::Crypto
     OR TARGET LibreSSL::TLS
     OR TARGET mbedtls_static
     OR TARGET mbedtls)
    list(APPEND PATCH_REMOVE_RULES "(lib)?crypto" "(lib)?ssl")
    list(APPEND PATCH_ADD_TARGETS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME})
  endif()

  if(TARGET uv_a
     OR TARGET uv
     OR TARGET libuv)
    list(APPEND PATCH_REMOVE_RULES "(lib)?uv(_a)?")
    list(APPEND PATCH_ADD_TARGETS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBUV_LINK_NAME})
  endif()
  if(PATCH_REMOVE_RULES OR PATCH_ADD_TARGETS)
    project_build_tools_patch_imported_link_interface_libraries(
      ${TARGET_NAME} REMOVE_LIBRARIES ${PATCH_REMOVE_RULES} ADD_LIBRARIES ${PATCH_ADD_TARGETS})
  endif()
endfunction()

macro(PROJECT_THIRD_PARTY_LIBWEBSOCKETS_IMPORT)
  if(TARGET websockets)
    echowithcolor(COLOR GREEN
                  "-- Dependency(${PROJECT_NAME}): libwebsockets found target websockets")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES websockets)
    project_third_party_libwebsockets_patch_imported_target(websockets)
  elseif(TARGET websockets_shared)
    echowithcolor(COLOR GREEN
                  "-- Dependency(${PROJECT_NAME}): libwebsockets found target  websockets_shared")
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES websockets_shared)
    project_third_party_libwebsockets_patch_imported_target(websockets_shared)
  endif()
endmacro()

if(NOT Libwebsockets_FOUND
   AND NOT TARGET websockets
   AND NOT TARGET websockets_shared)
  if(VCPKG_TOOLCHAIN)
    find_package(Libwebsockets QUIET CONFIG)
    project_third_party_libwebsockets_import()
  endif()

  if(NOT Libwebsockets_FOUND
     AND NOT TARGET websockets
     AND NOT TARGET websockets_shared)
    find_package(Libwebsockets QUIET CONFIG)
    project_third_party_libwebsockets_import()
    if(NOT Libwebsockets_FOUND)
      if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_VERSION)
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_VERSION "v4.2.0")
      endif()

      if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_GIT_URL)
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_GIT_URL
            "https://github.com/warmcat/libwebsockets.git")
      endif()

      if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR)
        project_third_party_get_build_dir(
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR "libwebsockets"
          ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_VERSION})
      endif()

      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_REPOSITORY_DIR
          "${PROJECT_THIRD_PARTY_PACKAGE_DIR}/libwebsockets-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_VERSION}"
      )

      project_git_clone_repository(
        URL "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_GIT_URL}" REPO_DIRECTORY
        "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_REPOSITORY_DIR}" TAG
        "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_VERSION}")

      if(NOT EXISTS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR})
        file(MAKE_DIRECTORY ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR})
      endif()

      if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS)
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
            ${CMAKE_COMMAND}
            "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_REPOSITORY_DIR}"
            "-Wno-dev"
            "-DCMAKE_INSTALL_PREFIX=${PROJECT_THIRD_PARTY_INSTALL_DIR}"
            "-DLWS_STATIC_PIC=ON"
            "-DLWS_LINK_TESTAPPS_DYNAMIC=OFF"
            "-DLWS_WITHOUT_CLIENT=ON"
            "-DLWS_WITHOUT_DAEMONIZE=ON"
            "-DLWS_WITHOUT_TESTAPPS=ON"
            "-DLWS_WITHOUT_TEST_CLIENT=ON"
            "-DLWS_WITHOUT_TEST_PING=ON"
            "-DLWS_WITHOUT_TEST_SERVER=ON"
            "-DLWS_WITHOUT_TEST_SERVER_EXTPOLL=ON"
            "-DLWS_WITH_PLUGINS=ON"
            "-DLWS_WITHOUT_EXTENSIONS=OFF")
      else()
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
            ${CMAKE_COMMAND}
            "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_REPOSITORY_DIR}"
            "-Wno-dev"
            "-DCMAKE_INSTALL_PREFIX=${PROJECT_THIRD_PARTY_INSTALL_DIR}"
            ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS})
      endif()

      project_build_tools_append_cmake_inherit_options(
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS DISABLE_ASM_FLAGS)

      project_third_party_append_build_shared_lib_var(
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS LWS_WITH_SHARED
        BUILD_SHARED_LIBS)

      project_third_party_append_find_root_args(
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS)

      if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBUV_LINK_NAME)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DLWS_WITH_LIBUV=ON")
        if(Libuv_INCLUDE_DIRS)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DLWS_LIBUV_INCLUDE_DIRS=${Libuv_INCLUDE_DIRS}")
        endif()
        if(Libuv_LIBRARIES)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DLWS_LIBUV_LIBRARIES=${Libuv_LIBRARIES}")
        endif()
      endif()

      if(NOT WIN32
         AND NOT CYGWIN
         AND NOT MINGW)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DLWS_UNIX_SOCK=ON")
      endif()

      if(ZLIB_INCLUDE_DIRS AND ZLIB_LIBRARIES)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DLWS_WITH_ZLIB=ON" "-DLWS_ZLIB_INCLUDE_DIRS=${ZLIB_INCLUDE_DIRS}")
        list_append_unescape(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
                             "-DLWS_ZLIB_LIBRARIES=${ZLIB_LIBRARIES}")
      endif()
      if(OPENSSL_FOUND AND NOT LIBRESSL_FOUND)
        if(OPENSSL_ROOT_DIR
           AND (TARGET OpenSSL::SSL
                OR TARGET OpenSSL::Crypto
                OR OPENSSL_LIBRARIES))
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}")
        endif()
        if(MSVC)
          # Some version of libwebsockets have compiling problems.
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DLWS_WITH_SSL=ON" "-DLWS_WITH_CLIENT=ON"
               "-DLWS_OPENSSL_INCLUDE_DIRS=${OPENSSL_INCLUDE_DIR}")
          list_append_unescape(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
                               "-DLWS_OPENSSL_LIBRARIES=${OPENSSL_SSL_LIBRARIES}")
        else()
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DOPENSSL_USE_STATIC_LIBS=${OPENSSL_USE_STATIC_LIBS}")
        endif()
      elseif(LIBRESSL_FOUND)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DLWS_WITH_SSL=OFF")
      endif()
      if(NOT MSVC)
        file(WRITE "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.sh"
             "#!/bin/bash${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}")
        file(WRITE
             "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.sh"
             "#!/bin/bash${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}")
        project_third_party_generate_load_env_bash(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-load-envs.sh")
        file(
          APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.sh"
          "export PATH=\"${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}:\$PATH\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
        )
        file(
          APPEND
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.sh"
          "source \"${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-load-envs.sh\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
        )
        file(
          APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.sh"
          "source \"${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-load-envs.sh\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
        )

        project_make_executable(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.sh")
        project_make_executable(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.sh")

        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
        if(CMAKE_AR)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DCMAKE_AR=${CMAKE_AR}")
        endif()

        find_package(Threads)
        if(CMAKE_DL_LIBS)
          if(CMAKE_USE_PTHREADS_INIT)
            file(
              APPEND
              "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-load-envs.sh"
              "export LDFLAGS=\"\$LDFLAGS -l${CMAKE_DL_LIBS} -pthread\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
            )
          else()
            file(
              APPEND
              "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-load-envs.sh"
              "export LDFLAGS=\"\$LDFLAGS -l${CMAKE_DL_LIBS}\"${PROJECT_THIRD_PARTY_BUILDTOOLS_BASH_EOL}"
            )
          endif()
        endif()

        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}")
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DCMAKE_C_FLAGS_RELWITHDEBINFO=${CMAKE_C_FLAGS_RELWITHDEBINFO}")
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
             "-DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}")

        if(CMAKE_EXE_LINKER_FLAGS)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DCMAKE_EXE_LINKER_FLAGS=${CMAKE_EXE_LINKER_FLAGS}")
        endif()

        if(CMAKE_RANLIB)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DCMAKE_RANLIB=${CMAKE_RANLIB}")
        endif()

        if(CMAKE_STATIC_LINKER_FLAGS)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS
               "-DCMAKE_STATIC_LINKER_FLAGS=${CMAKE_STATIC_LINKER_FLAGS}")
        endif()

        project_expand_list_for_command_line_to_file(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.sh"
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS}")
        project_expand_list_for_command_line_to_file(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.sh"
          "${CMAKE_COMMAND}" "--build" "." "-j")
        project_expand_list_for_command_line_to_file(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.sh"
          "${CMAKE_COMMAND}" "--build" "." "--" "install")

        # build & install
        execute_process(
          COMMAND "${ATFRAMEWORK_CMAKE_TOOLSET_BASH}"
                  "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.sh"
          WORKING_DIRECTORY ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_EXECUTE_PROCESS_OUTPUT_OPTIONS})

        execute_process(
          COMMAND
            "${ATFRAMEWORK_CMAKE_TOOLSET_BASH}"
            "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.sh"
          WORKING_DIRECTORY ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_EXECUTE_PROCESS_OUTPUT_OPTIONS})

      else()
        file(WRITE "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.bat"
             "@echo off${PROJECT_THIRD_PARTY_BUILDTOOLS_EOL}")
        file(
          WRITE
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.bat"
          "@echo off${PROJECT_THIRD_PARTY_BUILDTOOLS_EOL}")
        file(
          APPEND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.bat"
          "set PATH=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR};%PATH%${PROJECT_THIRD_PARTY_BUILDTOOLS_EOL}"
        )
        file(
          APPEND
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.bat"
          "set PATH=${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR};%PATH%${PROJECT_THIRD_PARTY_BUILDTOOLS_EOL}"
        )
        project_make_executable(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.bat")
        project_make_executable(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.bat")

        project_expand_list_for_command_line_to_file(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.bat"
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_OPTIONS}")
        project_expand_list_for_command_line_to_file(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.bat"
          "${CMAKE_COMMAND}" "--build" "." "-j")
        project_expand_list_for_command_line_to_file(
          "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.bat"
          "${CMAKE_COMMAND}" "--build" "." "--target" "INSTALL")

        # build & install
        execute_process(
          COMMAND "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-config.bat"
          WORKING_DIRECTORY ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_EXECUTE_PROCESS_OUTPUT_OPTIONS})

        execute_process(
          COMMAND
            "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}/run-build-release.bat"
          WORKING_DIRECTORY ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBWEBSOCKETS_BUILD_DIR}
                            ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_EXECUTE_PROCESS_OUTPUT_OPTIONS})
      endif()

      find_package(Libwebsockets CONFIG)
      project_third_party_libwebsockets_import()
    endif()
  endif()
else()
  project_third_party_libwebsockets_import()
endif()

if(NOT Libwebsockets_FOUND
   AND NOT TARGET websockets
   AND NOT TARGET websockets_shared)
  message(FATAL_ERROR "-- Dependency(${PROJECT_NAME}): libwebsockets not found")
endif()
