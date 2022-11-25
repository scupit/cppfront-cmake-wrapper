# Hints:
#  - CPPFRONT_ROOT
#  - CPPFRONT_NO_CMAKE
# 
# Targets:
#   - cppfront::compiler
#   - cppfront::artifacts

include( FindPackageHandleStandardArgs )

if( TARGET cppfront::compiler AND TARGET cppfront::artifacts  ) # Begin Guard
  # We only define the cppfront::compiler and cppfront::artifacts targets, so just
  # use the existing ones if they are already found.
  find_package_handle_standard_args( cppfront )
else()
  if( CMAKE_CROSSCOMPILING )
    # When cross compiling, we should be able to look for the include directory/headers
    # on the system because cppfront only runs at build time anyways.
    set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )
    
    # Same as above. The compiler will always run on the host system, and generates platform-agnostic
    # files. Cross-compilation shouldn't affect this.
    set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
    set( CMAKE_FIND_ROOT_PATH_MODE_PACKAGE NEVER )
  endif()

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
      "$ENV{ProgramFiles}/cppfront-wrapper"
      "$ENV{ProgramFiles${_cppfront_x86}}/cppfront"
      "$ENV{ProgramFiles${_cppfront_x86}}/cppfront-wrapper"
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

    find_package_handle_standard_args( cppfront
      REQUIRED_VARS CPPFRONT_INCLUDE_DIR _cppfront_exe
    )

    if( NOT TARGET cppfront::artifacts )
      add_library( cppfront_artifacts INTERFACE IMPORTED )
      add_library( cppfront::artifacts ALIAS cppfront_artifacts )

      target_include_directories( cppfront_artifacts
        INTERFACE "${CPPFRONT_INCLUDE_DIR}"
      )

      target_compile_features( cppfront_artifacts
        INTERFACE cxx_std_20
      )

      target_compile_options( cppfront_artifacts
        INTERFACE "$<$<BOOL:${MSVC}>:/EHsc>"
      )
    endif()

    if( NOT TARGET cppfront::compiler )
      add_executable( cppfront_compiler IMPORTED )
      add_executable( cppfront::compiler ALIAS cppfront_compiler )

      set_target_properties( cppfront_compiler
        PROPERTIES
          IMPORTED_LOCATION "${_cppfront_exe}"
      )
    endif()
  endif()
endif() # End guard
