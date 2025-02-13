// purchaseapi.cpp
#include "purchaseapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;
PurchaseApi::PurchaseApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    ,  m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

// Helper Methods
Purchase PurchaseApi::purchaseFromJson(const QJsonObject &json) const
{
    Purchase purchase;
    purchase.id = json["id"_L1].toInt();
    purchase.reference_number = json["reference_number"_L1].toString();
    purchase.purchase_date = QDateTime::fromString(json["purchase_date"_L1].toString(), Qt::ISODate);
    purchase.supplier_id = json["supplier_id"_L1].toInt();
    purchase.cash_source_id = json["cash_source_id"_L1].toInt();
    purchase.status = json["status"_L1].toString();
    purchase.payment_status = json["payment_status"_L1].toString();
    purchase.total_amount = json["total_amount"_L1].toString().toDouble();
    purchase.paid_amount = json["paid_amount"_L1].toString().toDouble();
    purchase.notes = json["notes"_L1].toString();

    if (json.contains("supplier"_L1) && !json["supplier"_L1].isNull()) {
        purchase.supplier = json["supplier"_L1].toObject().toVariantMap();
    }

    if (json.contains("items"_L1)) {
        const QJsonArray itemsArray = json["items"_L1].toArray();
        for (const QJsonValue &value : itemsArray) {
            purchase.items.append(purchaseItemFromJson(value.toObject()));
        }
    }

    return purchase;
}

PurchaseItem PurchaseApi::purchaseItemFromJson(const QJsonObject &json) const
{
    PurchaseItem item;
    item.id = json["id"_L1].toInt();
    item.product_id = json["product_id"_L1].toInt();
    item.product_name = json["product_name"_L1].toString();
    item.quantity = json["quantity"_L1].toInt();
    item.unit_price = json["unit_price"_L1].toString().toDouble();
    item.total_price = json["total_price"_L1].toString().toDouble();
    item.tax_rate = json["tax_rate"_L1].toString().toDouble();
    item.tax_amount = json["tax_amount"_L1].toString().toDouble();
    item.discount_amount = json["discount_amount"_L1].toString().toDouble();
    item.notes = json["notes"_L1].toString();

    // Package-related fields
    item.is_package = json["is_package"_L1].toBool();
    item.package_id = json["package_id"_L1].toInt(-1);  // Use -1 as default
    item.update_package_prices = json["update_package_prices"_L1].toBool();
    item.package_purchase_price = json["package_purchase_price"_L1].toString().toDouble();
    item.package_selling_price = json["package_selling_price"_L1].toString().toDouble();
    item.update_prices = json["update_prices"_L1].toBool();

    if (json.contains("product"_L1)) {
        item.product = json["product"_L1].toObject().toVariantMap();
    }

    if (json.contains("package"_L1) && !json["package"_L1].isNull()) {
        const QJsonObject packageObj = json["package"_L1].toObject();
        item.package.id = packageObj["id"_L1].toInt();
        item.package.name = packageObj["name"_L1].toString();
        item.package.pieces_per_package = packageObj["pieces_per_package"_L1].toInt();
        item.package.purchase_price = packageObj["purchase_price"_L1].toString().toDouble();
        item.package.selling_price = packageObj["selling_price"_L1].toString().toDouble();
        item.package.barcode = packageObj["barcode"_L1].toString();
    }

    return item;
}


QJsonObject PurchaseApi::purchaseToJson(const Purchase &purchase) const
{
    QJsonObject json;

    // Required fields
    json["supplier_id"_L1] = purchase.supplier_id;
    json["cash_source_id"_L1] = purchase.cash_source_id;
    json["purchase_date"_L1] = purchase.purchase_date.toString(Qt::ISODate);

    // Optional fields
    if (purchase.due_date.isValid()) {
        json["due_date"_L1] = purchase.due_date.toString(Qt::ISODate);
    }

    if (!purchase.notes.isEmpty()) {
        json["notes"_L1] = purchase.notes;
    }

    // Items array
    QJsonArray itemsArray;
    for (const PurchaseItem &item : purchase.items) {
          QJsonObject itemJson = purchaseItemToJson(item);
          itemsArray.append(itemJson);
      }
    json["items"_L1] = itemsArray;

    // Debug output
    qDebug() << "Purchase JSON:" << QJsonDocument(json).toJson();

    return json;
}


