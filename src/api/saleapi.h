// saleapi.h
#ifndef SALEAPI_H
#define SALEAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

namespace NetworkApi {

struct SaleItem {
    int id = 0;
    int product_id = 0;
    QString product_name;
    int quantity = 0;
    double unit_price = 0.0;
    double total_price = 0.0;
    double tax_rate = 0.0;
    double tax_amount = 0.0;
    double discount_amount = 0.0;
    QString notes;
    QVariantMap product;
    bool is_package = false;
       int package_id = 0;
       int total_pieces = 0;
       QVariantMap package;
};

struct Sale {
    int id = 0;
    int team_id = 0;
    int client_id = 0;
    int cash_source_id = 0;
    QString reference_number;
    double total_amount = 0.0;
    double paid_amount = 0.0;
    double tax_amount = 0.0;
    double discount_amount = 0.0;
    QString payment_status = "unpaid";
    QString status = "pending";
    QDateTime sale_date;
    QDateTime due_date;
    QString notes;
    QVariantMap client;
    QList<SaleItem> items;
    bool checked = false;
};

struct PaginatedSales {
    QList<Sale> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

struct Payment {
    int cash_source_id;
    double amount;
    QString payment_method;
    QString reference_number;
    QString notes;
};

class SaleApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit SaleApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getSales(const QString &search = QString(),
                                      const QString &sortBy = "sale_date",
                                      const QString &sortDirection = "desc",
                                      int page = 1,
                                      const QString &status = QString(),
                                      const QString &paymentStatus = QString());

    Q_INVOKABLE QFuture<void> getSale(int id);
    Q_INVOKABLE QFuture<void> createSale(const Sale &sale);
    Q_INVOKABLE QFuture<void> updateSale(int id, const Sale &sale);
    Q_INVOKABLE QFuture<void> deleteSale(int id);

    // Additional operations
    Q_INVOKABLE QFuture<void> addPayment(int id, const Payment &payment);
    Q_INVOKABLE QFuture<void> generateInvoice(int id);
    Q_INVOKABLE QFuture<void> getSummary(const QString &period = "month");

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

signals:
    // Success signals
    void salesReceived(const PaginatedSales &sales);
    void saleReceived(const QVariantMap &sale);
    void saleCreated(const Sale &sale);
    void saleUpdated(const Sale &sale);
    void saleDeleted(int id);
    void paymentAdded(const QVariantMap &payment);
    void invoiceGenerated(const QVariantMap &invoice);
    void summaryReceived(const QVariantMap &summary);

    // Error signals
    void errorSalesReceived(const QString &message, ApiStatus status, const QString &details);
    void errorSaleReceived(const QString &message, ApiStatus status, const QString &details);
    void errorSaleCreated(const QString &message, ApiStatus status, const QString &details);
    void errorSaleUpdated(const QString &message, ApiStatus status, const QString &details);
    void errorSaleDeleted(const QString &message, ApiStatus status, const QString &details);
    void errorPaymentAdded(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceGenerated(const QString &message, ApiStatus status, const QString &details);
    void errorSummaryReceived(const QString &message, ApiStatus status, const QString &details);

    void isLoadingChanged();

private:
    // Helper methods for JSON conversion
    Sale saleFromJson(const QJsonObject &json) const;
    SaleItem saleItemFromJson(const QJsonObject &json) const;
    QJsonObject saleToJson(const Sale &sale) const;
    QJsonObject saleItemToJson(const SaleItem &item) const;
    QJsonObject paymentToJson(const Payment &payment) const;
    PaginatedSales paginatedSalesFromJson(const QJsonObject &json) const;
    QVariantMap saleToVariantMap(const Sale &sale) const;
    QVariantMap saleItemToVariantMap(const SaleItem &item) const;

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

#endif // SALEAPI_H
