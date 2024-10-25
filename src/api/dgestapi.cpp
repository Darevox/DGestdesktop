#include "dgestapi.h"


DGestApi::DGestApi(QNetworkAccessManager *netManager, QObject *parent)
    : NetworkApi::AbstractApi(netManager, parent)
//, m_settings("YourCompany", "DGestApp")
{
    m_token = m_settings.value("auth_token").toString();
    m_rememberme = m_settings.value("remember_me").toBool();
    setApiHost("https://dim.dervox.com"); // Set your actual API host here
}

QFuture<NetworkApi::LoginResult> DGestApi::login(const QString &email, const QString &password, const bool &rememberme)
{
    QNetworkRequest request = createRequest("/api/v1/login");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["email"] = email;
    json["password"] = password;
    QJsonDocument doc(json);

    return post<NetworkApi::LoginResult>(std::move(request), doc.toJson(), [this, rememberme](QNetworkReply *reply) {
        auto result = handleResponse<NetworkApi::LoginResult>(reply, "loginResult");
        if (std::holds_alternative<QString>(result)) {
            saveRemembeMe(rememberme);
        }
        return result;
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
        return handleResponse<NetworkApi::RegisterResult>(reply, "registerResult");
    });
}

QFuture<NetworkApi::ApiResult> DGestApi::logout()
{
    QNetworkRequest request = createRequest("/api/v1/logout");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    return get<NetworkApi::ApiResult>(std::move(request), [this](QNetworkReply *reply) {
        auto result = handleResponse<NetworkApi::ApiResult>(reply, "logoutResult");
        if (std::holds_alternative<std::monostate>(result)) {
            saveToken("");
        }
        return result;
    });
}

QFuture<NetworkApi::UserInfoResult> DGestApi::getUserInfo()
{
    QNetworkRequest request = createRequest("/api/v1/user");
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    return get<NetworkApi::UserInfoResult>(std::move(request), [this](QNetworkReply *reply) {
        return handleResponse<NetworkApi::UserInfoResult>(reply, "getUserInfoResult");
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

bool DGestApi::getRemembeMe() const
{
    return !m_token.isEmpty() && m_rememberme;
}

void DGestApi::saveRemembeMe(const bool &rememberme)
{
    m_rememberme = rememberme;
    m_settings.setValue("remember_me", rememberme);
}

QNetworkRequest DGestApi::createRequest(const QString &path) const
{
    return QNetworkRequest(apiUrl(path));
}

