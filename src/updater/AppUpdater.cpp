#include "AppUpdater.h"
#include "UpdateHelper.h"
#include "KUpdater.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QFileInfo>
#include <QUrl>
#include <QDebug>
#include <QProcess>
#include <QTimer>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QFile>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>

AppUpdater::AppUpdater(QObject* parent) : QObject(parent),
    m_updater(KUpdater::getInstance()),
    m_updateAvailable(false),
    m_checkingForUpdate(false),
    m_downloading(false),
    m_silentUpdate(false),
    m_downloadProgress(0.0f),
    m_currentDownload(nullptr)
{
    m_currentVersion = QCoreApplication::applicationVersion();

    // Connect to KUpdater signals
    connect(m_updater, &KUpdater::checkingFinished,
            this, &AppUpdater::onCheckingFinished);

    // Set up network manager for downloads
    m_networkManager = new QNetworkAccessManager(this);

    // Set up update helper for installations
    m_updateHelper = new UpdateHelper(this);
    connect(m_updateHelper, &UpdateHelper::updateProgress,
            this, &AppUpdater::onUpdateInstallProgress);
    connect(m_updateHelper, &UpdateHelper::updateFinished,
            this, &AppUpdater::onUpdateInstallFinished);
    connect(m_updateHelper, &UpdateHelper::updateError,
            this, &AppUpdater::onUpdateInstallError);
}

AppUpdater::~AppUpdater()
{
}

void AppUpdater::setUpdateUrl(const QString& url)
{
    m_updateUrl = url;
    setupUpdater();
}

void AppUpdater::setCurrentVersion(const QString& version)
{
    m_currentVersion = version;
    if (!m_updateUrl.isEmpty()) {
        m_updater->setModuleVersion(m_updateUrl, version);
    }
}

void AppUpdater::setSilentUpdate(bool silent)
{
    m_silentUpdate = silent;
}

void AppUpdater::setupUpdater()
{
    if (m_updateUrl.isEmpty())
        return;

    // Initialize the updater with our version
    m_updater->setModuleVersion(m_updateUrl, m_currentVersion);

    // Set user agent with app info
    QString userAgent = QStringLiteral("%1/%2 (KF Integration)").arg(
        QCoreApplication::applicationName(),
        QCoreApplication::applicationVersion());
    m_updater->setUserAgentString(m_updateUrl, userAgent);
}

void AppUpdater::checkForUpdates()
{
    if (m_updateUrl.isEmpty()) {
        qWarning() << "Update URL not set!";
        return;
    }

    m_checkingForUpdate = true;
    Q_EMIT checkingForUpdateChanged();

    m_updater->checkForUpdates(m_updateUrl);
}

void AppUpdater::onCheckingFinished(const QString& url)
{
    if (url != m_updateUrl)
        return;

    m_checkingForUpdate = false;
    Q_EMIT checkingForUpdateChanged();

    // Get update information
    bool hasUpdate = m_updater->getUpdateAvailable(url);
    if (hasUpdate != m_updateAvailable) {
        m_updateAvailable = hasUpdate;
        Q_EMIT updateAvailableChanged();
    }

    if (hasUpdate) {
        QString newVersion = m_updater->getLatestVersion(url);
        if (newVersion != m_latestVersion) {
            m_latestVersion = newVersion;
            Q_EMIT latestVersionChanged();
        }

        QString newChangelog = m_updater->getChangelog(url);
        if (newChangelog != m_changelog) {
            m_changelog = newChangelog;
            Q_EMIT changelogChanged();
        }
    }

    Q_EMIT updateCheckFinished(hasUpdate);
}

void AppUpdater::downloadAndInstall()
{
    if (!m_updateAvailable || m_updateUrl.isEmpty())
        return;

    // Get download URL from the updater
    QString downloadUrl = m_updater->getDownloadUrl(m_updateUrl);
    if (downloadUrl.isEmpty()) {
        Q_EMIT downloadError(QStringLiteral("Download URL is empty"));
        return;
    }

    // Create a destination file path in temp directory
    QString fileName = QFileInfo(downloadUrl).fileName();
    QDir tempDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation));

    // Add timestamp to avoid conflicts
    QString timestamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-hhmmss"));
    QString destinationPath = tempDir.filePath(QStringLiteral("%1-%2").arg(timestamp, fileName));

    // Start the download
    startDownload(downloadUrl, destinationPath);
}

