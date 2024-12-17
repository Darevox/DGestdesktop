
#include "productmodel.h"

namespace NetworkApi {

ProductModel::ProductModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField("created_at")
    , m_sortDirection("desc")
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
                packageMap["id"] = package.id;
                packageMap["name"] = package.name;
                packageMap["pieces_per_package"] = package.pieces_per_package;
                packageMap["purchase_price"] = package.purchase_price;
                packageMap["selling_price"] = package.selling_price;
                packageMap["barcode"] = package.barcode;
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
        emit currentPageChanged();
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
        emit sortFieldChanged();
        refresh();  // Refresh data if needed after sort field changes
    }
}
void ProductModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        emit sortDirectionChanged();
        refresh();  // Refresh data if needed after sort direction changes
    }
}

void ProductModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit searchQueryChanged();
        refresh();  // Refresh data based on search query
    }
}
// void ProductModel::handleProductsReceived(const PaginatedProducts &products)
// {
//     beginResetModel();
//     m_products = products.data;
//     endResetModel();

//     m_totalItems = products.total;
//     emit totalItemsChanged();

//     m_currentPage = products.currentPage;
//     emit currentPageChanged();

//     m_totalPages = products.lastPage;
//     emit totalPagesChanged();

//     setLoading(false);
//     setErrorMessage(QString());
// }
void ProductModel::handleProductsReceived(const PaginatedProducts& products)
{
    beginResetModel();

    m_products = products.data;
    endResetModel();

    m_totalItems = products.total;
    emit totalItemsChanged();

    m_currentPage = products.currentPage;
    emit currentPageChanged();

    m_totalPages = products.lastPage;
    emit totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    // Emit a signal to notify the view that the data has changed
    emit dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
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
    emit productCreated();
}

void ProductModel::handleProductUpdated(const Product &product)
{
    for (int i = 0; i < m_products.count(); ++i) {
        if (m_products[i].id == product.id) {
            m_products[i] = product;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit productUpdated();
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
    emit productDeleted();
}

void ProductModel::handleStockUpdated(const Product &product)
{
    for (int i = 0; i < m_products.count(); ++i) {
        if (m_products[i].id == product.id) {
            m_products[i] = product;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit stockUpdated();
}

// Private methods implementation
void ProductModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void ProductModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        emit errorMessageChanged();
    }
}

Product ProductModel::productFromVariantMap(const QVariantMap &map) const
{
    Product product;
    product.id = map.value("id", 0).toInt();
    product.reference = map.value("reference").toString();
    product.name = map.value("name").toString();
    product.description = map.value("description").toString();
    product.price = map.value("price", 0).toInt();
    product.purchase_price = map.value("purchase_price", 0).toInt();

    product.expiredDate = map.value("expiredDate").toDateTime();
    product.quantity = map.value("quantity", 0).toInt();
    product.productUnitId = map.value("productUnitId", 0).toInt();
    product.sku = map.value("sku").toString();
    product.barcode = map.value("barcode").toString();
    product.minStockLevel = map.value("minStockLevel", 0.0).toDouble();
    product.maxStockLevel = map.value("maxStockLevel", 0.0).toDouble();
    product.reorderPoint = map.value("reorderPoint", 0.0).toDouble();
    product.location = map.value("location").toString();

    // Handle the unit if present in the map
    QVariantMap unitMap = map.value("unit").toMap();
    if (!unitMap.isEmpty()) {
        product.unit.id = unitMap.value("id", 0).toInt();
        product.unit.name = unitMap.value("name").toString();
    }
    if (map.contains("packages")) {
        QVariantList packagesList = map["packages"].toList();
        for (const QVariant &packageVar : packagesList) {
            QVariantMap packageMap = packageVar.toMap();
            ProductPackageProduct package;
            package.name = packageMap["name"].toString();
            package.pieces_per_package = packageMap["pieces_per_package"].toInt();
            package.purchase_price = packageMap["purchase_price"].toDouble();
            package.selling_price = packageMap["selling_price"].toDouble();
            package.barcode = packageMap["barcode"].toString();
            product.packages.append(package);
        }
    }

    return product;
}

QVariantMap ProductModel::productToVariantMap(const Product &product) const
{
    QVariantMap map;
    map["id"] = product.id;
    map["reference"] = product.reference;
    map["name"] = product.name;
    map["description"] = product.description;
    map["price"] = product.price;
    map["purchase_price"] = product.purchase_price;
    map["expiredDate"] = product.expiredDate;
    map["quantity"] = product.quantity;
    map["productUnitId"] = product.productUnitId;
    map["sku"] = product.sku;
    map["barcode"] = product.barcode;
    map["minStockLevel"] = product.minStockLevel;
    map["maxStockLevel"] = product.maxStockLevel;
    map["reorderPoint"] = product.reorderPoint;
    map["location"] = product.location;

    // Handle the unit
    QVariantMap unitMap;
    unitMap["id"] = product.unit.id;
    unitMap["name"] = product.unit.name;
    map["unit"] = unitMap;
    QVariantList packagesList;
    for (const ProductPackageProduct &package : product.packages) {
        QVariantMap packageMap;
        packageMap["name"] = package.name;
        packageMap["pieces_per_package"] = package.pieces_per_package;
        packageMap["purchase_price"] = package.purchase_price;
        packageMap["selling_price"] = package.selling_price;
        packageMap["barcode"] = package.barcode;
        packagesList.append(packageMap);
    }
    map["packages"] = packagesList;
    return map;
}
// Add setData method to support checking
bool ProductModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_products.count()) {
            m_products[index.row()].checked = value.toBool();
            emit dataChanged(index, index, {role});
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
        emit dataChanged(index, index, {CheckedRole});
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
            emit dataChanged(index, index, {CheckedRole});
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
        emit dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

bool ProductModel::hasCheckedItems() const
{
    return m_hasCheckedItems;
}

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
        emit hasCheckedItemsChanged();
    }
}

} // namespace NetworkApi
