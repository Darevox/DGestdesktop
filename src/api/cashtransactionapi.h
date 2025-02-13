// cashtransactionapi.h
#ifndef CASHTRANSACTIONAPI_H
#define CASHTRANSACTIONAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

namespace NetworkApi {

struct CashTransaction {
    int id;
    QString reference_number;
    QDateTime transaction_date;
    int cash_source_id;
    QString type;  // Changed from transaction_type to match backend
    double amount;
    QString category;
    QString payment_method;
    QString description;
    QVariantMap cash_source;
    QVariantMap transfer_destination;  // Changed from related_document to match backend
    bool checked = false;
};

struct PaginatedCashTransactions {
    QList<CashTransaction> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

class CashTransactionApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit CashTransactionApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // Match controller endpoints
    Q_INVOKABLE QFuture<void> getTransactions(
        const QString &search = QString(),
        const QString &sortBy = QStringLiteral("transaction_date"),
        const QString &sortDirection = QStringLiteral("desc"),
        int page = 1,
        const QString &type = QString(),
        int cashSourceId = 0,
        double minAmount = 0,
        double maxAmount = 0,
        const QDateTime &startDate = QDateTime(),
        const QDateTime &endDate = QDateTime()
    );

    Q_INVOKABLE QFuture<void> getTransaction(int id);
    Q_INVOKABLE QFuture<void> getTransactionsBySource(int sourceId, int page = 1);
    Q_INVOKABLE QFuture<void> getSummary(
        const QDateTime &startDate = QDateTime(),
        const QDateTime &endDate = QDateTime()
    );

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

Q_SIGNALS:
    // Success signals
    void transactionsReceived(const PaginatedCashTransactions &transactions);
    void transactionReceived(const QVariantMap &transaction);
    void transactionsBySourceReceived(const PaginatedCashTransactions &transactions);
    void summaryReceived(const QVariantMap &summary);

    // Error signals
    void errorTransactionsReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorTransactionReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorTransactionsBySourceReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorSummaryReceived(const QString &message, ApiStatus status, const QByteArray &details);

    void isLoadingChanged();

private:
    CashTransaction transactionFromJson(const QJsonObject &json) const;
    QVariantMap transactionToVariantMap(const CashTransaction &transaction) const;
    PaginatedCashTransactions paginatedTransactionsFromJson(const QJsonObject &json) const;

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

#endif // CASHTRANSACTIONAPI_H
