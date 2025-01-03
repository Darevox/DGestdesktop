#include <QApplication>  // Changed from QGuiApplication
#include <QQmlApplicationEngine>
#include <QtQml>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <QQuickStyle>
#include <Kirigami/Platform/PlatformTheme>
#include <KColorSchemeManager>
#include <QNetworkAccessManager>
#include <QLoggingCategory>
#include <KAboutData>
#include <colorschememanager.h>
#include <traymanager.h>
#include <printerhelper.h>
#include <printer.h>
#include <KIconThemes/kicontheme.h>


#include <api/userapi.h>
#include <api/subscriptionapi.h>
#include <api/productapi.h>
#include <api/activitylogapi.h>
#include <api/supplierapi.h>
#include <api/cashsourceapi.h>
#include <api/saleapi.h>
#include <api/purchaseapi.h>
#include <api/clientapi.h>
#include <api/invoiceapi.h>
#include <api/cashtransactionapi.h>
#include <api/dashboardanalyticsapi.h>


#include <model/productmodel.h>
#include <model/productunitmodel.h>
#include <model/barcodemodel.h>
#include <model/activitylogmodel.h>
#include <model/salemodel.h>
#include <model/purchasemodel.h>
#include <model/clientmodel.h>
#include <model/clientmodelfetch.h>
#include <model/suppliermodel.h>
#include <model/cashsourcemodel.h>
#include <model/cashsourcemodelfetch.h>

#include <model/cashtransactionmodel.h>
#include <model/invoicemodel.h>
#include <model/dashboardmodel.h>

