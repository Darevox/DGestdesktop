#ifndef PRODUCTMODEL_H
#define PRODUCTMODEL_H

#include "../api/productapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class ProductModel : public QAbstractTableModel
{
    Q_OBJECT
    // Q_PROPERTIES remain in public section
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
    // Enums remain public
    enum ProductRoles {
        IdRole = Qt::UserRole + 1,
        ReferenceRole,
        NameRole,
        DescriptionRole,
        PriceRole,
        Purchase_PriceRole,
        ExpiredDateRole,
        QuantityRole,
        ProductUnitRole,
        SkuRole,
        BarcodeRole,
        MinStockLevelRole,
        MaxStockLevelRole,
        ReorderPointRole,
        LocationRole,
        PackagesRole,
        CheckedRole = Qt::UserRole + 20
    };
    Q_ENUM(ProductRoles)

    explicit ProductModel(QObject *parent = nullptr);

    // Public interface methods
    Q_INVOKABLE void setApi(ProductApi* api);

    // QAbstractTableModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;

    // Public getters
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }
    int totalItems() const { return m_totalItems; }
    int currentPage() const { return m_currentPage; }
    int totalPages() const { return m_totalPages; }
    QString sortField() const { return m_sortField; }
    QString sortDirection() const { return m_sortDirection; }
    QString searchQuery() const { return m_searchQuery; }
    bool hasCheckedItems() const { return m_hasCheckedItems; }

    // Public QML methods
    Q_INVOKABLE virtual void refresh();
    Q_INVOKABLE virtual void loadPage(int page);
    Q_INVOKABLE void createProduct(const QVariantMap &productData);
    Q_INVOKABLE void updateProduct(int id, const QVariantMap &productData);
    Q_INVOKABLE void deleteProduct(int id);
    Q_INVOKABLE void updateStock(int id, int quantity, const QString &operation);
    Q_INVOKABLE QVariantMap getProduct(int row) const;
    Q_INVOKABLE void filterLowStock(bool enabled);
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedProductIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllProductsChecked();

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
    void productCreated();
    void productUpdated();
    void productDeleted();
    void stockUpdated();
    void hasCheckedItemsChanged();
    void rowCountChanged();

protected:
    // Protected methods that derived classes might need to access
    virtual void handleProductsReceived(const PaginatedProducts &products);
    void handleProductError(const QString &message, ApiStatus status);
    void handleProductCreated(const Product &product);
    void handleProductUpdated(const Product &product);
    void handleProductDeleted(int id);
    void handleStockUpdated(const Product &product);
    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    void updateHasCheckedItems();

    // Protected data members that derived classes might need to access
    ProductApi* m_api;
    QList<Product> m_products;
    bool m_loading;
    QString m_errorMessage;
    int m_totalItems;
    int m_currentPage;
    int m_totalPages;
    QString m_sortField;
    QString m_sortDirection;
    QString m_searchQuery;
    bool m_lowStockFilter;
    bool m_hasCheckedItems = false;

private:
    // Truly private methods that derived classes don't need
    Product productFromVariantMap(const QVariantMap &map) const;
    QVariantMap productToVariantMap(const Product &product) const;
};

}

#endif // PRODUCTMODEL_H
