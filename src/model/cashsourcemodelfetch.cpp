// cashsourcemodelfetch.cpp
#include "cashsourcemodelfetch.h"

namespace NetworkApi {
using namespace Qt::StringLiterals;
CashSourceModelFetch::CashSourceModelFetch(QObject *parent)
    : CashSourceModel(parent)
{
}

void CashSourceModelFetch::loadPage(int page)
{
    qDebug() << "CashSourceModelFetch::loadPage - Loading page:" << page
             << "Current page:" << m_currentPage
             << "Total pages:" << m_totalPages;

    if (page > 0 && page <= m_totalPages && !m_loading) {
        setLoading(true);
        m_api->getCashSources(m_searchQuery, m_sortField, m_sortDirection, page);
    }
}

void CashSourceModelFetch::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getCashSources(m_searchQuery, m_sortField, m_sortDirection, m_currentPage);
}

void CashSourceModelFetch::handleCashSourcesReceived(const PaginatedCashSources &sources)
{
    qDebug() << "CashSourceModelFetch::handleCashSourcesReceived - Received page:"
             << sources.currentPage << "of" << sources.lastPage
             << "Items count:" << sources.data.count();

    if (sources.currentPage == 1) {
        beginResetModel();
        m_sources.clear();
        endResetModel();
    }

    if (!sources.data.isEmpty()) {
        beginInsertRows(QModelIndex(), m_sources.count(),
                       m_sources.count() + sources.data.count() - 1);
        m_sources.append(sources.data);
        endInsertRows();
    }

    m_totalItems = sources.total;
    m_currentPage = sources.currentPage;
    m_totalPages = sources.lastPage;

    Q_EMIT totalItemsChanged();
    Q_EMIT currentPageChanged();
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    qDebug() << "CashSourceModelFetch::handleCashSourcesReceived - After update:"
             << "Current page:" << m_currentPage
             << "Total items:" << m_totalItems
             << "Total sources in model:" << m_sources.count();
}

} // namespace NetworkApi
