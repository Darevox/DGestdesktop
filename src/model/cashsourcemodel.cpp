// cashsourcemodel.cpp
#include "cashsourcemodel.h"

namespace NetworkApi {

CashSourceModel::CashSourceModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField("name")
    , m_sortDirection("asc")
    , m_hasCheckedItems(false)
{
}

void CashSourceModel::setApi(CashSourceApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &CashSourceApi::cashSourcesReceived, this, &CashSourceModel::handleCashSourcesReceived);
        connect(m_api, &CashSourceApi::errorCashSourcesReceived, this, &CashSourceModel::handleCashSourceError);
        connect(m_api, &CashSourceApi::cashSourceCreated, this, &CashSourceModel::handleCashSourceCreated);
        connect(m_api, &CashSourceApi::cashSourceUpdated, this, &CashSourceModel::handleCashSourceUpdated);
        connect(m_api, &CashSourceApi::cashSourceDeleted, this, &CashSourceModel::handleCashSourceDeleted);
        connect(m_api, &CashSourceApi::depositCompleted, this, &CashSourceModel::handleDepositCompleted);
        connect(m_api, &CashSourceApi::withdrawalCompleted, this, &CashSourceModel::handleWithdrawalCompleted);
        connect(m_api, &CashSourceApi::transferCompleted, this, &CashSourceModel::handleTransferCompleted);

        refresh();
    }
}

int CashSourceModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_sources.count();
}

int CashSourceModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 5; // ID, Name, Type, Balance, Status
}

QVariant CashSourceModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_sources.count())
        return QVariant();

    const CashSource &source = m_sources.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return source.id;
        case 1: return source.name;
        case 2: return source.type;
        case 3: return source.balance;
        case 4: return source.initial_balance;
        case 5: return source.status;
        }
    } else {
        switch (role) {
        case IdRole: return source.id;
        case NameRole: return source.name;
        case DescriptionRole: return source.description;
        case TypeRole: return source.type;
        case BalanceRole: return source.balance;
        case InitialBalanceRole: return source.initial_balance;
        case AccountNumberRole: return source.account_number;
        case BankNameRole: return source.bank_name;
        case StatusRole: return source.status;
        case IsDefaultRole: return source.is_default;
        case CheckedRole: return source.checked;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> CashSourceModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[DescriptionRole] = "description";
    roles[TypeRole] = "type";
    roles[BalanceRole] = "balance";
    roles[InitialBalanceRole] = "initialBalance";
    roles[AccountNumberRole] = "accountNumber";
    roles[BankNameRole] = "bankName";
    roles[StatusRole] = "status";
    roles[IsDefaultRole] = "isDefault";
    roles[CheckedRole] = "checked";
    return roles;
}

QVariant CashSourceModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Name");
        case 2: return tr("Type");
        case 3: return tr("Balance");
        case 4: return tr("Status");
        }
    }
    return QVariant();
}

bool CashSourceModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_sources.count()) {
            m_sources[index.row()].checked = value.toBool();
            emit dataChanged(index, index, {role});
            updateHasCheckedItems();
            return true;
        }
    }
    return false;
}

void CashSourceModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getCashSources(m_searchQuery, m_sortField, m_sortDirection, m_currentPage);
}

void CashSourceModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        emit currentPageChanged();
        refresh();
    }
}

void CashSourceModel::createCashSource(const QVariantMap &sourceData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createCashSource(cashSourceFromVariantMap(sourceData));
}

void CashSourceModel::updateCashSource(int id, const QVariantMap &sourceData)
{
    if (!m_api)
        return;

    qDebug() << "Updating cash source with ID:" << id;
    qDebug() << "Update data:" << sourceData;

    CashSource source;
    source.id = id;
    source.name = sourceData["name"].toString();
    source.type = sourceData["type"].toString();
    source.description = sourceData["description"].toString();
    source.status = sourceData["status"].toString();
    source.is_default = sourceData["is_default"].toBool();

    // Only include bank-specific fields if they exist
    if (sourceData.contains("account_number")) {
        source.account_number = sourceData["account_number"].toString();
    }
    if (sourceData.contains("bank_name")) {
        source.bank_name = sourceData["bank_name"].toString();
    }

    setLoading(true);
    m_api->updateCashSource(id, source);
}


void CashSourceModel::deleteCashSource(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deleteCashSource(id);
}

QVariantMap CashSourceModel::getCashSource(int row) const
{
    if (row < 0 || row >= m_sources.count())
        return QVariantMap();

    return cashSourceToVariantMap(m_sources.at(row));
}

void CashSourceModel::deposit(int id, double amount, const QString &notes)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deposit(id, amount, notes);
}

void CashSourceModel::withdraw(int id, double amount, const QString &notes)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->withdraw(id, amount, notes);
}

