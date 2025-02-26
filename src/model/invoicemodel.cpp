#include "invoicemodel.h"

namespace NetworkApi {
using namespace Qt::StringLiterals;
InvoiceModel::InvoiceModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField(QStringLiteral("issue_date"))
    , m_sortDirection(QStringLiteral("desc"))
    , m_hasCheckedItems(false)
{
}

void InvoiceModel::setApi(InvoiceApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &InvoiceApi::invoicesReceived, this, &InvoiceModel::handleInvoicesReceived);
        connect(m_api, &InvoiceApi::errorInvoicesReceived, this, &InvoiceModel::handleInvoiceError);
        connect(m_api, &InvoiceApi::invoiceCreated, this, &InvoiceModel::handleInvoiceCreated);
        connect(m_api, &InvoiceApi::invoiceUpdated, this, &InvoiceModel::handleInvoiceUpdated);
        connect(m_api, &InvoiceApi::invoiceDeleted, this, &InvoiceModel::handleInvoiceDeleted);
        connect(m_api, &InvoiceApi::paymentAdded, this, &InvoiceModel::handlePaymentAdded);
        connect(m_api, &InvoiceApi::pdfGenerated, this, &InvoiceModel::handlePdfGenerated);
        connect(m_api, &InvoiceApi::invoiceSent, this, &InvoiceModel::handleInvoiceSent);
        connect(m_api, &InvoiceApi::invoiceMarkedAsSent, this, &InvoiceModel::handleInvoiceMarkedAsSent);
        connect(m_api, &InvoiceApi::invoiceMarkedAsPaid, this, &InvoiceModel::handleInvoiceMarkedAsPaid);
        connect(m_api, &InvoiceApi::summaryReceived, this, &InvoiceModel::handleSummaryReceived);


    }
         refresh();
}

int InvoiceModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_invoices.count();
}

int InvoiceModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 6; // Date, Reference, Invoiceable, Status, Total, Paid, Actions
}
void InvoiceModel::setStartDate(const QDateTime &date)
{
    if (m_startDate != date) {
        m_startDate = date;
        Q_EMIT startDateChanged();
        m_currentPage = 1; // Reset to first page when changing filter
        Q_EMIT currentPageChanged();
     //   refresh();
    }
}

void InvoiceModel::setEndDate(const QDateTime &date)
{
    if (m_endDate != date) {
        m_endDate = date;
        Q_EMIT endDateChanged();
        m_currentPage = 1; // Reset to first page when changing filter
        Q_EMIT currentPageChanged();
       // refresh();
    }
}
QVariant InvoiceModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_invoices.count())
        return QVariant();

    const Invoice &invoice = m_invoices.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return invoice.issue_date;
        case 1: return invoice.reference_number;
        case 2: return QStringLiteral("%1 #%2").arg(invoice.invoiceable_type)
                                          .arg(invoice.invoiceable_id);
        case 3: return invoice.status;
        case 4: return invoice.total_amount;
        case 5: return invoice.getPaidAmount();
        case 6: return QString(); // Actions column
        }
    } else {
        switch (role) {
        case IdRole: return invoice.id;
        case TeamIdRole: return invoice.team_id;
        case ReferenceNumberRole: return invoice.reference_number;
        case InvoiceableTypeRole: return invoice.invoiceable_type;
        case InvoiceableIdRole: return invoice.invoiceable_id;
        case TotalAmountRole: return invoice.total_amount;
        case TaxAmountRole: return invoice.tax_amount;
        case DiscountAmountRole: return invoice.discount_amount;
        case StatusRole: return invoice.status;
        case IssueDateRole: return invoice.issue_date;
        case DueDateRole: return invoice.due_date;
        case NotesRole: return invoice.notes;
        case MetaDataRole: return invoice.meta_data;
        case ItemsRole: {
            QVariantList items;
            for (const auto &item : invoice.items) {
                items.append(invoiceItemToVariantMap(item));
            }
            return items;
        }
        case CheckedRole: return invoice.checked;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> InvoiceModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[TeamIdRole] = "teamId";
    roles[ReferenceNumberRole] = "referenceNumber";
    roles[InvoiceableTypeRole] = "invoiceableType";
    roles[InvoiceableIdRole] = "invoiceableId";
    roles[TotalAmountRole] = "totalAmount";
    roles[TaxAmountRole] = "taxAmount";
    roles[DiscountAmountRole] = "discountAmount";
    roles[StatusRole] = "status";
    roles[IssueDateRole] = "issueDate";
    roles[DueDateRole] = "dueDate";
    roles[NotesRole] = "notes";
    roles[MetaDataRole] = "metaData";
    roles[ItemsRole] = "items";
    roles[CheckedRole] = "checked";
    return roles;
}

QVariant InvoiceModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("Date");
        case 1: return tr("Reference");
        case 2: return tr("Invoiceable");
        case 3: return tr("Status");
        case 4: return tr("Total");
        case 5: return tr("Paid");
        case 6: return tr("Actions");
        }
    }
    return QVariant();
}

