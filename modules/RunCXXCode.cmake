# .rst: RunCXXCode
# ------------------
#
# Compile, run and get the resault of the given C++ source code.
#
# RunCXXCode(<code> <ret_var> <output_var>)
#
# ::
#
# <code>          - source code to try to compile <var>           - variable to store the result (1 for success, empty for failure) Will be
# created as an internal cache variable. <output_var>    - variable to store the output
#
# The following variables may be set before calling this macro to modify the way the check is run:
#
# ::
#
# CMAKE_REQUIRED_FLAGS = string of compile command line flags CMAKE_REQUIRED_DEFINITIONS = list of macros to define (-DFOO=bar)
# CMAKE_REQUIRED_INCLUDES = list of include directories CMAKE_REQUIRED_LIBRARIES = list of libraries to link CMAKE_REQUIRED_QUIET = execute
# quietly without messages

# =============================================================================
# Copyright 2014-2015 OWenT.
#
# Distributed under the OSI-approved BSD License (the "License"); see accompanying file
# Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the License for more information.
# =============================================================================
# (To distribute this file outside of CMake, substitute the full License text for the above
# reference.)

macro(RunCXXCode SOURCE VAR OUTPUT_VAR)
  if(NOT DEFINED "${VAR}")
    set(MACRO_CHECK_FUNCTION_DEFINITIONS "-D${VAR} ${CMAKE_REQUIRED_FLAGS}")
    if(CMAKE_REQUIRED_LIBRARIES)
      set(CHECK_CXX_SOURCE_COMPILES_ADD_LIBRARIES LINK_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES})
    else()
      set(CHECK_CXX_SOURCE_COMPILES_ADD_LIBRARIES)
    endif()
    if(CMAKE_REQUIRED_INCLUDES)
      set(CHECK_CXX_SOURCE_COMPILES_ADD_INCLUDES
          "-DINCLUDE_DIRECTORIES:STRING=${CMAKE_REQUIRED_INCLUDES}")
    else()
      set(CHECK_CXX_SOURCE_COMPILES_ADD_INCLUDES)
    endif()
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.cxx" "${SOURCE}\n")

    if(NOT CMAKE_REQUIRED_QUIET)
      message(STATUS "Performing Test ${VAR}")
    endif()
    try_run(
      ${VAR}_EXITCODE ${VAR}_COMPILED ${CMAKE_CURRENT_BINARY_DIR}
      ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/src.cxx
      COMPILE_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS} ${CHECK_CXX_SOURCE_COMPILES_ADD_LIBRARIES}
      CMAKE_FLAGS
        -DCOMPILE_DEFINITIONS:STRING=${MACRO_CHECK_FUNCTION_DEFINITIONS}
        -DCMAKE_SKIP_RPATH:BOOL=${CMAKE_SKIP_RPATH} "${CHECK_CXX_SOURCE_COMPILES_ADD_INCLUDES}"
      COMPILE_OUTPUT_VARIABLE ${OUTPUT_VAR})

    # if it did not compile make the return value fail code of 1
    if(NOT ${VAR}_COMPILED)
      set(${VAR}_EXITCODE 1)
    endif()
    # if the return value was 0 then it worked
    if("${${VAR}_EXITCODE}" EQUAL 0)
      set(${VAR}
          1
          CACHE INTERNAL "Test ${VAR}")
      if(NOT CMAKE_REQUIRED_QUIET)
        message(STATUS "Performing Test ${VAR} - Success")
      endif()
      file(APPEND ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
           "Performing C++ SOURCE FILE Test ${VAR} succeded with the following output:\n"
           "${${OUTPUT_VAR}}\n" "Return value: ${${VAR}}\n" "Source file was:\n${SOURCE}\n")
    else()
      if(CMAKE_CROSSCOMPILING AND "${${VAR}_EXITCODE}" MATCHES "FAILED_TO_RUN")
        set(${VAR} "${${VAR}_EXITCODE}")
      else()
        set(${VAR}
            ""
            CACHE INTERNAL "Test ${VAR}")
      endif()

      if(NOT CMAKE_REQUIRED_QUIET)
        message(STATUS "Performing Test ${VAR} - Failed")
      endif()
      file(
        APPEND ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
        "Performing C++ SOURCE FILE Test ${VAR} failed with the following output:\n"
        "${${OUTPUT_VAR}}\n" "Return value: ${${VAR}_EXITCODE}\n" "Source file was:\n${SOURCE}\n")
    endif()
  endif()
endmacro()
