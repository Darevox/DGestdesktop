cmake_minimum_required(VERSION 3.16)

# Set version
set(PROJECT_VERSION "1.0.0")
project(dim VERSION ${PROJECT_VERSION})
# Define environment options
set(APP_ENV "prod" CACHE STRING "Application environment (dev/prod)")
set_property(CACHE APP_ENV PROPERTY STRINGS dev prod)

# Define API URLs based on environment
if(APP_ENV STREQUAL "dev")
    set(API_BASE_URL "http://localhost:8000")
else()
    set(API_BASE_URL "https://dim.dervox.com")
endif()
set(KF_MIN_VERSION "6.5.0")
set(QT_MIN_VERSION "6.5.0")

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

# Include required KDE build settings
include(ECMSetupVersion)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)
include(ECMQmlModule)
include(ECMAddAndroidApk)

# Setup version
ecm_setup_version(${PROJECT_VERSION}
    VARIABLE_PREFIX DIM
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/dim-version.h"
)
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY
)
# Find required Qt packages
find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Quick
    QuickControls2
    Network
    Concurrent
    PrintSupport
    Svg
)

# Find required KF6 packages
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    Kirigami
    I18n
    CoreAddons
    ColorScheme
    IconThemes
    Prison
    QuickCharts
)

# Find Poppler
find_package(Poppler COMPONENTS Qt6)
set_package_properties(Poppler PROPERTIES
    TYPE RECOMMENDED
    PURPOSE "Support for PDF file operations"
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_subdirectory(src)

# Install files
install(FILES com.dervox.dim.desktop DESTINATION ${KDE_INSTALL_APPDIR})
install(FILES com.dervox.dim.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

# Install icons
install(FILES com.dervox.dim.svg
    DESTINATION ${KDE_INSTALL_FULL_ICONDIR}/hicolor/scalable/apps
)

# Install translations
ki18n_install(po)

# Print feature summary
feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
