# copy from atframework/libatframe_utils/repo/project/cmake/ProjectBuildOption.cmake

set(OPENSSL_USE_STATIC_LIBS TRUE)
if(CRYPTO_USE_OPENSSL
   OR CRYPTO_USE_LIBRESSL
   OR CRYPTO_USE_BORINGSSL)
  if(CRYPTO_USE_OPENSSL)
    include("${CMAKE_CURRENT_LIST_DIR}/openssl/openssl.cmake")
  elseif(CRYPTO_USE_LIBRESSL)
    include("${CMAKE_CURRENT_LIST_DIR}/libressl/libressl.cmake")
  elseif(CRYPTO_USE_BORINGSSL)
    include("${CMAKE_CURRENT_LIST_DIR}/boringssl/boringssl.cmake")
  else()
    find_package(OpenSSL)
  endif()
  if(NOT OPENSSL_FOUND)
    message(
      FATAL_ERROR
        "CRYPTO_USE_OPENSSL,CRYPTO_USE_LIBRESSL,CRYPTO_USE_BORINGSSL is set but openssl not found")
  endif()
elseif(CRYPTO_USE_MBEDTLS)
  include("${CMAKE_CURRENT_LIST_DIR}/mbedtls/mbedtls.cmake")
  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
    message(FATAL_ERROR "CRYPTO_USE_MBEDTLS is set but mbedtls not found")
  endif()
elseif(NOT CRYPTO_DISABLED)
  # try to find openssl or mbedtls
  include("${CMAKE_CURRENT_LIST_DIR}/openssl/openssl.cmake")

  if(NOT OPENSSL_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/libressl/libressl.cmake")
  endif()
  if(OPENSSL_FOUND)
    message(STATUS "Crypto enabled.(openssl found)")
    set(CRYPTO_USE_OPENSSL 1)
  else()
    include("${CMAKE_CURRENT_LIST_DIR}/mbedtls/mbedtls.cmake")
    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
      message(STATUS "Crypto enabled.(mbedtls found)")
      set(CRYPTO_USE_MBEDTLS 1)
    endif()
  endif()
endif()

if(NOT OPENSSL_FOUND AND NOT MBEDTLS_FOUND)
  message(FATAL_ERROR "Dependency: must at least have one of openssl,libressl or mbedtls.")
else()
  list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_COPY_EXECUTABLE_PATTERN
       "${PROJECT_THIRD_PARTY_INSTALL_DIR}/bin/openssl*")
endif()

if(NOT CRYPTO_DISABLED)
  find_package(Libsodium QUIET)
  if(Libsodium_FOUND)
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_PUBLIC_LINK_NAMES ${Libsodium_LIBRARIES})
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME ${Libsodium_LIBRARIES})
  endif()
endif()
