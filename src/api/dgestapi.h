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
    Q_INVOKABLE QFuture<NetworkApi::LoginResult> login(const QString &email, const QString &password, const bool &rememberme) override;
    Q_INVOKABLE QFuture<NetworkApi::RegisterResult> registerUser(const QString &name, const QString &email, const QString &password, const QString &c_password) override;
    Q_INVOKABLE QFuture<NetworkApi::ApiResult> logout() override;
    Q_INVOKABLE QFuture<NetworkApi::UserInfoResult> getUserInfo() override;
    Q_INVOKABLE bool isLoggedIn() const override;
    void saveToken(const QString &token) override;
    Q_INVOKABLE QString getToken() const override;
    Q_INVOKABLE bool getRemembeMe() const;
    void saveRemembeMe(const bool &rememberme);

signals:
    void registerResult(const QVariant &result);
    void loginResult(const QVariant &result);
    void getUserInfoResult(const QVariant &result);
    void logoutResult(const QVariant &result);

private:
    QNetworkRequest createRequest(const QString &path) const;
    QString m_token;
    bool m_rememberme;
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
                result["error"] = data.second;  // Set error message
                result["errorCode"] = static_cast<int>(data.first);  // Set error code as int
            } else if constexpr (std::is_same_v<T, QJsonObject>) {
                result["error"] = data["message"].toString();
                if (data.contains("errors")) {
                    result["validationErrors"] = data["errors"].toObject();
                }
                result["errorCode"] = data["error"].toBool() ? "VALIDATION_ERROR" : "UNKNOWN_ERROR";
            } else {
                result["error"] = QString("Unknown error");
                result["errorCode"] = "UNKNOWN_ERROR";
            }
        }
        QMetaObject::invokeMethod(this, signalName.toUtf8().constData(), Qt::QueuedConnection, Q_ARG(QVariant, QVariant::fromValue(result)));
    }



    template<typename T>
    T handleResponse(QNetworkReply *reply, const QString& signalName)
    {
        QJsonDocument response = QJsonDocument::fromJson(reply->readAll());
        QJsonObject jsonObject = response.object();

        if (reply->error() == QNetworkReply::NoError && !jsonObject.contains("error")) {
            // Successful response
            if (jsonObject.contains("accessToken")) {
                saveToken(jsonObject["accessToken"].toString());
            }
            emitResult(signalName, true, jsonObject);

            if constexpr (std::is_same_v<T, NetworkApi::LoginResult>) {
                return T(jsonObject["accessToken"].toString());
            } else if constexpr (std::is_same_v<T, NetworkApi::RegisterResult> || std::is_same_v<T, NetworkApi::UserInfoResult>) {
                return T(jsonObject);
            } else if constexpr (std::is_same_v<T, NetworkApi::ApiResult>) {
                return T(std::monostate{});
            }
        }   else {
            // Error response
            if (!jsonObject.isEmpty() && jsonObject.contains("message")) {
                // Backend error with JSON response
                emitResult(signalName, false, jsonObject); // Emit JSON error
                return T(NetworkApi::Error{QNetworkReply::NoError, jsonObject["message"].toString()});
            } else {
                // Network error
                NetworkApi::Error error{reply->error(), reply->errorString()};
                emitResult(signalName, false, error); // Emit network error
                return T(error);
            }
        }
    }

};

#endif // DGESTAPI_H
