// saleapi.cpp
#include "saleapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;

SaleApi::SaleApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

// Helper Methods
Sale SaleApi::saleFromJson(const QJsonObject &json) const
{
    Sale sale;
    sale.id = json["id"_L1].toInt();
    sale.team_id = json["team_id"_L1].toInt();
    sale.client_id = json["client_id"_L1].toInt();
    sale.cash_source_id = json["cash_source_id"_L1].toInt();
    sale.reference_number = json["reference_number"_L1].toString();
    sale.total_amount = json["total_amount"_L1].toString().toDouble();
    sale.paid_amount = json["paid_amount"_L1].toString().toDouble();
    sale.tax_amount = json["tax_amount"_L1].toString().toDouble();
    sale.discount_amount = json["discount_amount"_L1].toString().toDouble();
    sale.payment_status = json["payment_status"_L1].toString();
    sale.status = json["status"_L1].toString();

    // Get the type field with a default value of "sale" for backward compatibility
    sale.type = json.contains("type"_L1) ? json["type"_L1].toString() : QStringLiteral("sale");

    sale.sale_date = QDateTime::fromString(json["sale_date"_L1].toString(), Qt::ISODate);
    if (json.contains("due_date"_L1) && !json["due_date"_L1].isNull()) {
        sale.due_date = QDateTime::fromString(json["due_date"_L1].toString(), Qt::ISODate);
    }
    sale.createdAt = QDateTime::fromString(json[QStringLiteral("created_at")].toString(), Qt::ISODate);
    sale.notes = json["notes"_L1].toString();

    if (json.contains("client"_L1) && !json["client"_L1].isNull()) {
        sale.client = json["client"_L1].toObject().toVariantMap();
    }

    if (json.contains("items"_L1)) {
        const QJsonArray itemsArray = json["items"_L1].toArray();
        for (const QJsonValue &value : itemsArray) {
            sale.items.append(saleItemFromJson(value.toObject()));
        }
    }

    return sale;
}

SaleItem SaleApi::saleItemFromJson(const QJsonObject &json) const
{
    SaleItem item;
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

    // Add package-related fields
    item.is_package = json["is_package"_L1].toBool();
    item.package_id = json["package_id"_L1].toInt();
    item.total_pieces = json["total_pieces"_L1].toInt();

    if (json.contains("product"_L1) && !json["product"_L1].isNull()) {
        item.product = json["product"_L1].toObject().toVariantMap();
    }

    if (json.contains("package"_L1) && !json["package"_L1].isNull()) {
        item.package = json["package"_L1].toObject().toVariantMap();
    }

    return item;
}
QJsonObject SaleApi::saleToJson(const Sale &sale) const
{
    QJsonObject json;

    // Required fields
    json["cash_source_id"_L1] = sale.cash_source_id;
    json["sale_date"_L1] = sale.sale_date.toString(QStringLiteral("yyyy-MM-dd"));
    json["status"_L1] = sale.status;
    json["payment_status"_L1] = sale.payment_status;
    json["type"_L1] = sale.type; // Include type field

    // Amounts
    json["total_amount"_L1] = sale.total_amount;
    json["tax_amount"_L1] = sale.tax_amount;
    json["discount_amount"_L1] = sale.discount_amount;

    // Auto-payment flag and amount (only for sales, not quotes)
    if (sale.auto_payment && sale.type != QStringLiteral("quote")) {
        json["auto_payment"_L1] = true;
        json["payment_amount"_L1] = sale.payment_amount;
    }

    // Optional fields
    if (sale.client_id > 0) {
        json["client_id"_L1] = sale.client_id;
        if (sale.due_date.isValid()) {
            json["due_date"_L1] = sale.due_date.toString(QStringLiteral("yyyy-MM-dd"));
        }
    }

    if (!sale.notes.isEmpty()) {
        json["notes"_L1] = sale.notes;
    }

    // Items array using existing saleItemToJson method
    QJsonArray itemsArray;
    for (const SaleItem &item : sale.items) {
        itemsArray.append(saleItemToJson(item));
    }
    json["items"_L1] = itemsArray;
    return json;
}