#include <model/productmodelFetch.h>
#include <utils/pdfModel.h>
#include <utils/favoritemanager.h>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    KIconTheme::current();
    QApplication::setStyle("breeze");
    //   QLoggingCategory::setFilterRules("*.debug=true");
    KLocalizedString::setApplicationDomain("Managements");
    QCoreApplication::setOrganizationName(QStringLiteral("Dervox"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("Dervox.com"));
    QCoreApplication::setApplicationName(QStringLiteral("DGest"));
    qputenv("QML_XHR_ALLOW_FILE_READ", QByteArray("1"));
    qputenv("QML_XHR_ALLOW_FILE_WRITE", QByteArray("1"));
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QQmlApplicationEngine engine;
    //engine.addImportPath("qml");
    QNetworkAccessManager *networkManager = new QNetworkAccessManager();
    NetworkApi::UserApi *userapi = new NetworkApi::UserApi(networkManager);
    NetworkApi::SubscriptionApi *subscriptionApi = new NetworkApi::SubscriptionApi(networkManager);
    //  NetworkApi::ProductApi *productApi = new NetworkApi::ProductApi(networkManager);
    // NetworkApi::ProductApi *productApiFetch = new NetworkApi::ProductApi(networkManager);
    // Set shared network manager for createable instances
    NetworkApi::ProductApi::setSharedNetworkManager(networkManager);

    // Register for createable instances
    qmlRegisterType<NetworkApi::ProductApi>("com.dervox.ProductFetchApi", 1, 0, "ProductFetchApi");

    // Create singleton instance
    NetworkApi::ProductApi *productApi = new NetworkApi::ProductApi(networkManager);
     NetworkApi::ProductApi *productApiFetch = new NetworkApi::ProductApi(networkManager);

    engine.rootContext()->setContextProperty("productApi", productApi);

    NetworkApi::ActivityLogApi *activityLogApi = new NetworkApi::ActivityLogApi(networkManager);
    NetworkApi::SupplierApi *supplierApi = new NetworkApi::SupplierApi(networkManager);
    NetworkApi::CashSourceApi *cashSourceApi = new NetworkApi::CashSourceApi(networkManager);
    NetworkApi::CashSourceApi *cashSourceApiFetch = new NetworkApi::CashSourceApi(networkManager);

    NetworkApi::SaleApi *saleApi = new NetworkApi::SaleApi(networkManager);
    NetworkApi::PurchaseApi *purchaseApi = new NetworkApi::PurchaseApi(networkManager);
    NetworkApi::ClientApi *clientApi = new NetworkApi::ClientApi(networkManager);
    NetworkApi::ClientApi *clientApiFetch = new NetworkApi::ClientApi(networkManager);

    NetworkApi::InvoiceApi *invoiceApi = new NetworkApi::InvoiceApi(networkManager);
    NetworkApi::CashTransactionApi *cashTransactionApi = new NetworkApi::CashTransactionApi(networkManager);
    NetworkApi::DashboardAnalyticsApi *dashboardAnalyticsApi = new NetworkApi::DashboardAnalyticsApi(networkManager);


    NetworkApi::ProductModel *productModel = new NetworkApi::ProductModel();
    NetworkApi::ProductUnitModel *productUnitModel = new NetworkApi::ProductUnitModel();
    NetworkApi::BarcodeModel *barcodeModel = new NetworkApi::BarcodeModel();
    NetworkApi::ActivityLogModel *activityLogModel = new NetworkApi::ActivityLogModel();
    NetworkApi::SaleModel *saleModel = new NetworkApi::SaleModel();
    NetworkApi::PurchaseModel *purchaseModel = new NetworkApi::PurchaseModel();
    NetworkApi::SupplierModel *supplierModel = new NetworkApi::SupplierModel();
    NetworkApi::CashSourceModel *cashSourceModel = new NetworkApi::CashSourceModel();
    NetworkApi::CashSourceModelFetch *cashSourceModelFetch = new NetworkApi::CashSourceModelFetch();

    NetworkApi::CashTransactionModel *cashTransactionModel = new NetworkApi::CashTransactionModel();
    NetworkApi::ClientModel *clientModel = new NetworkApi::ClientModel();
    NetworkApi::ClientModelFetch *clientModelFetch = new NetworkApi::ClientModelFetch();
    NetworkApi::InvoiceModel *invoiceModel = new NetworkApi::InvoiceModel();
    NetworkApi::DashboardModel *dashboardModel = new NetworkApi::DashboardModel();

    NetworkApi::ProductModelFetch *productModelFetch = new NetworkApi::ProductModelFetch();

    qmlRegisterType<PrinterHelper>("com.dervox.printing", 1, 0, "PrinterHelper");
    qmlRegisterType<PdfModel>("com.dervox.Poppler", 1, 0, "Poppler");

    // TrayManager trayManager;
    qmlRegisterSingletonType(
                "org.kde.about",        // <========== used in the import
                1, 0, "About",          // <========== C++ object exported as a QML type
                [](QQmlEngine *engine, QJSEngine *) -> QJSValue {
        return engine->toScriptValue(KAboutData::applicationData());
    }
    );
    // Register the DGestApi instance as a context property
    engine.rootContext()->setContextProperty("api", userapi);
    engine.rootContext()->setContextProperty("subscriptionApi", subscriptionApi);
    engine.rootContext()->setContextProperty("productApi", productApi);
    engine.rootContext()->setContextProperty("productApiFetch", productApiFetch);
    engine.rootContext()->setContextProperty("activityLogApi", activityLogApi);
    engine.rootContext()->setContextProperty("supplierApi", supplierApi);
    engine.rootContext()->setContextProperty("cashSourceApi", cashSourceApi);
    engine.rootContext()->setContextProperty("cashSourceApiFetch", cashSourceApiFetch);
    engine.rootContext()->setContextProperty("saleApi", saleApi);
    engine.rootContext()->setContextProperty("purchaseApi", purchaseApi);
    engine.rootContext()->setContextProperty("clientApi", clientApi);
    engine.rootContext()->setContextProperty("clientApiFetch", clientApiFetch);

    engine.rootContext()->setContextProperty("invoiceApi", invoiceApi);
    engine.rootContext()->setContextProperty("cashTransactionApi", cashTransactionApi);
    engine.rootContext()->setContextProperty("dashboardAnalyticsApi", dashboardAnalyticsApi);


    engine.rootContext()->setContextProperty("productModel", productModel);
    engine.rootContext()->setContextProperty("productUnitModel", productUnitModel);
    engine.rootContext()->setContextProperty("barcodeModel", barcodeModel);
    engine.rootContext()->setContextProperty("activityLogModel", activityLogModel);
    engine.rootContext()->setContextProperty("saleModel", saleModel);
    engine.rootContext()->setContextProperty("purchaseModel", purchaseModel);
    engine.rootContext()->setContextProperty("supplierModel", supplierModel);
    engine.rootContext()->setContextProperty("cashSourceModel", cashSourceModel);
    engine.rootContext()->setContextProperty("cashSourceModelFetch", cashSourceModelFetch);

    engine.rootContext()->setContextProperty("cashTransactionModel", cashTransactionModel);
    engine.rootContext()->setContextProperty("clientModel", clientModel);
    engine.rootContext()->setContextProperty("clientModelFetch", clientModelFetch);

    engine.rootContext()->setContextProperty("invoiceModel", invoiceModel);
    engine.rootContext()->setContextProperty("dashboardModel", dashboardModel);
    //   engine.rootContext()->setContextProperty("trayManager", &trayManager);


    engine.rootContext()->setContextProperty("productModelFetch", productModelFetch);



    qmlRegisterType<ColorSchemeManager>("com.dervox.ColorSchemeManager", 1, 0, "ColorSchemeModel");
    qmlRegisterType<Printer>("com.dervox.Printer", 1, 0, "Printer");
    qmlRegisterType( QUrl(QStringLiteral("qrc:/DGest/utils/PDFView.qml")), "com.dervox.PDFView", 1, 0, "PDFView" );
    FavoriteManager *favoriteManager = new FavoriteManager();
    engine.rootContext()->setContextProperty("favoriteManager", favoriteManager);

    //qmlRegisterType<FavoriteManager>("com.dervox.FavoriteManager", 1, 0, "FavoriteManager");

    qmlRegisterType<NetworkApi::ProductModelFetch>("com.dervox.ProductFetchModel", 1, 0, "ProductFetchModel");


    //  qmlRegisterType<NetworkApi::ProductModel>("com.dervox.ProductModel", 1, 0, "ProductModel");
    qmlRegisterUncreatableType<NetworkApi::ProductModel>("com.dervox.ProductModel",
                                                         1,
                                                         0,
                                                         "ProductRoles",
                                                         QStringLiteral("Cannot create instances of ProductModel"));
    qmlRegisterUncreatableType<NetworkApi::ProductUnitModel>("com.dervox.ProductUnitModel",
                                                             1,
                                                             0,
                                                             "ProductUnitRoles",
                                                             QStringLiteral("Cannot create instances of ProductUnitModel"));
    qmlRegisterUncreatableType<NetworkApi::BarcodeModel>("com.dervox.BarcodeModel",
                                                         1,
                                                         0,
                                                         "BarcodeRoles",
                                                         QStringLiteral("Cannot create instances of BarcodeModel"));
    qmlRegisterUncreatableType<NetworkApi::ActivityLogModel>("com.dervox.ActivityLogModel",
                                                             1,
                                                             0,
                                                             "ActivityLogRoles",
                                                             QStringLiteral("Cannot create instances of ActivityLogModel"));
    qmlRegisterUncreatableType<NetworkApi::SaleModel>("com.dervox.SaleModel",
                                                      1,
                                                      0,
                                                      "SaleRoles",
                                                      QStringLiteral("Cannot create instances of SaleModel"));
    qmlRegisterUncreatableType<NetworkApi::PurchaseModel>("com.dervox.PurchaseModel",
                                                          1,
                                                          0,
                                                          "PurchaseRoles",
                                                          QStringLiteral("Cannot create instances of PurchaseModel"));
    qmlRegisterUncreatableType<NetworkApi::SupplierModel>("com.dervox.SupplierModel",
                                                          1,
                                                          0,
                                                          "SupplierRoles",
                                                          QStringLiteral("Cannot create instances of SupplierModel"));
    qmlRegisterUncreatableType<NetworkApi::CashSourceModel>("com.dervox.CashSourceModel",
                                                            1,
                                                            0,
                                                            "CashSourceRoles",
                                                            QStringLiteral("Cannot create instances of CashSourceModel"));
    qmlRegisterUncreatableType<NetworkApi::CashTransactionModel>("com.dervox.CashTransactionModel",
                                                                 1,
                                                                 0,
                                                                 "CashTransactionRoles",
                                                                 QStringLiteral("Cannot create instances of CashTransactionModel"));
    qmlRegisterUncreatableType<NetworkApi::ClientModel>("com.dervox.ClientModel",
                                                        1,
                                                        0,
                                                        "ClientRoles",
                                                        QStringLiteral("Cannot create instances of ClientModel"));
    qmlRegisterUncreatableType<NetworkApi::InvoiceModel>("com.dervox.InvoiceModel",
                                                         1,
                                                         0,
                                                         "InvoiceRoles",
                                                         QStringLiteral("Cannot create instances of InvoiceModel"));

    qmlRegisterType( QUrl(QStringLiteral("qrc:/DGest/contents/ui/pages/ApiStatusHandler.qml")), "com.dervox.ApiStatusHandler", 1, 0, "ApiStatusHandler" );



    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    const QUrl url(QStringLiteral("qrc:/DGest/contents/ui/Main.qml"));
    QObject::connect(
                &engine,
                &QQmlApplicationEngine::objectCreationFailed,
                &app,
                []() { QCoreApplication::exit(-1); },
    Qt::QueuedConnection);
    engine.load(url);

    // Move window setup after engine.load()
    // if (!engine.rootObjects().isEmpty()) {
    //     QQuickWindow* window = qobject_cast<QQuickWindow*>(engine.rootObjects().first());
    //     if (window) {
    //         trayManager.setMainWindow(window);
    //     }
    // }

    return app.exec();
}
