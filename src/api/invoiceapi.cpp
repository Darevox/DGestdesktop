#include "invoiceapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;

InvoiceApi::InvoiceApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    ,  m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

// Helper Methods
Invoice InvoiceApi::invoiceFromJson(const QJsonObject &json) const
{
    Invoice invoice;
    invoice.id = json["id"_L1].toInt();
    invoice.team_id = json["team_id"_L1].toInt();
    invoice.reference_number = json["reference_number"_L1].toString();
    invoice.invoiceable_type = json["invoiceable_type"_L1].toString();
    invoice.invoiceable_id = json["invoiceable_id"_L1].toInt();
    invoice.total_amount = json["total_amount"_L1].toString().toDouble();
    invoice.tax_amount = json["tax_amount"_L1].toString().toDouble();
    invoice.discount_amount = json["discount_amount"_L1].toString().toDouble();
    invoice.status = json["status"_L1].toString();
    invoice.issue_date = QDateTime::fromString(json["issue_date"_L1].toString(), Qt::ISODate);
    invoice.due_date = QDateTime::fromString(json["due_date"_L1].toString(), Qt::ISODate);
    invoice.notes = json["notes"_L1].toString();

    // Handle meta_data
    if (json.contains("meta_data"_L1) && !json["meta_data"_L1].isNull()) {
        invoice.meta_data = json["meta_data"_L1].toObject().toVariantMap();
    }

    // Handle morphed relationship data (invoiceable)
    if (json.contains("invoiceable"_L1) && !json["invoiceable"_L1].isNull()) {
        QJsonObject invoiceable = json["invoiceable"_L1].toObject();
        invoice.meta_data.insert("invoiceable_data"_L1, invoiceable.toVariantMap());
    }

    // Handle items if present
    if (json.contains("items"_L1) && json["items"_L1].isArray()) {
        const QJsonArray itemsArray = json["items"_L1].toArray();
        for (const QJsonValue &value : itemsArray) {
            invoice.items.append(invoiceItemFromJson(value.toObject()));
        }
    }

    return invoice;
}

InvoiceItem InvoiceApi::invoiceItemFromJson(const QJsonObject &json) const
{
    InvoiceItem item;
    item.id = json["id"_L1].toInt();
    item.description = json["description"_L1].toString();
    item.quantity = json["quantity"_L1].toInt();
    item.unit_price = json["unit_price"_L1].toDouble();
    item.total_price = json["total_price"_L1].toDouble();
    item.notes = json["notes"_L1].toString();
    return item;
}

QJsonObject InvoiceApi::invoiceToJson(const Invoice &invoice) const
{
    QJsonObject json;
    json["team_id"_L1] = invoice.team_id;
    json["reference_number"_L1] = invoice.reference_number;
    json["invoiceable_type"_L1] = invoice.invoiceable_type;
    json["invoiceable_id"_L1] = invoice.invoiceable_id;
    json["total_amount"_L1] = invoice.total_amount;
    json["tax_amount"_L1] = invoice.tax_amount;
    json["discount_amount"_L1] = invoice.discount_amount;
    json["status"_L1] = invoice.status;
    json["issue_date"_L1] = invoice.issue_date.toString(Qt::ISODate);
    json["due_date"_L1] = invoice.due_date.toString(Qt::ISODate);
    json["notes"_L1] = invoice.notes;

    if (!invoice.meta_data.isEmpty()) {
        json["meta_data"_L1] = QJsonObject::fromVariantMap(invoice.meta_data);
    }

    if (!invoice.items.isEmpty()) {
        QJsonArray itemsArray;
        for (const InvoiceItem &item : invoice.items) {
            itemsArray.append(invoiceItemToJson(item));
        }
        json["items"_L1] = itemsArray;
    }
    QJsonDocument doc(json);
    QByteArray jsonData = doc.toJson(QJsonDocument::Indented);
    qDebug()<<"DATA in CPP : " <<jsonData;
    return json;
}

QJsonObject InvoiceApi::invoiceItemToJson(const InvoiceItem &item) const
{
    QJsonObject json;
    json["description"_L1] = item.description;
    json["quantity"_L1] = item.quantity;
    json["unit_price"_L1] = item.unit_price;
    json["total_price"_L1] = item.unit_price * item.quantity;
    json["notes"_L1] = item.notes;
    return json;
}

