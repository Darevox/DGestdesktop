// purchaseapi.h
#ifndef PURCHASEAPI_H
#define PURCHASEAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

namespace NetworkApi {
struct ProductPackage {
    int id;
    QString name;
    int pieces_per_package;
    double purchase_price;
    double selling_price;
    QString barcode;
};

struct PurchaseItem {
    int id = 0;
    int product_id = 0;
    QString product_name;
    int quantity = 0;
    double unit_price = 0.0;
    double selling_price = 0.0;  // Add this
    double total_price = 0.0;
    double tax_rate = 0.0;
    double tax_amount = 0.0;
    double discount_amount = 0.0;
    QString notes;
    QVariantMap product;
    int package_id;
    bool update_prices = false;  // Add this
    bool is_package;
    ProductPackage package;
    bool update_package_prices = false;  // Add this
    double package_purchase_price = 0.0; // Add this
    double package_selling_price = 0.0;  // Add this
};

struct Purchase {
    int id = 0;
    int team_id = 0;
    int supplier_id = 0;
    int cash_source_id = 0;
    QString reference_number;
    double total_amount = 0.0;
    double paid_amount = 0.0;
    double tax_amount = 0.0;
    double discount_amount = 0.0;
    QString payment_status = QStringLiteral("unpaid");
    QString status = QStringLiteral("pending");
    QDateTime purchase_date;
    QDateTime due_date;
    QString notes;
    QVariantMap supplier;
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
                                           const QString &sortBy = QStringLiteral("purchase_date"),
                                           const QString &sortDirection = QStringLiteral("desc"),
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
    Q_INVOKABLE QFuture<void> getSummary(const QString &period = QStringLiteral("month"));

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

Q_SIGNALS:
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
    void errorPurchasesReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorPurchaseReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorPurchaseCreated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorPurchaseUpdated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorPurchaseDeleted(const QString &message, ApiStatus status, const QByteArray &details);
    void errorPaymentAdded(const QString &message, ApiStatus status, const QByteArray &details);
    void errorInvoiceGenerated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorSummaryReceived(const QString &message, ApiStatus status, const QByteArray &details);

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
            Q_EMIT isLoadingChanged();
        }
    }
};

} // namespace NetworkApi

#endif // PURCHASEAPI_H
