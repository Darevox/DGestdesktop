#include "KUpdater.h"
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QCoreApplication>
#include <QRegularExpression>
#include <QNetworkRequest>

KUpdater::KUpdater(QObject *parent) : QObject(parent)
{
    m_manager = new QNetworkAccessManager(this);
    connect(m_manager, &QNetworkAccessManager::finished, this, &KUpdater::onNetworkReply);

    // Set default user agent
    m_userAgent = QStringLiteral("%1/%2 (Qt/KF)").arg(
        QCoreApplication::applicationName(),
        QCoreApplication::applicationVersion());
}

KUpdater::~KUpdater()
{
}

KUpdater *KUpdater::getInstance()
{
    static KUpdater instance;
    return &instance;
}

bool KUpdater::compareVersions(const QString &remote, const QString &local)
{
    static QRegularExpression re(QStringLiteral("v?(\\d+)(?:\\.(\\d+))?(?:\\.(\\d+))?(?:-(\\w+)(?:(\\d+))?)?"));
    QRegularExpressionMatch remoteMatch = re.match(remote);
    QRegularExpressionMatch localMatch = re.match(local);

    if (!remoteMatch.hasMatch() || !localMatch.hasMatch()) {
        // Invalid version format
        return false;
    }

    for (int i = 1; i <= 3; ++i) {
        int remoteNum = remoteMatch.captured(i).toInt();
        int localNum = localMatch.captured(i).toInt();

        if (remoteNum > localNum)
            return true;
        else if (localNum > remoteNum)
            return false;
    }

    QString remoteSuffix = remoteMatch.captured(4);
    QString localSuffix = localMatch.captured(4);

    if (remoteSuffix.isEmpty() && !localSuffix.isEmpty())
        // Remote is stable, local is pre-release
        return true;
    if (!remoteSuffix.isEmpty() && localSuffix.isEmpty())
        // Remote is pre-release, local is stable
        return false;
    if (remoteSuffix != localSuffix)
        // Compare suffixes lexicographically
        return remoteSuffix > localSuffix;

    int remoteSuffixNum = remoteMatch.captured(5).toInt();
    int localSuffixNum = localMatch.captured(5).toInt();
    return remoteSuffixNum > localSuffixNum;
}

bool KUpdater::getUpdateAvailable(const QString &url) const
{
    return m_updateData.contains(url) ? m_updateData[url].updateAvailable : false;
}

QString KUpdater::getChangelog(const QString &url) const
{
    return m_updateData.contains(url) ? m_updateData[url].changelog : QString();
}

QString KUpdater::getDownloadUrl(const QString &url) const
{
    return m_updateData.contains(url) ? m_updateData[url].downloadUrl : QString();
}

QString KUpdater::getLatestVersion(const QString &url) const
{
    return m_updateData.contains(url) ? m_updateData[url].latestVersion : QString();
}

QString KUpdater::getModuleVersion(const QString &url) const
{
    return m_updateData.contains(url) ? m_updateData[url].moduleVersion :
           QCoreApplication::applicationVersion();
}

QString KUpdater::getUserAgentString(const QString &url) const
{
    Q_UNUSED(url);
    return m_userAgent;
}

QString KUpdater::getPlatformKey(const QString &url) const
{
    return m_updateData.contains(url) && !m_updateData[url].platformKey.isEmpty() ?
           m_updateData[url].platformKey : getPlatformKeyInternal();
}

QString KUpdater::getPlatformKeyInternal() const
{
#if defined(Q_OS_WIN)
    return QStringLiteral("windows");
#elif defined(Q_OS_MAC)
    return QStringLiteral("macos");  // Changed from "osx" to "macos" to match your JSON
#elif defined(Q_OS_LINUX)
    return QStringLiteral("linux");
#elif defined(Q_OS_ANDROID)
    return QStringLiteral("android");
#elif defined(Q_OS_IOS)
    return QStringLiteral("ios");
#else
    return QStringLiteral("unknown");
#endif
}

void KUpdater::checkForUpdates(const QString &url)
{
    // Ensure we have an entry for this URL
    if (!m_updateData.contains(url)) {
        UpdateData data;
        data.moduleVersion = QCoreApplication::applicationVersion();
        data.platformKey = getPlatformKeyInternal();
        data.updateAvailable = false;
        m_updateData[url] = data;
    }

    // Create request
    QNetworkRequest request{QUrl(url)};

    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                        QNetworkRequest::NoLessSafeRedirectPolicy);

    if (!m_userAgent.isEmpty())
        request.setRawHeader("User-Agent", m_userAgent.toUtf8());

    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));

    // Store the URL as a property to identify the reply
    QNetworkReply *reply = m_manager->get(request);

    // Use the non-stringliteral form for the property key
    reply->setProperty("url", url);
}


void KUpdater::setPlatformKey(const QString &url, const QString &platform)
{
    if (!m_updateData.contains(url)) {
        UpdateData data;
        data.moduleVersion = QCoreApplication::applicationVersion();
        data.updateAvailable = false;
        m_updateData[url] = data;
    }

    m_updateData[url].platformKey = platform;
}

