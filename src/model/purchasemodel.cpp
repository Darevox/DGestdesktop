// purchasemodel.cpp
#include "purchasemodel.h"
#include <QJsonDocument>

namespace NetworkApi {
using namespace Qt::StringLiterals;
PurchaseModel::PurchaseModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField(QStringLiteral("purchase_date"))
    , m_sortDirection(QStringLiteral("desc"))
    , m_hasCheckedItems(false)
{
}

void PurchaseModel::setApi(PurchaseApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &PurchaseApi::purchasesReceived, this, &PurchaseModel::handlePurchasesReceived);
        connect(m_api, &PurchaseApi::errorPurchasesReceived, this, &PurchaseModel::handlePurchaseError);
        connect(m_api, &PurchaseApi::purchaseCreated, this, &PurchaseModel::handlePurchaseCreated);
        connect(m_api, &PurchaseApi::purchaseUpdated, this, &PurchaseModel::handlePurchaseUpdated);
        connect(m_api, &PurchaseApi::purchaseDeleted, this, &PurchaseModel::handlePurchaseDeleted);
        connect(m_api, &PurchaseApi::paymentAdded, this, &PurchaseModel::handlePaymentAdded);
        connect(m_api, &PurchaseApi::invoiceGenerated, this, &PurchaseModel::handleInvoiceGenerated);
        connect(m_api, &PurchaseApi::summaryReceived, this, &PurchaseModel::handleSummaryReceived);

        refresh();
    }
}

int PurchaseModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_purchases.count();
}

int PurchaseModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 8; // Number of columns to display
}

QVariant PurchaseModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_purchases.count())
        return QVariant();

    const Purchase &purchase = m_purchases.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return purchase.id;
        case 1: return purchase.reference_number;
        case 2: return purchase.purchase_date;
        case 3: return purchase.supplier.value("name"_L1).toString();
        case 4: return purchase.status;
        case 5: return purchase.payment_status;
        case 6: return purchase.total_amount;
        case 7: return purchase.paid_amount;
        }
    } else {
        switch (role) {
        case IdRole: return purchase.id;
        case ReferenceNumberRole: return purchase.reference_number;
        case PurchaseDateRole: return purchase.purchase_date;
        case SupplierIdRole: return purchase.supplier_id;
        case SupplierRole: return purchase.supplier;
        case StatusRole: return purchase.status;
        case PaymentStatusRole: return purchase.payment_status;
        case TotalAmountRole: return purchase.total_amount;
        case PaidAmountRole: return purchase.paid_amount;
        case NotesRole: return purchase.notes;
        case ItemsRole: return QVariant::fromValue(purchase.items);
        case CheckedRole: return purchase.checked;
        }
    }

    return QVariant();
}
QHash<int, QByteArray> PurchaseModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[ReferenceNumberRole] = "referenceNumber";
    roles[PurchaseDateRole] = "purchaseDate";
    roles[SupplierIdRole] = "supplierId";
    roles[SupplierRole] = "supplier";
    roles[StatusRole] = "status";
    roles[PaymentStatusRole] = "paymentStatus";
    roles[TotalAmountRole] = "totalAmount";
    roles[PaidAmountRole] = "paidAmount";
    roles[NotesRole] = "notes";
    roles[ItemsRole] = "items";
    roles[CheckedRole] = "checked";
    return roles;
}

QVariant PurchaseModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Reference");
        case 2: return tr("Date");
        case 3: return tr("Supplier");
        case 4: return tr("Status");
        case 5: return tr("Payment Status");
        case 6: return tr("Total");
        case 7: return tr("Paid");
        }
    }
    return QVariant();
}

bool PurchaseModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_purchases.count()) {
            m_purchases[index.row()].checked = value.toBool();
            Q_EMIT dataChanged(index, index, {role});
            updateHasCheckedItems();
            return true;
        }
    }
    return false;
}

void PurchaseModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getPurchases(m_searchQuery, m_sortField, m_sortDirection, m_currentPage, m_status, m_paymentStatus);
}

void PurchaseModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        Q_EMIT currentPageChanged();
        refresh();
    }
}

void PurchaseModel::createPurchase(const QVariantMap &purchaseData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createPurchase(purchaseFromVariantMap(purchaseData));
}

void PurchaseModel::updatePurchase(int id, const QVariantMap &purchaseData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updatePurchase(id, purchaseFromVariantMap(purchaseData));
}

void PurchaseModel::deletePurchase(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deletePurchase(id);
}

