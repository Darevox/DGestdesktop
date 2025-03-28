// clientmodel.cpp
#include "clientmodel.h"
#include <QJsonDocument>

namespace NetworkApi {
using namespace Qt::StringLiterals;
ClientModel::ClientModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField(QStringLiteral("name"))
    , m_sortDirection(QStringLiteral("asc"))
    , m_hasCheckedItems(false)
{
}

void ClientModel::setApi(ClientApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &ClientApi::clientsReceived, this, &ClientModel::handleClientsReceived);
        connect(m_api, &ClientApi::errorClientsReceived, this, &ClientModel::handleClientError);
        connect(m_api, &ClientApi::clientCreated, this, &ClientModel::handleClientCreated);
        connect(m_api, &ClientApi::clientUpdated, this, &ClientModel::handleClientUpdated);
        connect(m_api, &ClientApi::clientDeleted, this, &ClientModel::handleClientDeleted);


    }
      refresh();
}

int ClientModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_clients.count();
}

int ClientModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 5; // Adjust based on your needs
}

QVariant ClientModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_clients.count())
        return QVariant();

    const Client &client = m_clients.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return client.id;
        case 1: return client.name;
        case 2: return client.email;
        case 3: return client.phone;
        case 4: return client.status;
        case 5: return client.balance;
        }
    } else {
        switch (role) {
        case IdRole: return client.id;
        case NameRole: return client.name;
        case EmailRole: return client.email;
        case PhoneRole: return client.phone;
        case AddressRole: return client.address;
        case TaxNumberRole: return client.tax_number;
        case PaymentTermsRole: return client.payment_terms;
        case NotesRole: return client.notes;
        case StatusRole: return client.status;
        case BalanceRole: return client.balance;
        case CheckedRole: return client.checked;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> ClientModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[EmailRole] = "email";
    roles[PhoneRole] = "phone";
    roles[AddressRole] = "address";
    roles[TaxNumberRole] = "taxNumber";
    roles[PaymentTermsRole] = "paymentTerms";
    roles[NotesRole] = "notes";
    roles[StatusRole] = "status";
    roles[BalanceRole] = "balance";
    roles[CheckedRole] = "checked";
    return roles;
}


QVariant ClientModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Name");
        case 2: return tr("Email");
        case 3: return tr("Phone");
        case 4: return tr("Type");
        case 5: return tr("Balance");
        case 6: return tr("Total Sales");
        }
    }
    return QVariant();
}

bool ClientModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_clients.count()) {
            m_clients[index.row()].checked = value.toBool();
            Q_EMIT dataChanged(index, index, {role});
            updateHasCheckedItems();
            return true;
        }
    }
    return false;
}

void ClientModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getClients(m_searchQuery, m_sortField, m_sortDirection, m_currentPage, m_currentType);
}

void ClientModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        Q_EMIT currentPageChanged();
        refresh();
    }
}

void ClientModel::createClient(const QVariantMap &clientData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createClient(clientFromVariantMap(clientData));
}

void ClientModel::updateClient(int id, const QVariantMap &clientData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updateClient(id, clientFromVariantMap(clientData));
}

void ClientModel::deleteClient(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deleteClient(id);
}

QVariantMap ClientModel::getClient(int row) const
{
    if (row < 0 || row >= m_clients.count())
        return QVariantMap();

    return clientToVariantMap(m_clients.at(row));
}



