#include "subscriptionapi.h"
#include <QJsonDocument>
#include <QJsonObject>

namespace NetworkApi {
using namespace Qt::StringLiterals;

SubscriptionApi::SubscriptionApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{

}

QFuture<void> SubscriptionApi::getStatus(const QString &token ) {
    QString authToken = token.isEmpty() ? getToken() : token;  // Use provided token or fallback
    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/subscription/status"));
    qDebug() << " 1 Token:" << authToken;
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(authToken).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        qDebug() << "Token:" << authToken;

        if (response.success && response.data.has_value()) {
            const QJsonObject &responseData = *response.data;
            qDebug() << "Full Response Data:" << responseData;

            // Check if 'subscription' key exists and is an object
            if (responseData.contains("subscription"_L1) && responseData["subscription"_L1].isObject()) {
                const QJsonObject &subscriptionData = responseData["subscription"_L1].toObject();

                // Parse subscription data
                m_subscription.type = subscriptionData["type"_L1].toString();
                m_subscription.status = subscriptionData["status"_L1].toString();
                m_subscription.startDate = subscriptionData["start_date"_L1].toString();
                m_subscription.expirationDate = subscriptionData["expiration_date"_L1].toString();
                m_subscription.daysUntilExpiration = subscriptionData["days_until_expiration"_L1].toInt();
                m_subscription.isActive = subscriptionData["is_active"_L1].toBool();
                m_subscription.planDetails = subscriptionData["plan_details"_L1].toObject();

                // Debug parsed data
                qDebug() << "Parsed Subscription Type:" << m_subscription.type;

                // Q_EMIT signal after parsing
                Q_EMIT statusReceived(m_subscription);
            } else {
                Q_EMIT statusError("Subscription data not found in response."_L1);
            }
        } else {
            QString errorMessage = response.error ? response.error->message : "Unknown error"_L1;
            Q_EMIT statusError(errorMessage);
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
