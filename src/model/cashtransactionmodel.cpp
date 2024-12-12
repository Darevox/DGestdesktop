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
{
}

void CashTransactionModel::setApi(CashTransactionApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &CashTransactionApi::transactionsReceived, this, &CashTransactionModel::handleTransactionsReceived);
        connect(m_api, &CashTransactionApi::errorTransactionsReceived, this, &CashTransactionModel::handleTransactionError);
        connect(m_api, &CashTransactionApi::transactionCreated, this, &CashTransactionModel::handleTransactionCreated);
        connect(m_api, &CashTransactionApi::transactionUpdated, this, &CashTransactionModel::handleTransactionUpdated);
        connect(m_api, &CashTransactionApi::transactionDeleted, this, &CashTransactionModel::handleTransactionDeleted);
        connect(m_api, &CashTransactionApi::transferCreated, this, &CashTransactionModel::handleTransferCreated);
        connect(m_api, &CashTransactionApi::categoriesReceived, this, &CashTransactionModel::handleCategoriesReceived);
        connect(m_api, &CashTransactionApi::cashFlowReceived, this, &CashTransactionModel::handleCashFlowReceived);
        connect(m_api, &CashTransactionApi::reportGenerated, this, &CashTransactionModel::handleReportGenerated);

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
    return 6; // Date, Reference, Type, Category, Amount, Description
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
        case 2: return transaction.transaction_type;
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
        case TransactionTypeRole: return transaction.transaction_type;
        case AmountRole: return transaction.amount;
        case CategoryRole: return transaction.category;
        case PaymentMethodRole: return transaction.payment_method;
        case DescriptionRole: return transaction.description;
        case CashSourceRole: return transaction.cash_source;
        case RelatedDocumentRole: return transaction.related_document;
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
    roles[TransactionTypeRole] = "transactionType";
    roles[AmountRole] = "amount";
    roles[CategoryRole] = "category";
    roles[PaymentMethodRole] = "paymentMethod";
    roles[DescriptionRole] = "description";
    roles[CashSourceRole] = "cashSource";
    roles[RelatedDocumentRole] = "relatedDocument";
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

void CashTransactionModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getTransactions(m_searchQuery, m_sortField, m_sortDirection, m_currentPage,
                          m_transactionType, m_category, m_cashSourceId);
}

void CashTransactionModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        emit currentPageChanged();
        refresh();
    }
}

void CashTransactionModel::createTransaction(const QVariantMap &transactionData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createTransaction(transactionFromVariantMap(transactionData));
}

void CashTransactionModel::updateTransaction(int id, const QVariantMap &transactionData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updateTransaction(id, transactionFromVariantMap(transactionData));
}

void CashTransactionModel::deleteTransaction(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deleteTransaction(id);
}

QVariantMap CashTransactionModel::getTransaction(int row) const
{
    if (row < 0 || row >= m_transactions.count())
        return QVariantMap();

    return transactionToVariantMap(m_transactions.at(row));
}

void CashTransactionModel::createTransfer(const QVariantMap &transferData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createTransfer(transferFromVariantMap(transferData));
}

void CashTransactionModel::loadCategories()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getCategories();
}

void CashTransactionModel::getCashFlow(const QString &period, int cashSourceId)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getCashFlow(period, cashSourceId);
}

void CashTransactionModel::generateReport(const QDateTime &startDate, const QDateTime &endDate, int cashSourceId)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->generateReport(startDate, endDate, cashSourceId);
}

// Selection methods
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

// Slots
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
        refresh();
    }
}

void CashTransactionModel::setTransactionType(const QString &type)
{
    if (m_transactionType != type) {
        m_transactionType = type;
        emit transactionTypeChanged();
        refresh();
    }
}

void CashTransactionModel::setCategory(const QString &category)
{
    if (m_category != category) {
        m_category = category;
        emit categoryChanged();
        refresh();
    }
}

void CashTransactionModel::setCashSourceId(int id)
{
    if (m_cashSourceId != id) {
        m_cashSourceId = id;
        emit cashSourceIdChanged();
        refresh();
    }
}