// Selection methods
void ClientModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_clients.count()) {
        m_clients[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList ClientModel::getCheckedClientIds() const
{
    QVariantList checkedIds;
    for (const auto &client : m_clients) {
        if (client.checked) {
            checkedIds.append(client.id);
        }
    }
    return checkedIds;
}

void ClientModel::clearAllChecked()
{
    for (int i = 0; i < m_clients.count(); ++i) {
        if (m_clients[i].checked) {
            m_clients[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}

void ClientModel::toggleAllClientsChecked()
{
    bool allChecked = true;
    for (const auto &client : m_clients) {
        if (!client.checked) {
            allChecked = false;
            break;
        }
    }

    for (int i = 0; i < m_clients.count(); ++i) {
        m_clients[i].checked = !allChecked;
        QModelIndex index = createIndex(i, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Slots
void ClientModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        Q_EMIT sortFieldChanged();
        refresh();
    }
}

void ClientModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        Q_EMIT sortDirectionChanged();
        refresh();
    }
}

void ClientModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        Q_EMIT searchQueryChanged();
        refresh();
    }
}

void ClientModel::filterByType(const QString &type)
{
    if (m_currentType != type) {
        m_currentType = type;
        refresh();
    }
}

// Private slots
void ClientModel::handleClientsReceived(const PaginatedClients &clients)
{
    beginResetModel();
    m_clients = clients.data;
    endResetModel();

    m_totalItems = clients.total;
    Q_EMIT totalItemsChanged();

    m_currentPage = clients.currentPage;
    Q_EMIT currentPageChanged();

    m_totalPages = clients.lastPage;
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    Q_EMIT dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}

void ClientModel::handleClientError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void ClientModel::handleClientCreated(const Client &client)
{
    beginInsertRows(QModelIndex(), m_clients.count(), m_clients.count());
    m_clients.append(client);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT clientCreated();
}

void ClientModel::handleClientUpdated(const Client &client)
{
    for (int i = 0; i < m_clients.count(); ++i) {
        if (m_clients[i].id == client.id) {
            m_clients[i] = client;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT clientUpdated();
}

void ClientModel::handleClientDeleted(int id)
{
    for (int i = 0; i < m_clients.count(); ++i) {
        if (m_clients[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_clients.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT clientDeleted();
}


// Private methods
void ClientModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void ClientModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        Q_EMIT errorMessageChanged();
    }
}

Client ClientModel::clientFromVariantMap(const QVariantMap &map) const
{
    Client client;
    client.id = map["id"_L1].toInt();
    client.name = map["name"_L1].toString();
    client.email = map["email"_L1].toString();
    client.phone = map["phone"_L1].toString();
    client.address = map["address"_L1].toString();
    client.tax_number = map["tax_number"_L1].toString();
    client.if_number = map["if_number"_L1].toString();
    client.rc_number = map["rc_number"_L1].toString();
    client.cnss_number = map["cnss_number"_L1].toString();
    client.tp_number = map["tp_number"_L1].toString();
    client.nis_number = map["nis_number"_L1].toString();
    client.nif_number = map["nif_number"_L1].toString();
    client.ai_number = map["ai_number"_L1].toString();
    client.payment_terms = map["payment_terms"_L1].toString();
    client.notes = map["notes"_L1].toString();
    client.status = map["status"_L1].toString();
    client.balance = map["balance"_L1].toString().toDouble();
    return client;
}

QVariantMap ClientModel::clientToVariantMap(const Client &client) const
{
    QVariantMap map;
    map["id"_L1] = client.id;
    map["name"_L1] = client.name;
    map["email"_L1] = client.email;
    map["phone"_L1] = client.phone;
    map["address"_L1] = client.address;
    map["tax_number"_L1] = client.tax_number;
    map["if_number"_L1] = client.if_number;
    map["rc_number"_L1] = client.rc_number;
    map["cnss_number"_L1] = client.cnss_number;
    map["tp_number"_L1] = client.tp_number;
    map["nis_number"_L1] = client.nis_number;
    map["nif_number"_L1] = client.nif_number;
    map["ai_number"_L1] = client.ai_number;
    map["payment_terms"_L1] = client.payment_terms;
    map["notes"_L1] = client.notes;
    map["status"_L1] = client.status;
    map["balance"_L1] = client.balance;
    return map;
}


void ClientModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &client : m_clients) {
        if (client.checked) {
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
