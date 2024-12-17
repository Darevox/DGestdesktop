// purchaseapi.cpp
#include "purchaseapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {

PurchaseApi::PurchaseApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

// Helper Methods
Purchase PurchaseApi::purchaseFromJson(const QJsonObject &json) const
{
    Purchase purchase;
    purchase.id = json["id"].toInt();
    purchase.reference_number = json["reference_number"].toString();
    purchase.purchase_date = QDateTime::fromString(json["purchase_date"].toString(), Qt::ISODate);
    purchase.supplier_id = json["supplier_id"].toInt();
    purchase.cash_source_id = json["cash_source_id"].toInt();
    purchase.status = json["status"].toString();
    purchase.payment_status = json["payment_status"].toString();
    purchase.total_amount = json["total_amount"].toString().toDouble();
    purchase.paid_amount = json["paid_amount"].toString().toDouble();
    purchase.notes = json["notes"].toString();

    if (json.contains("supplier") && !json["supplier"].isNull()) {
        purchase.supplier = json["supplier"].toObject().toVariantMap();
    }

    if (json.contains("items")) {
        const QJsonArray itemsArray = json["items"].toArray();
        for (const QJsonValue &value : itemsArray) {
            purchase.items.append(purchaseItemFromJson(value.toObject()));
        }
    }

    return purchase;
}

PurchaseItem PurchaseApi::purchaseItemFromJson(const QJsonObject &json) const
{
    PurchaseItem item;
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

    // Package-related fields
    item.is_package = json["is_package"].toBool();
    item.package_id = json["package_id"].toInt(-1);  // Use -1 as default
    item.update_package_prices = json["update_package_prices"].toBool();
    item.package_purchase_price = json["package_purchase_price"].toString().toDouble();
    item.package_selling_price = json["package_selling_price"].toString().toDouble();
    item.update_prices = json["update_prices"].toBool();

    if (json.contains("product")) {
        item.product = json["product"].toObject().toVariantMap();
    }

    if (json.contains("package") && !json["package"].isNull()) {
        const QJsonObject packageObj = json["package"].toObject();
        item.package.id = packageObj["id"].toInt();
        item.package.name = packageObj["name"].toString();
        item.package.pieces_per_package = packageObj["pieces_per_package"].toInt();
        item.package.purchase_price = packageObj["purchase_price"].toString().toDouble();
        item.package.selling_price = packageObj["selling_price"].toString().toDouble();
        item.package.barcode = packageObj["barcode"].toString();
    }

    return item;
}


QJsonObject PurchaseApi::purchaseToJson(const Purchase &purchase) const
{
    QJsonObject json;

    // Required fields
    json["supplier_id"] = purchase.supplier_id;
    json["cash_source_id"] = purchase.cash_source_id;
    json["purchase_date"] = purchase.purchase_date.toString(Qt::ISODate);

    // Optional fields
    if (purchase.due_date.isValid()) {
        json["due_date"] = purchase.due_date.toString(Qt::ISODate);
    }

    if (!purchase.notes.isEmpty()) {
        json["notes"] = purchase.notes;
    }

    // Items array
    QJsonArray itemsArray;
    for (const PurchaseItem &item : purchase.items) {
          QJsonObject itemJson = purchaseItemToJson(item);
          itemsArray.append(itemJson);
      }
    json["items"] = itemsArray;

    // Debug output
    qDebug() << "Purchase JSON:" << QJsonDocument(json).toJson();

    return json;
}


// In purchaseapi.cpp
QJsonObject PurchaseApi::purchaseItemToJson(const PurchaseItem &item) const
{
    QJsonObject json;
    json["product_id"] = item.product_id;
    json["quantity"] = item.quantity;
    json["unit_price"] = item.unit_price;
    json["selling_price"] = item.selling_price;
    json["tax_rate"] = item.tax_rate;
    json["discount_amount"] = item.discount_amount;

    // Add package-related fields
    json["is_package"] = item.is_package;
    json["package_id"] = item.package_id;

    if (item.is_package) {
        json["update_package_prices"] = item.update_package_prices;
        json["package_purchase_price"] = item.package_purchase_price;
        json["package_selling_price"] = item.package_selling_price;
        json["update_prices"] = false;  // Don't update product prices when it's a package
    } else {
        json["update_prices"] = item.update_prices;
        json["update_package_prices"] = false;
    }

    if (!item.notes.isEmpty()) {
        json["notes"] = item.notes;
    }

    // Add debug output
    qDebug() << "Purchase item JSON:" << json;

    return json;
}


QJsonObject PurchaseApi::paymentToJson(const PurchasePayment &payment) const
{
    QJsonObject json;
    json["cash_source_id"] = payment.cash_source_id;
    json["amount"] = payment.amount;
    json["payment_method"] = payment.payment_method;
    json["reference_number"] = payment.reference_number;
    json["notes"] = payment.notes;
    return json;
}

PaginatedPurchases PurchaseApi::paginatedPurchasesFromJson(const QJsonObject &json) const
{
    PaginatedPurchases result;
    const QJsonObject &meta = json["purchases"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(purchaseFromJson(value.toObject()));
    }

    return result;
}

