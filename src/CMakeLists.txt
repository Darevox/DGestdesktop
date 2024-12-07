cmake_minimum_required(VERSION 3.16)

project(DGest VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)


find_package(ECM   REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2 Network )
find_package(KF6  REQUIRED COMPONENTS Kirigami
    I18n
    CoreAddons
    ColorScheme
    IconThemes
    StatusNotifierItem
    Prison
)
qt_standard_project_setup()
qt_policy(SET QTP0001 OLD)
qt_add_executable(DGestapp
    main.cpp
)

qt_add_qml_module(DGestapp
    URI DGest
    VERSION 1.0
    QML_FILES
    contents/ui/Main.qml
    QML_FILES contents/ui/pages/user/Login.qml
    RESOURCES contents/ui/resources/logo.svg
    SOURCES api/abstractapi.h api/abstractapi.cpp
    #SOURCES api/dgestapi.h api/dgestapi.cpp
    QML_FILES contents/ui/pages/user/Signup.qml
    QML_FILES contents/ui/pages/Welcome.qml
    QML_FILES contents/ui/components/VNavigationTabBar.qml
    QML_FILES contents/ui/pages/AboutApp.qml
    QML_FILES contents/ui/pages/Settings.qml
    SOURCES api/userapi.h api/userapi.cpp
    QML_FILES contents/ui/components/DNotification.qml
    QML_FILES contents/ui/pages/user/Profile.qml
    SOURCES colorschememanager.h colorschememanager.cpp
    QML_FILES contents/ui/components/SkeletonLoaders.qml
    QML_FILES contents/ui/pages/NoPage.qml
    QML_FILES contents/ui/pages/ApiStatusHandler.qml
    SOURCES traymanager.h traymanager.cpp
    SOURCES api/subscriptionapi.h api/subscriptionapi.cpp
    QML_FILES contents/ui/pages/ExpiredSubscription.qml
    SOURCES api/productapi.h api/productapi.cpp
    SOURCES model/productmodel.h model/productmodel.cpp
    QML_FILES contents/ui/pages/product/Products.qml
    QML_FILES contents/ui/components/PaginationBar.qml
    QML_FILES contents/ui/pages/product/ProductDetails.qml
    SOURCES model/productunitmodel.h model/productunitmodel.cpp
    QML_FILES contents/ui/components/DFormTextFieldDelegate.qml
    QML_FILES contents/ui/components/DKTableView.qml
    QML_FILES
    QML_FILES contents/ui/pages/product/Barcode.qml
    QML_FILES
    SOURCES model/barcodemodel.h model/barcodemodel.cpp
    QML_FILES contents/ui/pages/product/BarcodePrint.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(DGestapp PROPERTIES
    #    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.DGest
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(DGestapp
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network
    KF6::Kirigami
    KF6::I18n
    KF6::CoreAddons
    KF6::ColorScheme
    KF6::IconThemes
    KF6::StatusNotifierItem
    KF6::Prison

)

include(GNUInstallDirs)
install(TARGETS DGestapp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
