include_guard(GLOBAL)

macro(PROJECT_THIRD_PARTY_RAPIDJSON_IMPORT)
  if(TARGET rapidjson)
    message(STATUS "Dependency(${PROJECT_NAME}): rapidjson using target: rapidjson")
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_LINK_NAME rapidjson)
  elseif(Rapidjson_INCLUDE_DIRS OR RapidJSON_INCLUDE_DIRS)
    if(Rapidjson_INCLUDE_DIRS AND NOT RapidJSON_INCLUDE_DIRS)
      set(RapidJSON_INCLUDE_DIRS ${Rapidjson_INCLUDE_DIRS})
      set(RapidJSON_FOUND ${Rapidjson_FOUND})
    endif()
    message(STATUS "Dependency(${PROJECT_NAME}): rapidjson using include directory: ${RapidJSON_INCLUDE_DIRS}")
    add_library(rapidjson INTERFACE IMPORTED)
    set_target_properties(rapidjson PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${RapidJSON_INCLUDE_DIRS})
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_LINK_NAME rapidjson)
  endif()
endmacro()

if(NOT TARGET rapidjson
   AND NOT Rapidjson_INCLUDE_DIRS
   AND NOT RapidJSON_INCLUDE_DIRS)
  # =========== third party rapidjson ==================
  project_third_party_port_declare(
    rapidjson
    VERSION
    "27c3a8dc0e2c9218fe94986d249a12b5ed838f1d" # 2022-07-20
    GIT_URL
    "https://github.com/Tencent/rapidjson.git"
    BUILD_OPTIONS
    "-DRAPIDJSON_BUILD_DOC=OFF"
    "-DRAPIDJSON_BUILD_EXAMPLES=OFF"
    "-DRAPIDJSON_BUILD_TESTS=OFF"
    "-DRAPIDJSON_BUILD_THIRDPARTY_GTEST=OFF")

  find_configure_package(
    PACKAGE
    RapidJSON
    BUILD_WITH_CMAKE
    CMAKE_INHERIT_BUILD_ENV
    CMAKE_INHERIT_BUILD_ENV_DISABLE_C_FLAGS
    CMAKE_FLAGS
    ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_BUILD_OPTIONS}
    WORKING_DIRECTORY
    "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
    BUILD_DIRECTORY
    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_BUILD_DIR}"
    PREFIX_DIRECTORY
    "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
    SRC_DIRECTORY_NAME
    "rapidjson-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_VERSION}"
    GIT_BRANCH
    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_VERSION}"
    GIT_URL
    "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_RAPIDJSON_GIT_URL}")

  project_third_party_rapidjson_import()
  if(NOT RapidJSON_FOUND)
    echowithcolor(COLOR RED "-- Dependency(${PROJECT_NAME}): rapidjson is required")
    message(FATAL_ERROR "rapidjson not found")
  endif()
else()
  project_third_party_rapidjson_import()
endif()
