
#include "productmodel.h"

namespace NetworkApi {
using namespace Qt::StringLiterals;
ProductModel::ProductModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField(QStringLiteral("created_at"))
    , m_sortDirection(QStringLiteral("desc"))
    , m_lowStockFilter(false)
{
}

void ProductModel::setApi(ProductApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &ProductApi::productsReceived, this, &ProductModel::handleProductsReceived);
        connect(m_api, &ProductApi::productError, this, &ProductModel::handleProductError);
        connect(m_api, &ProductApi::productCreated, this, &ProductModel::handleProductCreated);
        connect(m_api, &ProductApi::productUpdated, this, &ProductModel::handleProductUpdated);
        connect(m_api, &ProductApi::productDeleted, this, &ProductModel::handleProductDeleted);
        connect(m_api, &ProductApi::stockUpdated, this, &ProductModel::handleStockUpdated);

        refresh();
    }
}

int ProductModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_products.count();
}

int ProductModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 8; // Number of columns in our data
}
// QVariant ProductModel::data(const QModelIndex &index, int role) const
// {
//     if (!index.isValid() || index.row() >= m_products.count())
//         return QVariant();

//     const Product &product = m_products.at(index.row());

//     switch (role) {
//     case IdRole: return product.id;
//     case ReferenceRole: return product.reference;
//     case NameRole: return product.name;
//     case DescriptionRole: return product.description;
//     case PriceRole: return product.price;
//     case ExpiredDateRole: return product.expiredDate;
//     case QuantityRole: return product.quantity;
//     case ProductUnitRole: return product.unit.name;
//     case SkuRole: return product.sku;
//     case BarcodeRole: return product.barcode;
//     case MinStockLevelRole: return product.minStockLevel;
//     case MaxStockLevelRole: return product.maxStockLevel;
//     case ReorderPointRole: return product.reorderPoint;
//     case LocationRole: return product.location;
//     default: return QVariant();
//     }
// }
QVariant ProductModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_products.count())
        return QVariant();

    const Product &product = m_products.at(index.row());
    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return product.id;
        case 1: return product.reference;
        case 2: return product.name;
        case 3: return product.description;
        case 4: return product.price;
        case 5: return product.purchase_price;
        case 6: return product.expiredDate;
        case 7: return product.quantity;
        case 8: return product.unit.name;
        case 9: return product.sku;
            // case 9: return product.barcode;
        case 10: return product.minStockLevel;
            // case 11: return product.maxStockLevel;
            // case 12: return product.reorderPoint;
            // case 13: return product.location;
        }
    } else if (role >= IdRole) {
        switch (role) {
        case IdRole: return product.id;
        case ReferenceRole: return product.reference;
        case NameRole: return product.name;
        case DescriptionRole: return product.description;
        case PriceRole: return product.price;
        case Purchase_PriceRole : return product.purchase_price;
        case ExpiredDateRole: return product.expiredDate;
        case QuantityRole: return product.quantity;
        case ProductUnitRole: return product.unit.name;
        case SkuRole: return product.sku;
            // case BarcodeRole: return product.barcode;
        case MinStockLevelRole: return product.minStockLevel;
        case PackagesRole: {
            QVariantList packages;
            for (const auto &package : product.packages) {
                QVariantMap packageMap;
                packageMap["id"_L1] = package.id;
                packageMap["name"_L1] = package.name;
                packageMap["pieces_per_package"_L1] = package.pieces_per_package;
                packageMap["purchase_price"_L1] = package.purchase_price;
                packageMap["selling_price"_L1] = package.selling_price;
                packageMap["barcode"_L1] = package.barcode;
                packages.append(packageMap);
            }
            return packages;
        }
            // case MaxStockLevelRole: return product.maxStockLevel;
            // case ReorderPointRole: return product.reorderPoint;
            // case LocationRole: return product.location;
        }
    }
    if (role == CheckedRole) {
        if (index.row() < m_products.count()) {
            return m_products[index.row()].checked;
        }
    }


    return QVariant();
}

// QHash<int, QByteArray> ProductModel::roleNames() const
// {
//     QHash<int, QByteArray> roles;
//     roles[IdRole] = "id";
//     roles[ReferenceRole] = "reference";
//     roles[NameRole] = "name";
//     roles[DescriptionRole] = "description";
//     roles[PriceRole] = "price";
//     roles[ExpiredDateRole] = "expiredDate";
//     roles[QuantityRole] = "quantity";
//     roles[ProductUnitRole] = "productUnit";
//     roles[SkuRole] = "sku";
//     roles[BarcodeRole] = "barcode";
//     roles[MinStockLevelRole] = "minStockLevel";
//     roles[MaxStockLevelRole] = "maxStockLevel";
//     roles[ReorderPointRole] = "reorderPoint";
//     roles[LocationRole] = "location";
//     roles[Qt::DisplayRole] = "display"; // Add this line
//     return roles;
// }
QHash<int, QByteArray> ProductModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[ReferenceRole] = "reference";
    roles[NameRole] = "name";
    roles[DescriptionRole] = "description";
    roles[PriceRole] = "price";
    roles[Purchase_PriceRole] = "purchase_price";
    roles[ExpiredDateRole] = "expiredDate";
    roles[QuantityRole] = "quantity";
    roles[ProductUnitRole] = "productUnit";
    roles[SkuRole] = "sku";
    //roles[BarcodeRole] = "barcode";
    roles[MinStockLevelRole] = "minStockLevel";
    roles[PackagesRole] = "packages";
    roles[CheckedRole] = "checked";
    // roles[MaxStockLevelRole] = "maxStockLevel";
    // roles[ReorderPointRole] = "reorderPoint";
    // roles[LocationRole] = "location";
    return roles;
}