QVariantMap InvoiceApi::invoiceToVariantMap(const Invoice &invoice) const
{
    QVariantMap map;

    // Core database fields
    map["id"_L1] = invoice.id;
    map["team_id"_L1] = invoice.team_id;
    map["reference_number"_L1] = invoice.reference_number;
    map["invoiceable_type"_L1] = invoice.invoiceable_type;
    map["invoiceable_id"_L1] = invoice.invoiceable_id;
    map["total_amount"_L1] = invoice.total_amount;
    map["tax_amount"_L1] = invoice.tax_amount;
    map["discount_amount"_L1] = invoice.discount_amount;
    map["status"_L1] = invoice.status;
    map["issue_date"_L1] = invoice.issue_date;
    map["due_date"_L1] = invoice.due_date;
    map["notes"_L1] = invoice.notes;
    map["meta_data"_L1] = invoice.meta_data;

    // UI compatibility fields (computed or from meta_data)
    map["invoice_date"_L1] = invoice.issue_date;  // Alias for backward compatibility
    map["client_id"_L1] = invoice.getClientId();
    map["client"_L1] = invoice.getClient();
    map["payment_status"_L1] = invoice.getPaymentStatus();
    map["subtotal"_L1] = invoice.getSubtotal();
    map["paid_amount"_L1] = invoice.getPaidAmount();
    map["remaining_amount"_L1] = invoice.getRemainingAmount();
    map["terms_conditions"_L1] = invoice.getTermsConditions();

    // Items
    QVariantList itemsList;
    for (const InvoiceItem &item : invoice.items) {
        itemsList.append(invoiceItemToVariantMap(item));
    }
    map["items"_L1] = itemsList;

    return map;
}

QVariantMap InvoiceApi::invoiceItemToVariantMap(const InvoiceItem &item) const
{
    QVariantMap map;
    map["id"_L1] = item.id;
    map["description"_L1] = item.description;
    map["quantity"_L1] = item.quantity;
    map["unit_price"_L1] = item.unit_price;
    map["total_price"_L1] = item.total_price;
    map["notes"_L1] = item.notes;
    return map;
}

QJsonObject InvoiceApi::paymentToJson(const InvoicePayment &payment) const
{
    QJsonObject json;
    json["cash_source_id"_L1] = payment.cash_source_id;
    json["amount"_L1] = payment.amount;
    json["payment_method"_L1] = payment.payment_method;
    json["reference_number"_L1] = payment.reference_number;
    json["notes"_L1] = payment.notes;
    return json;
}

PaginatedInvoices InvoiceApi::paginatedInvoicesFromJson(const QJsonObject &json) const
{
    PaginatedInvoices result;
    const QJsonObject &meta = json["invoices"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(invoiceFromJson(value.toObject()));
    }

    return result;
}

