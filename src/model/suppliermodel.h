// suppliermodel.h
#ifndef SUPPLIERMODEL_H
#define SUPPLIERMODEL_H

#include "../api/supplierapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class SupplierModel : public QAbstractTableModel
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
    Q_PROPERTY(bool hasCheckedItems READ hasCheckedItems NOTIFY hasCheckedItemsChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)

public:
    enum SupplierRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        EmailRole,
        PhoneRole,
        AddressRole,
        PaymentTermsRole,
        TaxNumberRole,
        NotesRole,
        StatusRole,
        BalanceRole,
        CheckedRole
    };
    Q_ENUM(SupplierRoles)

    explicit SupplierModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(SupplierApi* api);

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
    bool hasCheckedItems() const { return m_hasCheckedItems; }

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void loadPage(int page);
    Q_INVOKABLE void createSupplier(const QVariantMap &supplierData);
    Q_INVOKABLE void updateSupplier(int id, const QVariantMap &supplierData);
    Q_INVOKABLE void deleteSupplier(int id);
    Q_INVOKABLE QVariantMap getSupplier(int row) const;

    // Selection methods
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedSupplierIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllSuppliersChecked();

public Q_SLOTS:
    void setSortField(const QString &field);
    void setSortDirection(const QString &direction);
    void setSearchQuery(const QString &query);

Q_SIGNALS:
    void loadingChanged();
    void errorMessageChanged();
    void totalItemsChanged();
    void currentPageChanged();
    void totalPagesChanged();
    void sortFieldChanged();
    void sortDirectionChanged();
    void searchQueryChanged();
    void supplierCreated();
    void supplierUpdated();
    void supplierDeleted();
    void hasCheckedItemsChanged();
    void rowCountChanged();

private Q_SLOTS:
    void handleSuppliersReceived(const PaginatedSuppliers &suppliers);
    void handleSupplierError(const QString &message, ApiStatus status);
    void handleSupplierCreated(const Supplier &supplier);
    void handleSupplierUpdated(const Supplier &supplier);
    void handleSupplierDeleted(int id);

private:
    SupplierApi* m_api;
    QList<Supplier> m_suppliers;
    bool m_loading;
    QString m_errorMessage;
    int m_totalItems;
    int m_currentPage;
    int m_totalPages;
    QString m_sortField;
    QString m_sortDirection;
    QString m_searchQuery;
    bool m_hasCheckedItems;

    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    Supplier supplierFromVariantMap(const QVariantMap &map) const;
    QVariantMap supplierToVariantMap(const Supplier &supplier) const;
    void updateHasCheckedItems();
};

} // namespace NetworkApi

#endif // SUPPLIERMODEL_H
