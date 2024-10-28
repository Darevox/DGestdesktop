#include "userapi.h"
#include <QJsonDocument>
#include <QJsonObject>

namespace NetworkApi {

UserApi::UserApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
    , m_rememberMe(false)
{
    m_token = m_settings.value("auth/token").toString();
    m_rememberMe = m_settings.value("auth/rememberMe", false).toBool();
}

QFuture<void> UserApi::login(const QString &email, const QString &password, bool rememberMe) {
    QNetworkRequest request = createRequest("/api/v1/login");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject jsonData;
    jsonData["email"] = email;
    jsonData["password"] = password;

    auto future = makeRequest<QString>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](TokenResponse response) {
        if (response.success) {
            saveToken(response.data.value_or(QString()));
            saveRememberMe(rememberMe);
            getUserInfo();
            emit loginSuccess(response.data.value());
        } else {
            QString errorMessageDetails = getErrorMessages(response.error->details);
            emit loginError(response.error->message, response.error->status,errorMessageDetails);
        }
    });

    // Ensure the function returns QFuture<void>
    return future.then([=]() {
        // Do nothing specific here, just ensure it returns void
    });
}

QFuture<void> UserApi::registerUser(const QString &name, const QString &email,
                                    const QString &password, const QString &confirmPassword) {
    QNetworkRequest request = createRequest("/api/v1/register");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject jsonData;
    jsonData["name"] = name;
    jsonData["email"] = email;
    jsonData["password"] = password;
    jsonData["c_password"] = confirmPassword;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit registerSuccess();
        } else {
            emit registerError(response.error->message);
        }
    });

    return future.then([=]() {
        // Convert to QFuture<void>
    });
}

QFuture<void> UserApi::logout() {
    QNetworkRequest request = createRequest("/api/v1/logout");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->get(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            saveToken("");
            emit logoutSuccess();
        } else {
            emit logoutError(response.error->message);
        }
    });

    return future.then([=]() {
        // Return a void future
    });
}

QFuture<void> UserApi::getUserInfo() {
    QNetworkRequest request = createRequest("/api/v1/user");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &userData = *response.data; // Dereference the optional
            m_user.name = userData["name"].toString(); // Save the user's name
            m_user.email = userData["email"].toString(); // Save the user's email
            emit userInfoReceived(response.data.value());
        } else {
            emit userInfoError(response.error->message,response.error->status);
        }
    });

    return future.then([=]() {
        // Return a void future
    });
}

bool UserApi::isLoggedIn() const {
    return !m_token.isEmpty();
}

QString UserApi::getToken() const {
    return m_token;
}

bool UserApi::getRememberMe() const {
    return m_rememberMe;
}

void UserApi::saveToken(const QString &token) {
    m_token = token;
    bool rememberMe = getRememberMe();
    if (rememberMe) {
        m_settings.setValue("auth/token", token);
    } else {
        m_settings.remove("auth/token");
    }
    emit loginStateChanged(!token.isEmpty());
}

void UserApi::saveRememberMe(bool rememberMe) {
    m_rememberMe = rememberMe;
    m_settings.setValue("auth/rememberMe", rememberMe);
    if (!rememberMe) {
        m_settings.remove("auth/token");
    }
}

} // namespace NetworkApi
