// purchasemodel.cpp
#include "purchasemodel.h"
#include <QJsonDocument>

namespace NetworkApi {

PurchaseModel::PurchaseModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField("purchase_date")
    , m_sortDirection("desc")
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
        case 3: return purchase.supplier.value("name").toString();
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
        case RemainingAmountRole: return purchase.remaining_amount;
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
    roles[RemainingAmountRole] = "remainingAmount";
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
            emit dataChanged(index, index, {role});
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
        emit currentPageChanged();
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
    payment.cash_source_id = paymentData["cashSourceId"].toInt();
    payment.amount = paymentData["amount"].toDouble();
    payment.payment_method = paymentData["paymentMethod"].toString();
    payment.reference_number = paymentData["referenceNumber"].toString();
    payment.notes = paymentData["notes"].toString();

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
        emit dataChanged(index, index, {CheckedRole});
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
            emit dataChanged(index, index, {CheckedRole});
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
        emit dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Slots
void PurchaseModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        emit sortFieldChanged();
        refresh();
    }
}

void PurchaseModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        emit sortDirectionChanged();
        refresh();
    }
}

void PurchaseModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit searchQueryChanged();
        refresh();
    }
}

void PurchaseModel::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
        refresh();
    }
}

void PurchaseModel::setPaymentStatus(const QString &paymentStatus)
{
    if (m_paymentStatus != paymentStatus) {
        m_paymentStatus = paymentStatus;
        emit paymentStatusChanged();
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
    emit totalItemsChanged();

    m_currentPage = purchases.currentPage;
    emit currentPageChanged();

    m_totalPages = purchases.lastPage;
    emit totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    emit dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
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
    emit purchaseCreated();
}

void PurchaseModel::handlePurchaseUpdated(const Purchase &purchase)
{
    for (int i = 0; i < m_purchases.count(); ++i) {
        if (m_purchases[i].id == purchase.id) {
            m_purchases[i] = purchase;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit purchaseUpdated();
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
    emit purchaseDeleted();
}

void PurchaseModel::handlePaymentAdded(const QVariantMap &payment)
{
    setLoading(false);
    setErrorMessage(QString());
    emit paymentAdded();
    refresh(); // Refresh to update the purchase's payment status and amounts
}

void PurchaseModel::handleInvoiceGenerated(const QVariantMap &invoice)
{
    setLoading(false);
    setErrorMessage(QString());
    emit invoiceGenerated(invoice["url"].toString());
}

void PurchaseModel::handleSummaryReceived(const QVariantMap &summary)
{
    setLoading(false);
    setErrorMessage(QString());
    emit summaryReceived(summary);
}

// Private methods
void PurchaseModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void PurchaseModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        emit errorMessageChanged();
    }
}

Purchase PurchaseModel::purchaseFromVariantMap(const QVariantMap &map) const
{
    Purchase purchase;
    purchase.id = map["id"].toInt();
    purchase.reference_number = map["referenceNumber"].toString();
    purchase.purchase_date = map["purchaseDate"].toDateTime();
    purchase.supplier_id = map["supplierId"].toInt();
    purchase.status = map["status"].toString();
    purchase.payment_status = map["paymentStatus"].toString();
    purchase.total_amount = map["totalAmount"].toDouble();
    purchase.paid_amount = map["paidAmount"].toDouble();
    purchase.remaining_amount = map["remainingAmount"].toDouble();
    purchase.notes = map["notes"].toString();
    purchase.supplier = map["supplier"].toMap();

    QVariantList itemsList = map["items"].toList();
    for (const QVariant &itemVar : itemsList) {
        QVariantMap itemMap = itemVar.toMap();
        PurchaseItem item;
        item.id = itemMap["id"].toInt();
        item.product_id = itemMap["productId"].toInt();
        item.product_name = itemMap["productName"].toString();
        item.quantity = itemMap["quantity"].toInt();
        item.unit_price = itemMap["unitPrice"].toDouble();
        item.total_price = itemMap["totalPrice"].toDouble();
        item.notes = itemMap["notes"].toString();
        item.product = itemMap["product"].toMap();
        purchase.items.append(item);
    }

    return purchase;
}
QVariantMap PurchaseModel::purchaseToVariantMap(const Purchase &purchase) const
{
    QVariantMap map;
    map["id"] = purchase.id;
    map["referenceNumber"] = purchase.reference_number;
    map["purchaseDate"] = purchase.purchase_date;
    map["supplierId"] = purchase.supplier_id;
    map["status"] = purchase.status;
    map["paymentStatus"] = purchase.payment_status;
    map["totalAmount"] = purchase.total_amount;
    map["paidAmount"] = purchase.paid_amount;
    map["remainingAmount"] = purchase.remaining_amount;
    map["notes"] = purchase.notes;
    map["supplier"] = purchase.supplier;

    QVariantList itemsList;
    for (const PurchaseItem &item : purchase.items) {
        QVariantMap itemMap;
        itemMap["id"] = item.id;
        itemMap["productId"] = item.product_id;
        itemMap["productName"] = item.product_name;
        itemMap["quantity"] = item.quantity;
        itemMap["unitPrice"] = item.unit_price;
        itemMap["totalPrice"] = item.total_price;
        itemMap["notes"] = item.notes;
        itemMap["product"] = item.product;
        itemsList.append(itemMap);
    }
    map["items"] = itemsList;

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
        emit hasCheckedItemsChanged();
    }
}

} // namespace NetworkApi
