// salemodel.cpp
#include "salemodel.h"
#include <QJsonDocument>

namespace NetworkApi {

SaleModel::SaleModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField("sale_date")
    , m_sortDirection("desc")
    , m_hasCheckedItems(false)
{
}

void SaleModel::setApi(SaleApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &SaleApi::salesReceived, this, &SaleModel::handleSalesReceived);
        connect(m_api, &SaleApi::errorSalesReceived, this, &SaleModel::handleSaleError);
        connect(m_api, &SaleApi::saleCreated, this, &SaleModel::handleSaleCreated);
        connect(m_api, &SaleApi::saleUpdated, this, &SaleModel::handleSaleUpdated);
        connect(m_api, &SaleApi::saleDeleted, this, &SaleModel::handleSaleDeleted);
        connect(m_api, &SaleApi::paymentAdded, this, &SaleModel::handlePaymentAdded);
        connect(m_api, &SaleApi::invoiceGenerated, this, &SaleModel::handleInvoiceGenerated);
        connect(m_api, &SaleApi::summaryReceived, this, &SaleModel::handleSummaryReceived);

        refresh();
    }
}

int SaleModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_sales.count();
}

int SaleModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 8; // Adjust based on your needs
}

QVariant SaleModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_sales.count())
        return QVariant();

    const Sale &sale = m_sales.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return sale.id;
        case 1: return sale.reference_number;
        case 2: return sale.sale_date;
        case 3: return sale.client.value("name").toString();
        case 4: return sale.status;
        case 5: return sale.payment_status;
        case 6: return sale.total_amount;
        case 7: return sale.paid_amount;
        }
    } else {
        switch (role) {
        case IdRole: return sale.id;
        case ReferenceNumberRole: return sale.reference_number;
        case SaleDateRole: return sale.sale_date;
        case ClientIdRole: return sale.client_id;
        case ClientRole: return sale.client;
        case StatusRole: return sale.status;
        case PaymentStatusRole: return sale.payment_status;
        case TotalAmountRole: return sale.total_amount;
        case PaidAmountRole: return sale.paid_amount;
        case RemainingAmountRole: return sale.remaining_amount;
        case NotesRole: return sale.notes;
        case ItemsRole: return QVariant::fromValue(sale.items);
        case CheckedRole: return sale.checked;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> SaleModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[ReferenceNumberRole] = "referenceNumber";
    roles[SaleDateRole] = "saleDate";
    roles[ClientIdRole] = "clientId";
    roles[ClientRole] = "client";
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

QVariant SaleModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Reference");
        case 2: return tr("Date");
        case 3: return tr("Client");
        case 4: return tr("Status");
        case 5: return tr("Payment Status");
        case 6: return tr("Total");
        case 7: return tr("Paid");
        }
    }
    return QVariant();
}

bool SaleModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_sales.count()) {
            m_sales[index.row()].checked = value.toBool();
            emit dataChanged(index, index, {role});
            updateHasCheckedItems();
            return true;
        }
    }
    return false;
}

void SaleModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getSales(m_searchQuery, m_sortField, m_sortDirection, m_currentPage, m_status, m_paymentStatus);
}

void SaleModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        emit currentPageChanged();
        refresh();
    }
}

void SaleModel::createSale(const QVariantMap &saleData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createSale(saleFromVariantMap(saleData));
}

void SaleModel::updateSale(int id, const QVariantMap &saleData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updateSale(id, saleFromVariantMap(saleData));
}

void SaleModel::deleteSale(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deleteSale(id);
}

QVariantMap SaleModel::getSale(int row) const
{
    if (row < 0 || row >= m_sales.count())
        return QVariantMap();

    return saleToVariantMap(m_sales.at(row));
}

void SaleModel::addPayment(int id, const QVariantMap &paymentData)
{
    if (!m_api)
        return;

    setLoading(true);

    Payment payment;
    payment.cash_source_id = paymentData["cash_source_id"].toInt();
    payment.amount = paymentData["amount"].toDouble();
    payment.payment_method = paymentData["payment_method"].toString();
    payment.reference_number = paymentData["reference_number"].toString();
    payment.notes = paymentData["notes"].toString();

    m_api->addPayment(id, payment);
}

void SaleModel::generateInvoice(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->generateInvoice(id);
}

void SaleModel::getSummary(const QString &period)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getSummary(period);
}

