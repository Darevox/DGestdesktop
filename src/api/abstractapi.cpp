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
    url.setScheme(QStringLiteral("https"));
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
template<typename T>
QFuture<T> AbstractApi::reportResults(QNetworkReply *reply, std::function<T(QNetworkReply *)> process)
{
    auto interface = std::make_shared<QFutureInterface<T>>(QFutureInterfaceBase::Started);

    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (!interface->isCanceled()) {
            interface->reportResult(process(reply));
            interface->reportFinished();
        }
        reply->deleteLater();
    });
    connect(reply, &QNetworkReply::errorOccurred, this, [=](QNetworkReply::NetworkError error) {
        qWarning() << "Error for" << error << reply->url() << reply->errorString();
        interface->reportResult(T(Error{error, reply->errorString()}));
        interface->reportFinished();
        reply->deleteLater();
    });

    return interface->future();
}

template<typename T>
QFuture<T> AbstractApi::get(QNetworkRequest &&request, std::function<T(QNetworkReply *)> process)
{
    return reportResults<T>(m_netManager->get(request), std::move(process));
}

template<typename T>
QFuture<T> AbstractApi::post(QNetworkRequest &&request, const QByteArray &data, std::function<T(QNetworkReply *)> process)
{
    return reportResults<T>(m_netManager->post(request, data), std::move(process));
}

template<typename T>
QFuture<T> AbstractApi::deleteResource(QNetworkRequest &&request, std::function<T(QNetworkReply *)> process)
{
    return reportResults<T>(m_netManager->deleteResource(request), std::move(process));
}
}