QVariant ProductModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Reference");
        case 2: return tr("Name");
        case 3: return tr("Description");
        case 4: return tr("Price");
        case 5: return tr("Purchase Price");
        case 6: return tr("Expired Date");
        case 7: return tr("Quantity");
        case 8: return tr("Unit");
        case 9: return tr("SKU");
            //  case 9: return tr("Barcode");
        case 10: return tr("Min Stock");
            // case 11: return tr("Max Stock");
            // case 12: return tr("Reorder Point");
            // case 13: return tr("Location");
        }
    }
    return QVariant();
}

void ProductModel::refresh()
{
    if (!m_api)
        return;
    setLoading(true);
    m_api->getProducts(m_searchQuery, m_sortField, m_sortDirection,m_currentPage, m_lowStockFilter);
}

void ProductModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        Q_EMIT currentPageChanged();
        refresh();
    }
}

void ProductModel::createProduct(const QVariantMap &productData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createProduct(productFromVariantMap(productData));
}

void ProductModel::updateProduct(int id, const QVariantMap &productData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updateProduct(id, productFromVariantMap(productData));
}

void ProductModel::deleteProduct(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deleteProduct(id);
    refresh();
}

void ProductModel::updateStock(int id, int quantity, const QString &operation)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updateStock(id, quantity, operation);
}

QVariantMap ProductModel::getProduct(int row) const
{
    if (row < 0 || row >= m_products.count())
        return QVariantMap();

    return productToVariantMap(m_products.at(row));
}

void ProductModel::filterLowStock(bool enabled)
{
    if (m_lowStockFilter != enabled) {
        m_lowStockFilter = enabled;
        refresh();
    }
}
void ProductModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        Q_EMIT sortFieldChanged();
        refresh();  // Refresh data if needed after sort field changes
    }
}
void ProductModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        Q_EMIT sortDirectionChanged();
        refresh();  // Refresh data if needed after sort direction changes
    }
}

void ProductModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        Q_EMIT searchQueryChanged();
        refresh();  // Refresh data based on search query
    }
}
// void ProductModel::handleProductsReceived(const PaginatedProducts &products)
// {
//     beginResetModel();
//     m_products = products.data;
//     endResetModel();

//     m_totalItems = products.total;
//     Q_EMIT totalItemsChanged();

//     m_currentPage = products.currentPage;
//     Q_EMIT currentPageChanged();

//     m_totalPages = products.lastPage;
//     Q_EMIT totalPagesChanged();

//     setLoading(false);
//     setErrorMessage(QString());
// }
void ProductModel::handleProductsReceived(const PaginatedProducts& products)
{
    beginResetModel();

    m_products = products.data;
    endResetModel();

    m_totalItems = products.total;
    Q_EMIT totalItemsChanged();

    m_currentPage = products.currentPage;
    Q_EMIT currentPageChanged();

    m_totalPages = products.lastPage;
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    // Q_EMIT a signal to notify the view that the data has changed
    Q_EMIT dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}
void ProductModel::handleProductError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void ProductModel::handleProductCreated(const Product &product)
{
    beginInsertRows(QModelIndex(), m_products.count(), m_products.count());
    m_products.append(product);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT productCreated();
}

