#ifndef INVOICEAPI_H
#define INVOICEAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>
#include <QFuture>
#include <QPromise>
#include <QNetworkReply>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QDateTime>
#include <QUrl>
namespace NetworkApi {

struct InvoiceItem {
    int id;
    QString description;
    int quantity;
    double unit_price;
    double total_price;
    QString notes;
};

struct Invoice {
    int id;
    int team_id;
    QString reference_number;
    QString invoiceable_type;
    int invoiceable_id;
    double total_amount;
    double tax_amount;
    double discount_amount;
    QString status;
    QDateTime issue_date;
    QDateTime due_date;
    QString notes;
    QVariantMap meta_data;
    QList<InvoiceItem> items;
    bool checked = false;

    // Helper methods for UI compatibility
    QString getPaymentStatus() const {
        if (status == "paid") return "paid";
        double paidAmount = meta_data.value("paid_amount", 0.0).toDouble();
        if (paidAmount > 0) return "partial";
        return "unpaid";
    }

    double getPaidAmount() const {
        return meta_data.value("paid_amount", 0.0).toDouble();
    }

    double getRemainingAmount() const {
        return total_amount - getPaidAmount();
    }

    double getSubtotal() const {
        return total_amount - tax_amount + discount_amount;
    }

    QVariantMap getClient() const {
        return meta_data.value("client", QVariantMap()).toMap();
    }

    int getClientId() const {
        return meta_data.value("client_id", 0).toInt();
    }

    QString getTermsConditions() const {
        return meta_data.value("terms_conditions", QString()).toString();
    }
};

struct PaginatedInvoices {
    QList<Invoice> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

struct InvoicePayment {
    int cash_source_id;
    double amount;
    QString payment_method;
    QString reference_number;
    QString notes;
};

class InvoiceApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit InvoiceApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getInvoices(const QString &search = QString(),
                                          const QString &sortBy = "issue_date",
                                          const QString &sortDirection = "desc",
                                          int page = 1,
                                          const QString &status = QString(),
                                          const QString &paymentStatus = QString(),
                                          const QDateTime &startDate = QDateTime(),
                                          const QDateTime &endDate = QDateTime()
                                            );

    Q_INVOKABLE QFuture<void> getInvoice(int id);
    Q_INVOKABLE QFuture<void> createInvoice(const Invoice &invoice);
    Q_INVOKABLE QFuture<void> updateInvoice(int id, const Invoice &invoice);
    Q_INVOKABLE QFuture<void> deleteInvoice(int id);

    // Additional operations
    Q_INVOKABLE QFuture<void> addPayment(int id, const InvoicePayment &payment);
    Q_INVOKABLE QFuture<QByteArray> generatePdf(int id);
    Q_INVOKABLE QFuture<void> sendToClient(int id);
    Q_INVOKABLE QFuture<void> markAsSent(int id);
    Q_INVOKABLE QFuture<void> markAsPaid(int id);
    Q_INVOKABLE QFuture<void> getSummary(const QString &period = "month");

    // Token management
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);

    bool isLoading() const { return m_isLoading; }

signals:
    // Success signals
    void invoicesReceived(const PaginatedInvoices &invoices);
    void invoiceReceived(const QVariantMap &invoice);
    void invoiceCreated(const Invoice &invoice);
    void invoiceUpdated(const Invoice &invoice);
    void invoiceDeleted(int id);
    void paymentAdded(const QVariantMap &payment);
    void pdfGenerated(const QString &pdfUrl);
    void invoiceSent(const QVariantMap &result);
    void invoiceMarkedAsSent(const QVariantMap &invoice);
    void invoiceMarkedAsPaid(const QVariantMap &invoice);
    void summaryReceived(const QVariantMap &summary);

    // Error signals
    void errorInvoicesReceived(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceReceived(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceCreated(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceUpdated(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceDeleted(const QString &message, ApiStatus status, const QString &details);
    void errorPaymentAdded(const QString &message, ApiStatus status,const QString &details);
    void errorPdfGenerated(const QString &message, const QString &details);
    void errorInvoiceSent(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceMarkedAsSent(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceMarkedAsPaid(const QString &message, ApiStatus status, const QString &details);
    void errorSummaryReceived(const QString &message, ApiStatus status, const QString &details);

    void isLoadingChanged();

private:
    QNetworkReply* m_currentReply = nullptr;
    Invoice invoiceFromJson(const QJsonObject &json) const;
    InvoiceItem invoiceItemFromJson(const QJsonObject &json) const;
    QJsonObject invoiceToJson(const Invoice &invoice) const;
    QJsonObject invoiceItemToJson(const InvoiceItem &item) const;
    QJsonObject paymentToJson(const InvoicePayment &payment) const;
    PaginatedInvoices paginatedInvoicesFromJson(const QJsonObject &json) const;
    QVariantMap invoiceToVariantMap(const Invoice &invoice) const;
    QVariantMap invoiceItemToVariantMap(const InvoiceItem &item) const;
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

#endif // INVOICEAPI_H