// Private slots
void CashTransactionModel::handleTransactionsReceived(const PaginatedCashTransactions &transactions)
{
    beginResetModel();
    m_transactions = transactions.data;
    endResetModel();

    m_totalItems = transactions.total;
    emit totalItemsChanged();

    m_currentPage = transactions.currentPage;
    emit currentPageChanged();

    m_totalPages = transactions.lastPage;
    emit totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    emit dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}

void CashTransactionModel::handleTransactionError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void CashTransactionModel::handleTransactionCreated(const CashTransaction &transaction)
{
    beginInsertRows(QModelIndex(), m_transactions.count(), m_transactions.count());
    m_transactions.append(transaction);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    emit transactionCreated();
}

void CashTransactionModel::handleTransactionUpdated(const CashTransaction &transaction)
{
    for (int i = 0; i < m_transactions.count(); ++i) {
        if (m_transactions[i].id == transaction.id) {
            m_transactions[i] = transaction;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit transactionUpdated();
}

void CashTransactionModel::handleTransactionDeleted(int id)
{
    for (int i = 0; i < m_transactions.count(); ++i) {
        if (m_transactions[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_transactions.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit transactionDeleted();
}

void CashTransactionModel::handleTransferCreated(const QVariantMap &transfer)
{
    setLoading(false);
    setErrorMessage(QString());
    emit transferCreated();
    refresh(); // Refresh to show the new transfer transactions
}

void CashTransactionModel::handleCategoriesReceived(const QVariantList &categories)
{
    setLoading(false);
    setErrorMessage(QString());
    emit categoriesLoaded(categories);
}

void CashTransactionModel::handleCashFlowReceived(const QVariantMap &cashFlow)
{
    setLoading(false);
    setErrorMessage(QString());
    emit cashFlowReceived(cashFlow);
}

void CashTransactionModel::handleReportGenerated(const QString &reportUrl)
{
    setLoading(false);
    setErrorMessage(QString());
    emit reportGenerated(reportUrl);
}

// Private methods
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

CashTransaction CashTransactionModel::transactionFromVariantMap(const QVariantMap &map) const
{
    CashTransaction transaction;
    transaction.id = map["id"].toInt();
    transaction.reference_number = map["referenceNumber"].toString();
    transaction.transaction_date = map["transactionDate"].toDateTime();
    transaction.cash_source_id = map["cashSourceId"].toInt();
    transaction.transaction_type = map["transactionType"].toString();
    transaction.amount = map["amount"].toDouble();
    transaction.category = map["category"].toString();
    transaction.payment_method = map["paymentMethod"].toString();
    transaction.description = map["description"].toString();
    transaction.cash_source = map["cashSource"].toMap();
    transaction.related_document = map["relatedDocument"].toMap();
    return transaction;
}

QVariantMap CashTransactionModel::transactionToVariantMap(const CashTransaction &transaction) const
{
    QVariantMap map;
    map["id"] = transaction.id;
    map["referenceNumber"] = transaction.reference_number;
    map["transactionDate"] = transaction.transaction_date;
    map["cashSourceId"] = transaction.cash_source_id;
    map["transactionType"] = transaction.transaction_type;
    map["amount"] = transaction.amount;
    map["category"] = transaction.category;
    map["paymentMethod"] = transaction.payment_method;
    map["description"] = transaction.description;
    map["cashSource"] = transaction.cash_source;
    map["relatedDocument"] = transaction.related_document;
    return map;
}

TransactionTransfer CashTransactionModel::transferFromVariantMap(const QVariantMap &map) const
{
    TransactionTransfer transfer;
    transfer.from_cash_source_id = map["fromCashSourceId"].toInt();
    transfer.to_cash_source_id = map["toCashSourceId"].toInt();
    transfer.amount = map["amount"].toDouble();
    transfer.description = map["description"].toString();
    transfer.reference_number = map["referenceNumber"].toString();
    return transfer;
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
