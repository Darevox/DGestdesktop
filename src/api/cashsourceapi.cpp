// cashsourceapi.cpp (complete implementation)
#include "cashsourceapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;
CashSource CashSourceApi::cashSourceFromJson(const QJsonObject &json) const
{
    CashSource source;
    source.id = json["id"_L1].toInt();
    source.name = json["name"_L1].toString();
    source.description = json["description"_L1].toString();
    source.type = json["type"_L1].toString();
    source.balance = json["balance"_L1].toString().toDouble();
    source.initial_balance = json["initial_balance"_L1].toString().toDouble();
    source.account_number = json["account_number"_L1].toString();
    source.bank_name = json["bank_name"_L1].toString();
    source.status = json["status"_L1].toString();
    source.is_default = json["is_default"_L1].toBool();
    return source;
}

QJsonObject CashSourceApi::cashSourceToJson(const CashSource &source) const
{
    QJsonObject json;

    // Only include non-empty values
    if (!source.name.isEmpty()) {
        json["name"_L1] = source.name;
    }

    if (!source.type.isEmpty()) {
        json["type"_L1] = source.type;
    }

    if (!source.description.isEmpty()) {
        json["description"_L1] = source.description;
    }

    if (!source.account_number.isEmpty()) {
        json["account_number"_L1] = source.account_number;
    }

    if (!source.bank_name.isEmpty()) {
        json["bank_name"_L1] = source.bank_name;
    }

    if (!source.status.isEmpty()) {
        json["status"_L1] = source.status;
    }

    // Include initial_balance if it's set (for new sources)
    if (source.initial_balance > 0) {
        json["initial_balance"_L1] = source.initial_balance;
    }

    // Always include is_default as it's a boolean
    json["is_default"_L1] = source.is_default;

    qDebug() << "Generated JSON for update:" << QJsonDocument(json).toJson();

    return json;
}



PaginatedCashSources CashSourceApi::paginatedCashSourcesFromJson(const QJsonObject &json) const
{
    PaginatedCashSources result;
    const QJsonObject &meta = json["cash_sources"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(cashSourceFromJson(value.toObject()));
    }

    return result;
}

QVariantMap CashSourceApi::cashSourceToVariantMap(const CashSource &source) const
{
    QVariantMap map;
    map["id"_L1] = source.id;
    map["name"_L1] = source.name;
    map["description"_L1] = source.description;
    map["type"_L1] = source.type;
    map["balance"_L1] = source.balance;
    map["initial_balance"_L1] = source.initial_balance;
    map["account_number"_L1] = source.account_number;
    map["bank_name"_L1] = source.bank_name;
    map["status"_L1] = source.status;
    map["isDefault"_L1] = source.is_default;
    return map;
}

QVariantMap CashSourceApi::transactionToVariantMap(const QJsonObject &json) const
{
    QVariantMap map;
    map["id"_L1] = json["id"_L1].toInt();
    map["team_id"_L1] = json["team_id"_L1].toInt();
    map["cash_source_id"_L1] = json["cash_source_id"_L1].toInt();
    map["transactionable_type"_L1] = json["transactionable_type"_L1].toString();
    map["transactionable_id"_L1] = json["transactionable_id"_L1].toInt();
    map["type"_L1] = json["type"_L1].toString();
    map["amount"_L1] = json["amount"_L1].toDouble();
    map["description"_L1] = json["description"_L1].toString();
    map["reference_number"_L1] = json["reference_number"_L1].toString();
    map["transfer_destination_id"_L1] = json["transfer_destination_id"_L1].toInt();
    map["transaction_date"_L1] = json["transaction_date"_L1].toString();

    // Include related cash source if present
    if (json.contains(QStringLiteral("cash_source"))) {
        map["cash_source"_L1] = cashSourceToVariantMap(
                    cashSourceFromJson(json["cash_source"_L1].toObject())
                    );
    }

    // Include destination cash source for transfers
    if (json.contains(QStringLiteral("transfer_destination"))) {
        map["transfer_destination"_L1] = cashSourceToVariantMap(
                    cashSourceFromJson(json["transfer_destination"_L1].toObject())
                    );
    }

    return map;
}


CashSourceApi::CashSourceApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

