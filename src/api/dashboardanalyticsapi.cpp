#include "dashboardanalyticsapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;
DashboardAnalyticsApi::DashboardAnalyticsApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
   ,  m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}
void DashboardAnalyticsApi::provideFakeData()
{
    // // Fake Sales Analytics
    // SaleAnalytics salesData;
    // salesData.totalSales = 1000;
    // salesData.totalRevenue = 50000.0;
    // salesData.averageSale = 50.0;
    // salesData.totalOrders = 100;

    // // Create fake history data
    // QVariantList salesHistory;
    // for (int i = 0; i < 50; i++) {
    //     salesHistory.append(QRandomGenerator::global()->bounded(1000, 5000));
    // }
    // salesData.history = salesHistory;

    // // Create fake top products
    // QList<QVariantMap> topProducts;
    // const QStringList productNames{
    //     "Laptop Pro X1"_L1,
    //     "Smartphone Y20"_L1,
    //     "Tablet Z10"_L1,
    //     "Wireless Earbuds"_L1,
    //     "Smart Watch V2"_L1
    // };
    // for (int i = 0; i < productNames.size(); i++) {
    //     QVariantMap product;
    //     product["name"_L1] = productNames[i];
    //     product["total_quantity"_L1] = QRandomGenerator::global()->bounded(100, 1000);
    //     product["total_revenue"_L1] = QRandomGenerator::global()->bounded(1000, 10000);
    //     product["icon"_L1] = QStringLiteral("package"); // Icon name for the UI
    //     product["description"_L1] = QStringLiteral("Best selling product #%1").arg(i + 1);
    //     topProducts.append(product);
    // }
    // salesData.topProducts = topProducts;

    // // Q_EMIT fake sales data
    // Q_EMIT salesAnalyticsReceived(salesData);

    // // Fake Purchase Analytics
    // PurchaseAnalytics purchaseData;
    // purchaseData.totalPurchases = 800;
    // purchaseData.totalCost = 40000.0;
    // purchaseData.averagePurchase = 50.0;

    // // Create fake purchase history
    // QVariantList purchaseHistory;
    // for (int i = 0; i < 50; i++) {
    //     purchaseHistory.append(QRandomGenerator::global()->bounded(800, 4000));
    // }
    // purchaseData.history = purchaseHistory;

    // // Create fake top suppliers
    // QList<QVariantMap> topSuppliers;
    // QStringList supplierNames = {
    //     "Tech Supplies Co.", "Global Electronics", "Digital Systems Ltd",
    //     "Smart Components", "Innovation Tech"
    // };

    // for (int i = 0; i < supplierNames.size(); i++) {
    //     QVariantMap supplier;
    //     supplier["name"_L1] = supplierNames[i];
    //     supplier["total_orders"_L1] = QRandomGenerator::global()->bounded(50, 200);
    //     supplier["total_amount"_L1] = QRandomGenerator::global()->bounded(5000, 20000);
    //     supplier["icon"_L1] = QStringLiteral("truck"); // Icon name for the UI
    //     supplier["description"_L1] = QStringLiteral("Top supplier #%1").arg(i + 1);
    //     topSuppliers.append(supplier);
    // }
    // purchaseData.topSuppliers = topSuppliers;

    // // Q_EMIT fake purchase data
    // Q_EMIT purchaseAnalyticsReceived(purchaseData);

    // // Fake Customer Analytics
    // QVariantList topCustomers;
    // QStringList customerNames = {
    //     "John Smith", "Alice Johnson", "Bob Williams",
    //     "Emma Davis", "Michael Brown"
    // };

    // for (int i = 0; i < customerNames.size(); i++) {
    //     QVariantMap customer;
    //     customer["name"_L1] = customerNames[i];
    //     customer["total_purchases"_L1] = QRandomGenerator::global()->bounded(10, 50);
    //     customer["total_spent"_L1] = QRandomGenerator::global()->bounded(1000, 5000);
    //     customer["icon"_L1] = "user"; // Icon name for the UI
    //     customer["description"_L1] = QString("Loyal customer since 2023");
    //     customer["last_purchase"_L1] = QDateTime::currentDateTime()
    //             .addDays(-QRandomGenerator::global()->bounded(1, 30))
    //             .toString(Qt::ISODate);
    //     topCustomers.append(customer);
    // }

    // // Q_EMIT fake customer data
    // Q_EMIT customerAnalyticsReceived(QVariantMap{{"top_customers", topCustomers}});

    // // // Fake Dashboard Overview
    // DashboardOverview overview;
    // // overview.dailySales = 5000.0;
    // // overview.monthlySales = 150000.0;
    // // overview.dailyPurchases = 4000.0;
    // // overview.monthlyPurchases = 120000.0;
    // // overview.lowStockCount = 15;
    // // overview.cashBalance = 30000.0;
    // // overview.totalOrders = 250;

    // // Create fake revenue data for trends
    // QVariantList revenueData;
    // double baseRevenue = 10000.0;
    // for (int i = 0; i < 12; i++) {
    //     double monthlyRevenue = baseRevenue + QRandomGenerator::global()->bounded(-2000, 2000);
    //     revenueData.append(monthlyRevenue);
    // }


    // // Q_EMIT fake overview data
    // Q_EMIT overallDashboardReceived(overview);

    // // Fake Inventory Analytics
    // InventoryAnalytics inventory;
    // inventory.totalProducts = 500;
    // inventory.totalStock = 25000;
    // inventory.averageStock = 50;

    // QList<QVariantMap> lowStockAlerts;
    // QStringList lowStockProducts = {
    //     "Wireless Mouse", "USB Cable", "Power Bank",
    //     "Screen Protector", "Phone Case"
    // };

    // for (int i = 0; i < lowStockProducts.size(); i++) {
    //     QVariantMap alert;
    //     alert["name"_L1] = lowStockProducts[i];
    //     alert["quantity"_L1] = QRandomGenerator::global()->bounded(1, 10);
    //     alert["min_quantity"_L1] = 15;
    //     alert["icon"_L1] = "package-down"; // Icon for low stock
    //     alert["description"_L1] = QString("Stock level critical");
    //     lowStockAlerts.append(alert);
    // }
    // inventory.lowStockAlerts = lowStockAlerts;

    // // Q_EMIT fake inventory data
    // Q_EMIT inventoryAnalyticsReceived(inventory);
}

