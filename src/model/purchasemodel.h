// purchasemodel.h
#ifndef PURCHASEMODEL_H
#define PURCHASEMODEL_H

#include "../api/purchaseapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class PurchaseModel : public QAbstractTableModel
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
    enum PurchaseRoles {
        IdRole = Qt::UserRole + 1,
        ReferenceNumberRole,
        PurchaseDateRole,
        SupplierIdRole,
        SupplierRole,
        StatusRole,
        PaymentStatusRole,
        TotalAmountRole,
        PaidAmountRole,
        RemainingAmountRole,
        NotesRole,
        ItemsRole,
        CheckedRole
    };
    Q_ENUM(PurchaseRoles)

    explicit PurchaseModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(PurchaseApi* api);

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
    Q_INVOKABLE void createPurchase(const QVariantMap &purchaseData);
    Q_INVOKABLE void updatePurchase(int id, const QVariantMap &purchaseData);
    Q_INVOKABLE void deletePurchase(int id);
    Q_INVOKABLE QVariantMap getPurchase(int row) const;
    Q_INVOKABLE void addPayment(int id, const QVariantMap &paymentData);
    Q_INVOKABLE void generateInvoice(int id);
    Q_INVOKABLE void getSummary(const QString &period = "month");

    // Selection methods
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedPurchaseIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllPurchasesChecked();

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
    void purchaseCreated();
    void purchaseUpdated();
    void purchaseDeleted();
    void paymentAdded();
    void invoiceGenerated(const QString &invoiceUrl);
    void summaryReceived(const QVariantMap &summary);
    void hasCheckedItemsChanged();
    void rowCountChanged();

private slots:
    void handlePurchasesReceived(const PaginatedPurchases &purchases);
    void handlePurchaseError(const QString &message, ApiStatus status);
    void handlePurchaseCreated(const Purchase &purchase);
    void handlePurchaseUpdated(const Purchase &purchase);
    void handlePurchaseDeleted(int id);
    void handlePaymentAdded(const QVariantMap &payment);
    void handleInvoiceGenerated(const QVariantMap &invoice);
    void handleSummaryReceived(const QVariantMap &summary);

private:
    PurchaseApi* m_api;
    QList<Purchase> m_purchases;
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
    Purchase purchaseFromVariantMap(const QVariantMap &map) const;
    QVariantMap purchaseToVariantMap(const Purchase &purchase) const;
    void updateHasCheckedItems();
};

} // namespace NetworkApi

#endif // PURCHASEMODEL_H
