if( NOT TARGET cppfront::artifacts AND NOT TARGET cppfront::compiler )

include( FetchContent )
include( GNUInstallDirs )

set( CPPFRONT_REVISION "main" CACHE STRING "The git branch, tag, or commit hash to be checked out after clone" )
set( CPPFRONT_REPOSITORY "git@github.com:hsutter/cppfront.git" CACHE STRING "The cppfront repository URL to clone from" )

if( IN_GCMAKE_CONTEXT )
  message( "Downloading main cppfront repository..." )

  CPMAddPackage(
    NAME cppfront_original_repo
    DOWNLOAD_ONLY TRUE
    GIT_REPOSITORY "${CPPFRONT_REPOSITORY}"
    GIT_TAG "${CPPFRONT_REVISION}"
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dep/cppfront_original_repo"
  )
else()
  FetchContent_Declare( cppfront_original_repo
    GIT_REPOSITORY "${CPPFRONT_REPOSITORY}"
    GIT_TAG "${CPPFRONT_REVISION}"
    GIT_PROGRESS ON
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dep/cppfront_original_repo"
  )
  FetchContent_GetProperties( cppfront_original_repo )
endif()

if( cppfront_original_repo_POPULATED OR cppfront_original_repo_ADDED )
  # the <dep-name>_POPULATED variable is created by FetchContent.
  if( cppfront_original_repo_POPULATED )
    FetchContent_Populate( cppfront_original_repo )
  endif()

  if( NOT TARGET cppfront::artifacts )
    add_library( cppfront_artifacts INTERFACE )
    add_library( cppfront::artifacts ALIAS cppfront_artifacts )

    target_include_directories( cppfront_artifacts
      INTERFACE
        "$<BUILD_INTERFACE:${cppfront_original_repo_SOURCE_DIR}/include>"
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
        "${cppfront_original_repo_SOURCE_DIR}/source/cppfront.cpp"
    )

    # Only the cppfront compiler will use files in source/.
    target_include_directories( cppfront
      PRIVATE
        "$<BUILD_INTERFACE:${cppfront_original_repo_SOURCE_DIR}/source>"
    )
    
    # Inherits configuration required by cppfront::artifacts, such as C++20 requirement
    # and include directory for cpputil.h.
    target_link_libraries( cppfront PRIVATE cppfront::artifacts )

    if (IN_GCMAKE_CONTEXT)
      initialize_build_config_vars()
      foreach( config_name IN ITEMS "Debug" "Release" "MinSizeRel" "RelWithDebInfo" )
        string( TOUPPER "${config_name}" upper_config_name )
        target_compile_options( cppfront PRIVATE "$<$<CONFIG:${config_name}>:${${upper_config_name}_LOCAL_COMPILER_FLAGS}>" )
        target_link_options( cppfront PRIVATE "$<$<CONFIG:${config_name}>:${${upper_config_name}_LOCAL_LINK_FLAGS}>" )
      endforeach()
    else()
      set( CPPFRONT_ADDITIONAL_COMPILER_FLAGS "" CACHE STRING "Semicolon separated list of additional flags to use when building cppfront.")
      target_compile_options( cppfront PRIVATE ${CPPFRONT_ADDITIONAL_COMPILER_FLAGS} )
      target_link_options( cppfront PRIVATE ${CPPFRONT_ADDITIONAL_COMPILER_FLAGS} )
    endif()
  endif()
endif()

endif()