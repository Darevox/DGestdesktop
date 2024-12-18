cmake_minimum_required(VERSION 3.16)

project(DGest VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)


find_package(ECM   REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})

find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2 Network Pdf Concurrent)
find_package(KF6  REQUIRED COMPONENTS Kirigami
    I18n
    CoreAddons
    ColorScheme
    IconThemes
    StatusNotifierItem
    Prison
    QuickCharts
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
    SOURCES api/activitylogapi.h api/activitylogapi.cpp
    SOURCES model/activitylogmodel.h model/activitylogmodel.cpp
    QML_FILES contents/ui/pages/activitylog/ActivityLog.qml
    SOURCES api/supplierapi.h api/supplierapi.cpp
    SOURCES api/cashsourceapi.h api/cashsourceapi.cpp
    SOURCES api/saleapi.h api/saleapi.cpp
    SOURCES api/purchaseapi.h api/purchaseapi.cpp
    SOURCES api/clientapi.h api/clientapi.cpp
    SOURCES api/invoiceapi.h api/invoiceapi.cpp
    SOURCES api/cashtransactionapi.h api/cashtransactionapi.cpp
    SOURCES model/salemodel.h model/salemodel.cpp
    SOURCES model/purchasemodel.h model/purchasemodel.cpp
    SOURCES model/clientmodel.h model/clientmodel.cpp
    SOURCES model/suppliermodel.h model/suppliermodel.cpp
    SOURCES model/cashsourcemodel.h model/cashsourcemodel.cpp
    SOURCES model/cashtransactionmodel.h model/cashtransactionmodel.cpp
    SOURCES model/invoicemodel.h model/invoicemodel.cpp
    QML_FILES contents/ui/pages/supplier/Supplier.qml
    QML_FILES contents/ui/pages/supplier/SupplierDetails.qml
    QML_FILES contents/ui/pages/cashsource/CashSource.qml
    QML_FILES contents/ui/pages/cashsource/CashSourceDetails.qml
    QML_FILES contents/ui/pages/cashsource/TransactionDialog.qml
    QML_FILES contents/ui/pages/cashsource/TransferDialog.qml
    QML_FILES contents/ui/components/DKTableViewAbstract.qml
    QML_FILES contents/ui/pages/cashTransaction/CashTransaction.qml
    QML_FILES contents/ui/pages/cashTransaction/CashTransactionDetails.qml
    QML_FILES contents/ui/pages/purchase/Purchase.qml
    QML_FILES contents/ui/pages/purchase/PurchaseDetails.qml
    QML_FILES contents/ui/pages/purchase/ProductSelectorDialog.qml
    QML_FILES contents/ui/pages/client/Client.qml
    QML_FILES contents/ui/pages/client/ClientDetails.qml
    QML_FILES contents/ui/pages/client/ClientSalesDialog.qml
    QML_FILES contents/ui/pages/client/ClientPaymentsDialog.qml
    QML_FILES contents/ui/pages/client/ClientStatisticsDialog.qml
    QML_FILES contents/ui/pages/sale/Sale.qml
    QML_FILES contents/ui/pages/sale/SaleDetails.qml
    QML_FILES contents/ui/pages/sale/ProductSelectorDialog.qml
    QML_FILES contents/ui/pages/invoice/Invoice.qml
    QML_FILES contents/ui/pages/invoice/InvoiceDetails.qml
    QML_FILES contents/ui/pages/invoice/AddPaymentDialog.qml
    QML_FILES contents/ui/pages/invoice/InvoiceItemDialog.qml
    QML_FILES contents/ui/pages/invoice/ViewPdfDialog.qml
    QML_FILES contents/ui/pages/invoice/InvoiceSummaryCard.qml
    SOURCES api/dashboardanalyticsapi.h api/dashboardanalyticsapi.cpp
    SOURCES model/dashboardmodel.h model/dashboardmodel.cpp
    QML_FILES contents/ui/pages/dashboard/LineChartCard.qml
    QML_FILES contents/ui/pages/dashboard/StatsCard.qml
    QML_FILES contents/ui/pages/dashboard/TopItemsCard.qml
    QML_FILES contents/ui/pages/dashboard/DateRangeSelector.qml
    QML_FILES contents/ui/pages/dashboard/Dashboard.qml
    QML_FILES contents/ui/pages/dashboard/PieChartCard.qml
    QML_FILES contents/ui/components/DStatusBadge.qml
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
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network Qt6::Pdf  Qt6::Concurrent
    KF6::Kirigami
    KF6::I18n
    KF6::CoreAddons
    KF6::ColorScheme
    KF6::IconThemes
    KF6::StatusNotifierItem
    KF6::Prison
    KF6::QuickCharts

)

include(GNUInstallDirs)
install(TARGETS DGestapp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
