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
    sale.team_id = json["team_id"].toInt();
    sale.client_id = json["client_id"].toInt();
    sale.cash_source_id = json["cash_source_id"].toInt();
    sale.reference_number = json["reference_number"].toString();
    sale.total_amount = json["total_amount"].toString().toDouble();
    sale.paid_amount = json["paid_amount"].toString().toDouble();
    sale.tax_amount = json["tax_amount"].toString().toDouble();
    sale.discount_amount = json["discount_amount"].toString().toDouble();
    sale.payment_status = json["payment_status"].toString();
    sale.status = json["status"].toString();
    sale.sale_date = QDateTime::fromString(json["sale_date"].toString(), Qt::ISODate);

    if (json.contains("due_date") && !json["due_date"].isNull()) {
        sale.due_date = QDateTime::fromString(json["due_date"].toString(), Qt::ISODate);
    }

    sale.notes = json["notes"].toString();

    if (json.contains("client") && !json["client"].isNull()) {
        sale.client = json["client"].toObject().toVariantMap();
    }

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
    item.unit_price = json["unit_price"].toString().toDouble();
    item.total_price = json["total_price"].toString().toDouble();
    item.tax_rate = json["tax_rate"].toString().toDouble();
    item.tax_amount = json["tax_amount"].toString().toDouble();
    item.discount_amount = json["discount_amount"].toString().toDouble();
    item.notes = json["notes"].toString();

    // Add package-related fields
    item.is_package = json["is_package"].toBool();
    item.package_id = json["package_id"].toInt();
    item.total_pieces = json["total_pieces"].toInt();

    if (json.contains("product") && !json["product"].isNull()) {
        item.product = json["product"].toObject().toVariantMap();
    }

    if (json.contains("package") && !json["package"].isNull()) {
        item.package = json["package"].toObject().toVariantMap();
    }

    return item;
}
QJsonObject SaleApi::saleToJson(const Sale &sale) const
{
    QJsonObject json;

    // Required fields
    json["cash_source_id"] = sale.cash_source_id;
    json["sale_date"] = sale.sale_date.toString("yyyy-MM-dd");
    json["status"] = sale.status;
    json["payment_status"] = sale.payment_status;

    // Amounts
    json["total_amount"] = sale.total_amount;
    json["tax_amount"] = sale.tax_amount;
    json["discount_amount"] = sale.discount_amount;
    // Auto-payment flag and amount
     if (sale.auto_payment) {
         json["auto_payment"] = true;
         json["payment_amount"] = sale.payment_amount;
     }
    // Optional fields
    if (sale.client_id > 0) {
        json["client_id"] = sale.client_id;
        if (sale.due_date.isValid()) {
            json["due_date"] = sale.due_date.toString("yyyy-MM-dd");
        }
    }

    if (!sale.notes.isEmpty()) {
        json["notes"] = sale.notes;
    }

    // Items array using existing saleItemToJson method
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
    json["tax_rate"] = item.tax_rate;
    json["discount_amount"] = item.discount_amount;
    json["is_package"] = item.is_package;
    json["total_pieces"] = item.total_pieces;

    if (item.is_package) {
        json["package_id"] = item.package_id;
    }

    if (!item.notes.isEmpty()) {
        json["notes"] = item.notes;
    }

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
    map["team_id"] = sale.team_id;
    map["client_id"] = sale.client_id;
    map["cash_source_id"] = sale.cash_source_id;
    map["reference_number"] = sale.reference_number;
    map["total_amount"] = sale.total_amount;
    map["paid_amount"] = sale.paid_amount;
    map["tax_amount"] = sale.tax_amount;
    map["discount_amount"] = sale.discount_amount;
    map["payment_status"] = sale.payment_status;
    map["status"] = sale.status;
    map["sale_date"] = sale.sale_date;
    map["due_date"] = sale.due_date;
    map["notes"] = sale.notes;
    map["client"] = sale.client;

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
    map["tax_rate"] = item.tax_rate;
    map["tax_amount"] = item.tax_amount;
    map["discount_amount"] = item.discount_amount;
    map["notes"] = item.notes;
    map["product"] = item.product;
    map["is_package"] = item.is_package;
    map["package_id"] = item.package_id;
    map["total_pieces"] = item.total_pieces;
    map["package"] = item.package;
    return map;
}

// API Methods
QFuture<void> SaleApi::getSales(const QString &search, const QString &sortBy,
                               const QString &sortDirection, int page,
                               const QString &status, const QString &paymentStatus)
{
    setLoading(true);
    QString path = "/api/v1/sales";

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
    QNetworkRequest request = createRequest(QString("/api/v1/sales/%1").arg(id));
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
    qDebug() << "================== Sale:";

    QNetworkRequest request = createRequest("/api/v1/sales");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = saleToJson(sale);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale createdSale = saleFromJson(response.data->value("sale").toObject());
             qDebug() << "================== Done:";
            emit saleCreated(createdSale);
        } else {
            qDebug() << "Error Sale details:" << response.error->details;

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
    QNetworkRequest request = createRequest(QString("/api/v1/sales/%1").arg(id));
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
    QNetworkRequest request = createRequest(QString("/api/v1/sales/%1").arg(id));
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
    QNetworkRequest request = createRequest(QString("/api/v1/sales/%1/add-payment").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"] = payment.amount;
    jsonData["reference_number"] = payment.reference_number;
    jsonData["notes"] = payment.notes;

    if (payment.cash_source_id > 0) {
        jsonData["cash_source_id"] = payment.cash_source_id;
    }

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit paymentAdded(response.data->value("sale").toObject().toVariantMap());
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
    QNetworkRequest request = createRequest(QString("/api/v1/sales/%1/generate-invoice").arg(id));
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
    QString path = "/api/v1/sales/summary";
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