QVariantMap PurchaseModel::getPurchase(int row) const
{
    if (row < 0 || row >= m_purchases.count())
        return QVariantMap();

    return purchaseToVariantMap(m_purchases.at(row));
}

void PurchaseModel::addPayment(int id, const QVariantMap &paymentData)
{
    if (!m_api)
        return;

    setLoading(true);

    PurchasePayment payment;
    payment.cash_source_id = paymentData["cashSourceId"_L1].toInt();
    payment.amount = paymentData["amount"_L1].toDouble();
    payment.payment_method = paymentData["paymentMethod"_L1].toString();
    payment.reference_number = paymentData["referenceNumber"_L1].toString();
    payment.notes = paymentData["notes"_L1].toString();

    m_api->addPayment(id, payment);
}

void PurchaseModel::generateInvoice(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->generateInvoice(id);
}

void PurchaseModel::getSummary(const QString &period)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getSummary(period);
}

// Selection methods
void PurchaseModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_purchases.count()) {
        m_purchases[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList PurchaseModel::getCheckedPurchaseIds() const
{
    QVariantList checkedIds;
    for (const auto &purchase : m_purchases) {
        if (purchase.checked) {
            checkedIds.append(purchase.id);
        }
    }
    return checkedIds;
}

void PurchaseModel::clearAllChecked()
{
    for (int i = 0; i < m_purchases.count(); ++i) {
        if (m_purchases[i].checked) {
            m_purchases[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}

void PurchaseModel::toggleAllPurchasesChecked()
{
    bool allChecked = true;
    for (const auto &purchase : m_purchases) {
        if (!purchase.checked) {
            allChecked = false;
            break;
        }
    }

    for (int i = 0; i < m_purchases.count(); ++i) {
        m_purchases[i].checked = !allChecked;
        QModelIndex index = createIndex(i, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Slots
void PurchaseModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        Q_EMIT sortFieldChanged();
        refresh();
    }
}

void PurchaseModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        Q_EMIT sortDirectionChanged();
        refresh();
    }
}

void PurchaseModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        Q_EMIT searchQueryChanged();
        refresh();
    }
}

void PurchaseModel::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        Q_EMIT statusChanged();
        refresh();
    }
}

void PurchaseModel::setPaymentStatus(const QString &paymentStatus)
{
    if (m_paymentStatus != paymentStatus) {
        m_paymentStatus = paymentStatus;
        Q_EMIT paymentStatusChanged();
        refresh();
    }
}

// Private slots
void PurchaseModel::handlePurchasesReceived(const PaginatedPurchases &purchases)
{
    beginResetModel();
    m_purchases = purchases.data;
    endResetModel();

    m_totalItems = purchases.total;
    Q_EMIT totalItemsChanged();

    m_currentPage = purchases.currentPage;
    Q_EMIT currentPageChanged();

    m_totalPages = purchases.lastPage;
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    Q_EMIT dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}

void PurchaseModel::handlePurchaseError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void PurchaseModel::handlePurchaseCreated(const Purchase &purchase)
{
    beginInsertRows(QModelIndex(), m_purchases.count(), m_purchases.count());
    m_purchases.append(purchase);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT purchaseCreated();
}

void PurchaseModel::handlePurchaseUpdated(const Purchase &purchase)
{
    for (int i = 0; i < m_purchases.count(); ++i) {
        if (m_purchases[i].id == purchase.id) {
            m_purchases[i] = purchase;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT purchaseUpdated();
}

void PurchaseModel::handlePurchaseDeleted(int id)
{
    for (int i = 0; i < m_purchases.count(); ++i) {
        if (m_purchases[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_purchases.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT purchaseDeleted();
}

void PurchaseModel::handlePaymentAdded(const QVariantMap &payment)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT paymentAdded();
    refresh(); // Refresh to update the purchase's payment status and amounts
}

void PurchaseModel::handleInvoiceGenerated(const QVariantMap &invoice)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT invoiceGenerated(invoice["url"_L1].toString());
}

void PurchaseModel::handleSummaryReceived(const QVariantMap &summary)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT summaryReceived(summary);
}

// Private methods
void PurchaseModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void PurchaseModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        Q_EMIT errorMessageChanged();
    }
}