QFuture<void> CashSourceApi::getCashSources(const QString &search, const QString &sortBy,
                                            const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/cash-sources");

    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QStringLiteral("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QStringLiteral("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QStringLiteral("sort_direction=%1").arg(sortDirection);
    if (page > 0)
        queryParts << QStringLiteral("page=%1").arg(page);

    if (!queryParts.isEmpty()) {
         path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedCashSources paginatedSources = paginatedCashSourcesFromJson(*response.data);
            Q_EMIT cashSourcesReceived(paginatedSources);
        } else {
            Q_EMIT errorCashSourcesReceived(response.error->message, response.error->status,
                                          QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::getCashSource(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/cash-sources/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashSource source = cashSourceFromJson(response.data->value("cash_source"_L1).toObject());
            Q_EMIT cashSourceReceived(cashSourceToVariantMap(source));
        } else {


            Q_EMIT errorCashSourceReceived(response.error->message, response.error->status,
                                         QJsonDocument(response.error->details).toJson());

        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::createCashSource(const CashSource &source)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/cash-sources"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = cashSourceToJson(source);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashSource createdSource = cashSourceFromJson(response.data->value("cash_source"_L1).toObject());
            Q_EMIT cashSourceCreated(createdSource);
        } else {
            Q_EMIT errorCashSourceCreated(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::updateCashSource(int id, const CashSource &source)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/cash-sources/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = cashSourceToJson(source);

    // Debug output
    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Updating cash source. URL:" << request.url().toString();
 //   qDebug() << "Request data:" << QStringLiteral(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Update success response:" << *response.data;
            CashSource updatedSource = cashSourceFromJson(response.data->value("cash_source"_L1).toObject());
            Q_EMIT cashSourceUpdated(updatedSource);
        } else {
            qDebug() << "Update error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
            Q_EMIT errorCashSourceUpdated(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::deleteCashSource(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/cash-sources/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT cashSourceDeleted(id);
        } else {
            Q_EMIT errorCashSourceDeleted(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::deposit(int id, double amount, const QString &notes)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/cash-sources/%1/deposit").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"_L1] = amount;
    jsonData["description"_L1] = notes;  // Changed from 'notes' to 'description'

    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Sending deposit request to:" << request.url().toString();
    //qDebug() << "Request data:" << QStringLiteral(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Deposit success response:" << *response.data;
            QJsonObject transaction = response.data->value("transaction"_L1).toObject();
            Q_EMIT depositCompleted(transactionToVariantMap(transaction));

            // You might want to emit a signal for the updated cash source as well
            if (response.data->contains("cash_source"_L1)) {
                CashSource updatedSource = cashSourceFromJson(response.data->value("cash_source"_L1).toObject());
                Q_EMIT cashSourceUpdated(updatedSource);
            }
        } else {
            qDebug() << "Deposit error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
            Q_EMIT errorDeposit(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}


QFuture<void> CashSourceApi::withdraw(int id, double amount, const QString &notes)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/cash-sources/%1/withdraw").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["amount"_L1] = amount;
    jsonData["description"_L1] = notes;  // Changed from 'notes' to 'description'

    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Sending withdrawal request to:" << request.url().toString();
  //  qDebug() << "Request data:" << QStringLiteral(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Withdrawal success response:" << *response.data;
            QJsonObject transaction = response.data->value("transaction"_L1).toObject();
            Q_EMIT withdrawalCompleted(transactionToVariantMap(transaction));

            // Also emit signal for updated cash source
            if (response.data->contains("cash_source"_L1)) {
                CashSource updatedSource = cashSourceFromJson(response.data->value("cash_source"_L1).toObject());
                Q_EMIT cashSourceUpdated(updatedSource);
            }
        } else {
            qDebug() << "Withdrawal error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
            Q_EMIT errorWithdrawal(response.error->message, response.error->status,
                                 QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashSourceApi::transfer(const TransferData &transferData)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/cash-sources/%1/transfer").arg(transferData.sourceId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["destination_id"_L1] = transferData.destinationId;
    jsonData["amount"_L1] = transferData.amount;
    jsonData["description"_L1] = transferData.notes;  // Changed from 'notes' to 'description'

    QJsonDocument doc(jsonData);
    QByteArray jsonString = doc.toJson();
    qDebug() << "Sending transfer request to:" << request.url().toString();
   // qDebug() << "Request data:" << QStringLiteral(jsonString);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, jsonString);
    }).then([=](JsonResponse response) {
        if (response.success) {
            qDebug() << "Transfer success response:" << *response.data;
            QJsonObject transaction = response.data->value("transaction"_L1).toObject();
            Q_EMIT transferCompleted(transactionToVariantMap(transaction));

            // Emit signals for updated cash sources
            if (response.data->contains("source_account"_L1)) {
                CashSource sourceAccount = cashSourceFromJson(response.data->value("source_account"_L1).toObject());
                Q_EMIT cashSourceUpdated(sourceAccount);
            }
            if (response.data->contains("destination_account"_L1)) {
                CashSource destAccount = cashSourceFromJson(response.data->value("destination_account"_L1).toObject());
                Q_EMIT cashSourceUpdated(destAccount);
            }
        } else {
            qDebug() << "Transfer error response:";
            qDebug() << "Message:" << response.error->message;
            qDebug() << "Details:" << response.error->details;
            Q_EMIT errorTransfer(response.error->message, response.error->status,
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
