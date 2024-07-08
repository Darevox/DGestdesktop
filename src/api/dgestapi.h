#ifndef DGESTAPI_H
#define DGESTAPI_H

#include <QObject>
#include "abstractapi.h"
#include <QSettings>
#include <QJsonDocument>
#include <QJsonObject>

class DGestApi : public NetworkApi::AbstractApi
{
    Q_OBJECT
public:
    explicit DGestApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);
    Q_INVOKABLE QFuture<NetworkApi::LoginResult> login(const QString &email, const QString &password) override;
    Q_INVOKABLE QFuture<NetworkApi::RegisterResult> registerUser(const QString &name, const QString &email, const QString &password, const QString &c_password) override;
    Q_INVOKABLE QFuture<NetworkApi::ApiResult> logout() override;
    QFuture<NetworkApi::UserInfoResult> getUserInfo() override;
    bool isLoggedIn() const override;
    void saveToken(const QString &token) override;
    QString getToken() const override;
signals:
    void registerResult(const QVariant &result);
    void loginResult(const QVariant &result);
private:
    QNetworkRequest createRequest(const QString &path) const;
    QString m_token;
    QSettings m_settings;
    template<typename T>
    void emitResult(const QString& signalName, bool success, const T& data)
    {
        QVariantMap result;
        result["success"] = success;
        if (success) {
            result["data"] = QVariant::fromValue(data);
        } else {
            if constexpr (std::is_same_v<T, NetworkApi::Error>) {
                result["error"] = data.second; // Accessing the error message from the pair
                result["errorCode"] = data.first; // Assuming data.first is the error code
            } else if constexpr (std::is_same_v<T, QJsonObject>) {
                // Convert QJsonObject to a string representation
                QJsonDocument doc(data);
                 result["error"] = QString::fromUtf8(doc.toJson(QJsonDocument::Indented));
            } else {
                result["error"] = QString("Unknown error");
            }
        }
        QMetaObject::invokeMethod(this, signalName.toUtf8().constData(), Qt::QueuedConnection, Q_ARG(QVariant, QVariant::fromValue(result)));
    }



};

#endif // DGESTAPI_H
