#include "dashboardanalyticsapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>

namespace NetworkApi {

DashboardAnalyticsApi::DashboardAnalyticsApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}
void DashboardAnalyticsApi::provideFakeData()
{
    // Fake Sales Analytics
    SaleAnalytics salesData;
    salesData.totalSales = 1000;
    salesData.totalRevenue = 50000.0;
    salesData.averageSale = 50.0;
    salesData.totalOrders = 100;

    // Create fake history data
    QVariantList salesHistory;
    for (int i = 0; i < 50; i++) {
        salesHistory.append(QRandomGenerator::global()->bounded(1000, 5000));
    }
    salesData.history = salesHistory;

    // Create fake top products
    QList<QVariantMap> topProducts;
    QStringList productNames = {
        "Laptop Pro X1", "Smartphone Y20", "Tablet Z10",
        "Wireless Earbuds", "Smart Watch V2"
    };

    for (int i = 0; i < productNames.size(); i++) {
        QVariantMap product;
        product["name"] = productNames[i];
        product["total_quantity"] = QRandomGenerator::global()->bounded(100, 1000);
        product["total_revenue"] = QRandomGenerator::global()->bounded(1000, 10000);
        product["icon"] = "package"; // Icon name for the UI
        product["description"] = QString("Best selling product #%1").arg(i + 1);
        topProducts.append(product);
    }
    salesData.topProducts = topProducts;

    // Emit fake sales data
    emit salesAnalyticsReceived(salesData);

    // Fake Purchase Analytics
    PurchaseAnalytics purchaseData;
    purchaseData.totalPurchases = 800;
    purchaseData.totalCost = 40000.0;
    purchaseData.averagePurchase = 50.0;

    // Create fake purchase history
    QVariantList purchaseHistory;
    for (int i = 0; i < 50; i++) {
        purchaseHistory.append(QRandomGenerator::global()->bounded(800, 4000));
    }
    purchaseData.history = purchaseHistory;

    // Create fake top suppliers
    QList<QVariantMap> topSuppliers;
    QStringList supplierNames = {
        "Tech Supplies Co.", "Global Electronics", "Digital Systems Ltd",
        "Smart Components", "Innovation Tech"
    };

    for (int i = 0; i < supplierNames.size(); i++) {
        QVariantMap supplier;
        supplier["name"] = supplierNames[i];
        supplier["total_orders"] = QRandomGenerator::global()->bounded(50, 200);
        supplier["total_amount"] = QRandomGenerator::global()->bounded(5000, 20000);
        supplier["icon"] = "truck"; // Icon name for the UI
        supplier["description"] = QString("Top supplier #%1").arg(i + 1);
        topSuppliers.append(supplier);
    }
    purchaseData.topSuppliers = topSuppliers;

    // Emit fake purchase data
    emit purchaseAnalyticsReceived(purchaseData);

    // Fake Customer Analytics
    QVariantList topCustomers;
    QStringList customerNames = {
        "John Smith", "Alice Johnson", "Bob Williams",
        "Emma Davis", "Michael Brown"
    };

    for (int i = 0; i < customerNames.size(); i++) {
        QVariantMap customer;
        customer["name"] = customerNames[i];
        customer["total_purchases"] = QRandomGenerator::global()->bounded(10, 50);
        customer["total_spent"] = QRandomGenerator::global()->bounded(1000, 5000);
        customer["icon"] = "user"; // Icon name for the UI
        customer["description"] = QString("Loyal customer since 2023");
        customer["last_purchase"] = QDateTime::currentDateTime()
                .addDays(-QRandomGenerator::global()->bounded(1, 30))
                .toString(Qt::ISODate);
        topCustomers.append(customer);
    }

    // Emit fake customer data
    emit customerAnalyticsReceived(QVariantMap{{"top_customers", topCustomers}});

    // // Fake Dashboard Overview
    DashboardOverview overview;
    // overview.dailySales = 5000.0;
    // overview.monthlySales = 150000.0;
    // overview.dailyPurchases = 4000.0;
    // overview.monthlyPurchases = 120000.0;
    // overview.lowStockCount = 15;
    // overview.cashBalance = 30000.0;
    // overview.totalOrders = 250;

    // Create fake revenue data for trends
    QVariantList revenueData;
    double baseRevenue = 10000.0;
    for (int i = 0; i < 12; i++) {
        double monthlyRevenue = baseRevenue + QRandomGenerator::global()->bounded(-2000, 2000);
        revenueData.append(monthlyRevenue);
    }


    // Emit fake overview data
    emit overallDashboardReceived(overview);

    // Fake Inventory Analytics
    InventoryAnalytics inventory;
    inventory.totalProducts = 500;
    inventory.totalStock = 25000;
    inventory.averageStock = 50;

    QList<QVariantMap> lowStockAlerts;
    QStringList lowStockProducts = {
        "Wireless Mouse", "USB Cable", "Power Bank",
        "Screen Protector", "Phone Case"
    };

    for (int i = 0; i < lowStockProducts.size(); i++) {
        QVariantMap alert;
        alert["name"] = lowStockProducts[i];
        alert["quantity"] = QRandomGenerator::global()->bounded(1, 10);
        alert["min_quantity"] = 15;
        alert["icon"] = "package-down"; // Icon for low stock
        alert["description"] = QString("Stock level critical");
        lowStockAlerts.append(alert);
    }
    inventory.lowStockAlerts = lowStockAlerts;

    // Emit fake inventory data
    emit inventoryAnalyticsReceived(inventory);
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

        QString path = "/api/v1/dashboard/sales-analytics";
        QStringList queryParts;

        // Always add timeframe
        queryParts << QString("timeframe=%1").arg(timeframe.isEmpty() ? "daily" : timeframe);

        // For "daily" timeframe, set both start and end date to today if not provided
        if (timeframe == "daily" && (!startDate.isValid() || !endDate.isValid())) {
            QDate today = QDate::currentDate();
            queryParts << QString("start_date=%1").arg(today.toString("yyyy-MM-dd"));
            queryParts << QString("end_date=%1").arg(today.toString("yyyy-MM-dd"));
        } else {
            // Use provided dates
            if (startDate.isValid())
                queryParts << QString("start_date=%1").arg(startDate.toString("yyyy-MM-dd"));
            if (endDate.isValid())
                queryParts << QString("end_date=%1").arg(endDate.toString("yyyy-MM-dd"));
        }

        // Append query parameters to path
        if (!queryParts.isEmpty()) {
            path += "?" + queryParts.join("&");
        }

        QNetworkRequest request = createRequest(path);
        request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

        qDebug() << "Making analytics request to:" << request.url().toString();

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            SaleAnalytics analytics = salesAnalyticsFromJson(*response.data);
            qDebug()<<"getSalesAnalytics data : "<<*response.data;
            emit salesAnalyticsReceived(analytics);
        } else {
            qDebug() << "Sales Analytics Error:";
            qDebug() << "Message:" << response.error->message;
            if (!response.error->details.isEmpty()) {
                qDebug() << "Details:" << QJsonDocument(response.error->details).toJson(QJsonDocument::Indented);
            }

            emit analyticsError(
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

    QString path = "/api/v1/dashboard/purchase-analytics";
    QStringList queryParts;

    queryParts << QString("timeframe=%1").arg(timeframe.isEmpty() ? "daily" : timeframe);

    if (startDate.isValid())
        queryParts << QString("start_date=%1").arg(startDate.toString("yyyy-MM-dd"));
    if (endDate.isValid())
        queryParts << QString("end_date=%1").arg(endDate.toString("yyyy-MM-dd"));

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PurchaseAnalytics analytics = purchaseAnalyticsFromJson(*response.data);
            qDebug()<<"getPurchaseAnalytics data : "<<*response.data;

            emit purchaseAnalyticsReceived(analytics);
        } else {
            qDebug() << "Purchase Analytics Error:";
            qDebug() << "Message:" << response.error->message;
            if (!response.error->details.isEmpty()) {
                qDebug() << "Details:" << QJsonDocument(response.error->details).toJson(QJsonDocument::Indented);
            }

            emit analyticsError(
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

    QString path = "/api/v1/dashboard/inventory-analytics";
    QStringList queryParts;

    // Always add timeframe
    queryParts << QString("timeframe=%1").arg(timeframe.isEmpty() ? "daily" : timeframe);

    // For "daily" timeframe, set both start and end date to today if not provided
    if (timeframe == "daily" && (!startDate.isValid() || !endDate.isValid())) {
        QDate today = QDate::currentDate();
        queryParts << QString("start_date=%1").arg(today.toString("yyyy-MM-dd"));
        queryParts << QString("end_date=%1").arg(today.toString("yyyy-MM-dd"));
    } else {
        // Use provided dates
        if (startDate.isValid())
            queryParts << QString("start_date=%1").arg(startDate.toString("yyyy-MM-dd"));
        if (endDate.isValid())
            queryParts << QString("end_date=%1").arg(endDate.toString("yyyy-MM-dd"));
    }

    // Append query parameters to path
    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "getInventoryAnalytics data : " << *response.data;
            InventoryAnalytics analytics = inventoryAnalyticsFromJson(*response.data);
            emit inventoryAnalyticsReceived(analytics);
        } else {
            emit analyticsError(response.error->message, response.error->status,
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

    QString path = "/api/v1/dashboard/customer-analytics";
    QStringList queryParts;

    // Always add timeframe
    queryParts << QString("timeframe=%1").arg(timeframe.isEmpty() ? "daily" : timeframe);

    // For "daily" timeframe, set both start and end date to today if not provided
    if (timeframe == "daily" && (!startDate.isValid() || !endDate.isValid())) {
        QDate today = QDate::currentDate();
        queryParts << QString("start_date=%1").arg(today.toString("yyyy-MM-dd"));
        queryParts << QString("end_date=%1").arg(today.toString("yyyy-MM-dd"));
    } else {
        // Use provided dates
        if (startDate.isValid())
            queryParts << QString("start_date=%1").arg(startDate.toString("yyyy-MM-dd"));
        if (endDate.isValid())
            queryParts << QString("end_date=%1").arg(endDate.toString("yyyy-MM-dd"));
    }

    // Append query parameters to path
    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }


    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "getCustomerAnalytics data : " << *response.data;
            emit customerAnalyticsReceived(response.data->toVariantMap());
        } else {
            emit analyticsError(response.error->message, response.error->status,
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

    QString path = "/api/v1/dashboard/overall";
    QStringList queryParts;

    // Always add timeframe
    queryParts << QString("timeframe=%1").arg(timeframe.isEmpty() ? "daily" : timeframe);

    // For "daily" timeframe, set both start and end date to today if not provided
    if (timeframe == "daily" && (!startDate.isValid() || !endDate.isValid())) {
        QDate today = QDate::currentDate();
        queryParts << QString("start_date=%1").arg(today.toString("yyyy-MM-dd"));
        queryParts << QString("end_date=%1").arg(today.toString("yyyy-MM-dd"));
    } else {
        // Use provided dates
        if (startDate.isValid())
            queryParts << QString("start_date=%1").arg(startDate.toString("yyyy-MM-dd"));
        if (endDate.isValid())
            queryParts << QString("end_date=%1").arg(endDate.toString("yyyy-MM-dd"));
    }

    // Append query parameters to path
    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "getOverallDashboard data : " << *response.data;
            DashboardOverview overview = dashboardOverviewFromJson(*response.data);
            emit overallDashboardReceived(overview);
        } else {
            emit analyticsError(response.error->message, response.error->status,
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
    const QJsonObject &data = json["data"].toObject();
    const QJsonObject &summary = data["summary"].toObject();
    const QJsonObject &allTime = data["all_time"].toObject();

    // Period stats
    analytics.totalSales = summary["total_sales"].toInt(0);
    analytics.totalRevenue = summary["total_revenue"].toString().toDouble();
    analytics.averageSale = summary["average_sale"].toString().toDouble();
    analytics.totalOrders = summary["total_orders"].toInt(0);

    // All-time stats
    analytics.allTimeSales = allTime["total_sales"].toInt(0);
    analytics.allTimeRevenue = allTime["total_revenue"].toString().toDouble();
    analytics.allTimeAverageSale = allTime["average_sale"].toString().toDouble();
    analytics.allTimeOrders = allTime["total_orders"].toInt(0);

    // History data
    const QJsonArray &historyArray = data["history"].toArray();
    QVariantList history;
    for (const QJsonValue &value : historyArray) {
        history.append(value.toString().toDouble());
    }
    analytics.history = history;

    // Top products
    const QJsonArray &topProductsArray = data["top_products"].toArray();
    for (const QJsonValue &value : topProductsArray) {
        analytics.topProducts.append(value.toObject().toVariantMap());
    }

    // Period info
    analytics.periodInfo = data["period_info"].toObject().toVariantMap();

    return analytics;
}

PurchaseAnalytics DashboardAnalyticsApi::purchaseAnalyticsFromJson(const QJsonObject &json) const
{
    PurchaseAnalytics analytics;
    const QJsonObject &data = json["data"].toObject();
    const QJsonObject &summary = data["summary"].toObject();
    const QJsonObject &allTime = data["all_time"].toObject();

    // Period stats
    analytics.totalPurchases = summary["total_purchases"].toInt(0);
    analytics.totalCost = summary["total_cost"].toString().toDouble();
    analytics.averagePurchase = summary["average_purchase"].toString().toDouble();

    // All-time stats
    analytics.allTimePurchases = allTime["total_purchases"].toInt(0);
    analytics.allTimeCost = allTime["total_cost"].toString().toDouble();
    analytics.allTimeAveragePurchase = allTime["average_purchase"].toString().toDouble();

    // History data
    const QJsonArray &historyArray = data["history"].toArray();
    QVariantList history;
    for (const QJsonValue &value : historyArray) {
        history.append(value.toString().toDouble());
    }
    analytics.history = history;

    // Top suppliers
    const QJsonArray &topSuppliersArray = data["top_suppliers"].toArray();
    for (const QJsonValue &value : topSuppliersArray) {
        analytics.topSuppliers.append(value.toObject().toVariantMap());
    }

    // Period info
    analytics.periodInfo = data["period_info"].toObject().toVariantMap();

    return analytics;
}

InventoryAnalytics DashboardAnalyticsApi::inventoryAnalyticsFromJson(const QJsonObject &json) const
{
    InventoryAnalytics analytics;
    const QJsonObject &data = json["data"].toObject();
    const QJsonObject &current = data["current"].toObject();

    // Current stats
    analytics.totalProducts = current["total_products"].toInt();
    analytics.totalStock = current["total_stock"].toInt();
    analytics.averageStock = current["average_stock"].toString().toDouble();

    // Low stock alerts
    const QJsonArray &lowStockArray = data["low_stock_alerts"].toArray();
    for (const QJsonValue &value : lowStockArray) {
        analytics.lowStockAlerts.append(value.toObject().toVariantMap());
    }

    // Stock movements
    const QJsonArray &movementsArray = data["movements"].toArray();
    for (const QJsonValue &value : movementsArray) {
        analytics.movements.append(value.toObject().toVariantMap());
    }

    // Period info
    analytics.periodInfo = data["period_info"].toObject().toVariantMap();

    return analytics;
}

DashboardOverview DashboardAnalyticsApi::dashboardOverviewFromJson(const QJsonObject &json) const
{
    DashboardOverview overview;
    const QJsonObject &data = json["data"].toObject();
    const QJsonObject &periodStats = data["period_stats"].toObject();
    const QJsonObject &allTime = data["all_time"].toObject();
    const QJsonObject &currentStatus = data["current_status"].toObject();

    // Period stats
    overview.periodSales = periodStats["sales"].toString().toDouble();
    overview.periodPurchases = periodStats["purchases"].toString().toDouble();
    overview.periodOrders = periodStats["orders"].toInt();

    // All-time stats
    overview.allTimeSales = allTime["total_sales"].toString().toDouble();
    overview.allTimePurchases = allTime["total_purchases"].toString().toDouble();
    overview.allTimeOrders = allTime["total_orders"].toInt();

    // Current status
    overview.lowStockCount = currentStatus["low_stock_alerts"].toInt();
    overview.cashBalance = currentStatus["cash_balance"].toString().toDouble();

    // Period info
    overview.periodInfo = data["period_info"].toObject().toVariantMap();

    return overview;
}

} // namespace NetworkApi
