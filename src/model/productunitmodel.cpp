#include "productunitmodel.h"

namespace NetworkApi {
using namespace Qt::StringLiterals;
ProductUnitModel::ProductUnitModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ProductUnitModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_units.count();
}

QVariant ProductUnitModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_units.count())
        return QVariant();

    const ProductUnit &unit = m_units.at(index.row());

    switch (role) {
    case IdRole:
        return unit.id;
    case NameRole:
        return unit.name;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ProductUnitModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    return roles;
}

void ProductUnitModel::setUnits(const QList<ProductUnit>& units)
{
    beginResetModel();
    m_units = units;
    endResetModel();
}

void ProductUnitModel::fetchUnits(ProductApi* api)
{
    if (!api) return;

    connect(api, &ProductApi::productUnitsReceived, this, &ProductUnitModel::handleUnitsReceived, Qt::UniqueConnection);
    connect(api, &ProductApi::errorOccurred, this, &ProductUnitModel::handleError, Qt::UniqueConnection);

    api->getProductUnits();
}

void ProductUnitModel::handleUnitsReceived(const QList<ProductUnit>& units)
{
    setUnits(units);
}

void ProductUnitModel::handleError(const ApiError& error)
{
    // Handle error - you might want to Q_EMIT a signal or set an error property
    qWarning() << "Error fetching product units:" << error.message;
}

} // namespace NetworkApi
