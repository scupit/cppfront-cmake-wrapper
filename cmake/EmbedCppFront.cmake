if( NOT TARGET cppfront::artifacts AND NOT TARGET cppfront::compiler )

include( FetchContent )
include( GNUInstallDirs )

set( CPPFRONT_REVISION "main" CACHE STRING "The git branch, tag, or commit hash to be checked out after clone" )

FetchContent_Declare( cppfront
  GIT_REPOSITORY "git@github.com:hsutter/cppfront.git"
  GIT_TAG "${CPPFRONT_REVISION}"
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dep/cppfront"
)

FetchContent_GetProperties( cppfront )
if( NOT cppfront_POPULATED )
  FetchContent_Populate( cppfront )

  if( NOT TARGET cppfront::artifacts )
    
    add_library( cppfront_artifacts INTERFACE )
    add_library( cppfront::artifacts ALIAS cppfront_artifacts )

    target_include_directories( cppfront_artifacts
      INTERFACE
        "$<BUILD_INTERFACE:${cppfront_SOURCE_DIR}/source>"
        "$<BUILD_INTERFACE:${cppfront_SOURCE_DIR}/include>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
    )

    target_compile_features( cppfront_artifacts
      INTERFACE cxx_std_20
    )

    target_compile_options( cppfront_artifacts
      INTERFACE
        "$<$<BOOL:${MSVC}>:/EHsc>"
    )
  endif()

  if( NOT TARGET cppfront::compiler )
    add_executable( cppfront )
    add_executable( cppfront::compiler ALIAS cppfront )

    target_sources( cppfront
      PRIVATE 
        "${cppfront_SOURCE_DIR}/source/cppfront.cpp"
    )
    
    # Inherits configuration required by cppfront::artifacts, such as C++20
    target_link_libraries( cppfront PRIVATE cppfront::artifacts )

    # The build instructions at
    # https://github.com/hsutter/cppfront#how-do-i-build-cppfront
    # specify this MSVC flag.
    target_compile_options( cppfront
      PRIVATE
        "$<$<BOOL:${MSVC}>:/EHsc>"
    )
  endif()
endif()

endif()