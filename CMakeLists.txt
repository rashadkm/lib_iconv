################################################################################
# Project:  Lib iconv
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2015, NextGIS <info@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(iconv C)

# some init settings
#set(CMAKE_COLOR_MAKEFILE ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()  
# set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
option(BUILD_SHARED_LIBS  "Build shared libs." ON)

set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/bin" CACHE INTERNAL "Installation directory for executables" FORCE)
set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib" CACHE INTERNAL "Installation directory for libraries" FORCE)
set(INSTALL_INC_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE INTERNAL "Installation directory for headers" FORCE)

include(util)
set(ICONV_MAJOR_VERSION -1)
set(ICONV_MINOR_VERSION -1)
check_version(ICONV_MAJOR_VERSION ICONV_MINOR_VERSION)
set(VERSION ${ICONV_MAJOR_VERSION}.${ICONV_MINOR_VERSION})

include(configure)

configure_file(${CMAKE_MODULE_PATH}/cmake_uninstall.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE @ONLY)

include_directories ( ${CMAKE_CURRENT_SOURCE_DIR} )
include_directories ( ${CMAKE_CURRENT_BINARY_DIR} )
include_directories ( ${CMAKE_CURRENT_SOURCE_DIR}/include )
include_directories ( ${CMAKE_CURRENT_SOURCE_DIR}/srclib )
include_directories ( ${CMAKE_CURRENT_BINARY_DIR}/include )

#add_definitions ( -DINSTALLPREFIX=NULL -DNO_XMALLOC -DBUILDING_LIBCHARSET -DINSTALLDIR="" )
if(${ENABLE_RELOCATABLE})
    add_definitions ( -Dset_relocation_prefix=libcharset_set_relocation_prefix -Drelocate=libcharset_relocate -DENABLE_RELOCATABLE=1 )
else()
    add_definitions ( -DENABLE_RELOCATABLE=0 )
endif()

set(PUBLIC_HDRS
    ${CMAKE_CURRENT_BINARY_DIR}/include/iconv.h
)

set(PRIVATE_HDRS
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/libcharset.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/localcharset.h
    libcharset/lib/relocatable.h
)

set(SRCS
    lib/iconv.c
    libcharset/lib/localcharset.c
    libcharset/lib/relocatable.c
)

if(WIN32)

    if(BUILD_SHARED_LIBS)
        set(SRCS ${SRCS} 
            windows/libiconv.rc
        )
        add_definitions(-DBUILDING_DLL)
        add_definitions (-DPACKAGE_VERSION_MAJOR=${ICONV_MAJOR_VERSION})
        add_definitions (-DPACKAGE_VERSION_MINOR=${ICONV_MINOR_VERSION}) 
        add_definitions (-DPACKAGE_VERSION_SUBMINOR=0) 
        add_definitions (-DPACKAGE_VERSION_STRING="lib${PROJECT_NAME}-${VERSION}")    
    endif()
    
    if (MSVC)
        # -D_UNICODE -DUNICODE 
        add_definitions (-D_CRT_NONSTDC_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS -D_CRT_NON_CONFORMING_SWPRINTFS -D_CRT_SECURE_NO_DEPRECATE)
    endif()
endif()


add_definitions(-DIN_LIBRARY -DBUILDING_LIBICONV -DLIBDIR="" -DHAVE_WORKING_O_NOFOLLOW) # -DLIBICONV_PLUG

report_version(${PROJECT_NAME} ${VERSION})     

set(LIB_NAME)
if(BUILD_SHARED_LIBS)
    set(LIB_NAME ${PROJECT_NAME})
    add_library(${LIB_NAME} SHARED ${SRCS} ${PUBLIC_HDRS} ${PRIVATE_HDRS})
    set_target_properties(${LIB_NAME} PROPERTIES DEFINE_SYMBOL XML2_DLL)
    set_target_properties(${LIB_NAME} PROPERTIES SOVERSION 1)
