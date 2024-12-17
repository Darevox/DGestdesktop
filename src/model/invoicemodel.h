// invoicemodel.h
#ifndef INVOICEMODEL_H
#define INVOICEMODEL_H

#include "../api/invoiceapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class InvoiceModel : public QAbstractTableModel
{
    Q_OBJECT

    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY totalItemsChanged)
    Q_PROPERTY(int currentPage READ currentPage NOTIFY currentPageChanged)
    Q_PROPERTY(int totalPages READ totalPages NOTIFY totalPagesChanged)
    Q_PROPERTY(QString sortField READ sortField WRITE setSortField NOTIFY sortFieldChanged)
    Q_PROPERTY(QString sortDirection READ sortDirection WRITE setSortDirection NOTIFY sortDirectionChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY searchQueryChanged)
    Q_PROPERTY(QString status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(QString paymentStatus READ paymentStatus WRITE setPaymentStatus NOTIFY paymentStatusChanged)
    Q_PROPERTY(bool hasCheckedItems READ hasCheckedItems NOTIFY hasCheckedItemsChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)

public:
    enum InvoiceRoles {
        IdRole = Qt::UserRole + 1,
        TeamIdRole,
        ReferenceNumberRole,
        InvoiceableTypeRole,
        InvoiceableIdRole,
        TotalAmountRole,
        TaxAmountRole,
        DiscountAmountRole,
        StatusRole,
        IssueDateRole,
        DueDateRole,
        NotesRole,
        MetaDataRole,
        ItemsRole,
        CheckedRole
    };
    Q_ENUM(InvoiceRoles)

    explicit InvoiceModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(InvoiceApi* api);

    // QAbstractTableModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;

    // Properties
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }
    int totalItems() const { return m_totalItems; }
    int currentPage() const { return m_currentPage; }
    int totalPages() const { return m_totalPages; }
    QString sortField() const { return m_sortField; }
    QString sortDirection() const { return m_sortDirection; }
    QString searchQuery() const { return m_searchQuery; }
    QString status() const { return m_status; }
    QString paymentStatus() const { return m_paymentStatus; }
    bool hasCheckedItems() const { return m_hasCheckedItems; }

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void loadPage(int page);
    Q_INVOKABLE void createInvoice(const QVariantMap &invoiceData);
    Q_INVOKABLE void updateInvoice(int id, const QVariantMap &invoiceData);
    Q_INVOKABLE void deleteInvoice(int id);
    Q_INVOKABLE QVariantMap getInvoice(int row) const;
    Q_INVOKABLE void addPayment(int id, const QVariantMap &paymentData);
    Q_INVOKABLE void generatePdf(int id);
    Q_INVOKABLE void sendToClient(int id);
    Q_INVOKABLE void markAsSent(int id);
    Q_INVOKABLE void markAsPaid(int id);
    Q_INVOKABLE void getSummary(const QString &period = "month");

    // Selection methods
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedInvoiceIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllInvoicesChecked();

public slots:
    void setSortField(const QString &field);
    void setSortDirection(const QString &direction);
    void setSearchQuery(const QString &query);
    void setStatus(const QString &status);
    void setPaymentStatus(const QString &paymentStatus);

signals:
    void loadingChanged();
    void errorMessageChanged();
    void totalItemsChanged();
    void currentPageChanged();
    void totalPagesChanged();
    void sortFieldChanged();
    void sortDirectionChanged();
    void searchQueryChanged();
    void statusChanged();
    void paymentStatusChanged();
    void invoiceCreated();
    void invoiceUpdated();
    void invoiceDeleted();
    void paymentAdded();
    void pdfGenerated(const QString &pdfUrl);
    void invoiceSent();
    void invoiceMarkedAsSent();
    void invoiceMarkedAsPaid();
    void summaryReceived(const QVariantMap &summary);
    void hasCheckedItemsChanged();
    void rowCountChanged();

private slots:
    void handleInvoicesReceived(const PaginatedInvoices &invoices);
    void handleInvoiceError(const QString &message, ApiStatus status);
    void handleInvoiceCreated(const Invoice &invoice);
    void handleInvoiceUpdated(const Invoice &invoice);
    void handleInvoiceDeleted(int id);
    void handlePaymentAdded(const QVariantMap &payment);
    void handlePdfGenerated(const QString &pdfUrl);
    void handleInvoiceSent(const QVariantMap &result);
    void handleInvoiceMarkedAsSent(const QVariantMap &invoice);
    void handleInvoiceMarkedAsPaid(const QVariantMap &invoice);
    void handleSummaryReceived(const QVariantMap &summary);

private:
    InvoiceApi* m_api;
    QList<Invoice> m_invoices;
    bool m_loading;
    QString m_errorMessage;
    int m_totalItems;
    int m_currentPage;
    int m_totalPages;
    QString m_sortField;
    QString m_sortDirection;
    QString m_searchQuery;
    QString m_status;
    QString m_paymentStatus;
    bool m_hasCheckedItems;

    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    Invoice invoiceFromVariantMap(const QVariantMap &map) const;
    QVariantMap invoiceToVariantMap(const Invoice &invoice) const;
    InvoiceItem invoiceItemFromVariantMap(const QVariantMap &map) const;
    QVariantMap invoiceItemToVariantMap(const InvoiceItem &item) const;
    InvoicePayment paymentFromVariantMap(const QVariantMap &map) const;
    void updateHasCheckedItems();
};

} // namespace NetworkApi

#endif // INVOICEMODEL_H
