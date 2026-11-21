cmake_minimum_required(VERSION 3.16)

project(immanip VERSION 0.1.0 DESCRIPTION "A C image manipulation library" LANGUAGES C)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(CTest)

add_library(immanip SHARED src/immanip.c)
add_library(immanip::immanip ALIAS immanip)
target_compile_features(immanip PUBLIC c_std_99)
target_compile_definitions(immanip PRIVATE IMMANIP_VERSION="${PROJECT_VERSION}")
target_include_directories(immanip PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
set_target_properties(immanip PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR})

if(BUILD_TESTING)
    add_executable(immanip_test tests/test_immanip.c)
    target_link_libraries(immanip_test PRIVATE immanip::immanip)
    add_test(NAME immanip_test COMMAND immanip_test)
endif()

set(immanip_cmake_dir "${CMAKE_INSTALL_LIBDIR}/cmake/immanip")
configure_package_config_file(cmake/immanip-config.cmake.in
    "${PROJECT_BINARY_DIR}/immanip-config.cmake"
    INSTALL_DESTINATION "${immanip_cmake_dir}")
write_basic_package_version_file("${PROJECT_BINARY_DIR}/immanip-config-version.cmake"
    VERSION ${PROJECT_VERSION} COMPATIBILITY SameMajorVersion)
file(RELATIVE_PATH immanip_pc_prefix "${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig"
    "${CMAKE_INSTALL_PREFIX}")
configure_file(cmake/immanip.pc.in "${PROJECT_BINARY_DIR}/immanip.pc" @ONLY)

install(TARGETS immanip EXPORT immanip-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT Runtime
            NAMELINK_COMPONENT Development
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT Development
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT Runtime)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} COMPONENT Development)
install(EXPORT immanip-targets NAMESPACE immanip::
    DESTINATION "${immanip_cmake_dir}" COMPONENT Development)
install(FILES "${PROJECT_BINARY_DIR}/immanip-config.cmake"
              "${PROJECT_BINARY_DIR}/immanip-config-version.cmake"
    DESTINATION "${immanip_cmake_dir}" COMPONENT Development)
install(FILES "${PROJECT_BINARY_DIR}/immanip.pc"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig" COMPONENT Development)
install(FILES LICENSE DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/libimmanip0"
    RENAME copyright COMPONENT Runtime)

set(CPACK_PACKAGE_CONTACT "Immanip maintainers <rafael.a.diazcruz.dev@brulent.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_GENERATOR "DEB")
set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_COMPONENTS_ALL Runtime Development)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_RUNTIME_PACKAGE_NAME libimmanip0)
set(CPACK_DEBIAN_DEVELOPMENT_PACKAGE_NAME libimmanip-dev)
set(CPACK_DEBIAN_DEVELOPMENT_PACKAGE_DEPENDS "libimmanip0 (= ${PROJECT_VERSION})")
set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_SOURCE_IGNORE_FILES "/[.]git/;^${PROJECT_SOURCE_DIR}/build[^/]*/;^${PROJECT_SOURCE_DIR}/dist/")
include(CPack)