QFuture<void> DashboardAnalyticsApi::getSalesAnalytics(const QString &timeframe,
                                                       const QDate &startDate,
                                                       const QDate &endDate)
{
    // if (m_testMode) {
    //     provideFakeData();
    //     return QtConcurrent::run([](){});
    // }

    setLoading(true);

        QString path = QStringLiteral("/api/v1/dashboard/sales-analytics");
        QStringList queryParts;

        // Always add timeframe
        queryParts << QStringLiteral("timeframe=%1").arg(timeframe.isEmpty() ? QStringLiteral("daily") : timeframe);

        // For "daily" timeframe, set both start and end date to today if not provided
        if (timeframe ==  QStringLiteral("daily") && (!startDate.isValid() || !endDate.isValid())) {
            QDate today = QDate::currentDate();
            queryParts << QStringLiteral("start_date=%1").arg(today.toString( QStringLiteral("yyyy-MM-dd")));
            queryParts << QStringLiteral("end_date=%1").arg(today.toString( QStringLiteral("yyyy-MM-dd")));
        } else {
            // Use provided dates
            if (startDate.isValid())
                queryParts << QStringLiteral("start_date=%1").arg(startDate.toString( QStringLiteral("yyyy-MM-dd")));
            if (endDate.isValid())
                queryParts << QStringLiteral("end_date=%1").arg(endDate.toString( QStringLiteral("yyyy-MM-dd")));
        }

        // Append query parameters to path
        if (!queryParts.isEmpty()) {
            path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
        }

        QNetworkRequest request = createRequest(path);
        request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

        qDebug() << "Making analytics request to:" << request.url().toString();

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            SaleAnalytics analytics = salesAnalyticsFromJson(*response.data);
            qDebug()<<"getSalesAnalytics data : "<<*response.data;
            Q_EMIT salesAnalyticsReceived(analytics);
        } else {
            qDebug() << "Sales Analytics Error:";
            qDebug() << "Message:" << response.error->message;
            if (!response.error->details.isEmpty()) {
                qDebug() << "Details:" << QJsonDocument(response.error->details).toJson(QJsonDocument::Indented);
            }

            Q_EMIT analyticsError(
                        response.error->message,
                        response.error->status,
                        QJsonDocument(response.error->details).toJson()
                        );
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

// Similar update for getPurchaseAnalytics
QFuture<void> DashboardAnalyticsApi::getPurchaseAnalytics(const QString &timeframe,
                                                          const QDate &startDate,
                                                          const QDate &endDate)
{
    // if (m_testMode) {
    //     provideFakeData();
    //     return QtConcurrent::run([](){});
    // }

    setLoading(true);

    QString path = QStringLiteral("/api/v1/dashboard/purchase-analytics");
    QStringList queryParts;

    queryParts << QStringLiteral("timeframe=%1").arg(timeframe.isEmpty() ?  QStringLiteral("daily") : timeframe);

    if (startDate.isValid())
        queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(QStringLiteral("yyyy-MM-dd")));
    if (endDate.isValid())
        queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(QStringLiteral("yyyy-MM-dd")));

    if (!queryParts.isEmpty()) {
        path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PurchaseAnalytics analytics = purchaseAnalyticsFromJson(*response.data);
            qDebug()<<"getPurchaseAnalytics data : "<<*response.data;

            Q_EMIT purchaseAnalyticsReceived(analytics);
        } else {
            qDebug() << "Purchase Analytics Error:";
            qDebug() << "Message:" << response.error->message;
            if (!response.error->details.isEmpty()) {
                qDebug() << "Details:" << QJsonDocument(response.error->details).toJson(QJsonDocument::Indented);
            }

            Q_EMIT analyticsError(
                        response.error->message,
                        response.error->status,
                        QJsonDocument(response.error->details).toJson()
                        );
        }
        setLoading(false);
    });

    return future.then([=]() {});
}
QFuture<void> DashboardAnalyticsApi::getInventoryAnalytics(const QString &timeframe,
                                                           const QDate &startDate,
                                                           const QDate &endDate)
{
    setLoading(true);

    QString path =  QStringLiteral("/api/v1/dashboard/inventory-analytics");
    QStringList queryParts;

    // Always add timeframe
    queryParts << QStringLiteral("timeframe=%1").arg(timeframe.isEmpty() ? QStringLiteral("daily") : timeframe);

    // For "daily" timeframe, set both start and end date to today if not provided
    if (timeframe ==  QStringLiteral("daily") && (!startDate.isValid() || !endDate.isValid())) {
        QDate today = QDate::currentDate();
        queryParts << QStringLiteral("start_date=%1").arg(today.toString(QStringLiteral("yyyy-MM-dd")));
        queryParts << QStringLiteral("end_date=%1").arg(today.toString(QStringLiteral("yyyy-MM-dd")));
    } else {
        // Use provided dates
        if (startDate.isValid())
            queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(QStringLiteral("yyyy-MM-dd")));
        if (endDate.isValid())
            queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(QStringLiteral("yyyy-MM-dd")));
    }

    // Append query parameters to path
    if (!queryParts.isEmpty()) {
        path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "getInventoryAnalytics data : " << *response.data;
            InventoryAnalytics analytics = inventoryAnalyticsFromJson(*response.data);
            Q_EMIT inventoryAnalyticsReceived(analytics);
        } else {
            Q_EMIT analyticsError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> DashboardAnalyticsApi::getCustomerAnalytics(const QString &timeframe,
                                                          const QDate &startDate,
                                                          const QDate &endDate)
{
    setLoading(true);

    QString path = QStringLiteral("/api/v1/dashboard/customer-analytics");
    QStringList queryParts;

    // Always add timeframe
    queryParts << QStringLiteral("timeframe=%1").arg(timeframe.isEmpty() ? QStringLiteral("daily") : timeframe);

    // For "daily" timeframe, set both start and end date to today if not provided
    if (timeframe == QStringLiteral("daily") && (!startDate.isValid() || !endDate.isValid())) {
        QDate today = QDate::currentDate();
        queryParts << QStringLiteral("start_date=%1").arg(today.toString(QStringLiteral("yyyy-MM-dd")));
        queryParts << QStringLiteral("end_date=%1").arg(today.toString(QStringLiteral("yyyy-MM-dd")));
    } else {
        // Use provided dates
        if (startDate.isValid())
            queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(QStringLiteral("yyyy-MM-dd")));
        if (endDate.isValid())
            queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(QStringLiteral("yyyy-MM-dd")));
    }

    // Append query parameters to path
    if (!queryParts.isEmpty()) {
       path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }


    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "getCustomerAnalytics data : " << *response.data;
            Q_EMIT customerAnalyticsReceived(response.data->toVariantMap());
        } else {
            Q_EMIT analyticsError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> DashboardAnalyticsApi::getOverallDashboard(const QString &timeframe,
                                                         const QDate &startDate,
                                                         const QDate &endDate)
{
    setLoading(true);

    QString path =  QStringLiteral("/api/v1/dashboard/overall");
    QStringList queryParts;

    // Always add timeframe
    queryParts << QStringLiteral("timeframe=%1").arg(timeframe.isEmpty() ? QStringLiteral("daily"): timeframe);

    // For "daily" timeframe, set both start and end date to today if not provided
    if (timeframe == QStringLiteral("daily") && (!startDate.isValid() || !endDate.isValid())) {
        QDate today = QDate::currentDate();
        queryParts << QStringLiteral("start_date=%1").arg(today.toString(QStringLiteral("yyyy-MM-dd")));
        queryParts << QStringLiteral("end_date=%1").arg(today.toString(QStringLiteral("yyyy-MM-dd")));
    } else {
        // Use provided dates
        if (startDate.isValid())
            queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(QStringLiteral("yyyy-MM-dd")));
        if (endDate.isValid())
            queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(QStringLiteral("yyyy-MM-dd")));
    }

    // Append query parameters to path
    if (!queryParts.isEmpty()) {
       path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "getOverallDashboard data : " << *response.data;
            DashboardOverview overview = dashboardOverviewFromJson(*response.data);
            Q_EMIT overallDashboardReceived(overview);
        } else {
            Q_EMIT analyticsError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}