void AppUpdater::startDownload(const QString& url, const QString& destination)
{
    // Prepare for download
    m_downloading = true;
    m_downloadProgress = 0.0f;
    m_downloadPath = destination;

    Q_EMIT downloadingChanged();
    Q_EMIT downloadProgressChanged();

    // Create a proper network request
    QNetworkRequest request;
    request.setUrl(QUrl(url));  // Set URL directly

    // Set redirect policy
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                       QNetworkRequest::NoLessSafeRedirectPolicy);

    // Set appropriate headers
    request.setHeader(QNetworkRequest::UserAgentHeader,
                     QStringLiteral("%1/%2").arg(
                         QCoreApplication::applicationName(),
                         QCoreApplication::applicationVersion()));

    // Start the download
    m_currentDownload = m_networkManager->get(request);

    if (!m_currentDownload) {
        // Handle error - failed to create request
        m_downloading = false;
        Q_EMIT downloadingChanged();
        Q_EMIT downloadError(QStringLiteral("Failed to create download request"));
        return;
    }

    // Connect signals for the download
    connect(m_currentDownload, &QNetworkReply::downloadProgress,
            this, &AppUpdater::onDownloadProgress);

    connect(m_currentDownload, &QNetworkReply::finished,
            this, &AppUpdater::onDownloadFinished);

    // Error handling - use the correct signal for Qt 6
    connect(m_currentDownload, &QNetworkReply::errorOccurred,
            this, &AppUpdater::onDownloadError);
}

void AppUpdater::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal <= 0) {
        // Unknown size, show indeterminate progress
        m_downloadProgress = 0.5f;  // Just show halfway since we don't know total
        Q_EMIT downloadProgressChanged();
        return;
    }

    // Calculate percentage
    m_downloadProgress = static_cast<float>(bytesReceived) / bytesTotal;
    Q_EMIT downloadProgressChanged();

    // Optional: Emit additional signal with human-readable sizes
    QString received = formatFileSize(bytesReceived);
    QString total = formatFileSize(bytesTotal);
    Q_EMIT downloadProgressText(QStringLiteral("%1 of %2").arg(received, total));
}

// Helper method
QString AppUpdater::formatFileSize(qint64 bytes)
{
    const qint64 kb = 1024;
    const qint64 mb = 1024 * kb;
    const qint64 gb = 1024 * mb;

    if (bytes < kb) {
        return QStringLiteral("%1 B").arg(bytes);
    } else if (bytes < mb) {
        return QStringLiteral("%1 KB").arg(bytes / kb);
    } else if (bytes < gb) {
        return QStringLiteral("%1 MB").arg(bytes / mb);
    } else {
        return QStringLiteral("%1 GB").arg(static_cast<double>(bytes) / gb, 0, 'f', 1);
    }
}


void AppUpdater::onDownloadFinished()
{
    // Guard against null pointer or if we're no longer in downloading state
    if (!m_currentDownload || !m_downloading) {
        return;
    }

    // Check if the request completed without errors
    if (m_currentDownload->error() == QNetworkReply::NoError) {
        // Save the file
        QFile file(m_downloadPath);
        if (!file.open(QIODevice::WriteOnly)) {
            Q_EMIT downloadError(QStringLiteral("Could not save file: %1").arg(file.errorString()));
        } else {
            // Write all data to file
            file.write(m_currentDownload->readAll());
            file.close();

            // Store download path before clearing state
            QString downloadedPath = m_downloadPath;

            // Update state
            m_downloading = false;
            m_downloadProgress = 1.0f;

            // Clear the download pointer first to prevent access after potential deletion
            QNetworkReply* replyToDelete = m_currentDownload;
            m_currentDownload = nullptr;

            // Emit signals after clearing state
            Q_EMIT downloadingChanged();
            Q_EMIT downloadProgressChanged();
            Q_EMIT downloadFinished(downloadedPath);

            // Install after notifying UI
            installUpdate(downloadedPath);

            // Finally delete the reply
            replyToDelete->deleteLater();
        }
    } else {
        // If there was an error, it will be handled by onDownloadError
        // But we need to make sure we clean up
        m_currentDownload->deleteLater();
        m_currentDownload = nullptr;
    }
}