QJsonObject SaleApi::saleItemToJson(const SaleItem &item) const
{
    QJsonObject json;
    json["product_id"_L1] = item.product_id;
    json["quantity"_L1] = item.quantity;
    json["unit_price"_L1] = item.unit_price;
    json["tax_rate"_L1] = item.tax_rate;
    json["discount_amount"_L1] = item.discount_amount;
    json["is_package"_L1] = item.is_package;
    json["total_pieces"_L1] = item.total_pieces;

    if (item.is_package) {
        json["package_id"_L1] = item.package_id;
    }

    if (!item.notes.isEmpty()) {
        json["notes"_L1] = item.notes;
    }

    return json;
}

QJsonObject SaleApi::paymentToJson(const Payment &payment) const
{
    QJsonObject json;
    json["cash_source_id"_L1] = payment.cash_source_id;
    json["amount"_L1] = payment.amount;
    json["payment_method"_L1] = payment.payment_method;
    json["reference_number"_L1] = payment.reference_number;
    json["notes"_L1] = payment.notes;
    return json;
}

PaginatedSales SaleApi::paginatedSalesFromJson(const QJsonObject &json) const
{
    PaginatedSales result;
    const QJsonObject &meta = json["sales"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(saleFromJson(value.toObject()));
    }

    return result;
}

QVariantMap SaleApi::saleToVariantMap(const Sale &sale) const
{
    QVariantMap map;
    map["id"_L1] = sale.id;
    map["team_id"_L1] = sale.team_id;
    map["client_id"_L1] = sale.client_id;
    map["cash_source_id"_L1] = sale.cash_source_id;
    map["reference_number"_L1] = sale.reference_number;
    map["total_amount"_L1] = sale.total_amount;
    map["paid_amount"_L1] = sale.paid_amount;
    map["tax_amount"_L1] = sale.tax_amount;
    map["discount_amount"_L1] = sale.discount_amount;
    map["payment_status"_L1] = sale.payment_status;
    map["status"_L1] = sale.status;
    map["type"_L1] = sale.type; // Add type field
    map["sale_date"_L1] = sale.sale_date;
    map["due_date"_L1] = sale.due_date;
    map["notes"_L1] = sale.notes;
    map["client"_L1] = sale.client;

    QVariantList itemsList;
    for (const SaleItem &item : sale.items) {
        itemsList.append(saleItemToVariantMap(item));
    }
    map["items"_L1] = itemsList;

    return map;
}


QVariantMap SaleApi::saleItemToVariantMap(const SaleItem &item) const
{
    QVariantMap map;
    map["id"_L1] = item.id;
    map["product_id"_L1] = item.product_id;
    map["product_name"_L1] = item.product_name;
    map["quantity"_L1] = item.quantity;
    map["unit_price"_L1] = item.unit_price;
    map["total_price"_L1] = item.total_price;
    map["tax_rate"_L1] = item.tax_rate;
    map["tax_amount"_L1] = item.tax_amount;
    map["discount_amount"_L1] = item.discount_amount;
    map["notes"_L1] = item.notes;
    map["product"_L1] = item.product;
    map["is_package"_L1] = item.is_package;
    map["package_id"_L1] = item.package_id;
    map["total_pieces"_L1] = item.total_pieces;
    map["package"_L1] = item.package;
    return map;
}

