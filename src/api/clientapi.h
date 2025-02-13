// clientapi.h
#ifndef CLIENTAPI_H
#define CLIENTAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

namespace NetworkApi {

struct Client {
    int id;
    QString name;
    QString email;
    QString phone;
    QString address;
    QString tax_number;
    QString payment_terms;
    QString notes;
    QString status;
    double balance;
    bool checked = false;
};

struct PaginatedClients {
    QList<Client> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

class ClientApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit ClientApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getClients(const QString &search = QString(),
                                        const QString &sortBy = QStringLiteral("created_at"),
                                        const QString &sortDirection = QStringLiteral("desc"),
                                        int page = 1,
                                        const QString &status = QString());

    Q_INVOKABLE QFuture<void> getClient(int id);
    Q_INVOKABLE QFuture<void> createClient(const Client &client);
    Q_INVOKABLE QFuture<void> updateClient(int id, const Client &client);
    Q_INVOKABLE QFuture<void> deleteClient(int id);

    // Additional operations
    Q_INVOKABLE QFuture<void> getSales(int id, int page = 1);
    Q_INVOKABLE QFuture<void> getPayments(int id, int page = 1);
    Q_INVOKABLE QFuture<void> getStatistics(int id);

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

Q_SIGNALS:
    // Success signals
    void clientsReceived(const PaginatedClients &clients);
    void clientReceived(const QVariantMap &client);
    void clientCreated(const Client &client);
    void clientUpdated(const Client &client);
    void clientDeleted(int id);
    void salesReceived(const QVariantMap &sales);
    void paymentsReceived(const QVariantMap &payments);
    void statisticsReceived(const QVariantMap &statistics);

    // Error signals
    void errorClientsReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorClientReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorClientCreated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorClientUpdated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorClientDeleted(const QString &message, ApiStatus status, const QByteArray &details);
    void errorSalesReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorPaymentsReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorStatisticsReceived(const QString &message, ApiStatus status, const QByteArray &details);

    void isLoadingChanged();

private:
    Client clientFromJson(const QJsonObject &json) const;
    QJsonObject clientToJson(const Client &client) const;
    PaginatedClients paginatedClientsFromJson(const QJsonObject &json) const;
    QVariantMap clientToVariantMap(const Client &client) const;

    QSettings m_settings;
    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            Q_EMIT isLoadingChanged();
        }
    }
};

} // namespace NetworkApi

#endif // CLIENTAPI_H
