#ifndef SUBSCRIPTIONAPI_H
#define SUBSCRIPTIONAPI_H

#include "abstractapi.h"
#include <QSettings>

struct Subscription {
    QString type;
    QString status;
    QString startDate;
    QString expirationDate;
    int daysUntilExpiration;
    bool isActive;
    QJsonObject planDetails;
};

namespace NetworkApi {

class SubscriptionApi : public AbstractApi {
    Q_OBJECT
public:
    explicit SubscriptionApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    Q_INVOKABLE QFuture<void> getStatus(const QString &token );
    Q_INVOKABLE bool isActive() const { return m_subscription.isActive; }

    Q_INVOKABLE QString getType() const { return m_subscription.type; }
    Q_INVOKABLE QString getStatusString() const { return m_subscription.status; }
    Q_INVOKABLE QString getStartDate() const { return m_subscription.startDate; }
    Q_INVOKABLE QString getExpirationDate() const {
        QDateTime expirationDate = QDateTime::fromString(m_subscription.expirationDate, Qt::ISODate);
        // Return the date formatted as "YYYY-MM-DD"
        return expirationDate.toString(QStringLiteral("yyyy-MM-dd")); }
    Q_INVOKABLE int getDaysUntilExpiration() const { return m_subscription.daysUntilExpiration; }
    Q_INVOKABLE QJsonObject getPlanDetails() const { return m_subscription.planDetails; }
    Q_INVOKABLE QString getToken() const;

Q_SIGNALS:
    void statusReceived(const Subscription &subscription);
    void statusError(const QString &message);

private:
    Subscription m_subscription;
    QSettings m_settings;

};

} // namespace NetworkApi

#endif // SUBSCRIPTIONAPI_H