// In purchaseapi.cpp
QJsonObject PurchaseApi::purchaseItemToJson(const PurchaseItem &item) const
{
    QJsonObject json;
    json["product_id"_L1] = item.product_id;
    json["quantity"_L1] = item.quantity;
    json["unit_price"_L1] = item.unit_price;
    json["selling_price"_L1] = item.selling_price;
    json["tax_rate"_L1] = item.tax_rate;
    json["discount_amount"_L1] = item.discount_amount;

    // Add package-related fields
    json["is_package"_L1] = item.is_package;
    json["package_id"_L1] = item.package_id;

    if (item.is_package) {
        json["update_package_prices"_L1] = item.update_package_prices;
        json["package_purchase_price"_L1] = item.package_purchase_price;
        json["package_selling_price"_L1] = item.package_selling_price;
        json["update_prices"_L1] = false;  // Don't update product prices when it's a package
    } else {
        json["update_prices"_L1] = item.update_prices;
        json["update_package_prices"_L1] = false;
    }

    if (!item.notes.isEmpty()) {
        json["notes"_L1] = item.notes;
    }

    // Add debug output
    qDebug() << "Purchase item JSON:" << json;

    return json;
}


QJsonObject PurchaseApi::paymentToJson(const PurchasePayment &payment) const
{
    QJsonObject json;
    json["cash_source_id"_L1] = payment.cash_source_id;
    json["amount"_L1] = payment.amount;
    json["payment_method"_L1] = payment.payment_method;
    json["reference_number"_L1] = payment.reference_number;
    json["notes"_L1] = payment.notes;
    return json;
}

PaginatedPurchases PurchaseApi::paginatedPurchasesFromJson(const QJsonObject &json) const
{
    PaginatedPurchases result;
    const QJsonObject &meta = json["purchases"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(purchaseFromJson(value.toObject()));
    }

    return result;
}

QVariantMap PurchaseApi::purchaseToVariantMap(const Purchase &purchase) const
{
    QVariantMap map;
    map["id"_L1] = purchase.id;
    map["reference_number"_L1] = purchase.reference_number;
    map["purchase_date"_L1] = purchase.purchase_date;
    map["supplier_id"_L1] = purchase.supplier_id;
    map["cash_source_id"_L1] = purchase.cash_source_id;
    map["supplier"_L1] = purchase.supplier;
    map["status"_L1] = purchase.status;
    map["payment_status"_L1] = purchase.payment_status;
    map["total_amount"_L1] = purchase.total_amount;
    map["paid_amount"_L1] = purchase.paid_amount;
    map["notes"_L1] = purchase.notes;

    QVariantList itemsList;
    for (const PurchaseItem &item : purchase.items) {
        itemsList.append(purchaseItemToVariantMap(item));
    }
    map["items"_L1] = itemsList;

    return map;
}

QVariantMap PurchaseApi::purchaseItemToVariantMap(const PurchaseItem &item) const
{
    QVariantMap map;
    map["id"_L1] = item.id;
    map["product_id"_L1] = item.product_id;
    map["product_name"_L1] = item.product_name;
    map["quantity"_L1] = item.quantity;
    map["unit_price"_L1] = item.unit_price;
    map["selling_price"_L1] = item.selling_price;
    map["total_price"_L1] = item.total_price;
    map["notes"_L1] = item.notes;
    map["product"_L1] = item.product;
    map["is_package"_L1] = item.is_package;
    map["package_id"_L1] = item.package_id;
    map["update_package_prices"_L1] = item.update_package_prices;
    map["package_purchase_price"_L1] = item.package_purchase_price;
    map["package_selling_price"_L1] = item.package_selling_price;

    if (item.is_package) {
        QVariantMap packageMap;
        packageMap["id"_L1] = item.package.id;
        packageMap["name"_L1] = item.package.name;
        packageMap["pieces_per_package"_L1] = item.package.pieces_per_package;
        packageMap["purchase_price"_L1] = item.package.purchase_price;
        packageMap["selling_price"_L1] = item.package.selling_price;
        packageMap["barcode"_L1] = item.package.barcode;
        map["package"_L1] = packageMap;
    }

    return map;
}

