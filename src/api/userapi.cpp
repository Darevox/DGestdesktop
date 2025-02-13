#include "userapi.h"
#include <QJsonDocument>
#include <QJsonObject>

namespace NetworkApi {
using namespace Qt::StringLiterals;

UserApi::UserApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    ,m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
    , m_rememberMe(false)
{
    m_token = m_settings.value("auth/token").toString();
    m_rememberMe = m_settings.value("auth/rememberMe", false).toBool();
}

QFuture<void> UserApi::login(const QString &email, const QString &password, bool rememberMe) {
    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/login"));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));

    QJsonObject jsonData;
    jsonData["email"_L1] = email;
    jsonData["password"_L1] = password;

    auto future = makeRequest<QString>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](TokenResponse response) {
        if (response.success) {
            saveToken(response.data.value_or(QString()));
            saveRememberMe(rememberMe);
            getUserInfo();
            Q_EMIT loginSuccess(response.data.value());
        } else {
            QString errorMessageDetails = getErrorMessages(response.error->details);
            Q_EMIT loginError(response.error->message, response.error->status,errorMessageDetails);
        }
    });

    // Ensure the function returns QFuture<void>
    return future.then([=]() {
        // Do nothing specific here, just ensure it returns void
    });
}

QFuture<void> UserApi::registerUser(const QString &name, const QString &email,
                                    const QString &password, const QString &confirmPassword) {
    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/register"));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));

    QJsonObject jsonData;
    jsonData["name"_L1] = name;
    jsonData["email"_L1] = email;
    jsonData["password"_L1] = password;
    jsonData["c_password"_L1] = confirmPassword;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Q_EMIT registerSuccess();
        } else {
            Q_EMIT registerError(response.error->message);
        }
    });

    return future.then([=]() {
        // Convert to QFuture<void>
    });
}

QFuture<void> UserApi::logout() {
    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/logout"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->get(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            saveToken(QString{});
            Q_EMIT logoutSuccess();
        } else {
            Q_EMIT logoutError(response.error->message);
        }
    });

    return future.then([=]() {
        // Return a void future
    });
}

QFuture<void> UserApi::getUserInfo() {
    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/user"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &userData = *response.data; // Dereference the optional
            m_user.name = userData["name"_L1].toString(); // Save the user's name
            m_user.email = userData["email"_L1].toString(); // Save the user's email
            m_user.team_id = userData["team_id"_L1].toInt();
            Q_EMIT userInfoReceived(response.data.value());
        } else {
            Q_EMIT userInfoError(response.error->message,response.error->status);
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
    Q_EMIT loginStateChanged(!token.isEmpty());
}

void UserApi::saveRememberMe(bool rememberMe) {
    m_rememberMe = rememberMe;
    m_settings.setValue("auth/rememberMe", rememberMe);
    if (!rememberMe) {
        m_settings.remove("auth/token");
    }
}

} // namespace NetworkApi
