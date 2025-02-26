// clientapi.cpp
#include "clientapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;
ClientApi::ClientApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    ,  m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

// Helper Methods
Client ClientApi::clientFromJson(const QJsonObject &json) const
{
    Client client;
    client.id = json["id"_L1].toInt();
    client.name = json["name"_L1].toString();
    client.email = json["email"_L1].toString();
    client.phone = json["phone"_L1].toString();
    client.address = json["address"_L1].toString();
    client.tax_number = json["tax_number"_L1].toString();
    client.payment_terms = json["payment_terms"_L1].toString();
    client.notes = json["notes"_L1].toString();
    client.status = json["status"_L1].toString();
    client.balance = json["balance"_L1].toString().toDouble();
    return client;
}

QJsonObject ClientApi::clientToJson(const Client &client) const
{
    QJsonObject json;
    json["name"_L1] = client.name;
    json["email"_L1] = client.email;
    json["phone"_L1] = client.phone;
    json["address"_L1] = client.address;
    json["tax_number"_L1] = client.tax_number;
    json["payment_terms"_L1] = client.payment_terms;
    json["notes"_L1] = client.notes;
    json["status"_L1] = client.status;
    return json;
}

PaginatedClients ClientApi::paginatedClientsFromJson(const QJsonObject &json) const
{
    PaginatedClients result;
    const QJsonObject &meta = json["clients"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(clientFromJson(value.toObject()));
    }

    return result;
}

QVariantMap ClientApi::clientToVariantMap(const Client &client) const
{
    QVariantMap map;
    map["id"_L1] = client.id;
    map["name"_L1] = client.name;
    map["email"_L1] = client.email;
    map["phone"_L1] = client.phone;
    map["address"_L1] = client.address;
    map["tax_number"_L1] = client.tax_number;
    map["payment_terms"_L1] = client.payment_terms;
    map["notes"_L1] = client.notes;
    map["status"_L1] = client.status;
    map["balance"_L1] = client.balance;
    return map;
}

// API Methods
QFuture<void> ClientApi::getClients(const QString &search, const QString &sortBy,
                                   const QString &sortDirection, int page,
                                   const QString &status)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/clients");

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

    if (!queryParts.isEmpty()) {
       path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedClients paginatedClients = paginatedClientsFromJson(*response.data);
            Q_EMIT clientsReceived(paginatedClients);
        } else {
            Q_EMIT errorClientsReceived(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::getClient(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/clients/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Client client = clientFromJson(response.data->value("client"_L1).toObject());
            Q_EMIT clientReceived(clientToVariantMap(client));
        } else {
            Q_EMIT errorClientReceived(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::createClient(const Client &client)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/clients"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json"_L1);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = clientToJson(client);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Client createdClient = clientFromJson(response.data->value("client"_L1).toObject());
            Q_EMIT clientCreated(createdClient);
        } else {
            Q_EMIT errorClientCreated(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::updateClient(int id, const Client &client)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/clients/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = clientToJson(client);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Client updatedClient = clientFromJson(response.data->value("client"_L1).toObject());
            Q_EMIT clientUpdated(updatedClient);
        } else {
            Q_EMIT errorClientUpdated(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::deleteClient(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/clients/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT clientDeleted(id);
        } else {
            Q_EMIT errorClientDeleted(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::getSales(int id, int page)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/clients/%1/sales").arg(id);
    if (page > 0) {
        path += QStringLiteral("?page=%1").arg(page);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QJsonObject salesObj = response.data->value("sales"_L1).toObject();
            QVariantMap result;

            // Extract pagination data
            result["current_page"_L1] = salesObj["current_page"_L1].toInt();
            result["last_page"_L1] = salesObj["last_page"_L1].toInt();
            result["total"_L1] = salesObj["total"_L1].toInt();
            result["per_page"_L1] = salesObj["per_page"_L1].toInt();

            // Convert sales data array
            QVariantList salesData;
            QJsonArray dataArray = salesObj["data"_L1].toArray();
            for (const QJsonValue &value : dataArray) {
                QJsonObject saleObj = value.toObject();
                QVariantMap sale;

                // Ensure proper data types
                sale["reference_number"_L1] = saleObj["reference_number"_L1].toString();
                sale["sale_date"_L1] = saleObj["sale_date"_L1].toString();
                sale["total_amount"_L1] = saleObj["total_amount"_L1].toString().toDouble();
                sale["paid_amount"_L1] = saleObj["paid_amount"_L1].toString().toDouble();
                sale["balance"_L1] = saleObj["total_amount"_L1].toString().toDouble() -
                                saleObj["paid_amount"_L1].toString().toDouble();
                sale["payment_status"_L1] = saleObj["payment_status"_L1].toString();

                salesData.append(sale);
            }
            result["data"_L1] = salesData;

            Q_EMIT salesReceived(result);
        } else {
            Q_EMIT errorSalesReceived(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}


QFuture<void> ClientApi::getPayments(int id, int page)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/clients/%1/transactions").arg(id);
    if (page > 0) {
        path += QStringLiteral("?page=%1").arg(page);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QVariantMap result;
            QJsonArray transactionsArray = response.data->value("transactions"_L1).toArray();

            // Set pagination data
            result["current_page"_L1] = 1;
            result["last_page"_L1] = 1;
            result["total"_L1] = transactionsArray.size();
            result["per_page"_L1] = transactionsArray.size();

            // Convert transactions data array
            QVariantList paymentsData;
            for (const QJsonValue &value : transactionsArray) {
                QJsonObject transactionObj = value.toObject();
                QVariantMap payment;

                payment["payment_date"_L1] = transactionObj["transaction_date"_L1].toString();
                payment["reference_number"_L1] = transactionObj["reference_number"_L1].toString();
                payment["amount"_L1] = transactionObj["amount"_L1].toString().toDouble();
                payment["payment_method"_L1] = transactionObj["type"_L1].toString();

                // Format sale reference number safely
                int transactionId = transactionObj["transactionable_id"_L1].toInt();
                QString formattedId = QStringLiteral("%1").arg(transactionId, 6, 10, QLatin1Char('0'));
                payment["sale_reference"_L1] = QStringLiteral("SALE-").append(formattedId);

                paymentsData.append(payment);
            }
            result["data"_L1] = paymentsData;

            Q_EMIT paymentsReceived(result);
        } else {
            Q_EMIT errorPaymentsReceived(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

// ClientApi.cpp
// ClientApi.cpp
QFuture<void> ClientApi::getStatistics(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/clients/%1/statement").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            // Just pass the whole response data
            Q_EMIT statisticsReceived(response.data->toVariantMap());
        } else {
            Q_EMIT errorStatisticsReceived(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}


QString ClientApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void ClientApi::saveToken(const QString &token) {
    m_token = token;
    m_settings.setValue("auth/token", token);
}

} // namespace NetworkApi
