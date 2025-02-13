#include "appsettings.h"
#include <QApplication>
#include <QProcess>
QByteArray AppSettings::loadScaleValue()
{
    QSettings settings(QStringLiteral("Dervox"),QStringLiteral( "DGest"));
    int scaleValue = settings.value("UI/Scale", 100).toInt();
    float scaleFactor = scaleValue / 100.0f;
    return QByteArray::number(scaleFactor);
}

void AppSettings::initializeScale()
{
    qputenv("QT_SCALE_FACTOR", loadScaleValue());
}

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
    , m_settings(QStringLiteral("Dervox"),QStringLiteral( "DGest"))
{
    m_scaleValue = m_settings.value("UI/Scale", 100).toInt();
}

void AppSettings::applyScale(int value)
{
    if (value != m_scaleValue) {
           m_scaleValue = value;
           m_settings.setValue("UI/Scale", value);
           m_settings.sync(); // Ensure settings are written immediately
           Q_EMIT scaleValueChanged();
           Q_EMIT restartRequired();
       }
}

void AppSettings::makeRestart()
{
    qApp->quit();
    QProcess::startDetached(qApp->arguments()[0], qApp->arguments());
}

int AppSettings::scaleValue() const
{
    return m_scaleValue;
}

void AppSettings::setScaleValue(int value)
{
    if (m_scaleValue != value) {
        m_scaleValue = value;
        Q_EMIT scaleValueChanged();
    }
}
