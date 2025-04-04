// suppliermodel.cpp
#include "suppliermodel.h"
#include <QJsonDocument>

namespace NetworkApi {
using namespace Qt::StringLiterals;
SupplierModel::SupplierModel(QObject *parent)
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

void SupplierModel::setApi(SupplierApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &SupplierApi::suppliersReceived, this, &SupplierModel::handleSuppliersReceived);
        connect(m_api, &SupplierApi::errorSuppliersReceived, this, &SupplierModel::handleSupplierError);
        connect(m_api, &SupplierApi::supplierCreated, this, &SupplierModel::handleSupplierCreated);
        connect(m_api, &SupplierApi::supplierUpdated, this, &SupplierModel::handleSupplierUpdated);
        connect(m_api, &SupplierApi::supplierDeleted, this, &SupplierModel::handleSupplierDeleted);


    }
     refresh();
}

int SupplierModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_suppliers.count();
}

int SupplierModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 5; // Adjust based on your needs
}

QVariant SupplierModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_suppliers.count())
        return QVariant();

    const Supplier &supplier = m_suppliers.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return supplier.id;
        case 1: return supplier.name;
        case 2: return supplier.email;
        case 3: return supplier.phone;
        case 4: return supplier.status;
        case 5: return supplier.balance;
        }
    } else {
        switch (role) {
        case IdRole: return supplier.id;
        case NameRole: return supplier.name;
        case EmailRole: return supplier.email;
        case PhoneRole: return supplier.phone;
        case AddressRole: return supplier.address;
        case PaymentTermsRole: return supplier.payment_terms;
        case TaxNumberRole: return supplier.tax_number;
        case NotesRole: return supplier.notes;
        case StatusRole: return supplier.status;
        case BalanceRole: return supplier.balance;
        case CheckedRole: return supplier.checked;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> SupplierModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[EmailRole] = "email";
    roles[PhoneRole] = "phone";
    roles[AddressRole] = "address";
    roles[PaymentTermsRole] = "paymentTerms";
    roles[TaxNumberRole] = "taxNumber";
    roles[NotesRole] = "notes";
    roles[StatusRole] = "status";
    roles[BalanceRole] = "balance";
    roles[CheckedRole] = "checked";
    return roles;
}

QVariant SupplierModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Name");
        case 2: return tr("Email");
        case 3: return tr("Phone");
        case 4: return tr("Status");
        case 5: return tr("Balance");
        }
    }
    return QVariant();
}

bool SupplierModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role == CheckedRole) {
        if (index.isValid() && index.row() < m_suppliers.count()) {
            m_suppliers[index.row()].checked = value.toBool();
            Q_EMIT dataChanged(index, index, {role});
            updateHasCheckedItems();
            return true;
        }
    }
    return false;
}

void SupplierModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getSuppliers(m_searchQuery, m_sortField, m_sortDirection, m_currentPage);
}

void SupplierModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        Q_EMIT currentPageChanged();
        refresh();
    }
}

void SupplierModel::createSupplier(const QVariantMap &supplierData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->createSupplier(supplierFromVariantMap(supplierData));
}

void SupplierModel::updateSupplier(int id, const QVariantMap &supplierData)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->updateSupplier(id, supplierFromVariantMap(supplierData));
}

void SupplierModel::deleteSupplier(int id)
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->deleteSupplier(id);
}

QVariantMap SupplierModel::getSupplier(int row) const
{
    if (row < 0 || row >= m_suppliers.count())
        return QVariantMap();

    return supplierToVariantMap(m_suppliers.at(row));
}

// Selection methods
void SupplierModel::setChecked(int row, bool checked)
{
    if (row >= 0 && row < m_suppliers.count()) {
        m_suppliers[row].checked = checked;
        QModelIndex index = createIndex(row, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
        updateHasCheckedItems();
    }
}

QVariantList SupplierModel::getCheckedSupplierIds() const
{
    QVariantList checkedIds;
    for (const auto &supplier : m_suppliers) {
        if (supplier.checked) {
            checkedIds.append(supplier.id);
        }
    }
    return checkedIds;
}

void SupplierModel::clearAllChecked()
{
    for (int i = 0; i < m_suppliers.count(); ++i) {
        if (m_suppliers[i].checked) {
            m_suppliers[i].checked = false;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index, {CheckedRole});
        }
    }
    updateHasCheckedItems();
}