else()
    set(LIB_NAME ${PROJECT_NAME}static)
    add_library(${LIB_NAME} STATIC ${SRCS} ${PUBLIC_HDRS} ${PRIVATE_HDRS})
    set_target_properties(${LIB_NAME} PROPERTIES SOVERSION 1)
endif()   

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

if(NOT CYGWIN)
    set_target_properties(${LIB_NAME} PROPERTIES VERSION ${VERSION})
endif()





set(CMAKE_CONFIG_PREFIX "ICONV")
set(CMAKE_EXPORT_TARGET_NAME ${CMAKE_CONFIG_PREFIX}Targets)

install(TARGETS ${LIB_NAME}
  EXPORT ${CMAKE_EXPORT_TARGET_NAME}
  RUNTIME DESTINATION "${INSTALL_BIN_DIR}"
  ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
  LIBRARY DESTINATION "${INSTALL_LIB_DIR}" )

export(TARGETS ${LIB_NAME}
  FILE "${CMAKE_BINARY_DIR}/${CMAKE_EXPORT_TARGET_NAME}.cmake")

install(FILES ${PUBLIC_HDRS} DESTINATION "${INSTALL_INC_DIR}")

set(${CMAKE_CONFIG_PREFIX}_VERSION ${VERSION})
string(TOLOWER ${CMAKE_CONFIG_PREFIX} CMAKE_CONFIG_PREFIX_)

if(WIN32 AND NOT CYGWIN)
  set(DEF_INSTALL_CMAKE_DIR cmake)
else()
  set(DEF_INSTALL_CMAKE_DIR lib/cmake/${CMAKE_CONFIG_PREFIX_})
endif()

set(INSTALL_CMAKE_DIR ${DEF_INSTALL_CMAKE_DIR} CACHE PATH
  "Installation directory for CMake files")


# Make relative paths absolute (needed later on)
foreach(p LIB BIN INCLUDE CMAKE)
  set(var INSTALL_${p}_DIR)
  if(NOT IS_ABSOLUTE "${${var}}")
    set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
  endif()
endforeach()

set(CONFIG_TYPE "NOCONFIG")
if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "")
  string(TOUPPER ${CMAKE_BUILD_TYPE} CONFIG_TYPE)
endif()

file(RELATIVE_PATH REL_INCLUDE_DIR "${INSTALL_CMAKE_DIR}"
  "${INSTALL_INC_DIR}")

# ... for the build tree
set(CONF_INCLUDE_DIRS "${CMAKE_BINARY_DIR}")
configure_file("${CMAKE_SOURCE_DIR}/cmake/${CMAKE_CONFIG_PREFIX}Config.cmake.in"
  "${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_PREFIX}Config.cmake" @ONLY)

# ... for the install tree
set(CONF_INCLUDE_DIRS "\${INSTALL_CMAKE_DIR}/${REL_INCLUDE_DIR}")
configure_file("${CMAKE_SOURCE_DIR}/cmake/${CMAKE_CONFIG_PREFIX}Config.cmake.in"
  "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${CMAKE_CONFIG_PREFIX}Config.cmake" @ONLY)
# ... for both
configure_file("${CMAKE_SOURCE_DIR}/cmake/${CMAKE_CONFIG_PREFIX}ConfigVersion.cmake.in"
  "${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_PREFIX}ConfigVersion.cmake" @ONLY)
 
install(FILES
  "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${CMAKE_CONFIG_PREFIX}Config.cmake"
  "${CMAKE_BINARY_DIR}/${CMAKE_CONFIG_PREFIX}ConfigVersion.cmake"
  DESTINATION ${DEF_INSTALL_CMAKE_DIR} )

# Install the export set for use with the install-tree
install(EXPORT ${CMAKE_EXPORT_TARGET_NAME} DESTINATION ${INSTALL_CMAKE_DIR})
