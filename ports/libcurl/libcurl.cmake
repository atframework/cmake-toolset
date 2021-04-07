if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.10")
  include_guard(GLOBAL)
endif()
# =========== third party libcurl ==================
macro(PROJECT_THIRD_PARTY_LIBCURL_IMPORT)
  if(CURL_FOUND)
    if(TARGET CURL::libcurl)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES CURL::libcurl)
      if(LIBRESSL_FOUND
         AND TARGET LibreSSL::Crypto
         AND TARGET LibreSSL::SSL)
        project_build_tools_patch_imported_link_interface_libraries(
          CURL::libcurl REMOVE_LIBRARIES "OpenSSL::SSL;OpenSSL::Crypto" ADD_LIBRARIES
          "LibreSSL::SSL;LibreSSL::Crypto")
      endif()
    else()
      if(CURL_INCLUDE_DIRS)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_INCLUDE_DIRS ${CURL_INCLUDE_DIRS})
      endif()

      if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES
             ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES})
      endif()
    endif()

    if(TARGET CURL::curl)
      get_target_property(CURL_EXECUTABLE CURL::curl IMPORTED_LOCATION)
      if(CURL_EXECUTABLE AND EXISTS ${CURL_EXECUTABLE})
        file(
          COPY ${CURL_EXECUTABLE}
          DESTINATION "${PROJECT_INSTALL_TOOLS_DIR}/bin"
          USE_SOURCE_PERMISSIONS)
      else()
        get_target_property(CURL_EXECUTABLE CURL::curl IMPORTED_LOCATION_NOCONFIG)
        if(CURL_EXECUTABLE AND EXISTS ${CURL_EXECUTABLE})
          file(
            COPY ${CURL_EXECUTABLE}
            DESTINATION "${PROJECT_INSTALL_TOOLS_DIR}/bin"
            USE_SOURCE_PERMISSIONS)
        endif()
      endif()
    else()
      find_program(
        CURL_EXECUTABLE
        NAMES curl curl.exe
        PATHS "${CURL_INCLUDE_DIRS}/../bin" "${CURL_INCLUDE_DIRS}/../" ${CURL_INCLUDE_DIRS}
        NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
      if(CURL_EXECUTABLE AND EXISTS ${CURL_EXECUTABLE})
        file(
          COPY ${CURL_EXECUTABLE}
          DESTINATION "${PROJECT_INSTALL_TOOLS_DIR}/bin"
          USE_SOURCE_PERMISSIONS)
      endif()
    endif()

    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_COPY_EXECUTABLE_PATTERN
         "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR}/bin/curl*")
  endif()
endmacro()

