#include "dashboardmodel.h"
#include <QJsonObject>
#include <QJsonArray>

namespace NetworkApi {

DashboardModel::DashboardModel(QObject *parent)
    : QObject(parent)
{
}

void DashboardModel::setApi(DashboardAnalyticsApi* api)
{
    if (m_api == api)
        return;

    m_api = api;

    // Connect to API signals
    connect(m_api, &DashboardAnalyticsApi::overallDashboardReceived,
            this, &DashboardModel::handleOverallDashboard);
    connect(m_api, &DashboardAnalyticsApi::salesAnalyticsReceived,
            this, &DashboardModel::handleSalesAnalytics);
    connect(m_api, &DashboardAnalyticsApi::purchaseAnalyticsReceived,
            this, &DashboardModel::handlePurchaseAnalytics);
    // Add this connection
    connect(m_api, &DashboardAnalyticsApi::customerAnalyticsReceived,
            this, &DashboardModel::handleCustomerAnalytics);
    connect(m_api, &DashboardAnalyticsApi::analyticsError,
            this, &DashboardModel::handleError);

    refresh();
}

void DashboardModel::refresh()
{

    if (!m_api)
        return;

    setLoading(true);
    updateData();
}

void DashboardModel::setTimeframe(const QString &timeframe)
{
    if (m_timeframe == timeframe)
        return;
    m_timeframe = timeframe;
    emit timeframeChanged();
}


void DashboardModel::setDateRange(const QDate &start, const QDate &end)
{
    if (m_startDate == start && m_endDate == end)
        return;
    m_startDate = start;
    m_endDate = end;
    emit dateRangeChanged();
    refresh();
}


void DashboardModel::updateData()
{   QString startDateStr = m_startDate.toString("yyyy-MM-dd");
    QString endDateStr = m_endDate.toString("yyyy-MM-dd");
    qDebug() << "Updating dashboard data for timeframe:" << m_timeframe;

    m_api->getOverallDashboard(m_timeframe);
    m_api->getSalesAnalytics(m_timeframe, m_startDate, m_endDate);
    m_api->getPurchaseAnalytics(m_timeframe, m_startDate, m_endDate);
    m_api->getCustomerAnalytics(m_timeframe, m_startDate, m_endDate);
    m_api->getInventoryAnalytics(m_timeframe, m_startDate, m_endDate);
}

void DashboardModel::handleOverallDashboard(const DashboardOverview &data)
{
    qDebug() << "Handling Overall Dashboard:";

    // Period stats
    m_totalSales = data.periodSales;
    m_totalPurchases = data.periodPurchases;
    m_totalOrders = data.periodOrders;
    m_totalRevenue = data.periodSales - data.periodPurchases;

    // All-time stats
    m_allTimeSales = data.allTimeSales;
    m_allTimePurchases = data.allTimePurchases;
    m_allTimeOrders = data.allTimeOrders;

    // Current status
    m_lowStockCount = data.lowStockCount;
    m_cashBalance = data.cashBalance;

    // Period info
    m_periodInfo = data.periodInfo;

    // Emit signals
    emit totalSalesChanged();
    emit totalPurchasesChanged();
    emit totalRevenueChanged();
    emit totalOrdersChanged();
    emit lowStockCountChanged();
    emit cashBalanceChanged();
    emit statsChanged();
    emit allTimeSalesChanged();
    emit allTimePurchasesChanged();
    emit allTimeOrdersChanged();
    emit periodInfoChanged();

    setLoading(false);
}

void DashboardModel::handleSalesAnalytics(const SaleAnalytics &data)
{
    // Period stats
    m_totalSales = data.totalRevenue;
    m_totalOrders = data.totalOrders;
    m_salesHistory = data.history;

    // All-time stats
    m_allTimeSales = data.allTimeRevenue;
    m_allTimeOrders = data.allTimeOrders;

    // Top products
    m_topProducts.clear();
    for (const QVariantMap &product : data.topProducts) {
        m_topProducts.append(QVariant::fromValue(product));
    }

    // Period info
    m_periodInfo = data.periodInfo;

    emit salesHistoryChanged();
    emit topItemsChanged();
    emit statsChanged();
    emit allTimeSalesChanged();
    emit allTimeOrdersChanged();
    emit periodInfoChanged();
    setLoading(false);
}

void DashboardModel::handlePurchaseAnalytics(const PurchaseAnalytics &data)
{
    // Period stats
    m_totalPurchases = data.totalCost;
    m_purchaseHistory = data.history;

    // All-time stats
    m_allTimePurchases = data.allTimeCost;

    // Update period info
    m_periodInfo = data.periodInfo;

    emit purchaseHistoryChanged();
    emit statsChanged();
    emit allTimePurchasesChanged();
    emit periodInfoChanged();
    setLoading(false);
}

void DashboardModel::handleCustomerAnalytics(const QVariantMap &data)
{
    qDebug() << "Handling Customer Analytics:";
    const QVariantMap dataMap = data["data"].toMap();

    if (dataMap.contains("top_customers")) {
        m_topCustomers = dataMap["top_customers"].toList();
        qDebug() << "Top Customers:" << m_topCustomers.count();

        // Update period info if available
        if (dataMap.contains("period_info")) {
            m_periodInfo = dataMap["period_info"].toMap();
            emit periodInfoChanged();
        }

        emit topCustomersChanged();
    }
    setLoading(false);
}
void DashboardModel::handleError(const QString &message, ApiStatus status, const QString &details)
{
    setLoading(false);
    emit error(message);
}

void DashboardModel::setLoading(bool loading)
{
    if (m_loading == loading)
        return;

    m_loading = loading;
    emit loadingChanged();
}
void DashboardModel::setStartDate(const QDate &date)
{
    if (m_startDate == date)
        return;
    m_startDate = date;
    emit dateRangeChanged();
}

void DashboardModel::setEndDate(const QDate &date)
{
    if (m_endDate == date)
        return;
    m_endDate = date;
    emit dateRangeChanged();
}
QVariantMap DashboardModel::formatTopItem(const QVariantMap &item)
{
    QVariantMap formatted = item;
    // Add any additional formatting here
    return formatted;
}

} // namespace NetworkApi
