#include <QApplication>  // Changed from QGuiApplication
#include <QQmlApplicationEngine>
#include <QtQml>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <QQuickStyle>
#include <Kirigami/Platform/PlatformTheme>
#include <KColorSchemeManager>
#include <api/userapi.h>
#include <QNetworkAccessManager>
#include <QLoggingCategory>
#include <KAboutData>
#include <colorschememanager.h>
#include <traymanager.h>

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
    QNetworkAccessManager *networkManager = new QNetworkAccessManager();
    NetworkApi::UserApi *userapi = new NetworkApi::UserApi(networkManager);
    TrayManager trayManager;
    qmlRegisterSingletonType(
        "org.kde.about",        // <========== used in the import
        1, 0, "About",          // <========== C++ object exported as a QML type
        [](QQmlEngine *engine, QJSEngine *) -> QJSValue {
            return engine->toScriptValue(KAboutData::applicationData());
        }
        );
    // Register the DGestApi instance as a context property
    engine.rootContext()->setContextProperty("api", userapi);
    engine.rootContext()->setContextProperty("trayManager", &trayManager);
    qmlRegisterType<ColorSchemeManager>("com.dervox.ColorSchemeManager", 1, 0, "ColorSchemeModel");
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
    if (!engine.rootObjects().isEmpty()) {
        QQuickWindow* window = qobject_cast<QQuickWindow*>(engine.rootObjects().first());
        if (window) {
            trayManager.setMainWindow(window);
        }
    }

    return app.exec();
}