QString DashboardAnalyticsApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void DashboardAnalyticsApi::saveToken(const QString &token) {
    m_token = token;
}

SaleAnalytics DashboardAnalyticsApi::salesAnalyticsFromJson(const QJsonObject &json) const
{
    SaleAnalytics analytics;
    const QJsonObject &data = json["data"_L1].toObject();
    const QJsonObject &summary = data["summary"_L1].toObject();
    const QJsonObject &allTime = data["all_time"_L1].toObject();

    // Period stats
    analytics.totalSales = summary["total_sales"_L1].toInt(0);
    analytics.totalRevenue = summary["total_revenue"_L1].toString().toDouble();
    analytics.averageSale = summary["average_sale"_L1].toString().toDouble();
    analytics.totalOrders = summary["total_orders"_L1].toInt(0);

    // All-time stats
    analytics.allTimeSales = allTime["total_sales"_L1].toInt(0);
    analytics.allTimeRevenue = allTime["total_revenue"_L1].toString().toDouble();
    analytics.allTimeAverageSale = allTime["average_sale"_L1].toString().toDouble();
    analytics.allTimeOrders = allTime["total_orders"_L1].toInt(0);

    // History data
    const QJsonArray &historyArray = data["history"_L1].toArray();
    QVariantList history;
    for (const QJsonValue &value : historyArray) {
        history.append(value.toString().toDouble());
    }
    analytics.history = history;

    // Top products
    const QJsonArray &topProductsArray = data["top_products"_L1].toArray();
    for (const QJsonValue &value : topProductsArray) {
        analytics.topProducts.append(value.toObject().toVariantMap());
    }

    // Period info
    analytics.periodInfo = data["period_info"_L1].toObject().toVariantMap();

    return analytics;
}

