// cashtransactionapi.cpp
#include "cashtransactionapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {

CashTransactionApi::CashTransactionApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

// API Methods
QFuture<void> CashTransactionApi::getTransactions(
    const QString &search,
    const QString &sortBy,
    const QString &sortDirection,
    int page,
    const QString &type,
    int cashSourceId,
    double minAmount,
    double maxAmount,
    const QDateTime &startDate,
    const QDateTime &endDate)
{
    setLoading(true);
    QString path = "/api/v1/transactions";

    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QString("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QString("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QString("sort_direction=%1").arg(sortDirection);
    if (page > 0)
        queryParts << QString("page=%1").arg(page);
    if (!type.isEmpty())
        queryParts << QString("type=%1").arg(type);
    if (cashSourceId > 0)
        queryParts << QString("cash_source_id=%1").arg(cashSourceId);
    if (minAmount > 0)
        queryParts << QString("min_amount=%1").arg(minAmount);
    if (maxAmount > 0)
        queryParts << QString("max_amount=%1").arg(maxAmount);
    if (startDate.isValid())
        queryParts << QString("start_date=%1").arg(startDate.toString(Qt::ISODate));
    if (endDate.isValid())
        queryParts << QString("end_date=%1").arg(endDate.toString(Qt::ISODate));

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }
    qDebug()<<"path : "<<path;
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedCashTransactions paginatedTransactions = paginatedTransactionsFromJson(*response.data);
            emit transactionsReceived(paginatedTransactions);
        } else {
            emit errorTransactionsReceived(response.error->message, response.error->status,
                                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getTransaction(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/transactions/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashTransaction transaction = transactionFromJson(response.data->value("transaction").toObject());
            emit transactionReceived(transactionToVariantMap(transaction));
        } else {
            emit errorTransactionReceived(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getTransactionsBySource(int sourceId, int page)
{
    setLoading(true);
    QString path = QString("/api/v1/transactions/by-source/%1").arg(sourceId);

    if (page > 0) {
        path += QString("?page=%1").arg(page);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedCashTransactions paginatedTransactions = paginatedTransactionsFromJson(*response.data);
            emit transactionsBySourceReceived(paginatedTransactions);
        } else {
            emit errorTransactionsBySourceReceived(response.error->message, response.error->status,
                                                 QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getSummary(const QDateTime &startDate, const QDateTime &endDate)
{
    setLoading(true);
    QString path = "/api/v1/transactions/summary";

    QStringList queryParts;
    if (startDate.isValid())
        queryParts << QString("start_date=%1").arg(startDate.toString(Qt::ISODate));
    if (endDate.isValid())
        queryParts << QString("end_date=%1").arg(endDate.toString(Qt::ISODate));

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
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

// Helper Methods
CashTransaction CashTransactionApi::transactionFromJson(const QJsonObject &json) const
{
    CashTransaction transaction;
    transaction.id = json["id"].toInt();
    transaction.reference_number = json["reference_number"].toString();
    transaction.transaction_date = QDateTime::fromString(json["transaction_date"].toString(), Qt::ISODate);
    transaction.cash_source_id = json["cash_source_id"].toInt();
    transaction.type = json["type"].toString();
    transaction.amount = json["amount"].toString().toDouble();
    transaction.category = json["category"].toString();
    transaction.payment_method = json["payment_method"].toString();
    transaction.description = json["description"].toString();

    if (json.contains("cash_source") && !json["cash_source"].isNull()) {
        transaction.cash_source = json["cash_source"].toObject().toVariantMap();
    }

    if (json.contains("transfer_destination") && !json["transfer_destination"].isNull()) {
        transaction.transfer_destination = json["transfer_destination"].toObject().toVariantMap();
    }

    return transaction;
}

PaginatedCashTransactions CashTransactionApi::paginatedTransactionsFromJson(const QJsonObject &json) const
{
    PaginatedCashTransactions result;
    const QJsonObject &meta = json["transactions"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(transactionFromJson(value.toObject()));
    }

    return result;
}

QVariantMap CashTransactionApi::transactionToVariantMap(const CashTransaction &transaction) const
{
    QVariantMap map;
    map["id"] = transaction.id;
    map["reference_number"] = transaction.reference_number;
    map["transaction_date"] = transaction.transaction_date;
    map["cash_source_id"] = transaction.cash_source_id;
    map["type"] = transaction.type;
    map["amount"] = transaction.amount;
    map["category"] = transaction.category;
    map["payment_method"] = transaction.payment_method;
    map["description"] = transaction.description;
    map["cash_source"] = transaction.cash_source;
    map["transfer_destination"] = transaction.transfer_destination;
    return map;
}

QString CashTransactionApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void CashTransactionApi::saveToken(const QString &token) {
    m_token = token;
    m_settings.setValue("auth/token", token);
}

} // namespace NetworkApi