DocumentConfig SaleApi::configFromVariantMap(const QVariantMap &map) const
{
    DocumentConfig config;

    // Extract all configuration values from the map
    if (map.contains("showClientInfo"_L1))
        config.showClientInfo = map["showClientInfo"_L1].toBool();

    if (map.contains("showAmountInWords"_L1))
        config.showAmountInWords = map["showAmountInWords"_L1].toBool();

    if (map.contains("showPaymentMethods"_L1))
        config.showPaymentMethods = map["showPaymentMethods"_L1].toBool();

    if (map.contains("showTaxNumbers"_L1))
        config.showTaxNumbers = map["showTaxNumbers"_L1].toBool();

    if (map.contains("showNotes"_L1))
        config.showNotes = map["showNotes"_L1].toBool();

    if (map.contains("showThanksMessage"_L1))
        config.showThanksMessage = map["showThanksMessage"_L1].toBool();

    if (map.contains("showTermsConditions"_L1))
        config.showTermsConditions = map["showTermsConditions"_L1].toBool();

    if (map.contains("logoEnabled"_L1))
        config.logoEnabled = map["logoEnabled"_L1].toBool();

    if (map.contains("primaryColor"_L1) && !map["primaryColor"_L1].toString().isEmpty())
        config.primaryColor = map["primaryColor"_L1].toString();

    if (map.contains("footerText"_L1))
        config.footerText = map["footerText"_L1].toString();

    if (map.contains("defaultNotes"_L1))
        config.defaultNotes = map["defaultNotes"_L1].toString();

    if (map.contains("thanksMessage"_L1))
        config.thanksMessage = map["thanksMessage"_L1].toString(); // Fixed: was setting defaultNotes again!

    if (map.contains("defaultTerms"_L1))
        config.defaultTerms = map["defaultTerms"_L1].toString();

    return config;
}


QJsonObject SaleApi::configToJson(const DocumentConfig &config) const
{
    QJsonObject json;
    json["showClientInfo"_L1] = config.showClientInfo;
    json["showAmountInWords"_L1] = config.showAmountInWords;
    json["showPaymentMethods"_L1] = config.showPaymentMethods;
    json["showTaxNumbers"_L1] = config.showTaxNumbers;
    json["showNotes"_L1] = config.showNotes;
    json["showThanksMessage"_L1] = config.showThanksMessage;
    json["showTermsConditions"_L1] = config.showTermsConditions;
    json["logoEnabled"_L1] = config.logoEnabled;
    json["primaryColor"_L1] = config.primaryColor;
    json["footerText"_L1] = config.footerText;
    json["defaultNotes"_L1] = config.defaultNotes;
    json["thanksMessage"_L1] = config.thanksMessage;
    json["defaultTerms"_L1] = config.defaultTerms;
    return json;
}

