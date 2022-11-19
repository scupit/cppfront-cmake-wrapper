cmake_minimum_required( VERSION 3.24 )

project( cppfront
  LANGUAGES CXX
)

include( FetchContent )
include( GNUInstallDirs )

option( CPPFRONT_INSTALL "Generates installation configuration when set to ON." ON )
set( CPPFRONT_REVISION "main" CACHE STRING "The git branch, tag, or commit hash to be checked out after clone" )

FetchContent_Declare( cppfront
  GIT_REPOSITORY "git@github.com:hsutter/cppfront.git"
  GIT_TAG "${CPPFRONT_REVISION}"
  SOURCE_DIR "dep/cppfront"
)

FetchContent_GetProperties( cppfront )
if( NOT cppfront_POPULATED )
  FetchContent_Populate( cppfront )

  if( NOT TARGET cppfront::headers )
    
    add_library( cppfront_headers INTERFACE )
    add_library( cppfront::headers ALIAS cppfront_headers )

    target_sources( cppfront_headers
      INTERFACE FILE_SET HEADERS
        "$<BUILD_INTERFACE:${cppfront_SOURCE_DIR}/include/cpputil.h>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/cpputil.h>"
    )

    target_include_directories( cppfront_headers
      INTERFACE
        "$<BUILD_INTERFACE:${cppfront_SOURCE_DIR}/source>"
        "$<BUILD_INTERFACE:${cppfront_SOURCE_DIR}/include>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
    )

    target_compile_features( cppfront_headers
      INTERFACE cxx_std_20
    )
  endif()

  if( NOT TARGET cppfront::compiler )
    add_executable( cppfront_compiler )
    add_executable( cppfront::compiler ALIAS cppfront_compiler )

    target_sources( cppfront_compiler
      PRIVATE 
        "${cppfront_SOURCE_DIR}/source/cppfront.cpp"
    )
    
    # Inherits configuration required by cppfront::headers
    target_link_libraries( cppfront_compiler PRIVATE cppfront::headers )

    # The build instructions at
    # https://github.com/hsutter/cppfront#how-do-i-build-cppfront
    # specify this MSVC flag.
    target_compile_options( cppfront_compiler
      PRIVATE
        "$<$<BOOL:${MSVC}>:/EHsc>"
    )
  endif()
endif()

if( CPPFRONT_INSTALL )
  install( TARGETS cppfront_headers cppfront_compiler
    EXPORT ${PROJECT_NAME}Targets
    RUNTIME
      DESTINATION "${CMAKE_INSTALL_BINDIR}"
      PERMISSIONS
        OWNER_READ OWNER_WRITE OWNER_EXECUTE 
        GROUP_READ GROUP_EXECUTE
        WORLD_READ
    ARCHIVE
      DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    FILE_SET HEADERS
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}" 
  )

  install( EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
  )

  include( CMakePackageConfigHelpers )

  configure_package_config_file( "${CMAKE_CURRENT_SOURCE_DIR}/Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake"
  )

  # TODO: Allow configuration of COMPATIBILITY
  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY AnyNewerVersion
  )

  install( FILES 
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
  )

  export( EXPORT ${PROJECT_NAME}Targets
    FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
  )
endif()