PurchaseAnalytics DashboardAnalyticsApi::purchaseAnalyticsFromJson(const QJsonObject &json) const
{
    PurchaseAnalytics analytics;
    const QJsonObject &data = json["data"_L1].toObject();
    const QJsonObject &summary = data["summary"_L1].toObject();
    const QJsonObject &allTime = data["all_time"_L1].toObject();

    // Period stats
    analytics.totalPurchases = summary["total_purchases"_L1].toInt(0);
    analytics.totalCost = summary["total_cost"_L1].toString().toDouble();
    analytics.averagePurchase = summary["average_purchase"_L1].toString().toDouble();

    // All-time stats
    analytics.allTimePurchases = allTime["total_purchases"_L1].toInt(0);
    analytics.allTimeCost = allTime["total_cost"_L1].toString().toDouble();
    analytics.allTimeAveragePurchase = allTime["average_purchase"_L1].toString().toDouble();

    // History data
    const QJsonArray &historyArray = data["history"_L1].toArray();
    QVariantList history;
    for (const QJsonValue &value : historyArray) {
        history.append(value.toString().toDouble());
    }
    analytics.history = history;

    // Top suppliers
    const QJsonArray &topSuppliersArray = data["top_suppliers"_L1].toArray();
    for (const QJsonValue &value : topSuppliersArray) {
        analytics.topSuppliers.append(value.toObject().toVariantMap());
    }

    // Period info
    analytics.periodInfo = data["period_info"_L1].toObject().toVariantMap();

    return analytics;
}

