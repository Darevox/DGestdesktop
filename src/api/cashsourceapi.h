// cashsourceapi.h
#ifndef CASHSOURCEAPI_H
#define CASHSOURCEAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

namespace NetworkApi {

struct CashSource {
    int id;
    QString name;
    QString description;
    QString type;
    double balance;
    QString status;
    bool is_default;
    bool checked = false;
};

struct PaginatedCashSources {
    QList<CashSource> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

struct TransferData {
    int sourceId;
    int destinationId;
    double amount;
    QString notes;
};

class CashSourceApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit CashSourceApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getCashSources(const QString &search = QString(),
                                            const QString &sortBy = "created_at",
                                            const QString &sortDirection = "desc",
                                            int page = 1);
    Q_INVOKABLE QFuture<void> getCashSource(int id);
    Q_INVOKABLE QFuture<void> createCashSource(const CashSource &cashSource);
    Q_INVOKABLE QFuture<void> updateCashSource(int id, const CashSource &cashSource);
    Q_INVOKABLE QFuture<void> deleteCashSource(int id);

    // Transaction operations
    Q_INVOKABLE QFuture<void> deposit(int id, double amount, const QString &notes = QString());
    Q_INVOKABLE QFuture<void> withdraw(int id, double amount, const QString &notes = QString());
    Q_INVOKABLE QFuture<void> transfer(const TransferData &transferData);

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

signals:
    // Success signals
    void cashSourcesReceived(const PaginatedCashSources &cashSources);
    void cashSourceReceived(const QVariantMap &cashSource);
    void cashSourceCreated(const CashSource &cashSource);
    void cashSourceUpdated(const CashSource &cashSource);
    void cashSourceDeleted(int id);
    void depositCompleted(const QVariantMap &transaction);
    void withdrawalCompleted(const QVariantMap &transaction);
    void transferCompleted(const QVariantMap &transaction);

    // Error signals for each operation
    void errorCashSourcesReceived(const QString &message, ApiStatus status, const QString &details);
    void errorCashSourceReceived(const QString &message, ApiStatus status, const QString &details);
    void errorCashSourceCreated(const QString &message, ApiStatus status, const QString &details);
    void errorCashSourceUpdated(const QString &message, ApiStatus status, const QString &details);
    void errorCashSourceDeleted(const QString &message, ApiStatus status, const QString &details);
    void errorDeposit(const QString &message, ApiStatus status, const QString &details);
    void errorWithdrawal(const QString &message, ApiStatus status, const QString &details);
    void errorTransfer(const QString &message, ApiStatus status, const QString &details);
    void cashSourceNotFound();

    void isLoadingChanged();

private:
    CashSource cashSourceFromJson(const QJsonObject &json) const;
    QJsonObject cashSourceToJson(const CashSource &cashSource) const;
    PaginatedCashSources paginatedCashSourcesFromJson(const QJsonObject &json) const;
    QVariantMap cashSourceToVariantMap(const CashSource &cashSource) const;
    QVariantMap transactionToVariantMap(const QJsonObject &json) const;

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

#endif // CASHSOURCEAPI_H
