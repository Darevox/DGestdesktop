// clientapi.cpp
#include "clientapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {

ClientApi::ClientApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

// Helper Methods
Client ClientApi::clientFromJson(const QJsonObject &json) const
{
    Client client;
    client.id = json["id"].toInt();
    client.name = json["name"].toString();
    client.email = json["email"].toString();
    client.phone = json["phone"].toString();
    client.address = json["address"].toString();
    client.tax_number = json["tax_number"].toString();
    client.payment_terms = json["payment_terms"].toString();
    client.notes = json["notes"].toString();
    client.status = json["status"].toString();
    client.balance = json["balance"].toDouble();
    return client;
}

QJsonObject ClientApi::clientToJson(const Client &client) const
{
    QJsonObject json;
    json["name"] = client.name;
    json["email"] = client.email;
    json["phone"] = client.phone;
    json["address"] = client.address;
    json["tax_number"] = client.tax_number;
    json["payment_terms"] = client.payment_terms;
    json["notes"] = client.notes;
    json["status"] = client.status;
    return json;
}

PaginatedClients ClientApi::paginatedClientsFromJson(const QJsonObject &json) const
{
    PaginatedClients result;
    const QJsonObject &meta = json["clients"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(clientFromJson(value.toObject()));
    }

    return result;
}

QVariantMap ClientApi::clientToVariantMap(const Client &client) const
{
    QVariantMap map;
    map["id"] = client.id;
    map["name"] = client.name;
    map["email"] = client.email;
    map["phone"] = client.phone;
    map["address"] = client.address;
    map["tax_number"] = client.tax_number;
    map["payment_terms"] = client.payment_terms;
    map["notes"] = client.notes;
    map["status"] = client.status;
    map["balance"] = client.balance;
    return map;
}

// API Methods
QFuture<void> ClientApi::getClients(const QString &search, const QString &sortBy,
                                   const QString &sortDirection, int page,
                                   const QString &status)
{
    setLoading(true);
    QString path = "/api/clients";

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

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedClients paginatedClients = paginatedClientsFromJson(*response.data);
            emit clientsReceived(paginatedClients);
        } else {
            emit errorClientsReceived(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::getClient(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/clients/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Client client = clientFromJson(response.data->value("client").toObject());
            emit clientReceived(clientToVariantMap(client));
        } else {
            emit errorClientReceived(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::createClient(const Client &client)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/clients");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = clientToJson(client);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Client createdClient = clientFromJson(response.data->value("client").toObject());
            emit clientCreated(createdClient);
        } else {
            emit errorClientCreated(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::updateClient(int id, const Client &client)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/clients/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = clientToJson(client);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Client updatedClient = clientFromJson(response.data->value("client").toObject());
            emit clientUpdated(updatedClient);
        } else {
            emit errorClientUpdated(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::deleteClient(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/clients/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit clientDeleted(id);
        } else {
            emit errorClientDeleted(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::getSales(int id, int page)
{
    setLoading(true);
    QString path = QString("/api/clients/%1/sales").arg(id);
    if (page > 0) {
        path += QString("?page=%1").arg(page);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit salesReceived(response.data->value("sales").toObject().toVariantMap());
        } else {
            emit errorSalesReceived(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::getPayments(int id, int page)
{
    setLoading(true);
    QString path = QString("/api/clients/%1/payments").arg(id);
    if (page > 0) {
        path += QString("?page=%1").arg(page);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit paymentsReceived(response.data->value("payments").toObject().toVariantMap());
        } else {
            emit errorPaymentsReceived(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ClientApi::getStatistics(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/clients/%1/statistics").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit statisticsReceived(response.data->value("statistics").toObject().toVariantMap());
        } else {
            emit errorStatisticsReceived(response.error->message, response.error->status,
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
