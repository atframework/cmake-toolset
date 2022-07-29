# =========== third party mbedtls ==================
include_guard(GLOBAL)

macro(PROJECT_THIRD_PARTY_MBEDTLS_IMPORT)
  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
    if(TARGET MbedTLS::mbedtls)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME MbedTLS::mbedtls)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND TRUE)
      message(STATUS "Dependency(${PROJECT_NAME}): MbedTLS found target MbedTLS::mbedtls")
    elseif(TARGET mbedtls_static)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME mbedtls_static)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND TRUE)
      message(STATUS "Dependency(${PROJECT_NAME}): MbedTLS found target mbedtls_static")
    elseif(TARGET mbedtls)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME mbedtls)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND TRUE)
      message(STATUS "Dependency(${PROJECT_NAME}): MbedTLS found target mbedtls")
    elseif(mbedTLS_FOUND OR MbedTLS_FOUND)
      add_library(mbedtls UNKNOWN IMPORTED)
      if(MBEDTLS_INCLUDE_DIR)
        set_target_properties(mbedtls PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${MBEDTLS_INCLUDE_DIR})
      elseif(MbedTLS_INCLUDE_DIRS)
        set_target_properties(mbedtls PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${MbedTLS_INCLUDE_DIRS})
      endif()

      if(MBEDTLS_TLS_LIBRARY)
        set_target_properties(mbedtls PROPERTIES IMPORTED_LOCATION ${MBEDTLS_TLS_LIBRARY})
      elseif(MbedTLS_TLS_LIBRARIES)
        set_target_properties(mbedtls PROPERTIES IMPORTED_LOCATION ${MbedTLS_TLS_LIBRARIES})
      elseif(MBEDTLS_LIBRARIES)
        set_target_properties(mbedtls PROPERTIES IMPORTED_LOCATION ${MBEDTLS_LIBRARIES})
      elseif(MbedTLS_LIBRARIES)
        set_target_properties(mbedtls PROPERTIES IMPORTED_LOCATION ${MbedTLS_LIBRARIES})
      else()
        message(FATAL_ERROR "Library not found for mbedtls")
      endif()
      message(STATUS "Dependency(${PROJECT_NAME}): MbedTLS found libraries and create target mbedtls")

      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND TRUE)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME mbedtls)
    endif()

    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND AND NOT
                                                               ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_MBEDTLS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_MBEDTLS
          TRUE
          CACHE BOOL "Cache ssl selector and directly use mbedtls next time")
    endif()
  endif()
endmacro()

if(NOT
   (TARGET MbedTLS::mbedtls
    OR TARGET mbedtls_static
    OR TARGET mbedtls
    OR mbedTLS_FOUND
    OR MbedTLS_FOUND))
  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_VERSION)
    # libcurl support mbedtls 3.0+ from 7.82.0 ===================================
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_VERSION "v3.2.1")
    # set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_VERSION "v2.28.1")
  endif()

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_GIT_URL)
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_GIT_URL "https://github.com/ARMmbed/mbedtls.git")
  endif()

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_BUILD_DIR)
    project_third_party_get_build_dir(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_BUILD_DIR "mbedtls"
                                      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_VERSION})
  endif()

  if(VCPKG_TOOLCHAIN)
    find_package(MbedTLS QUIET)
    if(TARGET MbedTLS::mbedtls
       OR TARGET mbedtls_static
       OR TARGET mbedtls
       OR mbedTLS_FOUND
       OR MbedTLS_FOUND)
      project_third_party_mbedtls_import()
    endif()
  endif()

  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
    if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_BUILD_FLAGS)
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_BUILD_FLAGS
          "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" "-DENABLE_TESTING=OFF" "-DUSE_STATIC_MBEDTLS_LIBRARY=ON"
          "-DUSE_SHARED_MBEDTLS_LIBRARY=OFF" "-DENABLE_PROGRAMS=OFF")
    endif()

    if(ZLIB_FOUND AND ZLIB_ROOT)
      list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_BUILD_FLAGS "-DZLIB_ROOT=${ZLIB_ROOT}"
           "-DENABLE_ZLIB_SUPPORT=ON")
    endif()

    message(STATUS "Try to configure and use mbedtls")
    find_configure_package(
      PACKAGE
      MbedTLS
      BUILD_WITH_CMAKE
      CMAKE_INHERIT_BUILD_ENV
      CMAKE_INHERIT_BUILD_ENV_DISABLE_CXX_FLAGS
      CMAKE_INHERIT_FIND_ROOT_PATH
      CMAKE_FLAGS
      ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_BUILD_FLAGS}
      WORKING_DIRECTORY
      "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
      SRC_DIRECTORY_NAME
      "mbedtls-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_VERSION}"
      GIT_BRANCH
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_VERSION}"
      BUILD_DIRECTORY
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_BUILD_DIR}"
      PREFIX_DIRECTORY
      "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
      GIT_URL
      "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_MBEDTLS_GIT_URL}")

    project_third_party_mbedtls_import()
  endif()
else()
  project_third_party_mbedtls_import()
endif()
