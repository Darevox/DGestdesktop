#ifndef USERAPI_H
#define USERAPI_H

#include "abstractapi.h"
#include <QSettings>

struct User {
    QString name;
    QString email;
};

namespace NetworkApi {

class UserApi : public AbstractApi {
    Q_OBJECT
public:
    explicit UserApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    Q_INVOKABLE QFuture<void> login(const QString &email, const QString &password, bool rememberMe);
    Q_INVOKABLE QFuture<void> registerUser(const QString &name, const QString &email,
                                           const QString &password, const QString &confirmPassword);
    Q_INVOKABLE QFuture<void> logout();
    Q_INVOKABLE QFuture<void> getUserInfo();

    Q_INVOKABLE bool isLoggedIn() const;
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE bool getRememberMe() const;

    Q_INVOKABLE QString getUserName() const { return m_user.name; }
    Q_INVOKABLE QString getUserEmail() const { return m_user.email; }

private:
    void saveToken(const QString &token);
    void saveRememberMe(bool rememberMe);

    QSettings m_settings;
    bool m_rememberMe;

    User m_user;

signals:
    // New signals to emit for QML interaction
    void loginSuccess(const QString &token);
    void loginError(const QString &message ,ApiStatus status , QString errorMessageDetails);
    void registerSuccess();
    void registerError(const QString &message);
    void logoutSuccess();
    void logoutError(const QString &message);
    void userInfoReceived(const QJsonObject &userInfo);
    void userInfoError(const QString &message , ApiStatus status);

    void loginStateChanged(bool loggedIn);
};

} // namespace NetworkApi

#endif // USERAPI_H
