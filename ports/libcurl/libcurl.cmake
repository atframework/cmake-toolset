include_guard(GLOBAL)
# =========== third party libcurl ==================
macro(PROJECT_THIRD_PARTY_LIBCURL_IMPORT)
  if(CURL_FOUND)
    if(TARGET CURL::libcurl)
      if(LIBRESSL_FOUND
         AND TARGET LibreSSL::Crypto
         AND TARGET LibreSSL::SSL)
        project_build_tools_patch_imported_link_interface_libraries(
          CURL::libcurl REMOVE_LIBRARIES "OpenSSL::SSL;OpenSSL::Crypto" ADD_LIBRARIES "LibreSSL::SSL;LibreSSL::Crypto")
      endif()
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LINK_NAME CURL::libcurl)
      project_build_tools_patch_default_imported_config(CURL::libcurl)
    else()
      add_library(CURL::libcurl UNKNOWN IMPORTED)
      if(CURL_INCLUDE_DIRS)
        set_target_properties(CURL::libcurl PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${CURL_INCLUDE_DIRS})
      endif()

      if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES)
        set_target_properties(
          CURL::libcurl
          PROPERTIES IMPORTED_LOCATION ${CURL_LIBRARIES}
                     INTERFACE_LINK_LIBRARIES ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES})
      endif()
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LINK_NAME CURL::libcurl)
    endif()

    if(TARGET CURL::curl)
      get_target_property(CURL_EXECUTABLE CURL::curl IMPORTED_LOCATION)
      if(CURL_EXECUTABLE AND EXISTS ${CURL_EXECUTABLE})
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BIN_CURL "${CURL_EXECUTABLE}")
      else()
        get_target_property(CURL_EXECUTABLE CURL::curl IMPORTED_LOCATION_NOCONFIG)
        if(CURL_EXECUTABLE AND EXISTS ${CURL_EXECUTABLE})
          set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BIN_CURL "${CURL_EXECUTABLE}")
        endif()
      endif()
    else()
      find_program(
        CURL_EXECUTABLE
        NAMES curl curl.exe
        PATHS "${CURL_INCLUDE_DIRS}/../bin" "${CURL_INCLUDE_DIRS}/../" ${CURL_INCLUDE_DIRS}
        NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
      if(CURL_EXECUTABLE AND EXISTS ${CURL_EXECUTABLE})
        set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BIN_CURL "${CURL_EXECUTABLE}")
        add_executable(CURL::curl IMPORTED)
        set_target_properties(CURL::curl PROPERTIES IMPORTED_LOCATION_RELEASE "${CURL_EXECUTABLE}")
      endif()
    endif()
  endif()
endmacro()

