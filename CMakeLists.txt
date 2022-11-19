# 3.23 required for FILE_SET
cmake_minimum_required( VERSION 3.23 )

project( cppfront
  LANGUAGES CXX
  VERSION "0.0.1"
)

get_property( usingMultiConfigGenerator GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG )

set( VALID_BUILD_TYPES Release Debug )
if( usingMultiConfigGenerator )
  set( CMAKE_CONFIGURATION_TYPES ${VALID_BUILD_TYPES} )
else()
	set_property( CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${VALID_BUILD_TYPES} )

  if( NOT "${CMAKE_BUILD_TYPE}" IN_LIST VALID_BUILD_TYPES )
		set( CMAKE_BUILD_TYPE "Release" CACHE STRING "Picks either Debug or Release configuration" FORCE )
	endif()
endif()

include( cmake/EmbedCppFront.cmake )

set_target_properties( cppfront cppfront_headers
  PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "bin/$<CONFIG>"
    PDB_OUTPUT_DIRECTORY "bin/$<CONFIG>"
)

if( CPPFRONT_INSTALL )
  set( _cppfront_name_prefix "cppfront" )
  install( TARGETS cppfront_headers cppfront
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

  # TODO: Allow configuration of COMPATIBILITY
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
