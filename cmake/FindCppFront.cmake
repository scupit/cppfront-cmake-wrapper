# Hints:
#  - CPPFRONT_ROOT
#  - CPPFRONT_NO_CMAKE
# 
# Targets:
#   - cppfront::compiler
#   - cppfront::headers

if( NOT TARGET cppfront::compiler AND NOT TARGET cppfront::headers ) # Begin guard

set( _cppfront_search )

if( CPPFRONT_ROOT )
  unset( cppfront_DIR CACHE )
  unset( CPPFRONT_INCLUDE_DIR CACHE )
  unset( _cppfront_exe CACHE )
  set( _cppfront_root_search PATHS "${CPPFRONT_ROOT}" NO_DEFAULT_PATH )
  list( APPEND _cppfront_search _cppfront_root_search )
endif()

set( _cppfront_x86 "(x86)" )
set( _cppfront_main_search
  PATHS
    "$ENV{ProgramFiles}/cppfront"
    "$ENV{ProgramFiles${_cppfront_x86}}/cppfront"
)
unset( _cppfront_x86 )

list( APPEND _cppfront_search _cppfront_main_search )

if( NOT CPPFRONT_NO_CMAKE )
  foreach( search IN LISTS _cppfront_search )
    find_package( cppfront QUIET CONFIG
      ${${search}}
    )

    if( cppfront_FOUND )
      break()
    endif()
  endforeach()
endif()

if( NOT cppfront_FOUND )
  foreach( search IN LISTS _cppfront_search )
    find_path( CPPFRONT_INCLUDE_DIR
      NAMES "cpp2util.h"
      ${${search}}
      PATH_SUFFIXES "include"
    )

    find_program( _cppfront_exe
      NAMES "cppfront"
      NAMES_PER_DIR
      ${${search}}
      PATH_SUFFIXES "bin"
    )
  endforeach()

  mark_as_advanced( CPPFRONT_INCLUDE_DIR _cppfront_exe )

  include( FindPackageHandleStandardArgs )
  find_package_handle_standard_args( cppfront
    REQUIRED_VARS CPPFRONT_INCLUDE_DIR _cppfront_exe
  )

  if( NOT TARGET cppfront::headers )
    add_library( cppfront::headers INTERFACE IMPORTED )

    target_include_directories( cppfront::headers
      INTERFACE "${CPPFRONT_INCLUDE_DIR}"
    )

    target_compile_features( cppfront::headers
      INTERFACE cxx_std_20
    )
  endif()

  if( NOT TARGET cppfront::compiler )
    add_executable( cppfront::compiler IMPORTED )
    set_target_properties( cppfront::compiler
      PROPERTIES
        IMPORTED_LOCATION "${_cppfront_exe}"
    )
  endif()
endif()

endif() # End guard
