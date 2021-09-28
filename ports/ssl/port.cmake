include_guard(GLOBAL)

# Migrate configures

if(NOT DEFINED ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_OPENSSL AND DEFINED CRYPTO_USE_OPENSSL)
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_OPENSSL ${CRYPTO_USE_OPENSSL})
endif()

if(NOT DEFINED ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_LIBRESSL AND DEFINED CRYPTO_USE_LIBRESSL)
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_LIBRESSL ${CRYPTO_USE_LIBRESSL})
endif()

if(NOT DEFINED ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_MBEDTLS AND DEFINED CRYPTO_USE_MBEDTLS)
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_MBEDTLS ${CRYPTO_USE_MBEDTLS})
endif()

if(NOT DEFINED ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_DISABLED AND DEFINED CRYPTO_DISABLED)
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_DISABLED ${CRYPTO_DISABLED})
endif()

# set(OPENSSL_USE_STATIC_LIBS TRUE)
if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_OPENSSL
   OR ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_BORINGSSL
   OR ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_LIBRESSL
   OR CRYPTO_USE_BORINGSSL)
  if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_OPENSSL)
    include("${CMAKE_CURRENT_LIST_DIR}/openssl/openssl.cmake")
  elseif(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_BORINGSSL)
    include("${CMAKE_CURRENT_LIST_DIR}/boringssl/boringssl.cmake")
  elseif(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_LIBRESSL)
    include("${CMAKE_CURRENT_LIST_DIR}/libressl/libressl.cmake")
  elseif(CRYPTO_USE_BORINGSSL)
    include("${CMAKE_CURRENT_LIST_DIR}/boringssl/boringssl.cmake")
  else()
    find_package(OpenSSL)
  endif()
  if(NOT OPENSSL_FOUND)
    message(
      FATAL_ERROR
        "ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_OPENSSL,ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_BORINGSSL,ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_LIBRESSL,CRYPTO_USE_BORINGSSL is set but openssl not found"
    )
  endif()
elseif(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_MBEDTLS)
  include("${CMAKE_CURRENT_LIST_DIR}/mbedtls/mbedtls.cmake")
  if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
    message(FATAL_ERROR "ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_MBEDTLS is set but mbedtls not found")
  endif()
elseif(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_DISABLED)
  # try to find openssl or mbedtls
  include("${CMAKE_CURRENT_LIST_DIR}/openssl/openssl.cmake")

  if(NOT OPENSSL_FOUND)
    include("${CMAKE_CURRENT_LIST_DIR}/libressl/libressl.cmake")
  endif()
  if(OPENSSL_FOUND)
    message(STATUS "Crypto enabled.(openssl found)")
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_OPENSSL 1)
  else()
    include("${CMAKE_CURRENT_LIST_DIR}/mbedtls/mbedtls.cmake")
    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
      message(STATUS "Crypto enabled.(mbedtls found)")
      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_USE_MBEDTLS 1)
    endif()
  endif()
endif()

if(NOT OPENSSL_FOUND AND NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_MBEDTLS_FOUND)
  message(FATAL_ERROR "Dependency: must at least have one of openssl,libressl or mbedtls.")
endif()

if(NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPTO_DISABLED)
  find_package(Libsodium QUIET)
  if(Libsodium_FOUND)
    list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_CRYPT_LINK_NAME ${Libsodium_LIBRARIES})
  endif()
endif()
