# Generate QML module
add_executable(dim
)

# Set target properties
set_target_properties(dim PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)


ecm_add_qml_module(dim
    URI com.dervox.dim
    VERSION 1.0
)

# Declare QML sources grouped by functionality
set(DIM_QML_PAGES
    contents/ui/Main.qml
    # User related pages
    contents/ui/pages/user/Login.qml
    contents/ui/pages/user/Signup.qml
    contents/ui/pages/user/Profile.qml
    # Main pages
    contents/ui/pages/Welcome.qml
    contents/ui/pages/AboutApp.qml
    contents/ui/pages/Settings.qml
    contents/ui/pages/NoPage.qml
    contents/ui/pages/ApiStatusHandler.qml
    # Product pages
    contents/ui/pages/product/Products.qml
    contents/ui/pages/product/ProductDetails.qml
    contents/ui/pages/product/Barcode.qml
    contents/ui/pages/product/BarcodePrint.qml
    contents/ui/pages/product/ProductImageEditor.qml
    contents/ui/pages/product/ImageFileDialog.qml
    contents/ui/pages/product/ImageBannerCard.qml
    contents/ui/pages/product/CategoriesSettings.qml
    # Activity log pages
    contents/ui/pages/activitylog/ActivityLog.qml
    # Supplier pages
    contents/ui/pages/supplier/Supplier.qml
    contents/ui/pages/supplier/SupplierDetails.qml
    # Cash source pages
    contents/ui/pages/cashsource/CashSource.qml
    contents/ui/pages/cashsource/CashSourceDetails.qml
    contents/ui/pages/cashsource/TransactionDialog.qml
    contents/ui/pages/cashsource/TransferDialog.qml
    # Cash transaction pages
    contents/ui/pages/cashTransaction/CashTransaction.qml
    contents/ui/pages/cashTransaction/CashTransactionDetails.qml
    # Purchase pages
    contents/ui/pages/purchase/Purchase.qml
    contents/ui/pages/purchase/PurchaseDetails.qml
    contents/ui/pages/purchase/ProductSelectorDialog.qml
    # Client pages
    contents/ui/pages/client/Client.qml
    contents/ui/pages/client/ClientDetails.qml
    contents/ui/pages/client/ClientSalesDialog.qml
    contents/ui/pages/client/ClientPaymentsDialog.qml
    contents/ui/pages/client/ClientStatisticsDialog.qml
    # Sale pages
    contents/ui/pages/sale/Sale.qml
    contents/ui/pages/sale/SaleDetails.qml
    contents/ui/pages/sale/ProductSelectorDialog.qml
    # Invoice pages
    contents/ui/pages/invoice/Invoice.qml
    contents/ui/pages/invoice/InvoiceDetails.qml
    contents/ui/pages/invoice/AddPaymentDialog.qml
    contents/ui/pages/invoice/InvoiceItemDialog.qml
    contents/ui/pages/invoice/ViewPdfDialog.qml
    contents/ui/pages/invoice/InvoiceSummaryCard.qml
    # Dashboard pages
    contents/ui/pages/dashboard/Dashboard.qml
    contents/ui/pages/dashboard/LineChartCard.qml
    contents/ui/pages/dashboard/StatsCard.qml
    contents/ui/pages/dashboard/TopItemsCard.qml
    contents/ui/pages/dashboard/DateRangeSelector.qml
    contents/ui/pages/dashboard/PieChartCard.qml
    # Quick sale pages
    contents/ui/pages/quickSalePage/QuickSalePage.qml
    contents/ui/pages/quickSalePage/QuickSaleTabContent.qml
    contents/ui/pages/quickSalePage/FavoriteProductsSettings.qml
    contents/ui/pages/quickSalePage/SharedFavoritesGrid.qml
    contents/ui/pages/quickSalePage/CashSourceSettings.qml
    # Team pages
    contents/ui/pages/team/TeamDialog.qml
    contents/ui/pages/team/TeamImageEditor.qml
    contents/ui/pages/team/TeamImageBannerCard.qml
    contents/ui/pages/team/ImageFileDialog.qml
)

