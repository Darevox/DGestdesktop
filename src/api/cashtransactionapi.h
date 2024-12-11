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
    QString transaction_type; // income, expense, transfer
    double amount;
    QString category;
    QString payment_method;
    QString description;
    QVariantMap cash_source;
    QVariantMap related_document; // Can hold sale, purchase, or invoice info
    bool checked = false;
};

struct PaginatedCashTransactions {
    QList<CashTransaction> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

struct TransactionTransfer {
    int from_cash_source_id;
    int to_cash_source_id;
    double amount;
    QString description;
    QString reference_number;
};

class CashTransactionApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit CashTransactionApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getTransactions(const QString &search = QString(),
                                             const QString &sortBy = "transaction_date",
                                             const QString &sortDirection = "desc",
                                             int page = 1,
                                             const QString &type = QString(),
                                             const QString &category = QString(),
                                             int cashSourceId = 0);

    Q_INVOKABLE QFuture<void> getTransaction(int id);
    Q_INVOKABLE QFuture<void> createTransaction(const CashTransaction &transaction);
    Q_INVOKABLE QFuture<void> updateTransaction(int id, const CashTransaction &transaction);
    Q_INVOKABLE QFuture<void> deleteTransaction(int id);

    // Additional operations
    Q_INVOKABLE QFuture<void> createTransfer(const TransactionTransfer &transfer);
    Q_INVOKABLE QFuture<void> getCategories();
    Q_INVOKABLE QFuture<void> getCashFlow(const QString &period = "month",
                                         int cashSourceId = 0);
    Q_INVOKABLE QFuture<void> generateReport(const QDateTime &startDate,
                                            const QDateTime &endDate,
                                            int cashSourceId = 0);

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

signals:
    // Success signals
    void transactionsReceived(const PaginatedCashTransactions &transactions);
    void transactionReceived(const QVariantMap &transaction);
    void transactionCreated(const CashTransaction &transaction);
    void transactionUpdated(const CashTransaction &transaction);
    void transactionDeleted(int id);
    void transferCreated(const QVariantMap &transfer);
    void categoriesReceived(const QVariantList &categories);
    void cashFlowReceived(const QVariantMap &cashFlow);
    void reportGenerated(const QString &reportUrl);

    // Error signals
    void errorTransactionsReceived(const QString &message, ApiStatus status, const QString &details);
    void errorTransactionReceived(const QString &message, ApiStatus status, const QString &details);
    void errorTransactionCreated(const QString &message, ApiStatus status, const QString &details);
    void errorTransactionUpdated(const QString &message, ApiStatus status, const QString &details);
    void errorTransactionDeleted(const QString &message, ApiStatus status, const QString &details);
    void errorTransferCreated(const QString &message, ApiStatus status, const QString &details);
    void errorCategoriesReceived(const QString &message, ApiStatus status, const QString &details);
    void errorCashFlowReceived(const QString &message, ApiStatus status, const QString &details);
    void errorReportGenerated(const QString &message, ApiStatus status, const QString &details);

    void isLoadingChanged();

private:
    CashTransaction transactionFromJson(const QJsonObject &json) const;
    QJsonObject transactionToJson(const CashTransaction &transaction) const;
    QJsonObject transferToJson(const TransactionTransfer &transfer) const;
    PaginatedCashTransactions paginatedTransactionsFromJson(const QJsonObject &json) const;
    QVariantMap transactionToVariantMap(const CashTransaction &transaction) const;

    QSettings m_settings;
    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            emit isLoadingChanged();
        }
    }
};

} // namespace NetworkApi

#endif // CASHTRANSACTIONAPI_H