bool InvoiceModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_invoices.count()) {
            m_invoices[index.row()].checked = value.toBool();
            Q_EMIT dataChanged(index, index, {role});
            updateHasCheckedItems();
            return true;
        }
    }
    return false;
}

void InvoiceModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getInvoices(m_searchQuery, m_sortField, m_sortDirection, m_currentPage, m_status, m_paymentStatus, m_startDate, m_endDate);
}

void InvoiceModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        Q_EMIT currentPageChanged();
        refresh();
    }
}

void InvoiceModel::createInvoice(const QVariantMap &invoiceData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createInvoice(invoiceFromVariantMap(invoiceData));
}

void InvoiceModel::updateInvoice(int id, const QVariantMap &invoiceData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updateInvoice(id, invoiceFromVariantMap(invoiceData));
}

void InvoiceModel::deleteInvoice(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deleteInvoice(id);
}

QVariantMap InvoiceModel::getInvoice(int row) const
{
    if (row < 0 || row >= m_invoices.count())
        return QVariantMap();

    return invoiceToVariantMap(m_invoices.at(row));
}

void InvoiceModel::addPayment(int id, const QVariantMap &paymentData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->addPayment(id, paymentFromVariantMap(paymentData));
}

void InvoiceModel::generatePdf(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->generatePdf(id);
}

void InvoiceModel::sendToClient(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->sendToClient(id);
}

void InvoiceModel::markAsSent(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->markAsSent(id);
}

void InvoiceModel::markAsPaid(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->markAsPaid(id);
}

void InvoiceModel::getSummary(const QString &period)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getSummary(period);
}

void InvoiceModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_invoices.count()) {
        m_invoices[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList InvoiceModel::getCheckedInvoiceIds() const
{
    QVariantList checkedIds;
    for (const auto &invoice : m_invoices) {
        if (invoice.checked) {
            checkedIds.append(invoice.id);
        }
    }
    return checkedIds;
}

void InvoiceModel::clearAllChecked()
{
    for (int i = 0; i < m_invoices.count(); ++i) {
        if (m_invoices[i].checked) {
            m_invoices[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}

void InvoiceModel::toggleAllInvoicesChecked()
{
    bool allChecked = true;
    for (const auto &invoice : m_invoices) {
        if (!invoice.checked) {
            allChecked = false;
            break;
        }
    }

    for (int i = 0; i < m_invoices.count(); ++i) {
        m_invoices[i].checked = !allChecked;
        QModelIndex index = createIndex(i, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

void InvoiceModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        Q_EMIT sortFieldChanged();
        refresh();
    }
}

void InvoiceModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        Q_EMIT sortDirectionChanged();
        refresh();
    }
}

void InvoiceModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        Q_EMIT searchQueryChanged();
        refresh();
    }
}

void InvoiceModel::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        Q_EMIT statusChanged();
       // refresh();
    }
}

void InvoiceModel::setPaymentStatus(const QString &paymentStatus)
{
    if (m_paymentStatus != paymentStatus) {
        m_paymentStatus = paymentStatus;
        Q_EMIT paymentStatusChanged();
        refresh();
    }
}

// Private slots
void InvoiceModel::handleInvoicesReceived(const PaginatedInvoices &invoices)
{
    beginResetModel();
    m_invoices = invoices.data;
    endResetModel();

    m_totalItems = invoices.total;
    Q_EMIT totalItemsChanged();

    m_currentPage = invoices.currentPage;
    Q_EMIT currentPageChanged();

    m_totalPages = invoices.lastPage;
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    Q_EMIT rowCountChanged();
}

void InvoiceModel::handleInvoiceError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void InvoiceModel::handleInvoiceCreated(const Invoice &invoice)
{
    beginInsertRows(QModelIndex(), m_invoices.count(), m_invoices.count());
    m_invoices.append(invoice);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT invoiceCreated();
}