void AppUpdater::onDownloadError(QNetworkReply::NetworkError error)
{
    // Guard against null pointer
    if (!m_currentDownload) {
        return;
    }

    // Store the error message before we delete the reply
    QString errorMessage;

    switch (error) {
    case QNetworkReply::ConnectionRefusedError:
    case QNetworkReply::HostNotFoundError:
    case QNetworkReply::TimeoutError:
    case QNetworkReply::NetworkSessionFailedError:
    case QNetworkReply::TemporaryNetworkFailureError:
        errorMessage = QStringLiteral("Network connection error: %1").arg(
                        m_currentDownload->errorString());
        break;

    case QNetworkReply::OperationCanceledError:
        errorMessage = QStringLiteral("Download was cancelled");
        break;

    case QNetworkReply::SslHandshakeFailedError:
        errorMessage = QStringLiteral("Secure connection failed: %1").arg(
                        m_currentDownload->errorString());
        break;

    default:
        errorMessage = QStringLiteral("Download error: %1").arg(
                        m_currentDownload->errorString());
        break;
    }

    // Update state
    m_downloading = false;

    // Clear the download pointer first
    QNetworkReply* replyToDelete = m_currentDownload;
    m_currentDownload = nullptr;

    // Emit signals after clearing state
    Q_EMIT downloadingChanged();

    // Emit the error after a slight delay to ensure UI is updated
    QTimer::singleShot(50, this, [this, errorMessage]() {
        Q_EMIT downloadError(errorMessage);
    });

    // Finally delete the reply
    replyToDelete->deleteLater();
}


void AppUpdater::cancelDownload()
{
    if (!m_downloading || !m_currentDownload) {
        return;
    }

    // Disconnect all signals to prevent callbacks after abort
    m_currentDownload->disconnect();

    // Set downloading flag to false first
    m_downloading = false;
    Q_EMIT downloadingChanged();

    // Set progress to 0
    m_downloadProgress = 0.0f;
    Q_EMIT downloadProgressChanged();

    // Abort and schedule deletion
    m_currentDownload->abort();
    m_currentDownload->deleteLater();
    m_currentDownload = nullptr;

    // Notify of cancellation - small delay to ensure UI updates first
    QTimer::singleShot(10, this, [this]() {
        Q_EMIT downloadError(QStringLiteral("Download cancelled by user"));
    });
}


void AppUpdater::installUpdate(const QString& filePath)
{
    // Check if the file exists
    if (!QFileInfo::exists(filePath)) {
        Q_EMIT downloadError(QStringLiteral("Update file not found: %1").arg(filePath));
        return;
    }

    // Get file extension
    QString fileExt = QFileInfo(filePath).suffix().toLower();

#ifdef Q_OS_WIN
    if (fileExt == QLatin1String("exe")) {
        // For Windows EXE installers
        QStringList args;
        if (m_silentUpdate) {
            args << QStringLiteral("/S"); // Silent install for NSIS
        }

        if (QProcess::startDetached(filePath, args)) {
            // Installer started successfully, now exit application
            QTimer::singleShot(500, []() {
                QCoreApplication::quit();
            });
        } else {
            Q_EMIT downloadError(QStringLiteral("Failed to start installer"));
        }
    }
    else if (fileExt == QLatin1String("zip")) {
        // For ZIP files, use update helper
        m_updateHelper->extractAndUpdate(filePath);
    }
    else {
        QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
    }
#elif defined(Q_OS_LINUX)
    if (fileExt == QLatin1String("appimage")) {
        // Make AppImage executable
        QFile file(filePath);
        file.setPermissions(file.permissions() | QFileDevice::ExeUser);

        // Run the AppImage
        QProcess::startDetached(filePath, QStringList());
        QTimer::singleShot(500, []() {
            QCoreApplication::quit();
        });
    }
    else if (fileExt == QLatin1String("deb")) {
        // For Debian packages
        QProcess process;
        process.start(QStringLiteral("pkexec"), QStringList() << QStringLiteral("apt") << QStringLiteral("install") << filePath);

        if (!process.waitForStarted()) {
            Q_EMIT downloadError(QStringLiteral("Failed to start package installer"));
        } else {
            QTimer::singleShot(500, []() {
                QCoreApplication::quit();
            });
        }
    }
    else if (fileExt == QLatin1String("zip")) {
        // For ZIP files
        m_updateHelper->extractAndUpdate(filePath);
    }
    else {
        QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
    }
#else
    // For other platforms, just open the file
    QDesktopServices::openUrl(QUrl::fromLocalFile(filePath));
#endif
}

void AppUpdater::onUpdateInstallProgress(int percent)
{
    Q_EMIT updateInstallProgressChanged(percent);
}

void AppUpdater::onUpdateInstallFinished(bool success)
{
    if (success) {
        Q_EMIT updateInstallFinished();
    }
}

void AppUpdater::onUpdateInstallError(const QString& error)
{
    Q_EMIT downloadError(error);
}