// Selection methods
void SaleModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_sales.count()) {
        m_sales[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        emit dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList SaleModel::getCheckedSaleIds() const
{
    QVariantList checkedIds;
    for (const auto &sale : m_sales) {
        if (sale.checked) {
            checkedIds.append(sale.id);
        }
    }
    return checkedIds;
}

void SaleModel::clearAllChecked()
{
    for (int i = 0; i < m_sales.count(); ++i) {
        if (m_sales[i].checked) {
            m_sales[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}

void SaleModel::toggleAllSalesChecked()
{
    bool allChecked = true;
    for (const auto &sale : m_sales) {
        if (!sale.checked) {
            allChecked = false;
            break;
        }
    }

    for (int i = 0; i < m_sales.count(); ++i) {
        m_sales[i].checked = !allChecked;
        QModelIndex index = createIndex(i, 0);
        emit dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Slots
void SaleModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        emit sortFieldChanged();
        refresh();
    }
}

void SaleModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        emit sortDirectionChanged();
        refresh();
    }
}

void SaleModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit searchQueryChanged();
        refresh();
    }
}

void SaleModel::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
        refresh();
    }
}

void SaleModel::setPaymentStatus(const QString &paymentStatus)
{
    if (m_paymentStatus != paymentStatus) {
        m_paymentStatus = paymentStatus;
        emit paymentStatusChanged();
        refresh();
    }
}

// Private slots
void SaleModel::handleSalesReceived(const PaginatedSales &sales)
{
    beginResetModel();
    m_sales = sales.data;
    endResetModel();

    m_totalItems = sales.total;
    emit totalItemsChanged();

    m_currentPage = sales.currentPage;
    emit currentPageChanged();

    m_totalPages = sales.lastPage;
    emit totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    emit dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}

void SaleModel::handleSaleError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void SaleModel::handleSaleCreated(const Sale &sale)
{
    beginInsertRows(QModelIndex(), m_sales.count(), m_sales.count());
    m_sales.append(sale);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    emit saleCreated();
}

void SaleModel::handleSaleUpdated(const Sale &sale)
{
    for (int i = 0; i < m_sales.count(); ++i) {
        if (m_sales[i].id == sale.id) {
            m_sales[i] = sale;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit saleUpdated();
}

void SaleModel::handleSaleDeleted(int id)
{
    for (int i = 0; i < m_sales.count(); ++i) {
        if (m_sales[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_sales.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit saleDeleted();
}

void SaleModel::handlePaymentAdded(const QVariantMap &payment)
{
    setLoading(false);
    setErrorMessage(QString());
    emit paymentAdded();
    refresh(); // Refresh to update the sale's payment status and amounts
}

void SaleModel::handleInvoiceGenerated(const QVariantMap &invoice)
{
    setLoading(false);
    setErrorMessage(QString());
    emit invoiceGenerated(invoice["url"].toString());
}

void SaleModel::handleSummaryReceived(const QVariantMap &summary)
{
    setLoading(false);
    setErrorMessage(QString());
    emit summaryReceived(summary);
}

// Private methods
void SaleModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void SaleModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        emit errorMessageChanged();
    }
}

Sale SaleModel::saleFromVariantMap(const QVariantMap &map) const
{
    Sale sale;
    sale.id = map["id"].toInt();
    sale.reference_number = map["referenceNumber"].toString();
    sale.sale_date = map["saleDate"].toDateTime();
    sale.client_id = map["clientId"].toInt();
    sale.status = map["status"].toString();
    sale.payment_status = map["paymentStatus"].toString();
    sale.total_amount = map["totalAmount"].toDouble();
    sale.paid_amount = map["paidAmount"].toDouble();
    sale.remaining_amount = map["remainingAmount"].toDouble();
    sale.notes = map["notes"].toString();
    sale.client = map["client"].toMap();

    QVariantList itemsList = map["items"].toList();
    for (const QVariant &itemVar : itemsList) {
        QVariantMap itemMap = itemVar.toMap();
        SaleItem item;
        item.id = itemMap["id"].toInt();
        item.product_id = itemMap["productId"].toInt();
        item.product_name = itemMap["productName"].toString();
        item.quantity = itemMap["quantity"].toInt();
        item.unit_price = itemMap["unitPrice"].toDouble();
        item.total_price = itemMap["totalPrice"].toDouble();
        item.notes = itemMap["notes"].toString();
        item.product = itemMap["product"].toMap();
        sale.items.append(item);
    }

    return sale;
}

QVariantMap SaleModel::saleToVariantMap(const Sale &sale) const
{
    QVariantMap map;
    map["id"] = sale.id;
    map["referenceNumber"] = sale.reference_number;
    map["saleDate"] = sale.sale_date;
    map["clientId"] = sale.client_id;
    map["status"] = sale.status;
    map["paymentStatus"] = sale.payment_status;
    map["totalAmount"] = sale.total_amount;
    map["paidAmount"] = sale.paid_amount;
    map["remainingAmount"] = sale.remaining_amount;
    map["notes"] = sale.notes;
    map["client"] = sale.client;

    QVariantList itemsList;
    for (const SaleItem &item : sale.items) {
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

void SaleModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &sale : m_sales) {
        if (sale.checked) {
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
