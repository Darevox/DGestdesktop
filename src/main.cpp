#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <QQuickStyle>
#include <Kirigami/Platform/PlatformTheme>
#include <KColorSchemeManager>
#include <api/dgestapi.h>
#include <QNetworkAccessManager>

#include <KAboutData>
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    KLocalizedString::setApplicationDomain("Managements");
    QCoreApplication::setOrganizationName(QStringLiteral("Dervox"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("Dervox.com"));
    QCoreApplication::setApplicationName(QStringLiteral("DGest"));

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QQmlApplicationEngine engine;
    QNetworkAccessManager *networkManager = new QNetworkAccessManager();
    DGestApi *dgestApi = new DGestApi(networkManager);
    qmlRegisterSingletonType(
        "org.kde.about",        // <========== used in the import
        1, 0, "About",          // <========== C++ object exported as a QML type
        [](QQmlEngine *engine, QJSEngine *) -> QJSValue {
            return engine->toScriptValue(KAboutData::applicationData());
        }
        );
    // Register the DGestApi instance as a context property
    engine.rootContext()->setContextProperty("api", dgestApi);

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    const QUrl url(QStringLiteral("qrc:/DGest/qml/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
