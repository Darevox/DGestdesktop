#ifndef DASHBOARDMODEL_H
#define DASHBOARDMODEL_H

#include <QObject>
#include <QDateTime>
#include "../api/dashboardanalyticsapi.h"

namespace NetworkApi {

class DashboardModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString timeframe READ timeframe WRITE setTimeframe NOTIFY timeframeChanged)
    Q_PROPERTY(QDate startDate READ startDate WRITE setStartDate NOTIFY dateRangeChanged)
    Q_PROPERTY(QDate endDate READ endDate WRITE setEndDate NOTIFY dateRangeChanged)
    Q_PROPERTY(QVariantList salesHistory READ salesHistory NOTIFY salesHistoryChanged)
    Q_PROPERTY(QVariantList purchaseHistory READ purchaseHistory NOTIFY purchaseHistoryChanged)
    Q_PROPERTY(QVariantList revenueData READ revenueData NOTIFY revenueDataChanged)

    // Overall stats
    Q_PROPERTY(double totalSales READ totalSales NOTIFY statsChanged)
    Q_PROPERTY(double totalPurchases READ totalPurchases NOTIFY statsChanged)
    Q_PROPERTY(double totalRevenue READ totalRevenue NOTIFY statsChanged)
    Q_PROPERTY(int totalOrders READ totalOrders NOTIFY statsChanged)
    Q_PROPERTY(int lowStockCount READ lowStockCount NOTIFY statsChanged)
    Q_PROPERTY(double cashBalance READ cashBalance NOTIFY statsChanged)

    // Top items
    Q_PROPERTY(QVariantList topProducts READ topProducts NOTIFY topItemsChanged)
    Q_PROPERTY(QVariantList topCustomers READ topCustomers NOTIFY topCustomersChanged)

    Q_PROPERTY(double allTimeSales READ allTimeSales NOTIFY allTimeSalesChanged)
    Q_PROPERTY(double allTimePurchases READ allTimePurchases NOTIFY allTimePurchasesChanged)
    Q_PROPERTY(int allTimeOrders READ allTimeOrders NOTIFY allTimeOrdersChanged)
    Q_PROPERTY(QVariantMap periodInfo READ periodInfo NOTIFY periodInfoChanged)

public:
    explicit DashboardModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(DashboardAnalyticsApi* api);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setDateRange(const QDate &start, const QDate &end);
    // Getters
    bool loading() const { return m_loading; }
    QString timeframe() const { return m_timeframe; }
    QDate startDate() const { return m_startDate; }
    QDate endDate() const { return m_endDate; }

    void setTimeframe(const QString &timeframe);
    void setStartDate(const QDate &date);
    void setEndDate(const QDate &date);
    QVariantList salesHistory() const { return m_salesHistory; }
    QVariantList purchaseHistory() const { return m_purchaseHistory; }
    QVariantList revenueData() const { return m_revenueData; }

    double totalSales() const { return m_totalSales; }
    double totalPurchases() const { return m_totalPurchases; }
    double totalRevenue() const { return m_totalRevenue; }
    int totalOrders() const { return m_totalOrders; }
    int lowStockCount() const { return m_lowStockCount; }
    double cashBalance() const { return m_cashBalance; }

    QVariantList topProducts() const { return m_topProducts; }
    QVariantList topCustomers() const { return m_topCustomers; }

    double allTimeSales() const { return m_allTimeSales; }
    double allTimePurchases() const { return m_allTimePurchases; }
    int allTimeOrders() const { return m_allTimeOrders; }
    QVariantMap periodInfo() const { return m_periodInfo; }


public slots:

signals:
    void loadingChanged();
    void timeframeChanged();
    void salesHistoryChanged();
    void purchaseHistoryChanged();
    void revenueDataChanged();
    void statsChanged();
    void topItemsChanged();
    void error(const QString &message);
    void dateRangeChanged();
    void totalSalesChanged();
    void totalPurchasesChanged();
    void totalRevenueChanged();
    void totalOrdersChanged();
    void lowStockCountChanged();
    void cashBalanceChanged();
    void topCustomersChanged();

    void allTimeSalesChanged();
    void allTimePurchasesChanged();
    void allTimeOrdersChanged();
    void periodInfoChanged();



private slots:
    void handleOverallDashboard(const DashboardOverview &data);
    void handleSalesAnalytics(const SaleAnalytics &data);
    void handlePurchaseAnalytics(const PurchaseAnalytics &data);
    void handleError(const QString &message, ApiStatus status, const QString &details);
    void handleCustomerAnalytics(const QVariantMap &data);

private:
    DashboardAnalyticsApi* m_api = nullptr;
    bool m_loading = false;
    QString m_timeframe = "daily";
    QDate m_startDate;
    QDate m_endDate;

    // Chart data
    QVariantList m_salesHistory;
    QVariantList m_purchaseHistory;
    QVariantList m_revenueData;

    // Stats
    double m_totalSales = 0;
    double m_totalPurchases = 0;
    double m_totalRevenue = 0;
    int m_totalOrders = 0;
    int m_lowStockCount = 0;
    double m_cashBalance = 0;

    // Top items
    QVariantList  m_topProducts;
    QVariantList m_topCustomers;

    void setLoading(bool loading);
    void updateData();
    void processChartData(const QVariantList &data, const QString &type);
    QVariantMap formatTopItem(const QVariantMap &item);

    double m_allTimeSales = 0;
    double m_allTimePurchases = 0;
    int m_allTimeOrders = 0;
    QVariantMap m_periodInfo;
};

} // namespace NetworkApi

#endif // DASHBOARDMODEL_H
