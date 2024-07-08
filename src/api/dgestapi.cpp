#include "dgestapi.h"


DGestApi::DGestApi(QNetworkAccessManager *netManager, QObject *parent)
    : NetworkApi::AbstractApi(netManager, parent)
//, m_settings("YourCompany", "DGestApp")
{
    m_token = m_settings.value("auth_token").toString();
    setApiHost("http://127.0.0.1:8000"); // Set your actual API host here
}
QFuture<NetworkApi::LoginResult> DGestApi::login(const QString &email, const QString &password)
{
    QNetworkRequest request = createRequest("/api/v1/login");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["email"] = email;
    json["password"] = password;
    QJsonDocument doc(json);

    return  post<NetworkApi::LoginResult>(std::move(request), doc.toJson(), [this](QNetworkReply *reply) {
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument response = QJsonDocument::fromJson(reply->readAll());
            QString token = response.object()["accessToken"].toString();
            saveToken(token);
            emitResult("loginResult", true, response.object());
            return NetworkApi::LoginResult(token);
        }
        NetworkApi::Error error{reply->error(), reply->errorString()};
        QByteArray responseBytes = reply->readAll();
        QJsonDocument responseDoc = QJsonDocument::fromJson(responseBytes);
        if (!responseBytes.isEmpty() && responseDoc.isObject()) {
            // If there is a response body, include it in the error handling
            emitResult("loginResult", false, responseDoc.object());
        } else {
            // If there is no response body, just pass the error
            emitResult("loginResult", false, error);
        }
        return NetworkApi::LoginResult(error);
    });

}
QFuture<NetworkApi::RegisterResult> DGestApi::registerUser(const QString &name, const QString &email, const QString &password, const QString &c_password)
{
    QNetworkRequest request = createRequest("/api/v1/register");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["name"] = name;
    json["email"] = email;
    json["password"] = password;
    json["c_password"] = c_password;
    QJsonDocument doc(json);

    return post<NetworkApi::RegisterResult>(std::move(request), doc.toJson(), [this](QNetworkReply *reply) {
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument response = QJsonDocument::fromJson(reply->readAll());
            QString token = response.object()["accessToken"].toString();
            saveToken(token);
            emitResult("registerResult", true, response.object());
            return NetworkApi::RegisterResult(response.object());
        }
        NetworkApi::Error error{reply->error(), reply->errorString()};
        QByteArray responseBytes = reply->readAll();
        QJsonDocument responseDoc = QJsonDocument::fromJson(responseBytes);
        if (!responseBytes.isEmpty() && responseDoc.isObject()) {
            // If there is a response body, include it in the error handling
            emitResult("registerResult", false, responseDoc.object());
        } else {
            // If there is no response body, just pass the error
            emitResult("registerResult", false, error);
        }
        return NetworkApi::RegisterResult(error);
    });

}

QFuture<NetworkApi::ApiResult> DGestApi::logout()
{
    QNetworkRequest request = createRequest("/v1/logout");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    return get<NetworkApi::ApiResult>(std::move(request), [this](QNetworkReply *reply) {
        if (reply->error() == QNetworkReply::NoError) {
            saveToken("");
            return NetworkApi::ApiResult(NetworkApi::Success{});
        }
        return NetworkApi::ApiResult(NetworkApi::Error{reply->error(), reply->errorString()});
    });
}

QFuture<NetworkApi::UserInfoResult> DGestApi::getUserInfo()
{
    QNetworkRequest request = createRequest("/v1/user");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    return get<NetworkApi::UserInfoResult>(std::move(request), [](QNetworkReply *reply) {
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument response = QJsonDocument::fromJson(reply->readAll());
            return NetworkApi::UserInfoResult(response.object());
        }
        return NetworkApi::UserInfoResult(NetworkApi::Error{reply->error(), reply->errorString()});
    });
}

bool DGestApi::isLoggedIn() const
{
    return !m_token.isEmpty();
}

void DGestApi::saveToken(const QString &token)
{
    m_token = token;
    m_settings.setValue("auth_token", token);
}

QString DGestApi::getToken() const
{
    return m_token;
}

QNetworkRequest DGestApi::createRequest(const QString &path) const
{
    return QNetworkRequest(apiUrl(path));
}

