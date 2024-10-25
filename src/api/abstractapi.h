// abstractapi.h
#ifndef ABSTRACTAPI_H
#define ABSTRACTAPI_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFuture>
#include <QJsonObject>
#include <variant>
#include <optional>
#include <QJsonDocument>

namespace NetworkApi {

// Keep your existing enums and structs as they are
enum class ApiStatus {
    Success,
    ValidationError,
    NetworkError,
    ServerError,
    AuthenticationError,
    UnknownError
};

struct ApiError {
    ApiStatus status;
    QString message;
    QJsonObject details;
};

template<typename T>
struct ApiResponse {
    bool success;
    std::optional<T> data;
    std::optional<ApiError> error;
};

using JsonResponse = ApiResponse<QJsonObject>;
using TokenResponse = ApiResponse<QString>;
using VoidResponse = ApiResponse<std::monostate>;

class AbstractApi : public QObject {
    Q_OBJECT
public:
    explicit AbstractApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);
    void setApiHost(const QString &host);
    QString apiHost() const;

protected:
    QNetworkAccessManager *m_netManager;
    QString m_apiHost;
    QString m_token;

    // Helper methods that need implementation
    QNetworkRequest createRequest(const QString &path) const;
    QUrl apiUrl(const QString &path) const;

    // Your existing template methods remain the same
    template<typename T>
    ApiResponse<T> handleResponse(QNetworkReply *reply) {
        // Keep your existing implementation
        QJsonDocument response = QJsonDocument::fromJson(reply->readAll());
        QJsonObject jsonObject = response.object();

        if (reply->error() == QNetworkReply::NoError && !jsonObject.contains("error")) {
            if constexpr (std::is_same_v<T, QJsonObject>) {
                return {true, jsonObject, std::nullopt};
            } else if constexpr (std::is_same_v<T, QString>) {
                return {true, jsonObject["accessToken"].toString(), std::nullopt};
            } else if constexpr (std::is_same_v<T, std::monostate>) {
                return {true, std::monostate{}, std::nullopt};
            }
        }

        ApiError error;
        if (!jsonObject.isEmpty() && jsonObject.contains("message")) {
            error.message = jsonObject["message"].toString();
            error.status = jsonObject.contains("errors") ?
                               ApiStatus::ValidationError :
                               ApiStatus::ServerError;
            error.details = jsonObject["errors"].toObject();
        } else {
            error.message = reply->errorString();
            error.status = ApiStatus::NetworkError;
        }

        return {false, std::nullopt, error};
    }

    template<typename T>
    QFuture<ApiResponse<T>> makeRequest(std::function<QNetworkReply*(void)> request) {
        // Keep your existing implementation
        auto interface = std::make_shared<QFutureInterface<ApiResponse<T>>>(QFutureInterfaceBase::Started);
        QNetworkReply *reply = request();

        connect(reply, &QNetworkReply::finished, this, [=]() {
            if (!interface->isCanceled()) {
                interface->reportResult(handleResponse<T>(reply));
                interface->reportFinished();
            }
            reply->deleteLater();
        });

        return interface->future();
    }

signals:
    void apiHostChanged();
    void errorOccurred(const ApiError &error);
};

} // namespace NetworkApi

#endif // ABSTRACTAPI_H