set(DIM_QML_COMPONENTS
    contents/ui/components/VNavigationTabBar.qml
    contents/ui/components/DNotification.qml
    contents/ui/components/SkeletonLoaders.qml
    contents/ui/components/PaginationBar.qml
    contents/ui/components/DFormTextFieldDelegate.qml
    contents/ui/components/DKTableView.qml
    contents/ui/components/DKTableViewAbstract.qml
    contents/ui/components/DStatusBadge.qml
    contents/ui/components/DSearchableComboBox.qml
    contents/ui/components/DSearchableComboBoxClient.qml
    contents/ui/components/DSearchableComboBoxCashSource.qml
    contents/ui/components/NumPad.qml
)
set(DIM_QML_UTILS
    utils/PDFView.qml

)
set(DIM_CPP_SOURCES
    main.cpp
    # API sources
    api/abstractapi.cpp
    api/userapi.cpp
    api/subscriptionapi.cpp
    api/productapi.cpp
    api/activitylogapi.cpp
    api/supplierapi.cpp
    api/cashsourceapi.cpp
    api/saleapi.cpp
    api/purchaseapi.cpp
    api/clientapi.cpp
    api/invoiceapi.cpp
    api/cashtransactionapi.cpp
    api/dashboardanalyticsapi.cpp
    api/teamapi.cpp
    # Model sources
    model/productmodel.cpp
    model/productunitmodel.cpp
    model/barcodemodel.cpp
    model/activitylogmodel.cpp
    model/salemodel.cpp
    model/purchasemodel.cpp
    model/clientmodel.cpp
    model/suppliermodel.cpp
    model/cashsourcemodel.cpp
    model/cashtransactionmodel.cpp
    model/invoicemodel.cpp
    model/dashboardmodel.cpp
    model/productmodelFetch.cpp
    model/clientmodelfetch.cpp
    model/cashsourcemodelfetch.cpp
    model/cashsourceproxymodel.cpp
    # Utils sources
    utils/pageImageProvider.cpp
    utils/pdfModel.cpp
    utils/favoritemanager.cpp
    utils/appsettings.cpp
    # Other sources
    colorschememanager.cpp
    printer.cpp
    printerhelper.cpp
)

set(DIM_HEADERS
    # API headers
    api/abstractapi.h
    api/userapi.h
    api/subscriptionapi.h
    api/productapi.h
    api/activitylogapi.h
    api/supplierapi.h
    api/cashsourceapi.h
    api/saleapi.h
    api/purchaseapi.h
    api/clientapi.h
    api/invoiceapi.h
    api/cashtransactionapi.h
    api/dashboardanalyticsapi.h
    api/teamapi.h
    # Model headers
    model/productmodel.h
    model/productunitmodel.h
    model/barcodemodel.h
    model/activitylogmodel.h
    model/salemodel.h
    model/purchasemodel.h
    model/clientmodel.h
    model/suppliermodel.h
    model/cashsourcemodel.h
    model/cashtransactionmodel.h
    model/invoicemodel.h
    model/dashboardmodel.h
    model/productmodelFetch.h
    model/clientmodelfetch.h
    model/cashsourcemodelfetch.h
    model/cashsourceproxymodel.h
    # Utils headers
    utils/pageImageProvider.h
    utils/pdfModel.h
    utils/favoritemanager.h
    utils/appsettings.h
    # Other headers
    colorschememanager.h
    printer.h
    printerhelper.h
)

# Add QML resources
qt_target_qml_sources(dim
    QML_FILES
    ${DIM_QML_PAGES}
    ${DIM_QML_COMPONENTS}
    ${DIM_QML_UTILS}
    RESOURCES
    contents/ui/resources/logo.svg
)

# Add C++ sources
target_sources(dim PRIVATE
    ${DIM_CPP_SOURCES}
    ${DIM_HEADERS}
)

# Define logging categories if needed
# ecm_qt_declare_logging_category(dim
#     HEADER "dim_logging.h"
#     IDENTIFIER "DIM_GENERAL"
#     CATEGORY_NAME "org.kde.dim"
#     DESCRIPTION "Dim Application"
#     DEFAULT_SEVERITY Info
#     EXPORT DIM
# )


# Include directories
target_include_directories(dim PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/api
    ${CMAKE_CURRENT_SOURCE_DIR}/model
    ${CMAKE_CURRENT_SOURCE_DIR}/utils
)

# Link libraries
target_link_libraries(dim
    PRIVATE
    Qt::Core
    Qt::Quick
    Qt::QuickControls2
    Qt::Network
    Qt::Concurrent
    Qt::PrintSupport
    Qt::Svg
    KF6::Kirigami
    KF6::I18n
    KF6::CoreAddons
    KF6::ColorScheme
    KF6::IconThemes
    KF6::Prison
    KF6::QuickCharts
)

# Optional Poppler support
if(Poppler_FOUND)
    target_link_libraries(dim PRIVATE Poppler::Qt6)
endif()

# PrintSupport conditional compilation
if(Qt6PrintSupport_FOUND)
    target_link_libraries(dim PRIVATE Qt6::PrintSupport)
else()
    target_compile_definitions(dim PRIVATE QT_NO_PRINTER)
endif()

# Android specific settings
if(ANDROID)
    target_link_libraries(dim PRIVATE Qt::Svg)

    # Add Android-specific icons
    kirigami_package_breeze_icons(ICONS
        "configure"
        "dialog-ok"
        "document-edit"
        "list-add"
        "edit-delete"
        # Add more icons as needed
    )

ecm_add_android_apk(dim ANDROID_DIR ${CMAKE_SOURCE_DIR}/android)
endif()

# Installation
install(TARGETS dim
    ${KF6_INSTALL_TARGETS_DEFAULT_ARGS}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install icons for non-Android platforms
if(NOT ANDROID)
    install(DIRECTORY icons/
        DESTINATION ${KDE_INSTALL_ICONDIR}/hicolor/scalable/apps
    )
endif()