if(NOT CURL_EXECUTABLE)
  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION "7.80.0")
  endif()

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_GIT_URL)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_GIT_URL "https://github.com/curl/curl.git")
  endif()
  string(REPLACE "." "_" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_GIT_TAG
                 "curl-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION}")

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_DIR)
    project_third_party_get_build_dir(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_DIR "libcurl"
                                      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION})
  endif()

  if(VCPKG_TOOLCHAIN)
    find_package(CURL QUIET)
    project_third_party_libcurl_import()
  endif()

  if(NOT CURL_FOUND)
    set(Libcurl_ROOT ${PROJECT_THIRD_PARTY_INSTALL_DIR})
    set(LIBCURL_ROOT ${PROJECT_THIRD_PARTY_INSTALL_DIR})

    set(CURL_ROOT ${LIBCURL_ROOT})

    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
                                                                    "-DBUILD_TESTING=OFF")
    endif()

    if(ANDROID)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DBUILD_SHARED_LIBS=OFF")
    else()
      project_third_party_append_build_shared_lib_var(
        "libcurl" "" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS BUILD_SHARED_LIBS)
    endif()

    if(CMAKE_CROSSCOMPILING)
      if(ANDROID
         OR APPLE
         OR IOS
         OR UNIX)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DHAVE_POLL_FINE_EXITCODE=0"
             "-DHAVE_POLL_FINE_EXITCODE__TRYRUN_OUTPUT=0")
      endif()
    endif()

    if(OPENSSL_FOUND)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DCMAKE_USE_OPENSSL=ON")
      if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_BORINGSSL OR OPENSSL_VERSION VERSION_GREATER_EQUAL "3.0.0")
        list(
          APPEND
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS
          "-DOPENSSL_ROOT_DIR=${PROJECT_THIRD_PARTY_INSTALL_DIR}"
          "-DOPENSSL_VERSION=${OPENSSL_VERSION}"
          "-DOPENSSL_INCLUDE_DIR=${OPENSSL_INCLUDE_DIR}"
          "-DOPENSSL_SSL_LIBRARY=${OPENSSL_SSL_LIBRARY}"
          "-DOPENSSL_CRYPTO_LIBRARY=${OPENSSL_CRYPTO_LIBRARY}"
          "-DOPENSSL_LIBRARIES=${OPENSSL_SSL_LIBRARY}\\\;${OPENSSL_CRYPTO_LIBRARY}")
      elseif(
        OPENSSL_ROOT_DIR
        AND (TARGET OpenSSL::SSL
             OR TARGET OpenSSL::Crypto
             OR OPENSSL_LIBRARIES))
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR}")
      endif()
      if(DEFINED OPENSSL_USE_STATIC_LIBS)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS
             "-DOPENSSL_USE_STATIC_LIBS=${OPENSSL_USE_STATIC_LIBS}")
      endif()
    elseif(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DCMAKE_USE_MBEDTLS=ON")
      if(MbedTLS_ROOT)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DMbedTLS_ROOT=${MbedTLS_ROOT}")
      endif()
    endif()

    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_DISABLE_ARES)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DENABLE_THREADED_RESOLVER=ON")
    else()
      if(TARGET c-ares::cares
         OR TARGET c-ares::cares_static
         OR TARGET c-ares::cares_shared
         OR CARES_FOUND)
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS "-DENABLE_ARES=ON")
      endif()
    endif()

    find_configure_package(
      PACKAGE
      CURL
      FIND_PACKAGE_FLAGS
      CONFIG
      BUILD_WITH_CMAKE
      CMAKE_INHERIT_BUILD_ENV
      CMAKE_INHERIT_BUILD_ENV_DISABLE_CXX_FLAGS
      CMAKE_INHERIT_FIND_ROOT_PATH
      CMAKE_INHERIT_SYSTEM_LINKS
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_FLAGS}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      SRC_DIRECTORY_NAME
      "libcurl-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_GIT_TAG}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_GIT_URL}")

    if(NOT CURL_FOUND)
      echowithcolor(COLOR RED "-- Dependency(${PROJECT_NAME}): libcurl is required")
      message(FATAL_ERROR "libcurl not found")
    endif()

    unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES)
    if(TARGET CURL::libcurl)
      message(STATUS "Dependency(${PROJECT_NAME}): libcurl found target: CURL::libcurl")
    else()
      message(STATUS "Dependency(${PROJECT_NAME}): libcurl found.(${CURL_INCLUDE_DIRS}|${CURL_LIBRARIES})")
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TEST_SRC
          "#include <curl/curl.h>
            #include <stdio.h>

            int main () {
                curl_global_init(CURL_GLOBAL_ALL)\;
                printf(\"libcurl version: %s\", LIBCURL_VERSION)\;
                return 0\;
            }")

      file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/try_run_libcurl_test.c"
           ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TEST_SRC})

      if(MSVC)
        try_compile(
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_CURRENT_BINARY_DIR}
          "${CMAKE_CURRENT_BINARY_DIR}/try_run_libcurl_test.c"
          CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${CURL_INCLUDE_DIRS}
          LINK_LIBRARIES ${CURL_LIBRARIES}
          OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_DYN_MSG)
      else()
        try_run(
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_RESULT
          ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_CURRENT_BINARY_DIR}
          "${CMAKE_CURRENT_BINARY_DIR}/try_run_libcurl_test.c"
          CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${CURL_INCLUDE_DIRS} LINK_LIBRARIES ${CURL_LIBRARIES}
          COMPILE_OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_DYN_MSG
          RUN_OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
      endif()

      if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT)
        echowithcolor(COLOR YELLOW "-- Libcurl: Dynamic symbol test in ${CURL_LIBRARIES} failed, try static symbols")
        if(MSVC)
          if(ZLIB_FOUND)
            list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES ${ZLIB_LIBRARIES})
          endif()

          try_compile(
            ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_CURRENT_BINARY_DIR}
            "${CMAKE_CURRENT_BINARY_DIR}/try_run_libcurl_test.c"
            CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${CURL_INCLUDE_DIRS}
            COMPILE_DEFINITIONS /D CURL_STATICLIB
            LINK_LIBRARIES ${CURL_LIBRARIES} ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES}
            OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_STA_MSG)
        else()
          get_filename_component(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR ${CURL_LIBRARIES} DIRECTORY)
          find_package(PkgConfig)
          if(PKG_CONFIG_FOUND AND EXISTS "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR}/pkgconfig/libcurl.pc")
            pkg_check_modules(LIBCURL "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR}/pkgconfig/libcurl.pc")
            list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES ${LIBCURL_STATIC_LIBRARIES})
            list(REMOVE_ITEM ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES curl)
            message(
              STATUS
                "Libcurl use static link with ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES} in ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_LIBDIR}"
            )
          else()
            if(OPENSSL_FOUND)
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES ${OPENSSL_LIBRARIES})
            else()
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES ssl crypto)
            endif()
            if(ZLIB_FOUND)
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES ${ZLIB_LIBRARIES})
            else()
              list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES z)
            endif()
          endif()

          try_run(
            ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_RESULT
            ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT ${CMAKE_CURRENT_BINARY_DIR}
            "${CMAKE_CURRENT_BINARY_DIR}/try_run_libcurl_test.c"
            CMAKE_FLAGS -DCMAKE_INCLUDE_DIRECTORIES_BEFORE=${CURL_INCLUDE_DIRS}
            COMPILE_DEFINITIONS -DCURL_STATICLIB LINK_LIBRARIES ${CURL_LIBRARIES}
                                ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES} -lpthread
            COMPILE_OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_STA_MSG
            RUN_OUTPUT_VARIABLE ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
          list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES pthread)
        endif()
        if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_RESULT)
          message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_DYN_MSG})
          message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_COMPILE_STA_MSG})
          message(FATAL_ERROR "Libcurl: try compile with ${CURL_LIBRARIES} failed")
        else()
          message(STATUS "Libcurl: use static symbols")
          if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
            message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT})
          endif()

          add_library(CURL::libcurl UNKNOWN IMPORTED)
          set_target_properties(CURL::libcurl PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${CURL_INCLUDE_DIRS}
                                                         INTERFACE_COMPILE_DEFINITIONS "CURL_STATICLIB=1")
          set_target_properties(
            CURL::libcurl
            PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C;CXX"
                       IMPORTED_LOCATION ${CURL_LIBRARIES}
                       INTERFACE_LINK_LIBRARIES ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_STATIC_LINK_NAMES})
        endif()
      else()
        message(STATUS "Libcurl: use dynamic symbols")
        if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)
          message(STATUS ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT})
        endif()

        add_library(CURL::libcurl UNKNOWN IMPORTED)
        set_target_properties(CURL::libcurl PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${CURL_INCLUDE_DIRS})
        set_target_properties(CURL::libcurl PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C;CXX" IMPORTED_LOCATION
                                                                                                 ${CURL_LIBRARIES})
      endif()
    endif()
    unset(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_LIBCURL_TRY_RUN_OUT)

    project_third_party_libcurl_import()
  endif()
else()
  project_third_party_libcurl_import()
endif()