void KUpdater::setUserAgentString(const QString &url, const QString &agent)
{
    Q_UNUSED(url);
    m_userAgent = agent;
}

void KUpdater::setModuleVersion(const QString &url, const QString &version)
{
    if (!m_updateData.contains(url)) {
        UpdateData data;
        data.updateAvailable = false;
        data.platformKey = getPlatformKeyInternal();
        m_updateData[url] = data;
    }

    m_updateData[url].moduleVersion = version;
}

void KUpdater::onNetworkReply(QNetworkReply *reply)
{
    QString url = reply->property("url").toString();

    // Check for redirect
    QUrl redirect = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
    if (!redirect.isEmpty()) {
        checkForUpdates(redirect.toString());
        reply->deleteLater();
        return;
    }

    // If we had an error
    if (reply->error() != QNetworkReply::NoError) {
        if (m_updateData.contains(url)) {
            m_updateData[url].updateAvailable = false;
        }
        Q_EMIT checkingFinished(url);
        reply->deleteLater();
        return;
    }

    // Read the JSON data
    QByteArray data = reply->readAll();
    QJsonParseError parseError;
    QJsonDocument document = QJsonDocument::fromJson(data, &parseError);
    reply->deleteLater();

    // Check if JSON is valid
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        qWarning() << QStringLiteral("JSON parse error:") << parseError.errorString();
        if (m_updateData.contains(url)) {
            m_updateData[url].updateAvailable = false;
        }
        Q_EMIT checkingFinished(url);
        return;
    }

    // Parse the JSON - NEW CODE FOR THE NEW FORMAT
    QJsonObject rootObj = document.object();

    // Verify this is the right application
    QString appName = rootObj.value(QStringLiteral("application")).toString();
    if (appName != QStringLiteral("DIM")) {
        qWarning() << QStringLiteral("Unexpected application name in update JSON:") << appName;
        if (m_updateData.contains(url)) {
            m_updateData[url].updateAvailable = false;
        }
        Q_EMIT checkingFinished(url);
        return;
    }

    // Get the latest overall version from the JSON
    QString currentVersion = rootObj.value(QStringLiteral("current_version")).toString();

    // Get our platform key
    QString platformKey = getPlatformKey(url);

    // Get the updates array
    QJsonArray updatesArray = rootObj.value(QStringLiteral("updates")).toArray();
    if (updatesArray.isEmpty()) {
        qWarning() << QStringLiteral("No updates found in JSON");
        if (m_updateData.contains(url)) {
            m_updateData[url].updateAvailable = false;
        }
        Q_EMIT checkingFinished(url);
        return;
    }

    // Find a compatible update for our platform
    QJsonObject latestUpdate;
    QString latestVersion;

    // First, try to find the update that matches the current_version
    for (const QJsonValue& updateValue : updatesArray) {
        QJsonObject updateObj = updateValue.toObject();
        QString version = updateObj.value(QStringLiteral("version")).toString();

        // Check if this matches the current version
        if (version == currentVersion) {
            // Make sure it has our platform
            QJsonObject downloadUrls = updateObj.value(QStringLiteral("download_url")).toObject();
            if (downloadUrls.contains(platformKey)) {
                latestUpdate = updateObj;
                latestVersion = version;
                break;
            }
        }
    }

    // If we didn't find a matching version, take the first one with our platform
    if (latestUpdate.isEmpty()) {
        for (const QJsonValue& updateValue : updatesArray) {
            QJsonObject updateObj = updateValue.toObject();
            QJsonObject downloadUrls = updateObj.value(QStringLiteral("download_url")).toObject();

            if (downloadUrls.contains(platformKey)) {
                latestUpdate = updateObj;
                latestVersion = updateObj.value(QStringLiteral("version")).toString();
                break;
            }
        }
    }

    // If we still couldn't find anything, we can't update
    if (latestUpdate.isEmpty()) {
        qWarning() << QStringLiteral("No compatible update found for platform:") << platformKey;
        if (m_updateData.contains(url)) {
            m_updateData[url].updateAvailable = false;
        }
        Q_EMIT checkingFinished(url);
        return;
    }

    // Update the stored data with the information from the found update
    if (m_updateData.contains(url)) {
        m_updateData[url].changelog = latestUpdate.value(QStringLiteral("changelog")).toString();

        // Get platform-specific download URL
        QJsonObject downloadUrls = latestUpdate.value(QStringLiteral("download_url")).toObject();
        m_updateData[url].downloadUrl = downloadUrls.value(platformKey).toString();

        m_updateData[url].latestVersion = latestVersion;

        // Get the current app version
        QString currentAppVersion = m_updateData[url].moduleVersion;

        // Check if update is available by comparing versions
        bool updateAvailable = compareVersions(latestVersion, currentAppVersion);

        m_updateData[url].updateAvailable = updateAvailable;

        qDebug() << QStringLiteral("Update check complete:")
                 << QStringLiteral("Current version =") << currentAppVersion
                 << QStringLiteral("Latest version =") << latestVersion
                 << QStringLiteral("Update available =") << updateAvailable;
    }

    Q_EMIT checkingFinished(url);
}