void InvoiceModel::handleInvoiceUpdated(const Invoice &invoice)
{
    for (int i = 0; i < m_invoices.count(); ++i) {
        if (m_invoices[i].id == invoice.id) {
            m_invoices[i] = invoice;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, createIndex(i, columnCount() - 1));
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT invoiceUpdated();
}

void InvoiceModel::handleInvoiceDeleted(int id)
{
    for (int i = 0; i < m_invoices.count(); ++i) {
        if (m_invoices[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_invoices.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT invoiceDeleted();
}

void InvoiceModel::handlePaymentAdded(const QVariantMap &payment)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT paymentAdded();
    refresh(); // Refresh to update payment status and amounts
}

void InvoiceModel::handlePdfGenerated(const QString &pdfUrl)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT pdfGenerated(pdfUrl);
}

void InvoiceModel::handleInvoiceSent(const QVariantMap &result)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT invoiceSent();
}

void InvoiceModel::handleInvoiceMarkedAsSent(const QVariantMap &invoice)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT invoiceMarkedAsSent();
    refresh();
}

void InvoiceModel::handleInvoiceMarkedAsPaid(const QVariantMap &invoice)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT invoiceMarkedAsPaid();
    refresh();
}

void InvoiceModel::handleSummaryReceived(const QVariantMap &summary)
{
    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT summaryReceived(summary);
}

// Private methods
void InvoiceModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void InvoiceModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        Q_EMIT errorMessageChanged();
    }
}

Invoice InvoiceModel::invoiceFromVariantMap(const QVariantMap &map) const
{
    Invoice invoice;
    invoice.id = map["id"_L1].toInt();
    invoice.team_id = map["teamId"_L1].toInt();
    invoice.reference_number = map["referenceNumber"_L1].toString();
    invoice.invoiceable_type = map["invoiceable_type"_L1].toString();
    invoice.invoiceable_id = map["invoiceableId"_L1].toInt();
    invoice.total_amount = map["totalAmount"_L1].toDouble();
    invoice.tax_amount = map["taxAmount"_L1].toDouble();
    invoice.discount_amount = map["discountAmount"_L1].toDouble();
    invoice.status = map["status"_L1].toString();
    invoice.issue_date = map["issue_date"_L1].toDateTime();
    invoice.due_date = map["due_date"_L1].toDateTime();
    invoice.notes = map["notes"_L1].toString();
    invoice.meta_data = map["metaData"_L1].toMap();

    QVariantList itemsList = map["items"_L1].toList();
    for (const QVariant &itemVar : itemsList) {
        invoice.items.append(invoiceItemFromVariantMap(itemVar.toMap()));
    }

    return invoice;
}

QVariantMap InvoiceModel::invoiceToVariantMap(const Invoice &invoice) const
{
    QVariantMap map;
    map["id"_L1] = invoice.id;
    map["teamId"_L1] = invoice.team_id;
    map["referenceNumber"_L1] = invoice.reference_number;
    map["invoiceableType"_L1] = invoice.invoiceable_type;
    map["invoiceableId"_L1] = invoice.invoiceable_id;
    map["totalAmount"_L1] = invoice.total_amount;
    map["taxAmount"_L1] = invoice.tax_amount;
    map["discountAmount"_L1] = invoice.discount_amount;
    map["status"_L1] = invoice.status;
    map["issueDate"_L1] = invoice.issue_date;
    map["dueDate"_L1] = invoice.due_date;
    map["notes"_L1] = invoice.notes;
    map["metaData"_L1] = invoice.meta_data;

    QVariantList itemsList;
    for (const auto &item : invoice.items) {
        itemsList.append(invoiceItemToVariantMap(item));
    }
    map["items"_L1] = itemsList;

    return map;
}

InvoiceItem InvoiceModel::invoiceItemFromVariantMap(const QVariantMap &map) const
{
    InvoiceItem item;
    item.id = map["id"_L1].toInt();
    item.description = map["description"_L1].toString();
    item.quantity = map["quantity"_L1].toInt();
    item.unit_price = map["unitPrice"_L1].toDouble();
    item.total_price = map["totalPrice"_L1].toDouble();
    item.notes = map["notes"_L1].toString();
    return item;
}

QVariantMap InvoiceModel::invoiceItemToVariantMap(const InvoiceItem &item) const
{
    QVariantMap map;
    map["id"_L1] = item.id;
    map["description"_L1] = item.description;
    map["quantity"_L1] = item.quantity;
    map["unitPrice"_L1] = item.unit_price;
    map["totalPrice"_L1] = item.total_price;
    map["notes"_L1] = item.notes;
    return map;
}

InvoicePayment InvoiceModel::paymentFromVariantMap(const QVariantMap &map) const
{
    InvoicePayment payment;
    payment.cash_source_id = map["cashSourceId"_L1].toInt();
    payment.amount = map["amount"_L1].toDouble();
    payment.payment_method = map["paymentMethod"_L1].toString();
    payment.reference_number = map["referenceNumber"_L1].toString();
    payment.notes = map["notes"_L1].toString();
    return payment;
}

void InvoiceModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &invoice : m_invoices) {
        if (invoice.checked) {
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
