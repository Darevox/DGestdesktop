// cashtransactionapi.cpp
#include "cashtransactionapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;
CashTransactionApi::CashTransactionApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
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
    QString path = QStringLiteral("/api/v1/transactions");

    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QStringLiteral("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QStringLiteral("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QStringLiteral("sort_direction=%1").arg(sortDirection);
    if (page > 0)
        queryParts << QStringLiteral("page=%1").arg(page);
    if (!type.isEmpty())
        queryParts << QStringLiteral("type=%1").arg(type);
    if (cashSourceId > 0)
        queryParts << QStringLiteral("cash_source_id=%1").arg(cashSourceId);
    if (minAmount > 0)
        queryParts << QStringLiteral("min_amount=%1").arg(minAmount);
    if (maxAmount > 0)
        queryParts << QStringLiteral("max_amount=%1").arg(maxAmount);
    if (startDate.isValid())
        queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(Qt::ISODate));
    if (endDate.isValid())
        queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(Qt::ISODate));

    if (!queryParts.isEmpty()) {
      path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }
    qDebug()<<"path : "<<path;
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedCashTransactions paginatedTransactions = paginatedTransactionsFromJson(*response.data);
            Q_EMIT transactionsReceived(paginatedTransactions);
        } else {
            Q_EMIT errorTransactionsReceived(response.error->message, response.error->status,
                                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getTransaction(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/transactions/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashTransaction transaction = transactionFromJson(response.data->value("transaction"_L1).toObject());
            Q_EMIT transactionReceived(transactionToVariantMap(transaction));
        } else {
            Q_EMIT errorTransactionReceived(response.error->message, response.error->status,
                                        QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getTransactionsBySource(int sourceId, int page)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/transactions/by-source/%1").arg(sourceId);

    if (page > 0) {
        path += QStringLiteral("?page=%1").arg(page);
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedCashTransactions paginatedTransactions = paginatedTransactionsFromJson(*response.data);
            Q_EMIT transactionsBySourceReceived(paginatedTransactions);
        } else {
            Q_EMIT errorTransactionsBySourceReceived(response.error->message, response.error->status,
                                                 QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getSummary(const QDateTime &startDate, const QDateTime &endDate)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/transactions/summary");

    QStringList queryParts;
    if (startDate.isValid())
        queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(Qt::ISODate));
    if (endDate.isValid())
        queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(Qt::ISODate));

    if (!queryParts.isEmpty()) {
         path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
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

// Helper Methods
CashTransaction CashTransactionApi::transactionFromJson(const QJsonObject &json) const
{
    CashTransaction transaction;
    transaction.id = json["id"_L1].toInt();
    transaction.reference_number = json["reference_number"_L1].toString();
    transaction.transaction_date = QDateTime::fromString(json["transaction_date"_L1].toString(), Qt::ISODate);
    transaction.cash_source_id = json["cash_source_id"_L1].toInt();
    transaction.type = json["type"_L1].toString();
    transaction.amount = json["amount"_L1].toString().toDouble();
    transaction.category = json["category"_L1].toString();
    transaction.payment_method = json["payment_method"_L1].toString();
    transaction.description = json["description"_L1].toString();

    if (json.contains("cash_source"_L1) && !json["cash_source"_L1].isNull()) {
        transaction.cash_source = json["cash_source"_L1].toObject().toVariantMap();
    }

    if (json.contains("transfer_destination"_L1) && !json["transfer_destination"_L1].isNull()) {
        transaction.transfer_destination = json["transfer_destination"_L1].toObject().toVariantMap();
    }

    return transaction;
}

PaginatedCashTransactions CashTransactionApi::paginatedTransactionsFromJson(const QJsonObject &json) const
{
    PaginatedCashTransactions result;
    const QJsonObject &meta = json["transactions"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(transactionFromJson(value.toObject()));
    }

    return result;
}

QVariantMap CashTransactionApi::transactionToVariantMap(const CashTransaction &transaction) const
{
    QVariantMap map;
    map["id"_L1] = transaction.id;
    map["reference_number"_L1] = transaction.reference_number;
    map["transaction_date"_L1] = transaction.transaction_date;
    map["cash_source_id"_L1] = transaction.cash_source_id;
    map["type"_L1] = transaction.type;
    map["amount"_L1] = transaction.amount;
    map["category"_L1] = transaction.category;
    map["payment_method"_L1] = transaction.payment_method;
    map["description"_L1] = transaction.description;
    map["cash_source"_L1] = transaction.cash_source;
    map["transfer_destination"_L1] = transaction.transfer_destination;
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