if(NOT CURL_EXECUTABLE)
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION "curl-7_76_0")
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_REPO_URL "https://github.com/curl/curl.git")

  if(VCPKG_TOOLCHAIN)
    find_package(CURL QUIET)
    project_third_party_libcurl_import()
  endif()

  if(NOT CURL_FOUND)
    set(Libcurl_ROOT ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR})
    set(LIBCURL_ROOT ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR})

    set(CURL_ROOT ${LIBCURL_ROOT})

    unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_SSL_BACKEND)
    if(OPENSSL_FOUND)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_SSL_BACKEND "-DCMAKE_USE_OPENSSL=YES")
      if(OPENSSL_ROOT_DIR)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_SSL_BACKEND
             "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}")
      endif()
      if(OPENSSL_USE_STATIC_LIBS)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_SSL_BACKEND
             "-DOPENSSL_USE_STATIC_LIBS=${OPENSSL_USE_STATIC_LIBS}")
      endif()
    elseif(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_SSL_BACKEND "-DCMAKE_USE_MBEDTLS=YES")
      if(MbedTLS_ROOT)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_SSL_BACKEND
             "-DMbedTLS_ROOT=${MbedTLS_ROOT}")
      endif()
    endif()

    findconfigurepackage(
      PACKAGE
      CURL
      FIND_PACKAGE_FLAGS
      CONFIG
      BUILD_WITH_CMAKE
      CMAKE_FLAGS
      "-DBUILD_SHARED_LIBS=NO"
      "-DCMAKE_POSITION_INDEPENDENT_CODE=YES"
      "-DBUILD_TESTING=OFF"
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_SSL_BACKEND}
      WORKING_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${CMAKE_CURRENT_BINARY_DIR}/deps/libcurl-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION}/build_jobs_${PROJECT_PREBUILT_PLATFORM_NAME}"
      PREFIX_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_REPO_URL}")

    if(CURL_FOUND)
      echowithcolor(COLOR GREEN
                    "-- Dependency: libcurl found.(${CURL_INCLUDE_DIRS}|${CURL_LIBRARIES})")
    else()
      echowithcolor(COLOR RED "-- Dependency: libcurl is required")
      message(FATAL_ERROR "libcurl not found")
    endif()

    unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES)
    if(TARGET CURL::libcurl)
      echowithcolor(COLOR GREEN "-- Libcurl: use target CURL::libcurl")
    else()
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TEST_SRC
          "#include <curl/curl.h>
            #include <stdio.h>

            int main () {
                curl_global_init(CURL_GLOBAL_ALL)\;
                printf(\"libcurl version: %s\", LIBCURL_VERSION)\;
                return 0\;
            }")

      file(WRITE "${CMAKE_BINARY_DIR}/try_run_libcurl_test.c"
           ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TEST_SRC})

      if(MSVC)
        try_compile(
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_BINARY_DIR}
          "${CMAKE_BINARY_DIR}/try_run_libcurl_test.c"
          CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${CURL_INCLUDE_DIRS}
          LINK_LIBRARIES ${CURL_LIBRARIES}
          OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_DYN_MSG)
      else()
        try_run(
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_RESULT
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_BINARY_DIR}
          "${CMAKE_BINARY_DIR}/try_run_libcurl_test.c"
          CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${CURL_INCLUDE_DIRS} LINK_LIBRARIES ${CURL_LIBRARIES}
          COMPILE_OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_DYN_MSG
          RUN_OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
      endif()

      if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT)
        echowithcolor(
          COLOR YELLOW
          "-- Libcurl: Dynamic symbol test in ${CURL_LIBRARIES} failed, try static symbols")
        if(MSVC)
          if(ZLIB_FOUND)
            list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES
                 ${ZLIB_LIBRARIES})
          endif()

          try_compile(
            ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_BINARY_DIR}
            "${CMAKE_BINARY_DIR}/try_run_libcurl_test.c"
            CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${CURL_INCLUDE_DIRS}
            COMPILE_DEFINITIONS /D CURL_STATICLIB
            LINK_LIBRARIES ${CURL_LIBRARIES}
                           ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES}
            OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_STA_MSG)
        else()
          get_filename_component(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR
                                 ${CURL_LIBRARIES} DIRECTORY)
          find_package(PkgConfig)
          if(PKG_CONFIG_FOUND
             AND EXISTS
                 "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR}/pkgconfig/libcurl.pc")
            pkg_check_modules(
              LIBCURL
              "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR}/pkgconfig/libcurl.pc")
            list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES
                 ${LIBCURL_STATIC_LIBRARIES})
            list(REMOVE_ITEM ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES curl)
            message(
              STATUS
                "Libcurl use static link with ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES} in ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR}"
            )
          else()
            if(OPENSSL_FOUND)
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES
                   ${OPENSSL_LIBRARIES})
            else()
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES ssl
                   crypto)
            endif()
            if(ZLIB_FOUND)
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES
                   ${ZLIB_LIBRARIES})
            else()
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES z)
            endif()
          endif()

          try_run(
            ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_RESULT
            ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_BINARY_DIR}
            "${CMAKE_BINARY_DIR}/try_run_libcurl_test.c"
            CMAKE_FLAGS -DCMAKE_INCLUDE_DIRECTORIES_BEFORE=${CURL_INCLUDE_DIRS}
            COMPILE_DEFINITIONS
              -DCURL_STATICLIB LINK_LIBRARIES ${CURL_LIBRARIES}
              ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES} -lpthread
            COMPILE_OUTPUT_VARIABLE
              ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_STA_MSG
            RUN_OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES pthread)
        endif()
        if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT)
          message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_DYN_MSG})
          message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_STA_MSG})
          message(FATAL_ERROR "Libcurl: try compile with ${CURL_LIBRARIES} failed")
        else()
          echowithcolor(COLOR GREEN "-- Libcurl: use static symbols")
          if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
            message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT})
          endif()

          add_library(CURL::libcurl UNKNOWN IMPORTED)
          set_target_properties(
            CURL::libcurl PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${CURL_INCLUDE_DIRS}
                                     INTERFACE_COMPILE_DEFINITIONS "CURL_STATICLIB=1")
          set_target_properties(
            CURL::libcurl
            PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C;CXX"
                       IMPORTED_LOCATION ${CURL_LIBRARIES}
                       INTERFACE_LINK_LIBRARIES
                       ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES})
        endif()
      else()
        echowithcolor(COLOR GREEN "-- Libcurl: use dynamic symbols")
        if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
          message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT})
        endif()

        add_library(CURL::libcurl UNKNOWN IMPORTED)
        set_target_properties(CURL::libcurl PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                                       ${CURL_INCLUDE_DIRS})
        set_target_properties(CURL::libcurl PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C;CXX"
                                                       IMPORTED_LOCATION ${CURL_LIBRARIES})
      endif()
    endif()
    unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)

    project_third_party_libcurl_import()
  endif()
else()
  project_third_party_libcurl_import()
endif()
