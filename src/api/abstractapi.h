#ifndef ABSTRACTAPI_H
#define ABSTRACTAPI_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QFuture>
#include <QNetworkReply>
#include <variant>
#include <optional>
#include <QJsonObject>

namespace NetworkApi {
using Error = std::pair<QNetworkReply::NetworkError, QString>;
using Success = std::monostate;
using ApiResult = std::variant<Success, Error>;
using LoginResult = std::variant<QString, Error>; // QString for token
using RegisterResult = std::variant<QJsonObject, Error>;
using UserInfoResult = std::variant<QJsonObject, Error>;

class AbstractApi : public QObject
{
    Q_OBJECT
public:
    explicit AbstractApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);
    void setApiHost(const QString &host);
    QString apiHost() const;

    virtual QFuture<LoginResult> login(const QString &email, const QString &password, const bool &rememberme) = 0;
    virtual QFuture<RegisterResult> registerUser(const QString &name, const QString &email, const QString &password, const QString &c_password) = 0;
    virtual QFuture<ApiResult> logout() = 0;
    virtual QFuture<UserInfoResult> getUserInfo() = 0;
    virtual bool isLoggedIn() const = 0;
    virtual void saveToken(const QString &token) = 0;
    virtual QString getToken() const = 0;
protected:
    QNetworkAccessManager *m_netManager;
    QUrl apiUrl(const QString &path) const;


    template<typename T>
    QFuture<T> reportResults(QNetworkReply *reply, std::function<T(QNetworkReply *)> process)
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
    QFuture<T> get(QNetworkRequest &&request, std::function<T(QNetworkReply *)> process)
    {
        return reportResults<T>(m_netManager->get(request), std::move(process));
    }

    template<typename T>
    QFuture<T> post(QNetworkRequest &&request, const QByteArray &data, std::function<T(QNetworkReply *)> process)
    {
        return reportResults<T>(m_netManager->post(request, data), std::move(process));
    }

    template<typename T>
    QFuture<T> deleteResource(QNetworkRequest &&request, std::function<T(QNetworkReply *)> process)
    {
        return reportResults<T>(m_netManager->deleteResource(request), std::move(process));
    }

private:
    QString m_apiHost;

Q_SIGNALS:
    void apiHostChanged();
};
}
#endif // ABSTRACTAPI_H
