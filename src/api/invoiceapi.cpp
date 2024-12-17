#include "invoiceapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {

InvoiceApi::InvoiceApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

// Helper Methods
Invoice InvoiceApi::invoiceFromJson(const QJsonObject &json) const
{
    Invoice invoice;
    invoice.id = json["id"].toInt();
    invoice.team_id = json["team_id"].toInt();
    invoice.reference_number = json["reference_number"].toString();
    invoice.invoiceable_type = json["invoiceable_type"].toString();
    invoice.invoiceable_id = json["invoiceable_id"].toInt();
    invoice.total_amount = json["total_amount"].toString().toDouble();
    invoice.tax_amount = json["tax_amount"].toString().toDouble();
    invoice.discount_amount = json["discount_amount"].toString().toDouble();
    invoice.status = json["status"].toString();
    invoice.issue_date = QDateTime::fromString(json["issue_date"].toString(), Qt::ISODate);
    invoice.due_date = QDateTime::fromString(json["due_date"].toString(), Qt::ISODate);
    invoice.notes = json["notes"].toString();

    // Handle meta_data
    if (json.contains("meta_data") && !json["meta_data"].isNull()) {
        invoice.meta_data = json["meta_data"].toObject().toVariantMap();
    }

    // Handle morphed relationship data (invoiceable)
    if (json.contains("invoiceable") && !json["invoiceable"].isNull()) {
        QJsonObject invoiceable = json["invoiceable"].toObject();
        invoice.meta_data.insert("invoiceable_data", invoiceable.toVariantMap());
    }

    // Handle items if present
    if (json.contains("items") && json["items"].isArray()) {
        const QJsonArray itemsArray = json["items"].toArray();
        for (const QJsonValue &value : itemsArray) {
            invoice.items.append(invoiceItemFromJson(value.toObject()));
        }
    }

    return invoice;
}

InvoiceItem InvoiceApi::invoiceItemFromJson(const QJsonObject &json) const
{
    InvoiceItem item;
    item.id = json["id"].toInt();
    item.description = json["description"].toString();
    item.quantity = json["quantity"].toInt();
    item.unit_price = json["unit_price"].toDouble();
    item.total_price = json["total_price"].toDouble();
    item.notes = json["notes"].toString();
    return item;
}

QJsonObject InvoiceApi::invoiceToJson(const Invoice &invoice) const
{
    QJsonObject json;
    json["team_id"] = invoice.team_id;
    json["reference_number"] = invoice.reference_number;
    json["invoiceable_type"] = invoice.invoiceable_type;
    json["invoiceable_id"] = invoice.invoiceable_id;
    json["total_amount"] = invoice.total_amount;
    json["tax_amount"] = invoice.tax_amount;
    json["discount_amount"] = invoice.discount_amount;
    json["status"] = invoice.status;
    json["issue_date"] = invoice.issue_date.toString(Qt::ISODate);
    json["due_date"] = invoice.due_date.toString(Qt::ISODate);
    json["notes"] = invoice.notes;

    if (!invoice.meta_data.isEmpty()) {
        json["meta_data"] = QJsonObject::fromVariantMap(invoice.meta_data);
    }

    if (!invoice.items.isEmpty()) {
        QJsonArray itemsArray;
        for (const InvoiceItem &item : invoice.items) {
            itemsArray.append(invoiceItemToJson(item));
        }
        json["items"] = itemsArray;
    }

    return json;
}

QJsonObject InvoiceApi::invoiceItemToJson(const InvoiceItem &item) const
{
    QJsonObject json;
    json["description"] = item.description;
    json["quantity"] = item.quantity;
    json["unit_price"] = item.unit_price;
    json["total_price"] = item.unit_price * item.quantity;
    json["notes"] = item.notes;
    return json;
}

