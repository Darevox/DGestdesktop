#include "subscriptionapi.h"
#include <QJsonDocument>
#include <QJsonObject>

namespace NetworkApi {

SubscriptionApi::SubscriptionApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{

}

QFuture<void> SubscriptionApi::getStatus(const QString &token ) {
    QString authToken = token.isEmpty() ? getToken() : token;  // Use provided token or fallback
    QNetworkRequest request = createRequest("/api/v1/subscription/status");
    qDebug() << " 1 Token:" << authToken;
    request.setRawHeader("Authorization", QString("Bearer %1").arg(authToken).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        qDebug() << "Token:" << authToken;

        if (response.success && response.data.has_value()) {
            const QJsonObject &responseData = *response.data;
            qDebug() << "Full Response Data:" << responseData;

            // Check if 'subscription' key exists and is an object
            if (responseData.contains("subscription") && responseData["subscription"].isObject()) {
                const QJsonObject &subscriptionData = responseData["subscription"].toObject();

                // Parse subscription data
                m_subscription.type = subscriptionData["type"].toString();
                m_subscription.status = subscriptionData["status"].toString();
                m_subscription.startDate = subscriptionData["start_date"].toString();
                m_subscription.expirationDate = subscriptionData["expiration_date"].toString();
                m_subscription.daysUntilExpiration = subscriptionData["days_until_expiration"].toInt();
                m_subscription.isActive = subscriptionData["is_active"].toBool();
                m_subscription.planDetails = subscriptionData["plan_details"].toObject();

                // Debug parsed data
                qDebug() << "Parsed Subscription Type:" << m_subscription.type;

                // Emit signal after parsing
                emit statusReceived(m_subscription);
            } else {
                emit statusError("Subscription data not found in response.");
            }
        } else {
            QString errorMessage = response.error ? response.error->message : "Unknown error";
            emit statusError(errorMessage);
        }
    });
    return future.then([=]() {
        // Return a void future
    });
}
QString SubscriptionApi::getToken() const {
    QString token=m_settings.value("auth/token").toString();
    return token;
}

} // namespace NetworkApi
