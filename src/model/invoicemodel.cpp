// invoicemodel.cpp
#include "invoicemodel.h"

namespace NetworkApi {

InvoiceModel::InvoiceModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField("invoice_date")
    , m_sortDirection("desc")
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

        refresh();
    }
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
    return 7; // Date, Reference, Client, Status, Payment Status, Total, Paid
}

QVariant InvoiceModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_invoices.count())
        return QVariant();

    const Invoice &invoice = m_invoices.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return invoice.invoice_date;
        case 1: return invoice.reference_number;
        case 2: return invoice.client.value("name").toString();
        case 3: return invoice.status;
        case 4: return invoice.payment_status;
        case 5: return invoice.total_amount;
        case 6: return invoice.paid_amount;
        }
    } else {
        switch (role) {
        case IdRole: return invoice.id;
        case ReferenceNumberRole: return invoice.reference_number;
        case InvoiceDateRole: return invoice.invoice_date;
        case DueDateRole: return invoice.due_date;
        case ClientIdRole: return invoice.client_id;
        case ClientRole: return invoice.client;
        case StatusRole: return invoice.status;
        case PaymentStatusRole: return invoice.payment_status;
        case SubtotalRole: return invoice.subtotal;
        case TaxRateRole: return invoice.tax_rate;
        case TaxAmountRole: return invoice.tax_amount;
        case TotalAmountRole: return invoice.total_amount;
        case PaidAmountRole: return invoice.paid_amount;
        case RemainingAmountRole: return invoice.remaining_amount;
        case NotesRole: return invoice.notes;
        case TermsConditionsRole: return invoice.terms_conditions;
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
    roles[ReferenceNumberRole] = "referenceNumber";
    roles[InvoiceDateRole] = "invoiceDate";
    roles[DueDateRole] = "dueDate";
    roles[ClientIdRole] = "clientId";
    roles[ClientRole] = "client";
    roles[StatusRole] = "status";
    roles[PaymentStatusRole] = "paymentStatus";
    roles[SubtotalRole] = "subtotal";
    roles[TaxRateRole] = "taxRate";
    roles[TaxAmountRole] = "taxAmount";
    roles[TotalAmountRole] = "totalAmount";
    roles[PaidAmountRole] = "paidAmount";
    roles[RemainingAmountRole] = "remainingAmount";
    roles[NotesRole] = "notes";
    roles[TermsConditionsRole] = "termsConditions";
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
        case 2: return tr("Client");
        case 3: return tr("Status");
        case 4: return tr("Payment Status");
        case 5: return tr("Total");
        case 6: return tr("Paid");
        }
    }
    return QVariant();
}

bool InvoiceModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_invoices.count()) {
            m_invoices[index.row()].checked = value.toBool();
            emit dataChanged(index, index, {role});
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
    m_api->getInvoices(m_searchQuery, m_sortField, m_sortDirection, m_currentPage,
                       m_status, m_paymentStatus);
}

void InvoiceModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        emit currentPageChanged();
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
// invoicemodel.cpp (continued)

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

// Selection methods
void InvoiceModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_invoices.count()) {
        m_invoices[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        emit dataChanged(index, index, {CheckedRole});
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
            emit dataChanged(index, index, {CheckedRole});
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
        emit dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Slots
void InvoiceModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        emit sortFieldChanged();
        refresh();
    }
}

void InvoiceModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        emit sortDirectionChanged();
        refresh();
    }
}

void InvoiceModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit searchQueryChanged();
        refresh();
    }
}

void InvoiceModel::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
        refresh();
    }
}