QVariantMap InvoiceApi::invoiceToVariantMap(const Invoice &invoice) const
{
    QVariantMap map;

    // Core database fields
    map["id"] = invoice.id;
    map["team_id"] = invoice.team_id;
    map["reference_number"] = invoice.reference_number;
    map["invoiceable_type"] = invoice.invoiceable_type;
    map["invoiceable_id"] = invoice.invoiceable_id;
    map["total_amount"] = invoice.total_amount;
    map["tax_amount"] = invoice.tax_amount;
    map["discount_amount"] = invoice.discount_amount;
    map["status"] = invoice.status;
    map["issue_date"] = invoice.issue_date;
    map["due_date"] = invoice.due_date;
    map["notes"] = invoice.notes;
    map["meta_data"] = invoice.meta_data;

    // UI compatibility fields (computed or from meta_data)
    map["invoice_date"] = invoice.issue_date;  // Alias for backward compatibility
    map["client_id"] = invoice.getClientId();
    map["client"] = invoice.getClient();
    map["payment_status"] = invoice.getPaymentStatus();
    map["subtotal"] = invoice.getSubtotal();
    map["paid_amount"] = invoice.getPaidAmount();
    map["remaining_amount"] = invoice.getRemainingAmount();
    map["terms_conditions"] = invoice.getTermsConditions();

    // Items
    QVariantList itemsList;
    for (const InvoiceItem &item : invoice.items) {
        itemsList.append(invoiceItemToVariantMap(item));
    }
    map["items"] = itemsList;

    return map;
}

QVariantMap InvoiceApi::invoiceItemToVariantMap(const InvoiceItem &item) const
{
    QVariantMap map;
    map["id"] = item.id;
    map["description"] = item.description;
    map["quantity"] = item.quantity;
    map["unit_price"] = item.unit_price;
    map["total_price"] = item.total_price;
    map["notes"] = item.notes;
    return map;
}

QJsonObject InvoiceApi::paymentToJson(const InvoicePayment &payment) const
{
    QJsonObject json;
    json["cash_source_id"] = payment.cash_source_id;
    json["amount"] = payment.amount;
    json["payment_method"] = payment.payment_method;
    json["reference_number"] = payment.reference_number;
    json["notes"] = payment.notes;
    return json;
}

PaginatedInvoices InvoiceApi::paginatedInvoicesFromJson(const QJsonObject &json) const
{
    PaginatedInvoices result;
    const QJsonObject &meta = json["invoices"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(invoiceFromJson(value.toObject()));
    }

    return result;
}