// API Methods Implementation
QFuture<void> PurchaseApi::getPurchases(const QString &search, const QString &sortBy,
                                        const QString &sortDirection, int page,
                                        const QString &status, const QString &paymentStatus)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/purchases");

    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QStringLiteral("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QStringLiteral("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QStringLiteral("sort_direction=%1").arg(sortDirection);
    if (page > 0)
        queryParts << QStringLiteral("page=%1").arg(page);
    if (!status.isEmpty())
        queryParts << QStringLiteral("status=%1").arg(status);
    if (!paymentStatus.isEmpty())
        queryParts << QStringLiteral("payment_status=%1").arg(paymentStatus);

    if (!queryParts.isEmpty()) {
       path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedPurchases paginatedPurchases = paginatedPurchasesFromJson(*response.data);
            Q_EMIT purchasesReceived(paginatedPurchases);
        } else {
            Q_EMIT errorPurchasesReceived(response.error->message, response.error->status,
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
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/purchases/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Purchase purchase = purchaseFromJson(response.data->value("purchase"_L1).toObject());
            Q_EMIT purchaseReceived(purchaseToVariantMap(purchase));
        } else {
            Q_EMIT errorPurchaseReceived(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::createPurchase(const Purchase &purchase)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/purchases"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

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
            Purchase createdPurchase = purchaseFromJson(response.data->value("purchase"_L1).toObject());
            Q_EMIT purchaseCreated(createdPurchase);
        } else {
            QString errorDetails;
            if (response.error && !response.error->details.isEmpty()) {
                errorDetails = QString::fromUtf8(
                    QJsonDocument(response.error->details).toJson(QJsonDocument::Compact)
                );
            } else {
                using namespace Qt::StringLiterals;
                errorDetails = response.error ? response.error->message : "Unknown error"_L1;
            }

            qDebug() << "Purchase creation failed:"
                     << "\nMessage:" << (response.error ? response.error->message : "Unknown error"_L1)
                     << "\nDetails:" << errorDetails;

            Q_EMIT errorPurchaseCreated(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::updatePurchase(int id, const Purchase &purchase)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/purchases/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = purchaseToJson(purchase);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Purchase updatedPurchase = purchaseFromJson(response.data->value("purchase"_L1).toObject());
            Q_EMIT purchaseUpdated(updatedPurchase);
        } else {
            Q_EMIT errorPurchaseUpdated(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::deletePurchase(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/purchases/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT purchaseDeleted(id);
        } else {
            Q_EMIT errorPurchaseDeleted(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::addPayment(int id, const PurchasePayment &payment)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/purchases/%1/add-payment").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = paymentToJson(payment);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Q_EMIT paymentAdded(response.data->value("payment"_L1).toObject().toVariantMap());
        } else {
            Q_EMIT errorPaymentAdded(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::generateInvoice(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/purchases/%1/generate-invoice").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Q_EMIT invoiceGenerated(response.data->value("invoice"_L1).toObject().toVariantMap());
        } else {
            Q_EMIT errorInvoiceGenerated(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> PurchaseApi::getSummary(const QString &period)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/purchases/summary");
    if (!period.isEmpty()) {
        path += QStringLiteral("?period=%1").arg(period);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Q_EMIT summaryReceived(response.data->value("summary"_L1).toObject().toVariantMap());
        } else {
            Q_EMIT errorSummaryReceived(response.error->message, response.error->status,
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


