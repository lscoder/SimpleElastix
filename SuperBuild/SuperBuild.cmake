find_package(Git REQUIRED)
#-----------------------------------------------------------------------------

set(BUILDNAME "NoBuldNameGiven")
set(SITE      "NoSiteGiven")

enable_language(C)
enable_language(CXX)

#-----------------------------------------------------------------------------
# Platform check
#-----------------------------------------------------------------------------
set(PLATFORM_CHECK true)
if(PLATFORM_CHECK)
  # See CMake/Modules/Platform/Darwin.cmake)
  #   6.x == Mac OSX 10.2 (Jaguar)
  #   7.x == Mac OSX 10.3 (Panther)
  #   8.x == Mac OSX 10.4 (Tiger)
  #   9.x == Mac OSX 10.5 (Leopard)
  #  10.x == Mac OSX 10.6 (Snow Leopard)
  if (DARWIN_MAJOR_VERSION LESS "9")
    message(FATAL_ERROR "Only Mac OSX >= 10.5 are supported !")
  endif()
endif()

#-----------------------------------------------------------------------------
# Update CMake module path
#------------------------------------------------------------------------------

set(CMAKE_MODULE_PATH
  ${CMAKE_SOURCE_DIR}/CMake
  ${CMAKE_SOURCE_DIR}/SuperBuild
  ${CMAKE_BINARY_DIR}/CMake
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/../CMake #  CMake directory
  ${CMAKE_CURRENT_SOURCE_DIR}/../Wrapping
  ${CMAKE_MODULE_PATH}
  )

include(PreventInSourceBuilds)
include(PreventInBuildInstalls)

#-----------------------------------------------------------------------------
# Prerequisites
#------------------------------------------------------------------------------
#
# SimpleITK Addition: install to the common library
# directory, so that all libs/include etc ends up
# in one common tree
set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR} CACHE PATH "Where all the prerequisite libraries go" FORCE)

# Compute -G arg for configuring external projects with the same CMake generator:
if(CMAKE_EXTRA_GENERATOR)
  set(gen "${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
else()
  set(gen "${CMAKE_GENERATOR}")
endif()


#-----------------------------------------------------------------------------
# SimpleITK options
#------------------------------------------------------------------------------
option( ${CMAKE_PROJECT_NAME}_BUILD_TESTING "Turn on Testing for SimpleITK" ON )


#-----------------------------------------------------------------------------
# Default to build shared libraries off
#------------------------------------------------------------------------------
set(BUILD_SHARED_LIBS OFF)

#-----------------------------------------------------------------------------
# Setup build type
#------------------------------------------------------------------------------

# By default, let's build as Debug
if(NOT DEFINED CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug")
endif()

# let a dashboard override the default.
if(CTEST_BUILD_CONFIGURATION)
  set(CMAKE_BUILD_TYPE "${CTEST_BUILD_CONFIGURATION}")
endif()

#-------------------------------------------------------------------------
# augment compiler flags
#-------------------------------------------------------------------------
include(CompilerFlagSettings)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${C_DEBUG_DESIRED_FLAGS}" )
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_DEBUG_DESIRED_FLAGS}" )
else() # Release, or anything else
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${C_RELEASE_DESIRED_FLAGS}" )
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_RELEASE_DESIRED_FLAGS}" )
endif()

#------------------------------------------------------------------------------
# BuildName used for dashboard reporting
#------------------------------------------------------------------------------
if(NOT BUILDNAME)
  set(BUILDNAME "Unknown-build" CACHE STRING "Name of build to report to dashboard")
endif()


