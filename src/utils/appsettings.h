#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int scaleValue READ scaleValue WRITE setScaleValue NOTIFY scaleValueChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    static void initializeScale();  // New static method
    static QByteArray loadScaleValue();  // New method
    Q_INVOKABLE void applyScale(int value);
    Q_INVOKABLE void makeRestart();

    int scaleValue() const;
    void setScaleValue(int value);

Q_SIGNALS:
    void scaleValueChanged();
    void restartRequired();

private:
    QSettings m_settings;
    int m_scaleValue;
};

#endif // APPSETTINGS_H
