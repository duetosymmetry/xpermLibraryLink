#Copyright 2019-2020 Wolfram Research Inc.

#Permission is hereby granted, free of charge, to any person obtaining a copy of
#this software and associated documentation files (the "Software"), to deal in
#the Software without restriction, including without limitation the rights to
#use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
#the Software, and to permit persons to whom the Software is furnished to do so,
#subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
#FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
#COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
#IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# FindWolframLanguage.cmake
#
# Finds a Wolfram product that implements the Wolfram Language (e.g. Wolfram Desktop, Wolfram Mathematica or Wolfram Engine).
# A WolframKernel executable together with other components of the installation, if requested. The following locations are searched:
#   - location specified via WolframLanguage_ROOT or WolframLanguage_INSTALL_DIR
#   - default install directory for given OS
#   - system path
#
# Supported components are:
#   - WolframLibrary
#   - WSTP
#   - wolframscript
#
# Components are searched for in the same installation where the executable was found but this can be overriden by specifying WOLFRAM_LIBRARY_PATH
# or WSTP_PATH as custom locations of Wolfram Library and WSTP, respectively.
#
# This module will define the following variables
#
#    WolframLanguage_FOUND
#    WolframLanguage_VERSION
#    WolframLanguage_INSTALL_DIR
#    WolframLanguage_EXE
#
# And for specific components, if they were requested:
#
# WolframLibrary:
#    WolframLanguage_WolframLibrary_FOUND
#    WolframLibrary_FOUND
#    WolframLibrary_INCLUDE_DIRS
#    WolframLibrary_VERSION
#
#    and the imported target WolframLibrary::WolframLibrary
#
# WSTP:
#    WolframLanguage_WSTP_FOUND
#    WSTP_FOUND
#    WSTP_INCLUDE_DIRS
#    WSTP_LIBRARIES
#    WSTP_VERSION
#
#    and the imported target WSTP::WSTP
#
# wolframscript:
#    WolframLanguage_wolframscript_FOUND
#    WolframLanguage_wolframscript_EXE
#
# Author: Rafal Chojna - rafalc@wolfram.com

include("${CMAKE_CURRENT_LIST_DIR}/Wolfram/Common.cmake")

set(_MMA_FIND_NAMES WolframDesktop wolframdesktop Mathematica mathematica WolframKernel wolfram)
set(_MMA_FIND_SUFFIXES Executables MacOS Contents/MacOS)
set(_MMA_FIND_DOC "Location of WolframLanguage interpreter executable")

if(NOT WolframLanguage_ROOT AND Mathematica_INSTALL_DIR)
	set(WolframLanguage_ROOT ${Mathematica_INSTALL_DIR})
endif()
if(NOT WolframLanguage_ROOT AND MATHEMATICA_INSTALL_DIR)
	set(WolframLanguage_ROOT ${MATHEMATICA_INSTALL_DIR})
endif()

set(_MMA_FIND_QUIETLY)
if(WolframLanguage_FIND_QUIETLY)
	set(_MMA_FIND_QUIETLY QUIET)
endif()

###############################################################################
# Helper functions and macros
###############################################################################

function(parse_wolfram_language_version M_DIRECTORY VERSION)
	if(APPLE)
		find_file(VERSION_FILE Info.plist PATHS ${M_DIRECTORY} PATH_SUFFIXES Contents NO_DEFAULT_PATH)
	else()
		find_file(VERSION_FILE .VersionID ${M_DIRECTORY})
	endif()
	if(NOT VERSION_FILE)
		set(${VERSION} "${VERSION}-NOTFOUND" PARENT_SCOPE)
		return()
	endif()
	if(APPLE)
		file(READ ${VERSION_FILE} _VERSION_INFO)
		string(REGEX REPLACE ".*<key>CFBundleVersion</key>[ \n\t\r]+<string>([0-9\\.]+)</string>.*" "\\1" VERSION_ID_STRING "${_VERSION_INFO}")
	else()
		file(STRINGS ${VERSION_FILE} VERSION_ID_STRING)
	endif()
	set(${VERSION} ${VERSION_ID_STRING} PARENT_SCOPE)
endfunction()

macro(find_wolfram_language_from_hint)
	if(WolframLanguage_ROOT OR WolframLanguage_INSTALL_DIR)
		find_program(WolframLanguage_EXE
			NAMES ${_MMA_FIND_NAMES}
			HINTS ${WolframLanguage_ROOT} ${WolframLanguage_INSTALL_DIR}
			PATH_SUFFIXES ${_MMA_FIND_SUFFIXES}
			DOC ${_MMA_FIND_DOC}
			NO_DEFAULT_PATH)

		if(NOT WolframLanguage_EXE AND NOT WolframLanguage_FIND_QUIETLY)
			message(WARNING
				"Could not find WolframLanguage implementation in requested location \n${WolframLanguage_ROOT}${WolframLanguage_INSTALL_DIR}\n"
				"Looking in default directories...")
		endif()
	endif()