QFuture<void> InvoiceApi::getInvoices(const QString &search, const QString &sortBy,
                                     const QString &sortDirection, int page,
                                     const QString &status, const QString &paymentStatus,
                                      const QDateTime &startDate,
                                      const QDateTime &endDate
                                      )
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/invoices");

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
    if (startDate.isValid())
        queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(Qt::ISODate));
    if (endDate.isValid())
        queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(Qt::ISODate));
    if (!queryParts.isEmpty()) {
        path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedInvoices paginatedInvoices = paginatedInvoicesFromJson(*response.data);
            Q_EMIT invoicesReceived(paginatedInvoices);
        } else {
            Q_EMIT errorInvoicesReceived(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::getInvoice(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice invoice = invoiceFromJson(response.data->value("invoice"_L1).toObject());
            Q_EMIT invoiceReceived(invoiceToVariantMap(invoice));
        } else {
            Q_EMIT errorInvoiceReceived(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::createInvoice(const Invoice &invoice)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    QJsonObject jsonData = invoiceToJson(invoice);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice createdInvoice = invoiceFromJson(response.data->value("invoice"_L1).toObject());
            Q_EMIT invoiceCreated(createdInvoice);
        } else {
            Q_EMIT errorInvoiceCreated(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::updateInvoice(int id, const Invoice &invoice)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader,  QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    QJsonObject jsonData = invoiceToJson(invoice);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice updatedInvoice = invoiceFromJson(response.data->value("invoice"_L1).toObject());
            Q_EMIT invoiceUpdated(updatedInvoice);
        } else {
            Q_EMIT errorInvoiceUpdated(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::deleteInvoice(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT invoiceDeleted(id);
        } else {
            Q_EMIT errorInvoiceDeleted(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::addPayment(int id, const InvoicePayment &payment)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1/payments").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader,  QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

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
QFuture<QByteArray> InvoiceApi::generatePdf(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1/download").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto promise = std::make_shared<QPromise<QByteArray>>();

    m_currentReply = m_netManager->get(request);

    connect(m_currentReply, &QNetworkReply::finished, this, [this, promise]() {
        setLoading(false);

        if (m_currentReply->error() == QNetworkReply::NoError) {
            // Get the content type
            QString contentType = m_currentReply->header(QNetworkRequest::ContentTypeHeader).toString();

            if (contentType.contains("application/pdf"_L1)) {
                QByteArray pdfData = m_currentReply->readAll();

                // Save to app's data location instead of /tmp
                QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
                QDir().mkpath(QStringLiteral("%1/pdfs").arg(appDataPath));

                QString fileName = QStringLiteral("invoice-%1.pdf").arg(QDateTime::currentMSecsSinceEpoch());
                QString filePath = QStringLiteral("%1/pdfs/%2").arg(appDataPath, fileName);

                QFile file(filePath);
                if (file.open(QIODevice::WriteOnly)) {
                    file.write(pdfData);
                    file.close();

                    QString fileUrl = QUrl::fromLocalFile(filePath).toString();
                    qDebug() << "PDF saved to:" << fileUrl;
                    Q_EMIT pdfGenerated(fileUrl);
                    promise->addResult(pdfData);
                     setLoading(false);
                } else {
                    Q_EMIT errorPdfGenerated("Failed to save PDF"_L1, file.errorString());
                    promise->addResult(QByteArray());
                }
            } else if (contentType.contains("application/json"_L1)) {
                // Handle error response
                QJsonDocument jsonResponse = QJsonDocument::fromJson(m_currentReply->readAll());
                QJsonObject jsonObject = jsonResponse.object();
                QString errorMessage = jsonObject["message"_L1].toString();
                Q_EMIT errorPdfGenerated("Error"_L1, errorMessage);
                promise->addResult(QByteArray());
            }
        } else {
            Q_EMIT errorPdfGenerated("Network Error"_L1, m_currentReply->errorString());
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
//     QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1/download").arg(id));
//     request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

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

//                 QString fileName = QStringLiteral("invoice-%1.pdf").arg(QDateTime::currentMSecsSinceEpoch());
//                 QString filePath = QDir(tempPath).filePath(fileName);

//                 QFile file(filePath);
//                 if (file.open(QIODevice::WriteOnly)) {
//                     qint64 bytesWritten = file.write(pdfData);
//                     file.close();

//                     if (bytesWritten > 0) {
//                         QString fileUrl = QUrl::fromLocalFile(filePath).toString();
//                         qDebug() << "PDF saved to:" << fileUrl;
//                         Q_EMIT pdfGenerated(fileUrl);
//                         promise->addResult(pdfData);
//                     } else {
//                         throw std::runtime_error("Failed to write PDF data");
//                     }
//                 } else {
//                     throw std::runtime_error(file.errorString().toStdString());
//                 }
//             } catch (const std::exception& e) {
//                 qWarning() << "Error saving PDF:" << e.what();
//                 Q_EMIT errorPdfGenerated("Failed to save PDF", QString::fromStdString(e.what()));
//                 promise->addResult(QByteArray());
//             }
//         } else {
//             qWarning() << "Network error:" << m_currentReply->errorString();
//             Q_EMIT errorPdfGenerated("Failed to download PDF", m_currentReply->errorString());
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
//         Q_EMIT errorPdfGenerated("Network error", m_currentReply->errorString());
//         promise->addResult(QByteArray());
//         promise->finish();
//     });

//     return promise->future();
// }

QFuture<void> InvoiceApi::sendToClient(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1/send").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Q_EMIT invoiceSent(response.data->value("result"_L1).toObject().toVariantMap());
        } else {
            Q_EMIT errorInvoiceSent(response.error->message, response.error->status,
                                QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::markAsSent(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1/mark-as-sent").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice invoice = invoiceFromJson(response.data->value("invoice"_L1).toObject());
            Q_EMIT invoiceMarkedAsSent(invoiceToVariantMap(invoice));
        } else {
            Q_EMIT errorInvoiceMarkedAsSent(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::markAsPaid(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/invoices/%1/mark-as-paid").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Invoice invoice = invoiceFromJson(response.data->value("invoice"_L1).toObject());
            Q_EMIT invoiceMarkedAsPaid(invoiceToVariantMap(invoice));
        } else {
            Q_EMIT errorInvoiceMarkedAsPaid(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::getSummary(const QString &period)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/invoices/summary");
    if (!period.isEmpty()) {
        path += QStringLiteral("?period=%1").arg(period);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

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

QString InvoiceApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void InvoiceApi::saveToken(const QString &token) {
    m_token = token;
    m_settings.setValue("auth/token", token);
}

} // namespace NetworkApi
