// abstractapi.cpp
#include "abstractapi.h"
#include <QUrlQuery>

namespace NetworkApi {

AbstractApi::AbstractApi(QNetworkAccessManager *netManager, QObject *parent)
    : QObject(parent)
    , m_netManager(netManager)
 //   , m_apiHost("https://dim.dervox.com")
   , m_apiHost(QStringLiteral("http://localhost:8000"))
    , m_token(QStringLiteral(""))
{
}

void AbstractApi::setApiHost(const QString &host) {
    if (host != m_apiHost) {
        m_apiHost = host.endsWith(QStringLiteral("/"))
                  ? host.left(host.length() - 1)
                  : host;
        Q_EMIT apiHostChanged();
    }
}

QString AbstractApi::apiHost() const {
    return m_apiHost;
}
QUrl AbstractApi::apiUrl(const QString &path) const {
    QString fullPath = path.startsWith(QStringLiteral("/"))
        ? path
        : QStringLiteral("/%1").arg(path);
    return QUrl(m_apiHost + fullPath);
}

QNetworkRequest AbstractApi::createRequest(const QString &path) const {
    QNetworkRequest request(apiUrl(path));

    // Set common headers using QLatin1String for ASCII-only content types
    request.setHeader(QNetworkRequest::ContentTypeHeader,
        QLatin1String("application/json"));
    request.setRawHeader(
        QByteArrayLiteral("Accept"),
        QByteArrayLiteral("application/json"));

    // Add authorization header if token exists
    if (!m_token.isEmpty()) {
        request.setRawHeader(
            QByteArrayLiteral("Authorization"),
            QStringLiteral("Bearer %1").arg(m_token).toUtf8());
    }

    return request;
}

} // namespace NetworkApi
