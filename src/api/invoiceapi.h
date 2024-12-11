// invoiceapi.h
#ifndef INVOICEAPI_H
#define INVOICEAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

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
    QString reference_number;
    QDateTime invoice_date;
    QDateTime due_date;
    int client_id;
    QVariantMap client;
    QString status;
    QString payment_status;
    double subtotal;
    double tax_rate;
    double tax_amount;
    double total_amount;
    double paid_amount;
    double remaining_amount;
    QString notes;
    QString terms_conditions;
    QList<InvoiceItem> items;
    bool checked = false;
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
                                         const QString &sortBy = "invoice_date",
                                         const QString &sortDirection = "desc",
                                         int page = 1,
                                         const QString &status = QString(),
                                         const QString &paymentStatus = QString());

    Q_INVOKABLE QFuture<void> getInvoice(int id);
    Q_INVOKABLE QFuture<void> createInvoice(const Invoice &invoice);
    Q_INVOKABLE QFuture<void> updateInvoice(int id, const Invoice &invoice);
    Q_INVOKABLE QFuture<void> deleteInvoice(int id);

    // Additional operations
    Q_INVOKABLE QFuture<void> addPayment(int id, const InvoicePayment &payment);
    Q_INVOKABLE QFuture<void> generatePdf(int id);
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
    void errorPaymentAdded(const QString &message, ApiStatus status, const QString &details);
    void errorPdfGenerated(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceSent(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceMarkedAsSent(const QString &message, ApiStatus status, const QString &details);
    void errorInvoiceMarkedAsPaid(const QString &message, ApiStatus status, const QString &details);
    void errorSummaryReceived(const QString &message, ApiStatus status, const QString &details);

    void isLoadingChanged();

private:
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
