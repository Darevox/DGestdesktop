#ifndef KUPDATER_H
#define KUPDATER_H

#include <QObject>
#include <QString>
#include <QUrl>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QMap>
#include <QThread>

class KUpdater : public QObject
{
    Q_OBJECT

public:
    static KUpdater *getInstance();

    bool getUpdateAvailable(const QString &url) const;
    QString getChangelog(const QString &url) const;
    QString getDownloadUrl(const QString &url) const;
    QString getLatestVersion(const QString &url) const;
    QString getModuleVersion(const QString &url) const;
    QString getUserAgentString(const QString &url) const;
    QString getPlatformKey(const QString &url) const;

    static bool compareVersions(const QString &remote, const QString &local);

public Q_SLOTS:
    void checkForUpdates(const QString &url);
    void setModuleVersion(const QString &url, const QString &version);
    void setPlatformKey(const QString &url, const QString &platform);
    void setUserAgentString(const QString &url, const QString &agent);

Q_SIGNALS:
    void checkingFinished(const QString &url);
    void downloadFinished(const QString &url, const QString &filePath);

private:
    KUpdater(QObject *parent = nullptr);
    ~KUpdater();

    QNetworkAccessManager *m_manager;
    QString m_userAgent;

    // Store update data
    struct UpdateData {
        QString moduleVersion;
        QString latestVersion;
        QString changelog;
        QString downloadUrl;
        QString platformKey;
        bool updateAvailable;
    };

    QMap<QString, UpdateData> m_updateData;
    QString getPlatformKeyInternal() const;

private Q_SLOTS:
    void onNetworkReply(QNetworkReply *reply);
};

#endif // KUPDATER_H
