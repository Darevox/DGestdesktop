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
    source.balance = json["balance"].toString().toDouble();
    source.initial_balance = json["initial_balance"].toString().toDouble();
    source.account_number = json["account_number"].toString();
    source.bank_name = json["bank_name"].toString();
    source.status = json["status"].toString();
    source.is_default = json["is_default"].toBool();
    return source;
}

QJsonObject CashSourceApi::cashSourceToJson(const CashSource &source) const
{
    QJsonObject json;

    // Only include non-empty values
    if (!source.name.isEmpty()) {
        json["name"] = source.name;
    }

    if (!source.type.isEmpty()) {
        json["type"] = source.type;
    }

    if (!source.description.isEmpty()) {
        json["description"] = source.description;
    }

    if (!source.account_number.isEmpty()) {
        json["account_number"] = source.account_number;
    }

    if (!source.bank_name.isEmpty()) {
        json["bank_name"] = source.bank_name;
    }

    if (!source.status.isEmpty()) {
        json["status"] = source.status;
    }

    // Include initial_balance if it's set (for new sources)
    if (source.initial_balance > 0) {
        json["initial_balance"] = source.initial_balance;
    }

    // Always include is_default as it's a boolean
    json["is_default"] = source.is_default;

    qDebug() << "Generated JSON for update:" << QJsonDocument(json).toJson();

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
    map["initial_balance"] = source.initial_balance;
    map["account_number"] = source.account_number;
    map["bank_name"] = source.bank_name;
    map["status"] = source.status;
    map["isDefault"] = source.is_default;
    return map;
}

QVariantMap CashSourceApi::transactionToVariantMap(const QJsonObject &json) const
{
    QVariantMap map;
    map["id"] = json["id"].toInt();
    map["team_id"] = json["team_id"].toInt();
    map["cash_source_id"] = json["cash_source_id"].toInt();
    map["transactionable_type"] = json["transactionable_type"].toString();
    map["transactionable_id"] = json["transactionable_id"].toInt();
    map["type"] = json["type"].toString();
    map["amount"] = json["amount"].toDouble();
    map["description"] = json["description"].toString();
    map["reference_number"] = json["reference_number"].toString();
    map["transfer_destination_id"] = json["transfer_destination_id"].toInt();
    map["transaction_date"] = json["transaction_date"].toString();

    // Include related cash source if present
    if (json.contains("cash_source")) {
        map["cash_source"] = cashSourceToVariantMap(
            cashSourceFromJson(json["cash_source"].toObject())
        );
    }

    // Include destination cash source for transfers
    if (json.contains("transfer_destination")) {
        map["transfer_destination"] = cashSourceToVariantMap(
            cashSourceFromJson(json["transfer_destination"].toObject())
        );
    }

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
    QString path = "/api/v1/cash-sources";

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
    QNetworkRequest request = createRequest(QString("/api/v1/cash-sources/%1").arg(id));
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
    QNetworkRequest request = createRequest("/api/v1/cash-sources");
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
    QNetworkRequest request = createRequest(QString("/api/v1/cash-sources/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = cashSourceToJson(source);

    // Debug output
    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Updating cash source. URL:" << request.url().toString();
    qDebug() << "Request data:" << QString(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Update success response:" << *response.data;
            CashSource updatedSource = cashSourceFromJson(response.data->value("cash_source").toObject());
            emit cashSourceUpdated(updatedSource);
        } else {
            qDebug() << "Update error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
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
    QNetworkRequest request = createRequest(QString("/api/v1/cash-sources/%1").arg(id));
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
    QNetworkRequest request = createRequest(QString("/api/v1/cash-sources/%1/deposit").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"] = amount;
    jsonData["description"] = notes;  // Changed from 'notes' to 'description'

    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Sending deposit request to:" << request.url().toString();
    qDebug() << "Request data:" << QString(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Deposit success response:" << *response.data;
            QJsonObject transaction = response.data->value("transaction").toObject();
            emit depositCompleted(transactionToVariantMap(transaction));

            // You might want to emit a signal for the updated cash source as well
            if (response.data->contains("cash_source")) {
                CashSource updatedSource = cashSourceFromJson(response.data->value("cash_source").toObject());
                emit cashSourceUpdated(updatedSource);
            }
        } else {
            qDebug() << "Deposit error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
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
    QNetworkRequest request = createRequest(QString("/api/v1/cash-sources/%1/withdraw").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"] = amount;
    jsonData["description"] = notes;  // Changed from 'notes' to 'description'

    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Sending withdrawal request to:" << request.url().toString();
    qDebug() << "Request data:" << QString(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Withdrawal success response:" << *response.data;
            QJsonObject transaction = response.data->value("transaction").toObject();
            emit withdrawalCompleted(transactionToVariantMap(transaction));

            // Also emit signal for updated cash source
            if (response.data->contains("cash_source")) {
                CashSource updatedSource = cashSourceFromJson(response.data->value("cash_source").toObject());
                emit cashSourceUpdated(updatedSource);
            }
        } else {
            qDebug() << "Withdrawal error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
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
    QNetworkRequest request = createRequest(QString("/api/v1/cash-sources/%1/transfer").arg(transferData.sourceId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["destination_id"] = transferData.destinationId;
    jsonData["amount"] = transferData.amount;
    jsonData["description"] = transferData.notes;  // Changed from 'notes' to 'description'

    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Sending transfer request to:" << request.url().toString();
    qDebug() << "Request data:" << QString(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Transfer success response:" << *response.data;
            QJsonObject transaction = response.data->value("transaction").toObject();
            emit transferCompleted(transactionToVariantMap(transaction));

            // Emit signals for updated cash sources
            if (response.data->contains("source_account")) {
                CashSource sourceAccount = cashSourceFromJson(response.data->value("source_account").toObject());
                emit cashSourceUpdated(sourceAccount);
            }
            if (response.data->contains("destination_account")) {
                CashSource destAccount = cashSourceFromJson(response.data->value("destination_account").toObject());
                emit cashSourceUpdated(destAccount);
            }
        } else {
            qDebug() << "Transfer error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
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
