// saleapi.cpp
#include "saleapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {

SaleApi::SaleApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

// Helper Methods
Sale SaleApi::saleFromJson(const QJsonObject &json) const
{
    Sale sale;
    sale.id = json["id"].toInt();
    sale.reference_number = json["reference_number"].toString();
    sale.sale_date = QDateTime::fromString(json["sale_date"].toString(), Qt::ISODate);
    sale.client_id = json["client_id"].toInt();
    sale.status = json["status"].toString();
    sale.payment_status = json["payment_status"].toString();
    sale.total_amount = json["total_amount"].toDouble();
    sale.paid_amount = json["paid_amount"].toDouble();
    sale.remaining_amount = json["remaining_amount"].toDouble();
    sale.notes = json["notes"].toString();

    // Parse client if available
    if (json.contains("client") && !json["client"].isNull()) {
        sale.client = json["client"].toObject().toVariantMap();
    }

    // Parse items
    if (json.contains("items")) {
        const QJsonArray itemsArray = json["items"].toArray();
        for (const QJsonValue &value : itemsArray) {
            sale.items.append(saleItemFromJson(value.toObject()));
        }
    }

    return sale;
}

SaleItem SaleApi::saleItemFromJson(const QJsonObject &json) const
{
    SaleItem item;
    item.id = json["id"].toInt();
    item.product_id = json["product_id"].toInt();
    item.product_name = json["product_name"].toString();
    item.quantity = json["quantity"].toInt();
    item.unit_price = json["unit_price"].toDouble();
    item.total_price = json["total_price"].toDouble();
    item.notes = json["notes"].toString();

    if (json.contains("product") && !json["product"].isNull()) {
        item.product = json["product"].toObject().toVariantMap();
    }

    return item;
}

QJsonObject SaleApi::saleToJson(const Sale &sale) const
{
    QJsonObject json;
    json["client_id"] = sale.client_id;
    json["sale_date"] = sale.sale_date.toString(Qt::ISODate);
    json["notes"] = sale.notes;
    json["status"] = sale.status;

    // Convert items to JSON array
    QJsonArray itemsArray;
    for (const SaleItem &item : sale.items) {
        itemsArray.append(saleItemToJson(item));
    }
    json["items"] = itemsArray;

    return json;
}

QJsonObject SaleApi::saleItemToJson(const SaleItem &item) const
{
    QJsonObject json;
    json["product_id"] = item.product_id;
    json["quantity"] = item.quantity;
    json["unit_price"] = item.unit_price;
    json["notes"] = item.notes;
    return json;
}

QJsonObject SaleApi::paymentToJson(const Payment &payment) const
{
    QJsonObject json;
    json["cash_source_id"] = payment.cash_source_id;
    json["amount"] = payment.amount;
    json["payment_method"] = payment.payment_method;
    json["reference_number"] = payment.reference_number;
    json["notes"] = payment.notes;
    return json;
}

PaginatedSales SaleApi::paginatedSalesFromJson(const QJsonObject &json) const
{
    PaginatedSales result;
    const QJsonObject &meta = json["sales"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(saleFromJson(value.toObject()));
    }

    return result;
}

QVariantMap SaleApi::saleToVariantMap(const Sale &sale) const
{
    QVariantMap map;
    map["id"] = sale.id;
    map["reference_number"] = sale.reference_number;
    map["sale_date"] = sale.sale_date;
    map["client_id"] = sale.client_id;
    map["client"] = sale.client;
    map["status"] = sale.status;
    map["payment_status"] = sale.payment_status;
    map["total_amount"] = sale.total_amount;
    map["paid_amount"] = sale.paid_amount;
    map["remaining_amount"] = sale.remaining_amount;
    map["notes"] = sale.notes;

    QVariantList itemsList;
    for (const SaleItem &item : sale.items) {
        itemsList.append(saleItemToVariantMap(item));
    }
    map["items"] = itemsList;

    return map;
}

QVariantMap SaleApi::saleItemToVariantMap(const SaleItem &item) const
{
    QVariantMap map;
    map["id"] = item.id;
    map["product_id"] = item.product_id;
    map["product_name"] = item.product_name;
    map["quantity"] = item.quantity;
    map["unit_price"] = item.unit_price;
    map["total_price"] = item.total_price;
    map["notes"] = item.notes;
    map["product"] = item.product;
    return map;
}

// API Methods
QFuture<void> SaleApi::getSales(const QString &search, const QString &sortBy,
                               const QString &sortDirection, int page,
                               const QString &status, const QString &paymentStatus)
{
    setLoading(true);
    QString path = "/api/sales";

    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QString("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QString("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QString("sort_direction=%1").arg(sortDirection);
    if (page > 0)
        queryParts << QString("page=%1").arg(page);
    if (!status.isEmpty())
        queryParts << QString("status=%1").arg(status);
    if (!paymentStatus.isEmpty())
        queryParts << QString("payment_status=%1").arg(paymentStatus);

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedSales paginatedSales = paginatedSalesFromJson(*response.data);
            emit salesReceived(paginatedSales);
        } else {
            emit errorSalesReceived(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::getSale(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/sales/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale sale = saleFromJson(response.data->value("sale").toObject());
            emit saleReceived(saleToVariantMap(sale));
        } else {
            emit errorSaleReceived(response.error->message, response.error->status,
                                 QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::createSale(const Sale &sale)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/sales");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = saleToJson(sale);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale createdSale = saleFromJson(response.data->value("sale").toObject());
            emit saleCreated(createdSale);
        } else {
            emit errorSaleCreated(response.error->message, response.error->status,
                                QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::updateSale(int id, const Sale &sale)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/sales/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = saleToJson(sale);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale updatedSale = saleFromJson(response.data->value("sale").toObject());
            emit saleUpdated(updatedSale);
        } else {
            emit errorSaleUpdated(response.error->message, response.error->status,
                                QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::deleteSale(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/sales/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit saleDeleted(id);
        } else {
            emit errorSaleDeleted(response.error->message, response.error->status,
                                QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::addPayment(int id, const Payment &payment)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/sales/%1/add-payment").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = paymentToJson(payment);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit paymentAdded(response.data->value("payment").toObject().toVariantMap());
        } else {
            emit errorPaymentAdded(response.error->message, response.error->status,
                                 QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::generateInvoice(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/sales/%1/generate-invoice").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit invoiceGenerated(response.data->value("invoice").toObject().toVariantMap());
        } else {
            emit errorInvoiceGenerated(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::getSummary(const QString &period)
{
    setLoading(true);
    QString path = "/api/sales/summary";
    if (!period.isEmpty()) {
        path += QString("?period=%1").arg(period);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit summaryReceived(response.data->value("summary").toObject().toVariantMap());
        } else {
            emit errorSummaryReceived(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QString SaleApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void SaleApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
