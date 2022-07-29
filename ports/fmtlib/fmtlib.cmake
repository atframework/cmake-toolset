include_guard(GLOBAL)

macro(PROJECT_THIRD_PARTY_FMTLIB_IMPORT)
  if(TARGET fmt::fmt-header-only)
    message(STATUS "Dependency(${PROJECT_NAME}): fmtlib using target fmt::fmt-header-only")
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_LINK_NAME fmt::fmt-header-only)
  elseif(TARGET fmt::fmt)
    message(STATUS "Dependency(${PROJECT_NAME}): fmtlib using target fmt::fmt")
    set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_LINK_NAME fmt::fmt)
  else()
    message(STATUS "Dependency(${PROJECT_NAME}): fmtlib support disabled")
  endif()
endmacro()

option(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_ALTERNATIVE_STD "Do not compile fmt.dev if has std::format" ON)

# MSVC 1929 - VS 2019 (14.29) has wrong argument type for some functions of std::format So we disable it for easier to
# use
if(MSVC AND MSVC_VERSION LESS 1930)
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_STD_BLACKLIST TRUE)
else()
  set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_STD_BLACKLIST FALSE)
endif()

if(NOT TARGET fmt::fmt-header-only
   AND NOT TARGET fmt::fmt
   AND NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_STD_FORMAT)
  if(VCPKG_TOOLCHAIN)
    find_package(fmt QUIET)
    project_third_party_fmtlib_import()
  endif()

  if(NOT TARGET fmt::fmt-header-only
     AND NOT TARGET fmt::fmt
     AND NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_STD_FORMAT)
    include(CheckCXXSourceCompiles)
    if(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_ALTERNATIVE_STD
       AND NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_STD_BLACKLIST
       AND NOT DEFINED ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_STD_FORMAT
       AND NOT DEFINED CACHE{ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_STD_FORMAT})
      check_cxx_source_compiles(
        "
#include <format>
#include <iostream>
#include <string>
struct custom_object {
  int32_t x;
  std::string y;
};

// Some STL implement may have BUGs on some APIs, we need check it
template <class CharT>
struct std::formatter<custom_object, CharT> : std::formatter<CharT*, CharT> {
  template <class FormatContext>
  auto format(const custom_object &vec, FormatContext &ctx) {
    return std::vformat_to(ctx.out(), \"({},{})\", std::make_format_args(vec.x, vec.y));
  }
};
int main() {
  custom_object custom_obj;
  custom_obj.x = 43;
  custom_obj.y = \"44\";
  std::cout<< std::format(\"The answer is {}, custom object: {}.\", 42, custom_obj)<< std::endl;
  char buffer[64] = {0};
  const auto result = std::format_to_n(buffer, sizeof(buffer), \"{} {}: {}\", \"Hello\", \"World!\", 42);
  std::cout << \"Buffer: \" << buffer << \",Untruncated output size = \" << result.size << std::endl;
  return 0;
}"
        ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_STD_FORMAT)
    endif()

    # =========== third party fmtlib ==================
    if(NOT TARGET fmt::fmt-header-only
       AND NOT TARGET fmt::fmt
       AND (NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_ALTERNATIVE_STD
            OR ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_STD_BLACKLIST
            OR NOT ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_TEST_STD_FORMAT))
      project_third_party_port_declare(
        fmtlib
        VERSION
        "9.0.0"
        GIT_URL
        "https://github.com/fmtlib/fmt.git"
        BUILD_OPTIONS
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
        "-DFMT_DOC=OFF"
        "-DFMT_INSTALL=ON"
        "-DFMT_TEST=OFF"
        "-DFMT_FUZZ=OFF"
        "-DFMT_CUDA_TEST=OFF")

      project_third_party_append_build_shared_lib_var(
        "fmtlib" "" ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_BUILD_OPTIONS BUILD_SHARED_LIBS)

      set(ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_PATCH_FILE
          "${CMAKE_CURRENT_LIST_DIR}/fmtlib-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_VERSION}.patch")
      if(EXISTS "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_PATCH_FILE}")
        list(APPEND ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_BUILD_OPTIONS GIT_PATCH_FILES
             ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_PATCH_FILE})
      endif()

      set(FMT_ROOT ${PROJECT_THIRD_PARTY_INSTALL_DIR})
      set(Fmt_ROOT ${PROJECT_THIRD_PARTY_INSTALL_DIR})
      set(fmt_ROOT ${PROJECT_THIRD_PARTY_INSTALL_DIR})

      find_configure_package(
        PACKAGE
        fmt
        BUILD_WITH_CMAKE
        CMAKE_INHERIT_BUILD_ENV
        CMAKE_INHERIT_BUILD_ENV_DISABLE_C_FLAGS
        CMAKE_INHERIT_BUILD_ENV_DISABLE_ASM_FLAGS
        CMAKE_FLAGS
        ${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_BUILD_OPTIONS}
        WORKING_DIRECTORY
        "${PROJECT_THIRD_PARTY_PACKAGE_DIR}"
        BUILD_DIRECTORY
        "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_BUILD_DIR}"
        PREFIX_DIRECTORY
        "${PROJECT_THIRD_PARTY_INSTALL_DIR}"
        SRC_DIRECTORY_NAME
        "fmt-${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_VERSION}"
        GIT_BRANCH
        "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_VERSION}"
        GIT_URL
        "${ATFRAMEWORK_CMAKE_TOOLSET_THIRD_PARTY_FMTLIB_GIT_URL}")

      if(fmt_FOUND)
        project_third_party_fmtlib_import()
      else()
        echowithcolor(COLOR RED "-- Dependency(${PROJECT_NAME}): fmtlib is required but not found")
        message(FATAL_ERROR "fmtlib not found")
      endif()
    endif()
  endif()
else()
  project_third_party_fmtlib_import()
endif()
