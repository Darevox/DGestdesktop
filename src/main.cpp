#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <QQuickStyle>
#include <Kirigami/Platform/PlatformTheme>
#include <KColorSchemeManager>
#include <api/abstractapi.h>
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