void CashSourceModel::transfer(const QVariantMap &transferData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->transfer(transferDataFromVariantMap(transferData));
}
TransferData CashSourceModel::transferDataFromVariantMap(const QVariantMap &map) const
{
    TransferData data;
    data.sourceId = map["sourceId"].toInt();
    data.destinationId = map["destinationId"].toInt();
    data.amount = map["amount"].toDouble();
    data.notes = map["notes"].toString();
    return data;
}

// Selection methods
void CashSourceModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_sources.count()) {
        m_sources[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        emit dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList CashSourceModel::getCheckedCashSourceIds() const
{
    QVariantList checkedIds;
    for (const auto &source : m_sources) {
        if (source.checked) {
            checkedIds.append(source.id);
        }
    }
    return checkedIds;
}

void CashSourceModel::clearAllChecked()
{
    for (int i = 0; i < m_sources.count(); ++i) {
        if (m_sources[i].checked) {
            m_sources[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}

void CashSourceModel::toggleAllCashSourcesChecked()
{
    bool allChecked = true;
    for (const auto &source : m_sources) {
        if (!source.checked) {
            allChecked = false;
            break;
        }
    }

    for (int i = 0; i < m_sources.count(); ++i) {
        m_sources[i].checked = !allChecked;
        QModelIndex index = createIndex(i, 0);
        emit dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Slots
void CashSourceModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        emit sortFieldChanged();
        refresh();
    }
}

void CashSourceModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        emit sortDirectionChanged();
        refresh();
    }
}

void CashSourceModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit searchQueryChanged();
        refresh();
    }
}

// Private slots
void CashSourceModel::handleCashSourcesReceived(const PaginatedCashSources &sources)
{
    beginResetModel();
    m_sources = sources.data;
    endResetModel();

    m_totalItems = sources.total;
    emit totalItemsChanged();

    m_currentPage = sources.currentPage;
    emit currentPageChanged();

    m_totalPages = sources.lastPage;
    emit totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    emit dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}

void CashSourceModel::handleCashSourceError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void CashSourceModel::handleCashSourceCreated(const CashSource &source)
{
    beginInsertRows(QModelIndex(), m_sources.count(), m_sources.count());
    m_sources.append(source);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    emit cashSourceCreated();
}

void CashSourceModel::handleCashSourceUpdated(const CashSource &source)
{
    for (int i = 0; i < m_sources.count(); ++i) {
        if (m_sources[i].id == source.id) {
            m_sources[i] = source;
            QModelIndex index = createIndex(i, 0);
            emit dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit cashSourceUpdated();
}

void CashSourceModel::handleCashSourceDeleted(int id)
{
    for (int i = 0; i < m_sources.count(); ++i) {
        if (m_sources[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_sources.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    emit cashSourceDeleted();
}

void CashSourceModel::handleDepositCompleted(const QVariantMap &transaction)
{
    setLoading(false);
    setErrorMessage(QString());
    emit depositCompleted();
    refresh(); // Refresh to update balances
}

void CashSourceModel::handleWithdrawalCompleted(const QVariantMap &transaction)
{
    setLoading(false);
    setErrorMessage(QString());
    emit withdrawalCompleted();
    refresh(); // Refresh to update balances
}

void CashSourceModel::handleTransferCompleted(const QVariantMap &transaction)
{
    setLoading(false);
    setErrorMessage(QString());
    emit transferCompleted();
    refresh(); // Refresh to update balances
}

// Private methods
void CashSourceModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void CashSourceModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        emit errorMessageChanged();
    }
}

CashSource CashSourceModel::cashSourceFromVariantMap(const QVariantMap &map) const
{
    CashSource source;
    source.id = map["id"].toInt();
    source.name = map["name"].toString();
    source.description = map["description"].toString();
    source.type = map["type"].toString();
    source.balance = map["balance"].toDouble();
    source.initial_balance = map["initial_balance"].toDouble();  // Make sure this is handled
    source.account_number = map["account_number"].toString();
    source.bank_name = map["bank_name"].toString();
    source.status = map["status"].toString();

    // Handle both "is_default" and "isDefault" keys for consistency
    if (map.contains("is_default"))
        source.is_default = map["is_default"].toBool();
    else if (map.contains("isDefault"))
        source.is_default = map["isDefault"].toBool();

    return source;
}


QVariantMap CashSourceModel::cashSourceToVariantMap(const CashSource &source) const
{
    QVariantMap map;
    map["id"] = source.id;
    map["name"] = source.name;
    map["description"] = source.description;
    map["type"] = source.type;
    map["balance"] = source.balance;
    map["initial_balance"] = source.initial_balance;
    map["account_number"] = source.account_number;
    map["bank_name"] = source.bank_name;
    map["status"] = source.status;
    map["isDefault"] = source.is_default;
    return map;
}

void CashSourceModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &source : m_sources) {
        if (source.checked) {
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
