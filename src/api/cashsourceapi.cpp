// cashsourceapi.cpp (complete implementation)
#include "cashsourceapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {

CashSource CashSourceApi::cashSourceFromJson(const QJsonObject &json) const
{
    CashSource source;
    source.id = json["id"].toInt();
    source.name = json["name"].toString();
    source.description = json["description"].toString();
    source.type = json["type"].toString();
    source.balance = json["balance"].toDouble();
    source.status = json["status"].toString();
    source.is_default = json["is_default"].toBool();
    return source;
}

QJsonObject CashSourceApi::cashSourceToJson(const CashSource &source) const
{
    QJsonObject json;
    json["name"] = source.name;
    json["description"] = source.description;
    json["type"] = source.type;
    json["status"] = source.status;
    json["is_default"] = source.is_default;
    return json;
}

PaginatedCashSources CashSourceApi::paginatedCashSourcesFromJson(const QJsonObject &json) const
{
    PaginatedCashSources result;
    const QJsonObject &meta = json["cash_sources"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(cashSourceFromJson(value.toObject()));
    }

    return result;
}

QVariantMap CashSourceApi::cashSourceToVariantMap(const CashSource &source) const
{
    QVariantMap map;
    map["id"] = source.id;
    map["name"] = source.name;
    map["description"] = source.description;
    map["type"] = source.type;
    map["balance"] = source.balance;
    map["status"] = source.status;
    map["is_default"] = source.is_default;
    return map;
}

QVariantMap CashSourceApi::transactionToVariantMap(const QJsonObject &json) const
{
    QVariantMap map;
    map["id"] = json["id"].toInt();
    map["cash_source_id"] = json["cash_source_id"].toInt();
    map["type"] = json["type"].toString();
    map["amount"] = json["amount"].toDouble();
    map["notes"] = json["notes"].toString();
    map["transaction_date"] = json["transaction_date"].toString();
    map["reference_number"] = json["reference_number"].toString();

    // Include related cash source if present
    // if (json.contains("cash_source")) {
    //     map["cash_source"] = cashSourceToVariantMap(json["cash_source"].toObject());
    // }

    // // Include destination cash source for transfers
    // if (json.contains("destination_cash_source")) {
    //     map["destination_cash_source"] = cashSourceToVariantMap(
    //         json["destination_cash_source"].toObject());
    // }

    return map;
}

CashSourceApi::CashSourceApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

QFuture<void> CashSourceApi::getCashSources(const QString &search, const QString &sortBy,
                                          const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = "/api/cash-sources";

    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QString("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QString("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QString("sort_direction=%1").arg(sortDirection);
    if (page > 0)
        queryParts << QString("page=%1").arg(page);

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedCashSources paginatedSources = paginatedCashSourcesFromJson(*response.data);
            emit cashSourcesReceived(paginatedSources);
        } else {
            emit errorCashSourcesReceived(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::getCashSource(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-sources/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashSource source = cashSourceFromJson(response.data->value("cash_source").toObject());
            emit cashSourceReceived(cashSourceToVariantMap(source));
        } else {


                emit errorCashSourceReceived(response.error->message, response.error->status,
                                          QJsonDocument(response.error->details).toJson());

        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::createCashSource(const CashSource &source)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/cash-sources");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = cashSourceToJson(source);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashSource createdSource = cashSourceFromJson(response.data->value("cash_source").toObject());
            emit cashSourceCreated(createdSource);
        } else {
            emit errorCashSourceCreated(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::updateCashSource(int id, const CashSource &source)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-sources/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = cashSourceToJson(source);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashSource updatedSource = cashSourceFromJson(response.data->value("cash_source").toObject());
            emit cashSourceUpdated(updatedSource);
        } else {
            emit errorCashSourceUpdated(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::deleteCashSource(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-sources/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit cashSourceDeleted(id);
        } else {
            emit errorCashSourceDeleted(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::deposit(int id, double amount, const QString &notes)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-sources/%1/deposit").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"] = amount;
    jsonData["notes"] = notes;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit depositCompleted(transactionToVariantMap(response.data->value("transaction").toObject()));
        } else {
            emit errorDeposit(response.error->message, response.error->status,
                            QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::withdraw(int id, double amount, const QString &notes)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-sources/%1/withdraw").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"] = amount;
    jsonData["notes"] = notes;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit withdrawalCompleted(transactionToVariantMap(response.data->value("transaction").toObject()));
        } else {
            emit errorWithdrawal(response.error->message, response.error->status,
                               QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::transfer(const TransferData &transferData)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-sources/%1/transfer").arg(transferData.sourceId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["destination_id"] = transferData.destinationId;
    jsonData["amount"] = transferData.amount;
    jsonData["notes"] = transferData.notes;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit transferCompleted(transactionToVariantMap(response.data->value("transaction").toObject()));
        } else {
            emit errorTransfer(response.error->message, response.error->status,
                             QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QString CashSourceApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void CashSourceApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
