// cashtransactionmodel.cpp
#include "cashtransactionmodel.h"

namespace NetworkApi {

CashTransactionModel::CashTransactionModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField("transaction_date")
    , m_sortDirection("desc")
    , m_cashSourceId(0)
    , m_hasCheckedItems(false)
    , m_minAmount(0)
    , m_maxAmount(0)
{
}

void CashTransactionModel::setApi(CashTransactionApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &CashTransactionApi::transactionsReceived,
                this, &CashTransactionModel::handleTransactionsReceived);
        connect(m_api, &CashTransactionApi::transactionsBySourceReceived,
                this, &CashTransactionModel::handleTransactionsBySourceReceived);
        connect(m_api, &CashTransactionApi::summaryReceived,
                this, &CashTransactionModel::handleSummaryReceived);

        // Connect error signals
        connect(m_api, &CashTransactionApi::errorTransactionsReceived,
                this, &CashTransactionModel::handleApiError);
        connect(m_api, &CashTransactionApi::errorTransactionsBySourceReceived,
                this, &CashTransactionModel::handleApiError);
        connect(m_api, &CashTransactionApi::errorSummaryReceived,
                this, &CashTransactionModel::handleApiError);

        refresh();
    }
}

int CashTransactionModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_transactions.count();
}

int CashTransactionModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 5; // Date, Reference, Type, Category, Amount, Description
}

QVariant CashTransactionModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_transactions.count())
        return QVariant();

    const CashTransaction &transaction = m_transactions.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return transaction.transaction_date;
        case 1: return transaction.reference_number;
        case 2: return transaction.type;
        case 3: return transaction.category;
        case 4: return transaction.amount;
        case 5: return transaction.description;
        }
    } else {
        switch (role) {
        case IdRole: return transaction.id;
        case ReferenceNumberRole: return transaction.reference_number;
        case TransactionDateRole: return transaction.transaction_date;
        case CashSourceIdRole: return transaction.cash_source_id;
        case TypeRole: return transaction.type;
        case AmountRole: return transaction.amount;
        case CategoryRole: return transaction.category;
        case PaymentMethodRole: return transaction.payment_method;
        case DescriptionRole: return transaction.description;
        case CashSourceRole: return transaction.cash_source;
        case TransferDestinationRole: return transaction.transfer_destination;
        case CheckedRole: return transaction.checked;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> CashTransactionModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[ReferenceNumberRole] = "referenceNumber";
    roles[TransactionDateRole] = "transactionDate";
    roles[CashSourceIdRole] = "cashSourceId";
    roles[TypeRole] = "type";
    roles[AmountRole] = "amount";
    roles[CategoryRole] = "category";
    roles[PaymentMethodRole] = "paymentMethod";
    roles[DescriptionRole] = "description";
    roles[CashSourceRole] = "cashSource";
    roles[TransferDestinationRole] = "transferDestination";
    roles[CheckedRole] = "checked";
    return roles;
}

QVariant CashTransactionModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("Date");
        case 1: return tr("Reference");
        case 2: return tr("Type");
        case 3: return tr("Category");
        case 4: return tr("Amount");
        case 5: return tr("Description");
        }
    }
    return QVariant();
}

void CashTransactionModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getTransactions(m_searchQuery, m_sortField, m_sortDirection,
                           m_currentPage, m_transactionType, m_cashSourceId,
                           m_minAmount, m_maxAmount, m_startDate, m_endDate);
}

void CashTransactionModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        emit currentPageChanged();
        refresh();
    }
}

void CashTransactionModel::loadTransactionsBySource(int sourceId, int page)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getTransactionsBySource(sourceId, page);
}

QVariantMap CashTransactionModel::getTransaction(int row) const
{
    if (row < 0 || row >= m_transactions.count())
        return QVariantMap();

    const CashTransaction &transaction = m_transactions.at(row);
    QVariantMap map;
    map["id"] = transaction.id;
    map["reference_number"] = transaction.reference_number;
    map["transaction_date"] = transaction.transaction_date;
    map["cash_source_id"] = transaction.cash_source_id;
    map["type"] = transaction.type;
    map["amount"] = transaction.amount;
    map["category"] = transaction.category;
    map["payment_method"] = transaction.payment_method;
    map["description"] = transaction.description;
    map["cash_source"] = transaction.cash_source;
    map["transfer_destination"] = transaction.transfer_destination;
    return map;
}

