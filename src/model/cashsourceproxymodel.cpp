#include <model/cashsourceproxymodel.h>
#include <QDebug>

CashSourceProxyModel::CashSourceProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
}

void CashSourceProxyModel::setRTL(bool rtl)
{
    if (m_rtl != rtl) {
        m_rtl = rtl;
        invalidate();
        Q_EMIT rtlChanged();
    }
}

QVariant CashSourceProxyModel::data(const QModelIndex &index, int role) const
{
    if (!sourceModel()) {
        return QVariant();
    }

    // Map the index to source model
    QModelIndex sourceIndex = mapToSource(index);
    return sourceModel()->data(sourceIndex, role);
}

void CashSourceProxyModel::sort(int column, Qt::SortOrder order)
{
    if (!sourceModel()) {
        return;
    }

    // Map the column to source model
    int sourceColumn = mapToSourceColumn(column);
    sourceModel()->sort(sourceColumn, order);
}

int CashSourceProxyModel::mapToSourceColumn(int proxyColumn) const
{
    if (!m_rtl || !sourceModel()) {
        return proxyColumn;
    }
    return sourceModel()->columnCount() - 1 - proxyColumn;
}

int CashSourceProxyModel::mapFromSourceColumn(int sourceColumn) const
{
    if (!m_rtl || !sourceModel()) {
        return sourceColumn;
    }
    return sourceModel()->columnCount() - 1 - sourceColumn;
}

QModelIndex CashSourceProxyModel::mapToSource(const QModelIndex &proxyIndex) const
{
    if (!proxyIndex.isValid() || !sourceModel()) {
        return QModelIndex();
    }

    int sourceColumn = mapToSourceColumn(proxyIndex.column());
    return sourceModel()->index(proxyIndex.row(), sourceColumn);
}

QModelIndex CashSourceProxyModel::mapFromSource(const QModelIndex &sourceIndex) const
{
    if (!sourceIndex.isValid() || !sourceModel()) {
        return QModelIndex();
    }

    int proxyColumn = mapFromSourceColumn(sourceIndex.column());
    return index(sourceIndex.row(), proxyColumn);
}