void SupplierModel::toggleAllSuppliersChecked()
{
    bool allChecked = true;
    for (const auto &supplier : m_suppliers) {
        if (!supplier.checked) {
            allChecked = false;
            break;
        }
    }

    for (int i = 0; i < m_suppliers.count(); ++i) {
        m_suppliers[i].checked = !allChecked;
        QModelIndex index = createIndex(i, 0);
        Q_EMIT dataChanged(index, index, {CheckedRole});
    }
    updateHasCheckedItems();
}

// Slots
void SupplierModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        Q_EMIT sortFieldChanged();
        refresh();
    }
}

void SupplierModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        Q_EMIT sortDirectionChanged();
        refresh();
    }
}

void SupplierModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        Q_EMIT searchQueryChanged();
        refresh();
    }
}

// Private slots
void SupplierModel::handleSuppliersReceived(const PaginatedSuppliers &suppliers)
{
    beginResetModel();
    m_suppliers = suppliers.data;
    endResetModel();

    m_totalItems = suppliers.total;
    Q_EMIT totalItemsChanged();

    m_currentPage = suppliers.currentPage;
    Q_EMIT currentPageChanged();

    m_totalPages = suppliers.lastPage;
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    updateHasCheckedItems();
    Q_EMIT dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}

void SupplierModel::handleSupplierError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void SupplierModel::handleSupplierCreated(const Supplier &supplier)
{
    beginInsertRows(QModelIndex(), m_suppliers.count(), m_suppliers.count());
    m_suppliers.append(supplier);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT supplierCreated();
}

void SupplierModel::handleSupplierUpdated(const Supplier &supplier)
{
    for (int i = 0; i < m_suppliers.count(); ++i) {
        if (m_suppliers[i].id == supplier.id) {
            m_suppliers[i] = supplier;
            QModelIndex index = createIndex(i, 0);
            Q_EMIT dataChanged(index, index);
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT supplierUpdated();
}

void SupplierModel::handleSupplierDeleted(int id)
{
    for (int i = 0; i < m_suppliers.count(); ++i) {
        if (m_suppliers[i].id == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_suppliers.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
    Q_EMIT supplierDeleted();
}

// Private methods
void SupplierModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void SupplierModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        Q_EMIT errorMessageChanged();
    }
}

Supplier SupplierModel::supplierFromVariantMap(const QVariantMap &map) const
{
    Supplier supplier;
    supplier.id = map["id"_L1].toInt();
    supplier.name = map["name"_L1].toString();
    supplier.email = map["email"_L1].toString();
    supplier.phone = map["phone"_L1].toString();
    supplier.address = map["address"_L1].toString();
    supplier.payment_terms = map["paymentTerms"_L1].toString();
    supplier.tax_number = map["taxNumber"_L1].toString();
    supplier.notes = map["notes"_L1].toString();
    supplier.status = map["status"_L1].toString();
    supplier.balance = map["balance"_L1].toDouble();
    return supplier;
}

QVariantMap SupplierModel::supplierToVariantMap(const Supplier &supplier) const
{
    QVariantMap map;
    map["id"_L1] = supplier.id;
    map["name"_L1] = supplier.name;
    map["email"_L1] = supplier.email;
    map["phone"_L1] = supplier.phone;
    map["address"_L1] = supplier.address;
    map["paymentTerms"_L1] = supplier.payment_terms;
    map["taxNumber"_L1] = supplier.tax_number;
    map["notes"_L1] = supplier.notes;
    map["status"_L1] = supplier.status;
    map["balance"_L1] = supplier.balance;
    return map;
}

void SupplierModel::updateHasCheckedItems()
{
    bool hasChecked = false;
    for (const auto &supplier : m_suppliers) {
        if (supplier.checked) {
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