QFuture<void> InvoiceApi::getInvoices(const QString &search, const QString &sortBy,
                                     const QString &sortDirection, int page,
                                     const QString &status, const QString &paymentStatus)
{
    setLoading(true);
    QString path = "/api/v1/invoices";

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
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedInvoices paginatedInvoices = paginatedInvoicesFromJson(*response.data);
            emit invoicesReceived(paginatedInvoices);
        } else {
            emit errorInvoicesReceived(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::getInvoice(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice invoice = invoiceFromJson(response.data->value("invoice").toObject());
            emit invoiceReceived(invoiceToVariantMap(invoice));
        } else {
            emit errorInvoiceReceived(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::createInvoice(const Invoice &invoice)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/v1/invoices");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    QJsonObject jsonData = invoiceToJson(invoice);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice createdInvoice = invoiceFromJson(response.data->value("invoice").toObject());
            emit invoiceCreated(createdInvoice);
        } else {
            emit errorInvoiceCreated(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::updateInvoice(int id, const Invoice &invoice)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    QJsonObject jsonData = invoiceToJson(invoice);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice updatedInvoice = invoiceFromJson(response.data->value("invoice").toObject());
            emit invoiceUpdated(updatedInvoice);
        } else {
            emit errorInvoiceUpdated(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::deleteInvoice(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit invoiceDeleted(id);
        } else {
            emit errorInvoiceDeleted(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::addPayment(int id, const InvoicePayment &payment)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1/payments").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

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
QFuture<QByteArray> InvoiceApi::generatePdf(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1/download").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    auto promise = std::make_shared<QPromise<QByteArray>>();

    m_currentReply = m_netManager->get(request);

    connect(m_currentReply, &QNetworkReply::finished, this, [this, promise]() {
        setLoading(false);

        if (m_currentReply->error() == QNetworkReply::NoError) {
            // Get the content type
            QString contentType = m_currentReply->header(QNetworkRequest::ContentTypeHeader).toString();

            if (contentType.contains("application/pdf")) {
                QByteArray pdfData = m_currentReply->readAll();

                // Save to app's data location instead of /tmp
                QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
                QDir().mkpath(appDataPath + "/pdfs");

                QString fileName = QString("invoice-%1.pdf").arg(QDateTime::currentMSecsSinceEpoch());
                QString filePath = appDataPath + "/pdfs/" + fileName;

                QFile file(filePath);
                if (file.open(QIODevice::WriteOnly)) {
                    file.write(pdfData);
                    file.close();

                    QString fileUrl = QUrl::fromLocalFile(filePath).toString();
                    qDebug() << "PDF saved to:" << fileUrl;
                    emit pdfGenerated(fileUrl);
                    promise->addResult(pdfData);
                     setLoading(false);
                } else {
                    emit errorPdfGenerated("Failed to save PDF", file.errorString());
                    promise->addResult(QByteArray());
                }
            } else if (contentType.contains("application/json")) {
                // Handle error response
                QJsonDocument jsonResponse = QJsonDocument::fromJson(m_currentReply->readAll());
                QJsonObject jsonObject = jsonResponse.object();
                QString errorMessage = jsonObject["message"].toString();
                emit errorPdfGenerated("Error", errorMessage);
                promise->addResult(QByteArray());
            }
        } else {
            emit errorPdfGenerated("Network Error", m_currentReply->errorString());
            promise->addResult(QByteArray());
        }

        promise->finish();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    });

    return promise->future();
}

// QFuture<QByteArray> InvoiceApi::generatePdf(int id)
// {
//     setLoading(true);
//     QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1/download").arg(id));
//     request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

//     auto promise = std::make_shared<QPromise<QByteArray>>();

//     // Store reply as a member variable to prevent premature deletion
//     m_currentReply = m_netManager->get(request);

//     // Connect finished signal
//     connect(m_currentReply, &QNetworkReply::finished, this, [this, promise]() {
//         setLoading(false);

//         if (m_currentReply->error() == QNetworkReply::NoError) {
//             QByteArray pdfData = m_currentReply->readAll();

//             try {
//                 // Save PDF to temporary file
//                 QString tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
//                 QDir().mkpath(tempPath); // Ensure directory exists

//                 QString fileName = QString("invoice-%1.pdf").arg(QDateTime::currentMSecsSinceEpoch());
//                 QString filePath = QDir(tempPath).filePath(fileName);

//                 QFile file(filePath);
//                 if (file.open(QIODevice::WriteOnly)) {
//                     qint64 bytesWritten = file.write(pdfData);
//                     file.close();

//                     if (bytesWritten > 0) {
//                         QString fileUrl = QUrl::fromLocalFile(filePath).toString();
//                         qDebug() << "PDF saved to:" << fileUrl;
//                         emit pdfGenerated(fileUrl);
//                         promise->addResult(pdfData);
//                     } else {
//                         throw std::runtime_error("Failed to write PDF data");
//                     }
//                 } else {
//                     throw std::runtime_error(file.errorString().toStdString());
//                 }
//             } catch (const std::exception& e) {
//                 qWarning() << "Error saving PDF:" << e.what();
//                 emit errorPdfGenerated("Failed to save PDF", QString::fromStdString(e.what()));
//                 promise->addResult(QByteArray());
//             }
//         } else {
//             qWarning() << "Network error:" << m_currentReply->errorString();
//             emit errorPdfGenerated("Failed to download PDF", m_currentReply->errorString());
//             promise->addResult(QByteArray());
//         }

//         promise->finish();
//         m_currentReply->deleteLater();
//         m_currentReply = nullptr;
//     });

//     // Connect error signal
//     connect(m_currentReply, &QNetworkReply::errorOccurred, this, [this, promise](QNetworkReply::NetworkError error) {
//         qWarning() << "Network error occurred:" << error;
//         setLoading(false);
//         emit errorPdfGenerated("Network error", m_currentReply->errorString());
//         promise->addResult(QByteArray());
//         promise->finish();
//     });

//     return promise->future();
// }

QFuture<void> InvoiceApi::sendToClient(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1/send").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit invoiceSent(response.data->value("result").toObject().toVariantMap());
        } else {
            emit errorInvoiceSent(response.error->message, response.error->status,
                                QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::markAsSent(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1/mark-as-sent").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice invoice = invoiceFromJson(response.data->value("invoice").toObject());
            emit invoiceMarkedAsSent(invoiceToVariantMap(invoice));
        } else {
            emit errorInvoiceMarkedAsSent(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::markAsPaid(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/invoices/%1/mark-as-paid").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice invoice = invoiceFromJson(response.data->value("invoice").toObject());
            emit invoiceMarkedAsPaid(invoiceToVariantMap(invoice));
        } else {
            emit errorInvoiceMarkedAsPaid(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::getSummary(const QString &period)
{
    setLoading(true);
    QString path = "/api/v1/invoices/summary";
    if (!period.isEmpty()) {
        path += QString("?period=%1").arg(period);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(getToken()).toUtf8());

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

QString InvoiceApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void InvoiceApi::saveToken(const QString &token) {
    m_token = token;
    m_settings.setValue("auth/token", token);
}

} // namespace NetworkApi
