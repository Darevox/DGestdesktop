#pragma once

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
class KUpdater;
class UpdateHelper;

class AppUpdater : public QObject
{
    Q_OBJECT

    // QML properties
    Q_PROPERTY(bool updateAvailable READ isUpdateAvailable NOTIFY updateAvailableChanged)
    Q_PROPERTY(bool checkingForUpdate READ isCheckingForUpdate NOTIFY checkingForUpdateChanged)
    Q_PROPERTY(bool downloading READ isDownloading NOTIFY downloadingChanged)
    Q_PROPERTY(float downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)
    Q_PROPERTY(QString changelog READ changelog NOTIFY changelogChanged)
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)

public:
    explicit AppUpdater(QObject* parent = nullptr);
    ~AppUpdater();

    // Getters for properties
    bool isUpdateAvailable() const { return m_updateAvailable; }
    bool isCheckingForUpdate() const { return m_checkingForUpdate; }
    bool isDownloading() const { return m_downloading; }
    float downloadProgress() const { return m_downloadProgress; }
    QString latestVersion() const { return m_latestVersion; }
    QString changelog() const { return m_changelog; }
    QString currentVersion() const { return m_currentVersion; }

    // Set the update URL
    void setUpdateUrl(const QString& url);

    // Set the current app version (optional, will use QApplication version by default)
    void setCurrentVersion(const QString& version);

    // Set silent update mode
    void setSilentUpdate(bool silent);
    bool silentUpdate() const { return m_silentUpdate; }
    QString formatFileSize(qint64 bytes);
    public Q_SLOTS:
        // Check for updates
        Q_INVOKABLE void checkForUpdates();

    // Download and install the update
    Q_INVOKABLE void downloadAndInstall();

    // Cancel the download process
    Q_INVOKABLE void cancelDownload();

Q_SIGNALS:
    // Property notifications
    void updateAvailableChanged();
    void checkingForUpdateChanged();
    void downloadingChanged();
    void downloadProgressChanged();
    void latestVersionChanged();
    void changelogChanged();

    // Additional signals
    void updateCheckFinished(bool hasUpdate);
    void downloadFinished(const QString& filePath);
    void downloadError(const QString& errorMessage);
    void updateInstallProgressChanged(int percent);
    void updateInstallFinished();
    void downloadProgressText(const QString& progressText);

private Q_SLOTS:
    void onCheckingFinished(const QString& url);
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onDownloadFinished();
    void onDownloadError(QNetworkReply::NetworkError error);
    void onUpdateInstallProgress(int percent);
    void onUpdateInstallFinished(bool success);
    void onUpdateInstallError(const QString& error);

private:
    KUpdater* m_updater;
    UpdateHelper* m_updateHelper;
    QString m_updateUrl;
    QString m_currentVersion;
    QString m_latestVersion;
    QString m_changelog;
    bool m_updateAvailable;
    bool m_checkingForUpdate;
    bool m_downloading;
    bool m_silentUpdate;
    float m_downloadProgress;

    // Download handling
    QNetworkAccessManager* m_networkManager;
    QNetworkReply* m_currentDownload;
    QString m_downloadPath;

    void setupUpdater();
    void installUpdate(const QString& filePath);
    void startDownload(const QString& url, const QString& destination);
};