void CashTransactionModel::updateSummary(const QDateTime &startDate, const QDateTime &endDate)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getSummary(startDate, endDate);
}
bool CashTransactionModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_transactions.count()) {
            m_transactions[index.row()].checked = value.toBool();
            emit dataChanged(index, index, {role});
            updateHasCheckedItems();
            return true;
        }
    }
    return false;
}
void CashTransactionModel::handleTransactionsReceived(const PaginatedCashTransactions &transactions)
{
    beginResetModel();
    m_transactions = transactions.data;
    endResetModel();

    m_totalItems = transactions.total;
    m_currentPage = transactions.currentPage;
    m_totalPages = transactions.lastPage;

    emit totalItemsChanged();
    emit currentPageChanged();
    emit totalPagesChanged();

    setLoading(false);
    updateHasCheckedItems();
}

void CashTransactionModel::handleTransactionsBySourceReceived(const PaginatedCashTransactions &transactions)
{
    handleTransactionsReceived(transactions); // Same handling as regular transactions
}

void CashTransactionModel::handleSummaryReceived(const QVariantMap &summary)
{
    m_summary = summary;
    emit summaryChanged();
    setLoading(false);
}

void CashTransactionModel::handleApiError(const QString &message, ApiStatus status)
{
    setErrorMessage(message);
    setLoading(false);
}

void CashTransactionModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void CashTransactionModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        emit errorMessageChanged();
    }
}

void CashTransactionModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_transactions.count()) {
        m_transactions[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        emit dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList CashTransactionModel::getCheckedTransactionIds() const
{
    QVariantList checkedIds;
    for (const auto &transaction : m_transactions) {
        if (transaction.checked) {
            checkedIds.append(transaction.id);
        }
    }
    return checkedIds;
}

void CashTransactionModel::clearAllChecked()
{
    for (int i = 0; i < m_transactions.count(); ++i) {
        if (m_transactions[i].checked) {
            m_transactions[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}

void CashTransactionModel::toggleAllTransactionsChecked()
{
    bool allChecked = true;
    for (const auto &transaction : m_transactions) {
        if (!transaction.checked) {
            allChecked = false;
            break;
        }
    }

    for (int i = 0; i < m_transactions.count(); ++i) {
        m_transactions[i].checked = !allChecked;
        QModelIndex index = createIndex(i, 0);
        emit dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Property setters
void CashTransactionModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        emit sortFieldChanged();
        refresh();
    }
}

void CashTransactionModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        emit sortDirectionChanged();
        refresh();
    }
}

void CashTransactionModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit searchQueryChanged();
        m_currentPage = 1; // Reset to first page when searching
        emit currentPageChanged();
        refresh();
    }
}

void CashTransactionModel::setTransactionType(const QString &type)
{
    if (m_transactionType != type) {
        m_transactionType = type;
        emit transactionTypeChanged();
        m_currentPage = 1; // Reset to first page when changing type
        emit currentPageChanged();
        refresh();
    }
}

void CashTransactionModel::setCashSourceId(int id)
{
    if (m_cashSourceId != id) {
        m_cashSourceId = id;
        emit cashSourceIdChanged();
        m_currentPage = 1; // Reset to first page when changing source
        emit currentPageChanged();
        refresh();
    }
}
void CashTransactionModel::setMinAmount(double amount)
{
    if (m_minAmount != amount) {
        m_minAmount = amount;
        emit minAmountChanged();
        m_currentPage = 1; // Reset to first page when changing filter
        emit currentPageChanged();
        refresh();
    }
}

void CashTransactionModel::setMaxAmount(double amount)
{
    if (m_maxAmount != amount) {
        m_maxAmount = amount;
        emit maxAmountChanged();
        m_currentPage = 1; // Reset to first page when changing filter
        emit currentPageChanged();
        refresh();
    }
}

void CashTransactionModel::setStartDate(const QDateTime &date)
{
    if (m_startDate != date) {
        m_startDate = date;
        emit startDateChanged();
        m_currentPage = 1; // Reset to first page when changing filter
        emit currentPageChanged();
        refresh();
    }
}

void CashTransactionModel::setEndDate(const QDateTime &date)
{
    if (m_endDate != date) {
        m_endDate = date;
        emit endDateChanged();
        m_currentPage = 1; // Reset to first page when changing filter
        emit currentPageChanged();
        refresh();
    }
}
void CashTransactionModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &transaction : m_transactions) {
        if (transaction.checked) {
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
