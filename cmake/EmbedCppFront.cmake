if( NOT TARGET cppfront::artifacts AND NOT TARGET cppfront::compiler )

include( FetchContent )
include( GNUInstallDirs )

set( CPPFRONT_REVISION "main" CACHE STRING "The git branch, tag, or commit hash to be checked out after clone" )
set( CPPFRONT_REPOSITORY "git@github.com:hsutter/cppfront.git" CACHE STRING "The cppfront repository URL to clone from" )

if( IN_GCMAKE_CONTEXT )
  string( SHA1 repo_hash "${CPPFRONT_REPOSITORY}" )
  string( MAKE_C_IDENTIFIER "${repo_hash}" repo_hash )
  set( repo_destination_dir "${GCMAKE_DEP_CACHE_DIR}/cppfront_repo/git_repo/${repo_hash}" )

  if( NOT IS_DIRECTORY "${repo_destination_dir}" )
    FetchContent_Declare( _cached_cppfront_repo
      GIT_REPOSITORY "${CPPFRONT_REPOSITORY}"
      GIT_TAG "${CPPFRONT_REVISION}"
      GIT_PROGRESS ON
      SOURCE_DIR "${repo_destination_dir}"
    )

    FetchContent_GetProperties( _cached_cppfront_repo )
    if( NOT _cached_cppfront_repo_POPULATED )
      message( "Caching cppfront main repository..." )
      FetchContent_Populate( _cached_cppfront_repo )
    endif()
  endif()

  set( repo_cloning_from "${repo_destination_dir}" )
else()
  set( repo_cloning_from "${CPPFRONT_REPOSITORY}" )
endif()

FetchContent_Declare( cppfront_original_repo
  GIT_REPOSITORY "${repo_cloning_from}"
  GIT_TAG "${CPPFRONT_REVISION}"
  GIT_PROGRESS ON
  SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dep/cppfront_original_repo"
)

FetchContent_GetProperties( cppfront_original_repo )
if( NOT cppfront_original_repo_POPULATED )
  FetchContent_Populate( cppfront_original_repo )

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

    if (MINGW)
      message( WARNING "
        As of commit 8dd89ec8c9cfe9633286b2768ad0404455e342c7 (https://github.com/hsutter/cppfront/commit/8dd89ec8c9cfe9633286b2768ad0404455e342c7),
        the latest MinGW ld.exe (GNU binutils 2.40) distributed by msys2 fails to link cppfront.exe when
        compiling with optimizations off (Debug mode). If you're building in Debug mode with MinGW g++,
        you must use the `-fuse-ld=lld` flag to use LLVM's lld linker in place of ld (need to install Clang
        first).

        If using GCMake, set the CMake options -DGCMAKE_ADDITIONAL_COMPILER_FLAGS='fuse-ld=lld' and
        -DGCMAKE_ADDITIONAL_LINK_TIME_FLAGS='-fuse-ld=lld'. Otherwise, set the CMake option
        -DCPPFRONT_ADDITIONAL_COMPILER_FLAGS='-fuse-ld=lld'.
      ")
    endif()

    if (IN_GCMAKE_CONTEXT)
      initialize_build_config_vars()
      foreach( config_name IN ITEMS "Debug" "Release" "MinSizeRel" "RelWithDebInfo" )
        string( TOUPPER config_name upper_config_name )
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