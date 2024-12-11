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

#include <api/userapi.h>
#include <api/subscriptionapi.h>
#include <api/productapi.h>
#include <api/activitylogapi.h>


#include <model/productmodel.h>
#include <model/productunitmodel.h>
#include <model/barcodemodel.h>
#include <model/activitylogmodel.h>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QLoggingCategory::setFilterRules("*.debug=true");
    KLocalizedString::setApplicationDomain("Managements");
    QCoreApplication::setOrganizationName(QStringLiteral("Dervox"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("Dervox.com"));
    QCoreApplication::setApplicationName(QStringLiteral("DGest"));

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QQmlApplicationEngine engine;
    //engine.addImportPath("qml");
    QNetworkAccessManager *networkManager = new QNetworkAccessManager();
    NetworkApi::UserApi *userapi = new NetworkApi::UserApi(networkManager);
    NetworkApi::SubscriptionApi *subscriptionApi = new NetworkApi::SubscriptionApi(networkManager);
    NetworkApi::ProductApi *productApi = new NetworkApi::ProductApi(networkManager);
    NetworkApi::ActivityLogApi *activityLogApi = new NetworkApi::ActivityLogApi(networkManager);



    NetworkApi::ProductModel *productModel = new NetworkApi::ProductModel();
    NetworkApi::ProductUnitModel *productUnitModel = new NetworkApi::ProductUnitModel();
    NetworkApi::BarcodeModel *barcodeModel = new NetworkApi::BarcodeModel();
    NetworkApi::ActivityLogModel *activityLogModel = new NetworkApi::ActivityLogModel();

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
    engine.rootContext()->setContextProperty("activityLogApi", activityLogApi);

    engine.rootContext()->setContextProperty("productModel", productModel);
    engine.rootContext()->setContextProperty("productUnitModel", productUnitModel);
    engine.rootContext()->setContextProperty("barcodeModel", barcodeModel);
    engine.rootContext()->setContextProperty("activityLogModel", activityLogModel);

    //   engine.rootContext()->setContextProperty("trayManager", &trayManager);

    qmlRegisterType<ColorSchemeManager>("com.dervox.ColorSchemeManager", 1, 0, "ColorSchemeModel");
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