// API Methods
QFuture<void> SaleApi::getSales(const QString &search, const QString &sortBy,
                                const QString &sortDirection, int page,
                                const QString &status, const QString &paymentStatus,
                                const QString &type) // Add type parameter
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/sales");

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
    if (!type.isEmpty())
        queryParts << QStringLiteral("type=%1").arg(type); // Add type filter

    if (!queryParts.isEmpty()) {
        path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedSales paginatedSales = paginatedSalesFromJson(*response.data);
            Q_EMIT salesReceived(paginatedSales);
        } else {
            Q_EMIT errorSalesReceived(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}


QFuture<void> SaleApi::getSale(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/sales/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale sale = saleFromJson(response.data->value("sale"_L1).toObject());
            Q_EMIT saleReceived(saleToVariantMap(sale));
        } else {
            Q_EMIT errorSaleReceived(response.error->message, response.error->status,
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

    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/sales"));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = saleToJson(sale);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale createdSale = saleFromJson(response.data->value("sale"_L1).toObject());
            qDebug() << "================== Done:";
            Q_EMIT saleCreated(createdSale);
            Q_EMIT saleMapCreated(saleToVariantMap(createdSale));
        } else {
            qDebug() << "Error Sale details:" << response.error->details;

            Q_EMIT errorSaleCreated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::updateSale(int id, const Sale &sale)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/sales/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = saleToJson(sale);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale updatedSale = saleFromJson(response.data->value("sale"_L1).toObject());
            Q_EMIT saleUpdated(updatedSale);
        } else {
            Q_EMIT errorSaleUpdated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::deleteSale(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/sales/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT saleDeleted(id);
        } else {
            Q_EMIT errorSaleDeleted(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SaleApi::addPayment(int id, const Payment &payment)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/sales/%1/add-payment").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"_L1] = payment.amount;
    jsonData["reference_number"_L1] = payment.reference_number;
    jsonData["notes"_L1] = payment.notes;
    jsonData["payment_method"_L1] = payment.payment_method;
    if (payment.cash_source_id > 0) {
        jsonData["cash_source_id"_L1] = payment.cash_source_id;
    }

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Q_EMIT paymentAdded(response.data->value("sale"_L1).toObject().toVariantMap());
        } else {
            Q_EMIT errorPaymentAdded(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

// Update in saleapi.cpp
QFuture<void> SaleApi::generateInvoice(int id, const QVariantMap &configMap)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/sales/%1/generate-invoice").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    // Create request JSON object
    QJsonObject jsonData;

    // Convert QVariantMap to DocumentConfig struct
    DocumentConfig config = configFromVariantMap(configMap);

    // Convert DocumentConfig to JSON
    jsonData = configToJson(config);

    // Debug output
    qDebug() << "Sending invoice generation request:" << QJsonDocument(jsonData).toJson();

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            QVariantMap invoice = response.data->toVariantMap();
            Q_EMIT invoiceGenerated(invoice);
        } else {
            Q_EMIT errorInvoiceGenerated(response.error->message, response.error->status,
                                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}




QFuture<void> SaleApi::convertToSale(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/sales/%1/convert-to-sale").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Sale convertedSale = saleFromJson(response.data->value("sale"_L1).toObject());
            Q_EMIT saleConverted(saleToVariantMap(convertedSale));
        } else {
            Q_EMIT errorSaleConverted(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<QByteArray> SaleApi::generateReceipt(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/sales/%1/receipt").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto promise = std::make_shared<QPromise<QByteArray>>();

    m_currentReply = m_netManager->get(request);

    connect(m_currentReply, &QNetworkReply::finished, this, [this, promise]() {
        setLoading(false);

        if (m_currentReply->error() == QNetworkReply::NoError) {
            QString contentType = m_currentReply->header(QNetworkRequest::ContentTypeHeader).toString();

            if (contentType.contains("application/pdf"_L1)) {
                QByteArray pdfData = m_currentReply->readAll();

                // Save to app's data location
                QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
                QDir().mkpath(QStringLiteral("%1/pdfs").arg(appDataPath));

                QString fileName = QStringLiteral("receipt-%1.pdf").arg(QDateTime::currentMSecsSinceEpoch());
                QString filePath = QStringLiteral("%1/pdfs/%2").arg(appDataPath, fileName);

                QFile file(filePath);
                if (file.open(QIODevice::WriteOnly)) {
                    file.write(pdfData);
                    file.close();

                    // Ensure we create a proper URL using QUrl
                    QUrl fileUrl = QUrl::fromLocalFile(filePath);
                    QString fileUrlString = fileUrl.toString();

                    qDebug() << "Receipt PDF saved to:" << fileUrlString;
                    Q_EMIT receiptGenerated(fileUrlString);
                    promise->addResult(pdfData);
                    setLoading(false);
                } else {
                    Q_EMIT errorReceiptGenerated("Failed to save PDF"_L1, file.errorString());
                    promise->addResult(QByteArray());
                }
            } else if (contentType.contains("application/json"_L1)) {
                // Handle error response
                QJsonDocument jsonResponse = QJsonDocument::fromJson(m_currentReply->readAll());
                QJsonObject jsonObject = jsonResponse.object();
                QString errorMessage = jsonObject["message"_L1].toString();
                Q_EMIT errorReceiptGenerated("Error"_L1, errorMessage);
                promise->addResult(QByteArray());
            }
        } else {
            Q_EMIT errorReceiptGenerated("Network Error"_L1, m_currentReply->errorString());
            promise->addResult(QByteArray());
        }

        promise->finish();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    });

    return promise->future();
}

QFuture<void> SaleApi::getSummary(const QString &period)
{
    setLoading(true);
    QString path = QStringLiteral( "/api/v1/sales/summary");
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

QString SaleApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void SaleApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