InventoryAnalytics DashboardAnalyticsApi::inventoryAnalyticsFromJson(const QJsonObject &json) const
{
    InventoryAnalytics analytics;
    const QJsonObject &data = json["data"_L1].toObject();
    const QJsonObject &current = data["current"_L1].toObject();

    // Current stats
    analytics.totalProducts = current["total_products"_L1].toInt();
    analytics.totalStock = current["total_stock"_L1].toInt();
    analytics.averageStock = current["average_stock"_L1].toString().toDouble();

    // Low stock alerts
    const QJsonArray &lowStockArray = data["low_stock_alerts"_L1].toArray();
    for (const QJsonValue &value : lowStockArray) {
        analytics.lowStockAlerts.append(value.toObject().toVariantMap());
    }

    // Stock movements
    const QJsonArray &movementsArray = data["movements"_L1].toArray();
    for (const QJsonValue &value : movementsArray) {
        analytics.movements.append(value.toObject().toVariantMap());
    }

    // Period info
    analytics.periodInfo = data["period_info"_L1].toObject().toVariantMap();

    return analytics;
}

DashboardOverview DashboardAnalyticsApi::dashboardOverviewFromJson(const QJsonObject &json) const
{
    DashboardOverview overview;
    const QJsonObject &data = json["data"_L1].toObject();
    const QJsonObject &periodStats = data["period_stats"_L1].toObject();
    const QJsonObject &allTime = data["all_time"_L1].toObject();
    const QJsonObject &currentStatus = data["current_status"_L1].toObject();

    // Period stats
    overview.periodSales = periodStats["sales"_L1].toString().toDouble();
    overview.periodPurchases = periodStats["purchases"_L1].toString().toDouble();
    overview.periodOrders = periodStats["orders"_L1].toInt();

    // All-time stats
    overview.allTimeSales = allTime["total_sales"_L1].toString().toDouble();
    overview.allTimePurchases = allTime["total_purchases"_L1].toString().toDouble();
    overview.allTimeOrders = allTime["total_orders"_L1].toInt();

    // Current status
    overview.lowStockCount = currentStatus["low_stock_alerts"_L1].toInt();
    overview.cashBalance = currentStatus["cash_balance"_L1].toString().toDouble();

    // Period info
    overview.periodInfo = data["period_info"_L1].toObject().toVariantMap();

    return overview;
}

} // namespace NetworkApi
