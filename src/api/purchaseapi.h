// purchaseapi.h
#ifndef PURCHASEAPI_H
#define PURCHASEAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

namespace NetworkApi {

struct PurchaseItem {
    int id;
    int product_id;
    QString product_name;
    int quantity;
    double unit_price;
    double total_price;
    QString notes;
    QVariantMap product; // Will hold detailed product information
};

struct Purchase {
    int id;
    QString reference_number;
    QDateTime purchase_date;
    int supplier_id;
    QVariantMap supplier;
    QString status;
    QString payment_status;
    double total_amount;
    double paid_amount;
    double remaining_amount;
    QString notes;
    QList<PurchaseItem> items;
    bool checked = false;
};

struct PaginatedPurchases {
    QList<Purchase> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

struct PurchasePayment {
    int cash_source_id;
    double amount;
    QString payment_method;
    QString reference_number;
    QString notes;
};

class PurchaseApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit PurchaseApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getPurchases(const QString &search = QString(),
                                          const QString &sortBy = "purchase_date",
                                          const QString &sortDirection = "desc",
                                          int page = 1,
                                          const QString &status = QString(),
                                          const QString &paymentStatus = QString());

    Q_INVOKABLE QFuture<void> getPurchase(int id);
    Q_INVOKABLE QFuture<void> createPurchase(const Purchase &purchase);
    Q_INVOKABLE QFuture<void> updatePurchase(int id, const Purchase &purchase);
    Q_INVOKABLE QFuture<void> deletePurchase(int id);

    // Additional operations
    Q_INVOKABLE QFuture<void> addPayment(int id, const PurchasePayment &payment);
    Q_INVOKABLE QFuture<void> generateInvoice(int id);
    Q_INVOKABLE QFuture<void> getSummary(const QString &period = "month");

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

signals:
    // Success signals
    void purchasesReceived(const PaginatedPurchases &purchases);
    void purchaseReceived(const QVariantMap &purchase);
    void purchaseCreated(const Purchase &purchase);
    void purchaseUpdated(const Purchase &purchase);
    void purchaseDeleted(int id);
    void paymentAdded(const QVariantMap &payment);
    void invoiceGenerated(const QVariantMap &invoice);
    void summaryReceived(const QVariantMap &summary);

    // Error signals for each operation
    void errorPurchasesReceived(const QString &message, ApiStatus status, const QString &details);
    void errorPurchaseReceived(const QString &message, ApiStatus status, const QString &details);
    void errorPurchaseCreated(const QString &message, ApiStatus status, const QString &details);
    void errorPurchaseUpdated(const QString &message, ApiStatus status, const QString &details);
    void errorPurchaseDeleted(const QString &message, ApiStatus status, const QString &details);
    void errorPaymentAdded(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceGenerated(const QString &message, ApiStatus status, const QString &details);
    void errorSummaryReceived(const QString &message, ApiStatus status, const QString &details);

    void isLoadingChanged();

private:
    Purchase purchaseFromJson(const QJsonObject &json) const;
    PurchaseItem purchaseItemFromJson(const QJsonObject &json) const;
    QJsonObject purchaseToJson(const Purchase &purchase) const;
    QJsonObject purchaseItemToJson(const PurchaseItem &item) const;
    QJsonObject paymentToJson(const PurchasePayment &payment) const;
    PaginatedPurchases paginatedPurchasesFromJson(const QJsonObject &json) const;
    QVariantMap purchaseToVariantMap(const Purchase &purchase) const;
    QVariantMap purchaseItemToVariantMap(const PurchaseItem &item) const;

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

#endif // PURCHASEAPI_H
