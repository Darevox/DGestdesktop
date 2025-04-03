#include "quotemodel.h"

namespace NetworkApi {

QuoteModel::QuoteModel(QObject *parent)
    : SaleModel(parent)
{
    // Override the default type to "quote"
    setType(QStringLiteral("quote"));
}

// If you need to override or extend any methods, you can do so here.
// For example, if you want to modify how convertToSale works for quotes:

/*
void QuoteModel::convertToSale(int id)
{
    // Custom implementation for quotes
    // Or just call the parent implementation
    SaleModel::convertToSale(id);

    // Additional quote-specific logic here
}
*/
void QuoteModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    // Explicitly use "quote" instead of m_type
    m_api->getSales(m_searchQuery, m_sortField, m_sortDirection, m_currentPage, m_status, m_paymentStatus, QStringLiteral("quote"));
}

} // namespace NetworkApi