QVariantMap PurchaseApi::purchaseToVariantMap(const Purchase &purchase) const
{
    QVariantMap map;
    map["id"] = purchase.id;
    map["reference_number"] = purchase.reference_number;
    map["purchase_date"] = purchase.purchase_date;
    map["supplier_id"] = purchase.supplier_id;
    map["cash_source_id"] = purchase.cash_source_id;
    map["supplier"] = purchase.supplier;
    map["status"] = purchase.status;
    map["payment_status"] = purchase.payment_status;
    map["total_amount"] = purchase.total_amount;
    map["paid_amount"] = purchase.paid_amount;
    map["notes"] = purchase.notes;

    QVariantList itemsList;
    for (const PurchaseItem &item : purchase.items) {
        itemsList.append(purchaseItemToVariantMap(item));
    }
    map["items"] = itemsList;

    return map;
}

QVariantMap PurchaseApi::purchaseItemToVariantMap(const PurchaseItem &item) const
{
    QVariantMap map;
    map["id"] = item.id;
    map["product_id"] = item.product_id;
    map["product_name"] = item.product_name;
    map["quantity"] = item.quantity;
    map["unit_price"] = item.unit_price;
    map["selling_price"] = item.selling_price;
    map["total_price"] = item.total_price;
    map["notes"] = item.notes;
    map["product"] = item.product;
    map["is_package"] = item.is_package;
    map["package_id"] = item.package_id;
    map["update_package_prices"] = item.update_package_prices;
    map["package_purchase_price"] = item.package_purchase_price;
    map["package_selling_price"] = item.package_selling_price;

    if (item.is_package) {
        QVariantMap packageMap;
        packageMap["id"] = item.package.id;
        packageMap["name"] = item.package.name;
        packageMap["pieces_per_package"] = item.package.pieces_per_package;
        packageMap["purchase_price"] = item.package.purchase_price;
        packageMap["selling_price"] = item.package.selling_price;
        packageMap["barcode"] = item.package.barcode;
        map["package"] = packageMap;
    }

    return map;
}

// API Methods Implementation
QFuture<void> PurchaseApi::getPurchases(const QString &search, const QString &sortBy,
                                        const QString &sortDirection, int page,
                                        const QString &status, const QString &paymentStatus)
{
    setLoading(true);
    QString path = "/api/v1/purchases";

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
            PaginatedPurchases paginatedPurchases = paginatedPurchasesFromJson(*response.data);
            emit purchasesReceived(paginatedPurchases);
        } else {
            emit errorPurchasesReceived(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}
// Continuing purchaseapi.cpp...

QFuture<void> PurchaseApi::getPurchase(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/purchases/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Purchase purchase = purchaseFromJson(response.data->value("purchase").toObject());
            emit purchaseReceived(purchaseToVariantMap(purchase));
        } else {
            emit errorPurchaseReceived(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::createPurchase(const Purchase &purchase)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/v1/purchases");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = purchaseToJson(purchase);
    QByteArray requestData = QJsonDocument(jsonData).toJson();

    qDebug() << "Creating purchase with data:" << requestData;

    auto future = makeRequest<QJsonObject>([=]() {
        QNetworkReply* reply = m_netManager->post(request, requestData);

        // Add response logging
        connect(reply, &QNetworkReply::finished, [reply]() {
            if (reply->error() != QNetworkReply::NoError) {
                qDebug() << "Network error:" << reply->errorString();
            }
            qDebug() << "Response status:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qDebug() << "Response headers:" << reply->rawHeaderPairs();
            qDebug() << "Response data:" << reply->readAll();
        });

        return reply;
    }).then([=](JsonResponse response) {
        if (response.success) {
            Purchase createdPurchase = purchaseFromJson(response.data->value("purchase").toObject());
            emit purchaseCreated(createdPurchase);
        } else {
            QString errorDetails;
            if (response.error && !response.error->details.isEmpty()) {
                errorDetails = QJsonDocument(response.error->details).toJson();
            } else {
                errorDetails = response.error ? response.error->message : "Unknown error";
            }

            qDebug() << "Purchase creation failed:"
                     << "\nMessage:" << (response.error ? response.error->message : "Unknown error")
                     << "\nDetails:" << errorDetails;

            emit errorPurchaseCreated(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::updatePurchase(int id, const Purchase &purchase)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/purchases/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = purchaseToJson(purchase);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Purchase updatedPurchase = purchaseFromJson(response.data->value("purchase").toObject());
            emit purchaseUpdated(updatedPurchase);
        } else {
            emit errorPurchaseUpdated(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::deletePurchase(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/purchases/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit purchaseDeleted(id);
        } else {
            emit errorPurchaseDeleted(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::addPayment(int id, const PurchasePayment &payment)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/purchases/%1/add-payment").arg(id));
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

QFuture<void> PurchaseApi::generateInvoice(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/purchases/%1/generate-invoice").arg(id));
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

QFuture<void> PurchaseApi::getSummary(const QString &period)
{
    setLoading(true);
    QString path = "/api/v1/purchases/summary";
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

QString PurchaseApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void PurchaseApi::saveToken(const QString &token) {
    m_token = token;
    m_settings.setValue("auth/token", token);
}

} // namespace NetworkApi


