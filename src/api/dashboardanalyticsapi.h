#ifndef DASHBOARDANALYTICSAPI_H
#define DASHBOARDANALYTICSAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QDateTime>
#include <QRandomGenerator>
#include <QtConcurrent>

namespace NetworkApi {

struct SaleAnalytics {
    // Period stats
    int totalSales;
    double totalRevenue;
    double averageSale;
    int totalOrders;

    // All-time stats
    int allTimeSales;
    double allTimeRevenue;
    double allTimeAverageSale;
    int allTimeOrders;

    QList<QVariantMap> topProducts;
    QVariantList history;
    QVariantMap periodInfo;
};

struct PurchaseAnalytics {
    // Period stats
    int totalPurchases;
    double totalCost;
    double averagePurchase;

    // All-time stats
    int allTimePurchases;
    double allTimeCost;
    double allTimeAveragePurchase;

    QList<QVariantMap> topSuppliers;
    QVariantList history;
    QVariantMap periodInfo;
};

struct InventoryAnalytics {
    int totalProducts;
    int totalStock;
    double averageStock;
    QList<QVariantMap> lowStockAlerts;
    QVariantList movements;
    QVariantMap periodInfo;
};

struct DashboardOverview {
    // Period stats
    double periodSales;
    double periodPurchases;
    int periodOrders;

    // All-time stats
    double allTimeSales;
    double allTimePurchases;
    int allTimeOrders;

    // Current status
    int lowStockCount;
    double cashBalance;
    QVariantMap periodInfo;
};

class DashboardAnalyticsApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(bool testMode READ testMode WRITE setTestMode NOTIFY testModeChanged)

public:
    explicit DashboardAnalyticsApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // Main analytics methods with default timeframe
    Q_INVOKABLE QFuture<void> getSalesAnalytics(const QString &timeframe = QStringLiteral("daily"),
                                               const QDate &startDate = QDate(),
                                               const QDate &endDate = QDate());
    Q_INVOKABLE QFuture<void> getPurchaseAnalytics(const QString &timeframe = QStringLiteral("daily"),
                                                  const QDate &startDate = QDate(),
                                                  const QDate &endDate = QDate());
    Q_INVOKABLE QFuture<void> getInventoryAnalytics(const QString &timeframe = QStringLiteral("daily"),
                                                    const QDate &startDate = QDate(),
                                                    const QDate &endDate = QDate());
    Q_INVOKABLE QFuture<void> getCustomerAnalytics(const QString &timeframe = QStringLiteral("daily"),
                                                   const QDate &startDate = QDate(),
                                                   const QDate &endDate = QDate());
    Q_INVOKABLE QFuture<void> getOverallDashboard(const QString &timeframe = QStringLiteral("daily"),
                                                  const QDate &startDate = QDate(),
                                                  const QDate &endDate = QDate());

    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);
    bool isLoading() const { return m_isLoading; }
    bool testMode() const { return m_testMode; }
    void setTestMode(bool test) {
        if (m_testMode != test) {
            m_testMode = test;
            Q_EMIT testModeChanged();
        }
    }

Q_SIGNALS:
    void salesAnalyticsReceived(const SaleAnalytics &analytics);
    void purchaseAnalyticsReceived(const PurchaseAnalytics &analytics);
    void inventoryAnalyticsReceived(const InventoryAnalytics &analytics);
    void customerAnalyticsReceived(const QVariantMap &analytics);
    void overallDashboardReceived(const DashboardOverview &overview);
    void analyticsError(const QString &message, ApiStatus status, const QByteArray &details);
    void isLoadingChanged();
    void testModeChanged();

private:
    SaleAnalytics salesAnalyticsFromJson(const QJsonObject &json) const;
    PurchaseAnalytics purchaseAnalyticsFromJson(const QJsonObject &json) const;
    InventoryAnalytics inventoryAnalyticsFromJson(const QJsonObject &json) const;
    DashboardOverview dashboardOverviewFromJson(const QJsonObject &json) const;

    QSettings m_settings;
    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            Q_EMIT isLoadingChanged();
        }
    }
    bool m_testMode = false;
    void provideFakeData();
};

} // namespace NetworkApi

#endif // DASHBOARDANALYTICSAPI_H
