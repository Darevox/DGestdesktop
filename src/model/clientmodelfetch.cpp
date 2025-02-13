#include "clientmodelfetch.h"
namespace NetworkApi {
using namespace Qt::StringLiterals;
ClientModelFetch::ClientModelFetch(QObject *parent)
    : ClientModel{parent}
{

}
// clientmodelfetch.cpp
void ClientModelFetch::loadPage(int page)
{
    qDebug() << "ClientModelFetch::loadPage - Loading page:" << page
             << "Current page:" << m_currentPage
             << "Total pages:" << m_totalPages;

    if (page > 0 && page <= m_totalPages && !m_loading) {
        setLoading(true);
        // Pass the requested page instead of m_currentPage
        m_api->getClients(m_searchQuery, m_sortField, m_sortDirection, page, m_currentType);
    }
}

void ClientModelFetch::handleClientsReceived(const PaginatedClients &clients)
{
    qDebug() << "ClientModelFetch::handleClientsReceived - Received page:"
             << clients.currentPage << "of" << clients.lastPage
             << "Items count:" << clients.data.count();

    // Only clear for first page
    if (clients.currentPage == 1) {
        beginResetModel();
        m_clients.clear();
        endResetModel();
    }

    // Insert new rows
    if (!clients.data.isEmpty()) {
        beginInsertRows(QModelIndex(), m_clients.count(),
                       m_clients.count() + clients.data.count() - 1);
        m_clients.append(clients.data);
        endInsertRows();
    }

    // Update pagination info after adding new data
    m_totalItems = clients.total;
    m_currentPage = clients.currentPage; // Update current page to received page
    m_totalPages = clients.lastPage;

    Q_EMIT totalItemsChanged();
    Q_EMIT currentPageChanged();
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    qDebug() << "ClientModelFetch::handleClientsReceived - After update:"
             << "Current page:" << m_currentPage
             << "Total items:" << m_totalItems
             << "Total clients in model:" << m_clients.count();
}

void ClientModelFetch::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    // Always use current page for refresh
    m_api->getClients(m_searchQuery, m_sortField, m_sortDirection, m_currentPage, m_currentType);
}


}