void InvoiceModel::setPaymentStatus(const QString &paymentStatus)
{
    if (m_paymentStatus != paymentStatus) {
        m_paymentStatus = paymentStatus;
        emit paymentStatusChanged();
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
    emit totalItemsChanged();

    m_currentPage = invoices.currentPage;
    emit currentPageChanged();

    m_totalPages = invoices.lastPage;
    emit totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    emit dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
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
    emit invoiceCreated();
}

void InvoiceModel::handleInvoiceUpdated(const Invoice &invoice)
{
    for (int i = 0; i < m_invoices.count(); ++i) {
        if (m_invoices[i].id == invoice.id) {
            m_invoices[i] = invoice;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit invoiceUpdated();
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
    emit invoiceDeleted();
}

void InvoiceModel::handlePaymentAdded(const QVariantMap &payment)
{
    setLoading(false);
    setErrorMessage(QString());
    emit paymentAdded();
    refresh(); // Refresh to update payment status and amounts
}

void InvoiceModel::handlePdfGenerated(const QString &pdfUrl)
{
    setLoading(false);
    setErrorMessage(QString());
    emit pdfGenerated(pdfUrl);
}

void InvoiceModel::handleInvoiceSent(const QVariantMap &result)
{
    setLoading(false);
    setErrorMessage(QString());
    emit invoiceSent();
}

void InvoiceModel::handleInvoiceMarkedAsSent(const QVariantMap &invoice)
{
    setLoading(false);
    setErrorMessage(QString());
    emit invoiceMarkedAsSent();
    refresh(); // Refresh to update status
}

void InvoiceModel::handleInvoiceMarkedAsPaid(const QVariantMap &invoice)
{
    setLoading(false);
    setErrorMessage(QString());
    emit invoiceMarkedAsPaid();
    refresh(); // Refresh to update payment status
}

void InvoiceModel::handleSummaryReceived(const QVariantMap &summary)
{
    setLoading(false);
    setErrorMessage(QString());
    emit summaryReceived(summary);
}

// Private methods
void InvoiceModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void InvoiceModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        emit errorMessageChanged();
    }
}

Invoice InvoiceModel::invoiceFromVariantMap(const QVariantMap &map) const
{
    Invoice invoice;
    invoice.id = map["id"].toInt();
    invoice.reference_number = map["referenceNumber"].toString();
    invoice.invoice_date = map["invoiceDate"].toDateTime();
    invoice.due_date = map["dueDate"].toDateTime();
    invoice.client_id = map["clientId"].toInt();
    invoice.client = map["client"].toMap();
    invoice.status = map["status"].toString();
    invoice.payment_status = map["paymentStatus"].toString();
    invoice.subtotal = map["subtotal"].toDouble();
    invoice.tax_rate = map["taxRate"].toDouble();
    invoice.tax_amount = map["taxAmount"].toDouble();
    invoice.total_amount = map["totalAmount"].toDouble();
    invoice.paid_amount = map["paidAmount"].toDouble();
    invoice.remaining_amount = map["remainingAmount"].toDouble();
    invoice.notes = map["notes"].toString();
    invoice.terms_conditions = map["termsConditions"].toString();

    QVariantList itemsList = map["items"].toList();
    for (const QVariant &itemVar : itemsList) {
        invoice.items.append(invoiceItemFromVariantMap(itemVar.toMap()));
    }

    return invoice;
}

QVariantMap InvoiceModel::invoiceToVariantMap(const Invoice &invoice) const
{
    QVariantMap map;
    map["id"] = invoice.id;
    map["referenceNumber"] = invoice.reference_number;
    map["invoiceDate"] = invoice.invoice_date;
    map["dueDate"] = invoice.due_date;
    map["clientId"] = invoice.client_id;
    map["client"] = invoice.client;
    map["status"] = invoice.status;
    map["paymentStatus"] = invoice.payment_status;
    map["subtotal"] = invoice.subtotal;
    map["taxRate"] = invoice.tax_rate;
    map["taxAmount"] = invoice.tax_amount;
    map["totalAmount"] = invoice.total_amount;
    map["paidAmount"] = invoice.paid_amount;
    map["remainingAmount"] = invoice.remaining_amount;
    map["notes"] = invoice.notes;
    map["termsConditions"] = invoice.terms_conditions;

    QVariantList itemsList;
    for (const auto &item : invoice.items) {
        itemsList.append(invoiceItemToVariantMap(item));
    }
    map["items"] = itemsList;

    return map;
}

InvoiceItem InvoiceModel::invoiceItemFromVariantMap(const QVariantMap &map) const
{
    InvoiceItem item;
    item.id = map["id"].toInt();
    item.description = map["description"].toString();
    item.quantity = map["quantity"].toInt();
    item.unit_price = map["unitPrice"].toDouble();
    item.total_price = map["totalPrice"].toDouble();
    item.notes = map["notes"].toString();
    return item;
}

QVariantMap InvoiceModel::invoiceItemToVariantMap(const InvoiceItem &item) const
{
    QVariantMap map;
    map["id"] = item.id;
    map["description"] = item.description;
    map["quantity"] = item.quantity;
    map["unitPrice"] = item.unit_price;
    map["totalPrice"] = item.total_price;
    map["notes"] = item.notes;
    return map;
}

InvoicePayment InvoiceModel::paymentFromVariantMap(const QVariantMap &map) const
{
    InvoicePayment payment;
    payment.cash_source_id = map["cashSourceId"].toInt();
    payment.amount = map["amount"].toDouble();
    payment.payment_method = map["paymentMethod"].toString();
    payment.reference_number = map["referenceNumber"].toString();
    payment.notes = map["notes"].toString();
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
        emit hasCheckedItemsChanged();
    }
}

} // namespace NetworkApi

