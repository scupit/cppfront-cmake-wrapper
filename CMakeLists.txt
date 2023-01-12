# 3.24 is required for GLOBAL find_package.
# I'll have to test which early versions work when embedding it though.
cmake_minimum_required( VERSION 3.24 )

project( cppfront-wrapper
  LANGUAGES CXX
  VERSION "0.0.1"
)

option( EMBED_CPPFRONT "When ON, clones and builds cppfront. When OFF, searches for an existing cppfront installation using find_package." ON )
option( CPPFRONT_INSTALL "Generates installation configuration when set to ON." ${PROJECT_IS_TOP_LEVEL} )
option( CPPFRONT_BUILD_EXAMPLE "Builds the cppfront-wrapper example project." ${PROJECT_IS_TOP_LEVEL} )

if( NOT EMBED_CPPFRONT )
  list( APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" )
  find_package( cppfront MODULE REQUIRED GLOBAL )
else()
  get_property( usingMultiConfigGenerator GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG )
  set( VALID_BUILD_TYPES Release Debug MinSizeRel RelWithDebInfo )

  if( usingMultiConfigGenerator )
    set( CMAKE_CONFIGURATION_TYPES ${VALID_BUILD_TYPES} )
  else()
    set_property( CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${VALID_BUILD_TYPES} )

    # Don't force-reset the build type if using already using a build type which may
    # be valid for other projects. 
    if( NOT "${CMAKE_BUILD_TYPE}" IN_LIST VALID_BUILD_TYPES )
      set( CMAKE_BUILD_TYPE "Release" CACHE STRING "Picks either Debug or Release configuration" FORCE )
    endif()
  endif()

  include( cmake/EmbedCppFront.cmake )

  if( NOT IN_GCMAKE_CONTEXT )
    set_target_properties( cppfront cppfront_artifacts
      PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/$<CONFIG>"
        PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/$<CONFIG>"
    )
  endif()

  if( CPPFRONT_INSTALL AND NOT IN_GCMAKE_CONTEXT )
    set( _cppfront_name_prefix "cppfront" )
    install( TARGETS cppfront_artifacts cppfront
      EXPORT ${_cppfront_name_prefix}Targets
      RUNTIME
        DESTINATION "${CMAKE_INSTALL_BINDIR}"
        PERMISSIONS
          OWNER_READ OWNER_WRITE OWNER_EXECUTE 
          GROUP_READ GROUP_EXECUTE
          WORLD_READ
      ARCHIVE
        DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    )

    install( DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/dep/cppfront/include/"
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
    )

    install( EXPORT ${_cppfront_name_prefix}Targets
      FILE ${_cppfront_name_prefix}Targets.cmake
      DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${_cppfront_name_prefix}"
    )

    include( CMakePackageConfigHelpers )

    configure_package_config_file( "${CMAKE_CURRENT_SOURCE_DIR}/Config.cmake.in"
      "${CMAKE_CURRENT_BINARY_DIR}/${_cppfront_name_prefix}Config.cmake"
      INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake"
    )

    write_basic_package_version_file(
      "${CMAKE_CURRENT_BINARY_DIR}/${_cppfront_name_prefix}ConfigVersion.cmake"
      VERSION "${PROJECT_VERSION}"
      COMPATIBILITY AnyNewerVersion
    )

    install( FILES 
      "${CMAKE_CURRENT_BINARY_DIR}/${_cppfront_name_prefix}Config.cmake"
      "${CMAKE_CURRENT_BINARY_DIR}/${_cppfront_name_prefix}ConfigVersion.cmake"
      DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${_cppfront_name_prefix}"
    )

    export( EXPORT ${_cppfront_name_prefix}Targets
      FILE "${CMAKE_CURRENT_BINARY_DIR}/${_cppfront_name_prefix}Targets.cmake"
    )
  endif()
endif()

if( CPPFRONT_BUILD_EXAMPLE )
  add_subdirectory( "${CMAKE_CURRENT_SOURCE_DIR}/example" )
endif()