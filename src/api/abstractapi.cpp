#include "abstractapi.h"

namespace NetworkApi {

AbstractApi::AbstractApi(QNetworkAccessManager *netManager, QObject *parent)
    : QObject(parent)
    , m_netManager(netManager)
{
}
QUrl AbstractApi::apiUrl(const QString &path) const
{
    QUrl url = QUrl::fromUserInput(m_apiHost);
    url.setScheme(QStringLiteral("http"));
    url.setPath(path);
    return url;
}

void AbstractApi::setApiHost(const QString &host)
{
    m_apiHost = host;
    Q_EMIT apiHostChanged();
}

QString AbstractApi::apiHost() const
{
    return m_apiHost;
}


}
