// invoiceapi.cpp
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
    invoice.reference_number = json["reference_number"].toString();
    invoice.invoice_date = QDateTime::fromString(json["invoice_date"].toString(), Qt::ISODate);
    invoice.due_date = QDateTime::fromString(json["due_date"].toString(), Qt::ISODate);
    invoice.client_id = json["client_id"].toInt();
    invoice.status = json["status"].toString();
    invoice.payment_status = json["payment_status"].toString();
    invoice.subtotal = json["subtotal"].toDouble();
    invoice.tax_rate = json["tax_rate"].toDouble();
    invoice.tax_amount = json["tax_amount"].toDouble();
    invoice.total_amount = json["total_amount"].toDouble();
    invoice.paid_amount = json["paid_amount"].toDouble();
    invoice.remaining_amount = json["remaining_amount"].toDouble();
    invoice.notes = json["notes"].toString();
    invoice.terms_conditions = json["terms_conditions"].toString();

    if (json.contains("client") && !json["client"].isNull()) {
        invoice.client = json["client"].toObject().toVariantMap();
    }

    if (json.contains("items")) {
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
    json["client_id"] = invoice.client_id;
    json["invoice_date"] = invoice.invoice_date.toString(Qt::ISODate);
    json["due_date"] = invoice.due_date.toString(Qt::ISODate);
    json["notes"] = invoice.notes;
    json["terms_conditions"] = invoice.terms_conditions;
    json["tax_rate"] = invoice.tax_rate;

    QJsonArray itemsArray;
    for (const InvoiceItem &item : invoice.items) {
        itemsArray.append(invoiceItemToJson(item));
    }
    json["items"] = itemsArray;

    return json;
}

QJsonObject InvoiceApi::invoiceItemToJson(const InvoiceItem &item) const
{
    QJsonObject json;
    json["description"] = item.description;
    json["quantity"] = item.quantity;
    json["unit_price"] = item.unit_price;
    json["notes"] = item.notes;
    return json;
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

QVariantMap InvoiceApi::invoiceToVariantMap(const Invoice &invoice) const
{
    QVariantMap map;
    map["id"] = invoice.id;
    map["reference_number"] = invoice.reference_number;
    map["invoice_date"] = invoice.invoice_date;
    map["due_date"] = invoice.due_date;
    map["client_id"] = invoice.client_id;
    map["client"] = invoice.client;
    map["status"] = invoice.status;
    map["payment_status"] = invoice.payment_status;
    map["subtotal"] = invoice.subtotal;
    map["tax_rate"] = invoice.tax_rate;
    map["tax_amount"] = invoice.tax_amount;
    map["total_amount"] = invoice.total_amount;
    map["paid_amount"] = invoice.paid_amount;
    map["remaining_amount"] = invoice.remaining_amount;
    map["notes"] = invoice.notes;
    map["terms_conditions"] = invoice.terms_conditions;

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

// API Methods
QFuture<void> InvoiceApi::getInvoices(const QString &search, const QString &sortBy,
                                     const QString &sortDirection, int page,
                                     const QString &status, const QString &paymentStatus)
{
    setLoading(true);
    QString path = "/api/invoices";

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
    QNetworkRequest request = createRequest(QString("/api/invoices/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

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
    QNetworkRequest request = createRequest("/api/invoices");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

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
    QNetworkRequest request = createRequest(QString("/api/invoices/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

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
    QNetworkRequest request = createRequest(QString("/api/invoices/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

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
    QNetworkRequest request = createRequest(QString("/api/invoices/%1/add-payment").arg(id));
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

QFuture<void> InvoiceApi::generatePdf(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/invoices/%1/generate-pdf").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit pdfGenerated(response.data->value("pdf_url").toString());
        } else {
            emit errorPdfGenerated(response.error->message, response.error->status,
                                 QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> InvoiceApi::sendToClient(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/invoices/%1/send").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

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
    QNetworkRequest request = createRequest(QString("/api/invoices/%1/mark-as-sent").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit invoiceMarkedAsSent(response.data->value("invoice").toObject().toVariantMap());
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
    QNetworkRequest request = createRequest(QString("/api/invoices/%1/mark-as-paid").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit invoiceMarkedAsPaid(response.data->value("invoice").toObject().toVariantMap());
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
    QString path = "/api/invoices/summary";
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

QString InvoiceApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void InvoiceApi::saveToken(const QString &token) {
    m_token = token;
    m_settings.setValue("auth/token", token);
}

} // namespace NetworkApi