endmacro()

macro(find_wolfram_language_from_env)
	if(IS_DIRECTORY "$ENV{MATHEMATICA_HOME}")
		find_program(WolframLanguage_EXE
			NAMES ${_MMA_FIND_NAMES}
			HINTS "$ENV{MATHEMATICA_HOME}"
			PATH_SUFFIXES ${_MMA_FIND_SUFFIXES}
			DOC ${_MMA_FIND_DOC}
			NO_DEFAULT_PATH)
	endif()
endmacro()

macro(find_wolfram_language_on_path)
	find_program(WolframLanguage_EXE
		NAMES ${_MMA_FIND_NAMES}
		PATH_SUFFIXES ${_MMA_FIND_SUFFIXES}
		DOC ${_MMA_FIND_DOC})
endmacro()

function(find_wolfram_language_in_default_dir)
	get_default_wolfram_dirs(_DEFAULT_DIRS)
	find_program(WolframLanguage_EXE
		NAMES ${_MMA_FIND_NAMES}
		HINTS ${_DEFAULT_DIRS}
		PATH_SUFFIXES ${_MMA_FIND_SUFFIXES}
		DOC ${_MMA_FIND_DOC}
		NO_DEFAULT_PATH
		NAMES_PER_DIR)
endfunction()

# Locate wolframscript executable, preferably within WolframLanguage_INSTALL_DIR, if defined
function(find_wolframscript)
	set(CMAKE_FIND_APPBUNDLE NEVER)

	find_program(WolframLanguage_wolframscript_EXE
		NAMES wolframscript
		HINTS ${WolframLanguage_INSTALL_DIR}
		PATH_SUFFIXES ${_MMA_FIND_SUFFIXES}
		DOC "Path to wolframscript executable."
		NO_DEFAULT_PATH)
endfunction()

###############################################################################
# Action starts here
###############################################################################

# First, respect user-provided hints
find_wolfram_language_from_hint()

# If no hint provided, look for the environment variable MATHEMATICA_HOME
if(NOT WolframLanguage_EXE)
	find_wolfram_language_from_env()
endif()

# If no hint or env variable set, search default installation directories
if(NOT WolframLanguage_EXE)
	find_wolfram_language_in_default_dir()
endif()

# Finally, try looking for WolframLanguage on the system path and wherever CMake looks by default
if(NOT WolframLanguage_EXE)
	find_wolfram_language_on_path()
endif()

if (WolframLanguage_EXE)
	get_filename_component(WolframLanguage_EXE_REALPATH ${WolframLanguage_EXE} REALPATH)

	get_filename_component(WolframLanguage_EXE_DIRECTORY ${WolframLanguage_EXE_REALPATH} DIRECTORY)

	if(WIN32)
		# On Windows executables are in the installation directory
		set(_WolframLanguage_DIRECTORY ${WolframLanguage_EXE_DIRECTORY})
	else()
		# Jump one level up from the Executables directory
		get_filename_component(_WolframLanguage_DIRECTORY ${WolframLanguage_EXE_DIRECTORY} DIRECTORY)
	endif()

	parse_wolfram_language_version(${_WolframLanguage_DIRECTORY} WolframLanguage_VERSION)

	set(WolframLanguage_INSTALL_DIR ${_WolframLanguage_DIRECTORY} CACHE PATH "Path to the root folder of WolframLanguage installation." FORCE)
endif()

foreach(_COMP IN LISTS WolframLanguage_FIND_COMPONENTS)
	if(_COMP STREQUAL "WolframLibrary")
		find_package(WolframLibrary ${_MMA_FIND_QUIETLY})
		set(WolframLanguage_${_COMP}_FOUND ${WolframLibrary_FOUND})
	elseif(_COMP STREQUAL "WSTP")
		find_package(WSTP ${_MMA_FIND_QUIETLY})
		set(WolframLanguage_${_COMP}_FOUND ${WSTP_FOUND})
	elseif(_COMP STREQUAL "wolframscript")
		find_wolframscript(WolframLanguage_wolframscript_EXE)
		if(EXISTS ${WolframLanguage_wolframscript_EXE})
			set(WolframLanguage_${_COMP}_FOUND TRUE)
		else()
			set(WolframLanguage_${_COMP}_FOUND FALSE)
		endif()
	else()
		if(NOT WolframLanguage_FIND_QUIETLY)
			message(WARNING "Unknown WolframLanguage component \"${_COMP}\" requested.")
		endif()
		set(WolframLanguage_${_COMP}_FOUND FALSE)
	endif()
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WolframLanguage
		REQUIRED_VARS
			WolframLanguage_EXE
		VERSION_VAR
			WolframLanguage_VERSION
		FAIL_MESSAGE
			"Could not find WolframLanguage, please set the path to WolframLanguage installation folder in the variable WolframLanguage_INSTALL_DIR"
		HANDLE_COMPONENTS)