void ProductModel::handleProductUpdated(const Product &product)
{
    for (int i = 0; i < m_products.count(); ++i) {
        if (m_products[i].id == product.id) {
            m_products[i] = product;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT productUpdated();
}

void ProductModel::handleProductDeleted(int id)
{
    for (int i = 0; i < m_products.count(); ++i) {
        if (m_products[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_products.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT productDeleted();
}

void ProductModel::handleStockUpdated(const Product &product)
{
    for (int i = 0; i < m_products.count(); ++i) {
        if (m_products[i].id == product.id) {
            m_products[i] = product;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT stockUpdated();
}

// Private methods implementation
void ProductModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void ProductModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        Q_EMIT errorMessageChanged();
    }
}

Product ProductModel::productFromVariantMap(const QVariantMap &map) const
{
    Product product;
    product.id = map.value("id"_L1, 0).toInt();
    product.reference = map.value("reference"_L1).toString();
    product.name = map.value("name"_L1).toString();
    product.description = map.value("description"_L1).toString();
    product.price = map.value("price"_L1, 0).toInt();
    product.purchase_price = map.value("purchase_price"_L1, 0).toInt();

    product.expiredDate = map.value("expiredDate"_L1).toDateTime();
    product.quantity = map.value("quantity"_L1, 0).toInt();
    product.productUnitId = map.value("productUnitId"_L1, 0).toInt();
    product.sku = map.value("sku"_L1).toString();
    product.barcode = map.value("barcode"_L1).toString();
    product.minStockLevel = map.value("minStockLevel"_L1, 0.0).toDouble();
    product.maxStockLevel = map.value("maxStockLevel"_L1, 0.0).toDouble();
    product.reorderPoint = map.value("reorderPoint"_L1, 0.0).toDouble();
    product.location = map.value("location"_L1).toString();

    // Handle the unit if present in the map
    QVariantMap unitMap = map.value("unit"_L1).toMap();
    if (!unitMap.isEmpty()) {
        product.unit.id = unitMap.value("id"_L1, 0).toInt();
        product.unit.name = unitMap.value("name"_L1).toString();
    }
    if (map.contains("packages"_L1)) {
        QVariantList packagesList = map["packages"_L1].toList();
        for (const QVariant &packageVar : packagesList) {
            QVariantMap packageMap = packageVar.toMap();
            ProductPackageProduct package;
            package.name = packageMap["name"_L1].toString();
            package.pieces_per_package = packageMap["pieces_per_package"_L1].toInt();
            package.purchase_price = packageMap["purchase_price"_L1].toDouble();
            package.selling_price = packageMap["selling_price"_L1].toDouble();
            package.barcode = packageMap["barcode"_L1].toString();
            product.packages.append(package);
        }
    }

    return product;
}

QVariantMap ProductModel::productToVariantMap(const Product &product) const
{
    QVariantMap map;
    map["id"_L1] = product.id;
    map["reference"_L1] = product.reference;
    map["name"_L1] = product.name;
    map["description"_L1] = product.description;
    map["price"_L1] = product.price;
    map["purchase_price"_L1] = product.purchase_price;
    map["expiredDate"_L1] = product.expiredDate;
    map["quantity"_L1] = product.quantity;
    map["productUnitId"_L1] = product.productUnitId;
    map["sku"_L1] = product.sku;
    map["barcode"_L1] = product.barcode;
    map["minStockLevel"_L1] = product.minStockLevel;
    map["maxStockLevel"_L1] = product.maxStockLevel;
    map["reorderPoint"_L1] = product.reorderPoint;
    map["location"_L1] = product.location;

    // Handle the unit
    QVariantMap unitMap;
    unitMap["id"_L1] = product.unit.id;
    unitMap["name"_L1] = product.unit.name;
    map["unit"_L1] = unitMap;
    QVariantList packagesList;
    for (const ProductPackageProduct &package : product.packages) {
        QVariantMap packageMap;
        packageMap["name"_L1] = package.name;
        packageMap["pieces_per_package"_L1] = package.pieces_per_package;
        packageMap["purchase_price"_L1] = package.purchase_price;
        packageMap["selling_price"_L1] = package.selling_price;
        packageMap["barcode"_L1] = package.barcode;
        packagesList.append(packageMap);
    }
    map["packages"_L1] = packagesList;
    return map;
}
// Add setData method to support checking
bool ProductModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_products.count()) {
            m_products[index.row()].checked = value.toBool();
            Q_EMIT dataChanged(index, index, {role});
            return true;
        }
    }
    return false;
}

// Implement new methods
void ProductModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_products.count()) {
        m_products[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList ProductModel::getCheckedProductIds() const
{
    QVariantList checkedIds;
    for (const auto &product : m_products) {
        if (product.checked) {
            checkedIds.append(product.id);
        }
    }
    return checkedIds;
}

void ProductModel::clearAllChecked()
{
    for (int i = 0; i < m_products.count(); ++i) {
        if (m_products[i].checked) {
            m_products[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}
void ProductModel::toggleAllProductsChecked()
{
    // Check if all are currently checked
    bool allCurrentlyChecked = true;
    for (const auto &product : m_products) {
        if (!product.checked) {
            allCurrentlyChecked = false;
            break;
        }
    }

    // Toggle all products' checked state
    for (int i = 0; i < m_products.count(); ++i) {
        m_products[i].checked = !allCurrentlyChecked;
        QModelIndex index = createIndex(i, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// bool ProductModel::hasCheckedItems() const
// {
//     return m_hasCheckedItems;
// }

void ProductModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &product : m_products) {
        if (product.checked) {
            hasChecked = true;
            break;
        }
    }

    if (hasChecked != m_hasCheckedItems) {
        m_hasCheckedItems = hasChecked;
        Q_EMIT hasCheckedItemsChanged();
    }
}

} // namespace NetworkApi