Purchase PurchaseModel::purchaseFromVariantMap(const QVariantMap &map) const
{
    Purchase purchase;
    purchase.supplier_id = map["supplier_id"_L1].toInt();
    purchase.cash_source_id = map["cash_source_id"_L1].toInt();
    purchase.purchase_date = QDateTime::fromString(map["purchase_date"_L1].toString(), Qt::ISODate);

    if (map.contains("due_date"_L1)) {
        purchase.due_date = QDateTime::fromString(map["due_date"_L1].toString(), Qt::ISODate);
    }

    if (map.contains("notes"_L1)) {
        purchase.notes = map["notes"_L1].toString();
    }

    QVariantList itemsList = map["items"_L1].toList();
    for (const QVariant &itemVar : itemsList) {
        QVariantMap itemMap = itemVar.toMap();
        PurchaseItem item;
        item.product_id = itemMap["product_id"_L1].toInt();
        item.quantity = itemMap["quantity"_L1].toInt();
        item.unit_price = itemMap["unit_price"_L1].toDouble();
        item.tax_rate = itemMap["tax_rate"_L1].toDouble();
        item.update_prices = itemMap["update_prices"_L1].toBool();
        item.selling_price = itemMap["selling_price"_L1].toDouble();

        // Add package-related fields
        item.is_package = itemMap["is_package"_L1].toBool();
        item.package_id = itemMap["package_id"_L1].toInt();
        item.update_package_prices = itemMap["update_package_prices"_L1].toBool();
        item.package_purchase_price = itemMap["package_purchase_price"_L1].toDouble();
        item.package_selling_price = itemMap["package_selling_price"_L1].toDouble();

        if (itemMap.contains("discount_amount"_L1)) {
            item.discount_amount = itemMap["discount_amount"_L1].toDouble();
        }

        if (itemMap.contains("notes"_L1)) {
            item.notes = itemMap["notes"_L1].toString();
        }

        // Handle package information if present
        if (itemMap.contains("package"_L1) && !itemMap["package"_L1].isNull()) {
            QVariantMap packageMap = itemMap["package"_L1].toMap();
            item.package.id = packageMap["id"_L1].toInt();
            item.package.name = packageMap["name"_L1].toString();
            item.package.pieces_per_package = packageMap["pieces_per_package"_L1].toInt();
            item.package.purchase_price = packageMap["purchase_price"_L1].toDouble();
            item.package.selling_price = packageMap["selling_price"_L1].toDouble();
            item.package.barcode = packageMap["barcode"_L1].toString();
        }

        purchase.items.append(item);
    }

    return purchase;
}
QVariantMap PurchaseModel::purchaseToVariantMap(const Purchase &purchase) const
{
    QVariantMap map;
    map["id"_L1] = purchase.id;
    map["referenceNumber"_L1] = purchase.reference_number;
    map["purchaseDate"_L1] = purchase.purchase_date;
    map["supplierId"_L1] = purchase.supplier_id;
    map["cash_source_id"_L1] = purchase.cash_source_id;
    map["status"_L1] = purchase.status;
    map["paymentStatus"_L1] = purchase.payment_status;
    map["totalAmount"_L1] = purchase.total_amount;
    map["paidAmount"_L1] = purchase.paid_amount;
    map["notes"_L1] = purchase.notes;
    map["supplier"_L1] = purchase.supplier;

    QVariantList itemsList;
    for (const PurchaseItem &item : purchase.items) {
        QVariantMap itemMap;
        itemMap["id"_L1] = item.id;
        itemMap["productId"_L1] = item.product_id;
        itemMap["productName"_L1] = item.product_name;
        itemMap["quantity"_L1] = item.quantity;
        itemMap["unitPrice"_L1] = item.unit_price;
        itemMap["totalPrice"_L1] = item.total_price;
        itemMap["notes"_L1] = item.notes;
        itemMap["product"_L1] = item.product;

        // Add package-related fields
        itemMap["is_package"_L1] = item.is_package;
        itemMap["package_id"_L1] = item.package_id;
        itemMap["update_package_prices"_L1] = item.update_package_prices;
        itemMap["package_purchase_price"_L1] = item.package_purchase_price;
        itemMap["package_selling_price"_L1] = item.package_selling_price;

        // Include package information if present
        if (item.is_package) {
            QVariantMap packageMap;
            packageMap["id"_L1] = item.package.id;
            packageMap["name"_L1] = item.package.name;
            packageMap["pieces_per_package"_L1] = item.package.pieces_per_package;
            packageMap["purchase_price"_L1] = item.package.purchase_price;
            packageMap["selling_price"_L1] = item.package.selling_price;
            packageMap["barcode"_L1] = item.package.barcode;
            itemMap["package"_L1] = packageMap;
        }

        itemsList.append(itemMap);
    }
    map["items"_L1] = itemsList;

    return map;
}
void PurchaseModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &purchase : m_purchases) {
        if (purchase.checked) {
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
