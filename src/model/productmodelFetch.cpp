#include "productmodelFetch.h"
#include <QDebug>

namespace NetworkApi {
using namespace Qt::StringLiterals;
ProductModelFetch::ProductModelFetch(QObject *parent)
    : ProductModel(parent)
{
}

void ProductModelFetch::loadPage(int page)
{
    qDebug() << "ProductModelFetch::loadPage - Loading page:" << page
             << "Current page:" << m_currentPage
             << "Total pages:" << m_totalPages;

    if (page > 0 && page <= m_totalPages && !m_loading) {
        setLoading(true);
        m_api->getProducts(m_searchQuery, m_sortField, m_sortDirection, page, m_lowStockFilter);
    }
}

void ProductModelFetch::refresh()
{
    if (!m_api)
        return;

    // Don't reset to first page on refresh
    setLoading(true);
    m_api->getProducts(m_searchQuery, m_sortField, m_sortDirection, m_currentPage, m_lowStockFilter);
}

void ProductModelFetch::handleProductsReceived(const PaginatedProducts& products)
{
    qDebug() << "ProductModelFetch::handleProductsReceived - Received page:"
             << products.currentPage << "of" << products.lastPage
             << "Items count:" << products.data.count();

    if (products.currentPage == 1) {
        // Only clear for first page
        beginResetModel();
        m_products.clear();
        endResetModel();
    }

    // Insert new rows
    if (!products.data.isEmpty()) {
        beginInsertRows(QModelIndex(), m_products.count(),
                       m_products.count() + products.data.count() - 1);
        m_products.append(products.data);
        endInsertRows();
    }

    m_totalItems = products.total;
    m_currentPage = products.currentPage;
    m_totalPages = products.lastPage;

    Q_EMIT totalItemsChanged();
    Q_EMIT currentPageChanged();
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    qDebug() << "ProductModelFetch::handleProductsReceived - After update:"
             << "Current page:" << m_currentPage
             << "Total items:" << m_totalItems
             << "Total products in model:" << m_products.count();
}

} // namespace NetworkApi