#------------------------------------------------------------------------------
# WIN32 /bigobj is required for windows builds because of the size of
#------------------------------------------------------------------------------
if (WIN32)
  # some object files (CastImage for instance)
  set ( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /bigobj" )
  set ( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /bigobj" )
  # Avoid some warnings
  add_definitions ( -D_SCL_SECURE_NO_WARNINGS )
endif()

#------------------------------------------------------------------------------
# Setup build locations.
#------------------------------------------------------------------------------
if(NOT SETIFEMPTY)
  macro(SETIFEMPTY) # A macro to set empty variables to meaninful defaults
    set(KEY ${ARGV0})
    set(VALUE ${ARGV1})
    if(NOT ${KEY})
      set(${ARGV})
    endif(NOT ${KEY})
  endmacro(SETIFEMPTY KEY VALUE)
endif(NOT SETIFEMPTY)
SETIFEMPTY(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
SETIFEMPTY(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
SETIFEMPTY(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
SETIFEMPTY(CMAKE_BUNDLE_OUTPUT_DIRECTORY  ${CMAKE_CURRENT_BINARY_DIR}/bin)


#------------------------------------------------------------------------------
# Common Build Options to pass to all subsequent tools
#------------------------------------------------------------------------------
set(ep_common_args
  --no-warn-unused-cli
  -DMAKECOMMAND:STRING=${MAKECOMMAND}
  -DCMAKE_SKIP_RPATH:BOOL=ON
  -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
  -DCMAKE_CXX_FLAGS_RELEASE:STRING=${CMAKE_CXX_FLAGS_RELEASE}
  -DCMAKE_CXX_FLAGS_DEBUG:STRING=${CMAKE_CXX_FLAGS_DEBUG}
  -DCMAKE_CXX_FLAGS:STRING=${CMAKE_CXX_FLAGS}
  -DCMAKE_C_FLAGS_RELEASE:STRING=${CMAKE_C_FLAGS_RELEASE}
  -DCMAKE_C_FLAGS_DEBUG:STRING=${CMAKE_C_FLAGS_DEBUG}
  -DCMAKE_C_FLAGS:STRING=${CMAKE_C_FLAGS}
  -DBUILD_EXAMPLES:BOOL=OFF
  -DCMAKE_GENERATOR:STRING=${CMAKE_GENERATOR}
  -DCMAKE_EXTRA_GENERATOR:STRING=${CMAKE_EXTRA_GENERATOR}
  -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
  -DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
  -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
  -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
  -DCMAKE_BUNDLE_OUTPUT_DIRECTORY:PATH=${CMAKE_BUNDLE_OUTPUT_DIRECTORY}
  -DMEMORYCHECK_COMMAND_OPTIONS:STRING=${MEMORYCHECK_COMMAND_OPTIONS}
  -DMEMORYCHECK_COMMAND:PATH=${MEMORYCHECK_COMMAND}
  -DCMAKE_SHARED_LINKER_FLAGS:STRING=${CMAKE_SHARED_LINKER_FLAGS}
  -DCMAKE_EXE_LINKER_FLAGS:STRING=${CMAKE_EXE_LINKER_FLAGS}
  -DCMAKE_MODULE_LINKER_FLAGS:STRING=${CMAKE_MODULE_LINKER_FLAGS}
  -DSITE:STRING=${SITE}
  -DBUILDNAME:STRING=${BUILDNAME}
)

#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
include(ExternalProject)
#------------------------------------------------------------------------------
# Swig
#------------------------------------------------------------------------------
option ( USE_SYSTEM_SWIG "Use a pre-compiled version of SWIG 2.0 previously configured for your system" OFF )
mark_as_advanced(USE_SYSTEM_SWIG)
if(USE_SYSTEM_SWIG)
  find_package ( SWIG 2 REQUIRED )
  include ( UseSWIGLocal )
else()
  include(External_Swig)
  list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES Swig)
endif()

#------------------------------------------------------------------------------
# ITK
#------------------------------------------------------------------------------

set(ITK_WRAPPING OFF CACHE BOOL "Turn OFF wrapping ITK with WrapITK")
if(ITK_WRAPPING)
  list(APPEND ITK_DEPENDENCIES Swig)
endif()
if(ITK_USE_FFTW)
  list(APPEND ITK_DEPENDENCIES fftw)
endif()
include(External_ITKv4)
list(APPEND ${CMAKE_PROJECT_NAME}_DEPENDENCIES ITK)


#------------------------------------------------------------------------------
# List of external projects
#------------------------------------------------------------------------------
set(external_project_list  ITK swig)

#-----------------------------------------------------------------------------
# Dump external project dependencies
#-----------------------------------------------------------------------------
set(ep_dependency_graph "# External project dependencies")
foreach(ep ${external_project_list})
  set(ep_dependency_graph "${ep_dependency_graph}\n${ep}:${${ep}_DEPENDENCIES}")
endforeach()
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/ExternalProjectDependencies.txt "${ep_dependency_graph}\n")

#-----------------------------------------------------------------------------
# Now delegate back to the main SimpleITK with ${CMAKE_PROJECT_NAME}_SuperBuild=OFF
# to actually build Simple ITK
#-----------------------------------------------------------------------------
message(STATUS "${CMAKE_PROJECT_NAME}_DEPENDENCIES ${${CMAKE_PROJECT_NAME}_DEPENDENCIES}")

#
# Use CMake file which present options for wrapped languages, and finds languages as needed
#
include(SITKLanguageOptions)

foreach( var IN LISTS SITK_LANGUAGES_VARS )
  
  if( ${var} ) # if variable has been set
    get_property( type CACHE ${var} PROPERTY TYPE )
    list( APPEND ep_languages_args "-D${var}:${type}=${${var}}" )
  endif()
endforeach()

message( STATUS "EP: ${ep_languages_args}" )


set(proj SimpleITK)
ExternalProject_Add(${proj}
  DOWNLOAD_COMMAND ""
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..
  BINARY_DIR SimpleITK-build
  CMAKE_GENERATOR ${gen}
  CMAKE_ARGS
    ${ep_common_args}
    ${ep_languages_args}
    # ITK
    -DITK_DIR:PATH=${ITK_DIR}
    # Swig
    -DSWIG_DIR:PATH=${SWIG_DIR}
    -DSWIG_EXECUTABLE:PATH=${SWIG_EXECUTABLE}
    -DBUILD_TESTING:BOOL=${CMAKE_PROJECT_NAME}_BUILD_TESTING
    -DWRAP_LUA:BOOL=${WRAP_LUA}
    -DWRAP_PYTHON:BOOL=${WRAP_PYTHON}
    -DWRAP_RUBY:BOOL=${WRAP_RUBY}
    -DWRAP_JAVA:BOOL=${WRAP_JAVA}
    -DWRAP_TCL:BOOL=${WRAP_TCL}
    -DWRAP_CSHARP:BOOL=${WRAP_CSHARP}
    -DWRAP_R:BOOL=${WRAP_R}
  INSTALL_COMMAND ""
  DEPENDS ${${CMAKE_PROJECT_NAME}_DEPENDENCIES}
)
