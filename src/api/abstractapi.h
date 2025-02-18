
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
#include <QJsonArray>
#include "config.h"
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
        Q_PROPERTY(QString apiHost READ apiHost NOTIFY apiHostChanged)
public:
    explicit AbstractApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);
    void setApiHost(const QString &host);
    QString apiHost() const;

protected:
    QNetworkAccessManager *m_netManager;
    QString m_apiHost;
    QString m_token;
    void setNetworkManager(QNetworkAccessManager *manager) {
        m_netManager = manager;
    }

    // Helper methods that need implementation
    QNetworkRequest createRequest(const QString &path) const;
    QUrl apiUrl(const QString &path) const;
    QString getErrorMessages(const QJsonObject &errorDetails) const{
        QStringList messagesList;

        // Iterate through each field (email, password, etc.)
        for (auto it = errorDetails.constBegin(); it != errorDetails.constEnd(); ++it) {
            QString fieldName = it.key();
            QJsonArray fieldErrors = it.value().toArray();

            // For each field, collect all error messages
            for (const QJsonValue &error : fieldErrors) {
              //  messagesList.append(QString("%1: %2").arg(fieldName, error.toString()));
                messagesList.append(error.toString());
            }
        }

        // Join all messages with a semicolon for better readability
        return messagesList.join(QStringLiteral(" "));
    }

    // 1. ERROR STATUS DETERMINATION
    ApiStatus determineErrorStatus(const QNetworkReply *reply, const QJsonObject &jsonResponse = QJsonObject()) const {
        // First priority: Check API-level errors in JSON response
        if (!jsonResponse.isEmpty()) {
            if (jsonResponse.value(QStringLiteral("error")).toBool() || jsonResponse.contains(QStringLiteral("errors"))) {
                // If there are field-specific errors, it's a validation error
                if (jsonResponse.contains(QStringLiteral("errors"))) {
                    return ApiStatus::ValidationError;
                }
                return ApiStatus::ServerError;
            }
        }

        // Second priority: Check network-level errors
        if (reply->error() != QNetworkReply::NoError) {
            switch (reply->error()) {
            case QNetworkReply::ConnectionRefusedError:
            case QNetworkReply::RemoteHostClosedError:
            case QNetworkReply::HostNotFoundError:
            case QNetworkReply::TimeoutError:
            case QNetworkReply::NetworkSessionFailedError:
            case QNetworkReply::TemporaryNetworkFailureError:
                //case QNetworkReply::NetworkConnectionRefusedError:
                return ApiStatus::NetworkError;
            case QNetworkReply::ServiceUnavailableError:
            case QNetworkReply::InternalServerError:
                // case QNetworkReply::BadGatewayError:
                //  case QNetworkReply::GatewayTimeoutError:
                return ApiStatus::ServerError;
            case QNetworkReply::AuthenticationRequiredError:
            case QNetworkReply::ContentAccessDenied:
            case QNetworkReply::ContentOperationNotPermittedError:
                return ApiStatus::AuthenticationError;
            default:
                return ApiStatus::UnknownError;
            }
        }

        return ApiStatus::Success;
    }

    // 2. ERROR MESSAGE GENERATION
    QString getErrorMessage(ApiStatus status, const QString& originalMessage, const QJsonObject &jsonResponse = QJsonObject()) const {
        // First priority: Use API-provided messages for certain errors
        if (!jsonResponse.isEmpty() && jsonResponse.contains(QStringLiteral("message"))) {
            QString apiMessage = jsonResponse[QStringLiteral("message")].toString();
            if (status == ApiStatus::ValidationError ||
                status == ApiStatus::ServerError ||
                status == ApiStatus::AuthenticationError) {
                return apiMessage;
            }
        }
        // Second priority: Use standard error messages
        switch (status) {

        case ApiStatus::NetworkError:
            return tr("Unable to connect to server. Please check your internet connection and try again.");
        case ApiStatus::ServerError:
            return tr("Server is currently unavailable. Please try again later.");
        case ApiStatus::AuthenticationError:
            return tr("Authentication error. Please login again.");
        case ApiStatus::ValidationError:
            if (!jsonResponse.isEmpty() && jsonResponse.contains(QStringLiteral("errors"))) {
                return getErrorMessages(jsonResponse[QStringLiteral("errors")].toObject());
            }
            return originalMessage;
        default:
            return originalMessage.isEmpty() ?
                       tr("An unknown error occurred. Please try again.") :
                       originalMessage;
        }
    }

    // 3. MAIN RESPONSE HANDLER
    template<typename T>
    ApiResponse<T> handleResponse(QNetworkReply *reply) {
        // Step 1: Read and parse response
        QByteArray responseData = reply->readAll();
        QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
        QJsonObject jsonObject = jsonDoc.object();

        // Step 2: Determine error status
        ApiStatus status = determineErrorStatus(reply, jsonObject);

        // Step 3: Handle success case
        if (status == ApiStatus::Success) {
            if constexpr (std::is_same_v<T, QJsonObject>) {
                return {true, jsonObject, std::nullopt};
            } else if constexpr (std::is_same_v<T, QString>) {
                return {true, jsonObject[QStringLiteral("accessToken")].toString(), std::nullopt};
            } else if constexpr (std::is_same_v<T, std::monostate>) {
                return {true, std::monostate{}, std::nullopt};
            }
        }

        // Step 4: Handle error case
        ApiError error;
        error.status = status;
        error.message = getErrorMessage(status, reply->errorString(), jsonObject);
        if (jsonObject.contains(QStringLiteral("errors"))) {
            error.details = jsonObject[QStringLiteral("errors")].toObject();
        }

        // Step 5: Debug output
        qDebug() << "Error Status:" << static_cast<int>(status);
        qDebug() << "Error Message:" << error.message;
        qDebug() << "Error Details:" << error.details;

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
Q_SIGNALS:
    void apiHostChanged();
    void errorOccurred(const ApiError &error);
};

} // namespace NetworkApi

#endif // ABSTRACTAPI_H
