// abstractapi.cpp
#include "abstractapi.h"
#include <QUrlQuery>

namespace NetworkApi {

AbstractApi::AbstractApi(QNetworkAccessManager *netManager, QObject *parent)
    : QObject(parent)
    , m_netManager(netManager)
    , m_apiHost("https://dim.dervox.com")  // Replace with your actual API host
    , m_token("")
{
}

void AbstractApi::setApiHost(const QString &host) {
    if (host != m_apiHost) {
        m_apiHost = host.endsWith('/') ? host.left(host.length() - 1) : host;
        emit apiHostChanged();
    }
}

QString AbstractApi::apiHost() const {
    return m_apiHost;
}
QUrl AbstractApi::apiUrl(const QString &path) const {
    QString fullPath = path.startsWith('/') ? path : QString("/%1").arg(path);
    return QUrl(m_apiHost + fullPath);
}

QNetworkRequest AbstractApi::createRequest(const QString &path) const {
    QNetworkRequest request(apiUrl(path));

    // Set common headers
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");

    // Add authorization header if token exists
    if (!m_token.isEmpty()) {
        request.setRawHeader("Authorization",
            QString("Bearer %1").arg(m_token).toUtf8());
    }

    return request;
}

} // namespace NetworkApi
