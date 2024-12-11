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

// Helper Methods
CashTransaction CashTransactionApi::transactionFromJson(const QJsonObject &json) const
{
    CashTransaction transaction;
    transaction.id = json["id"].toInt();
    transaction.reference_number = json["reference_number"].toString();
    transaction.transaction_date = QDateTime::fromString(json["transaction_date"].toString(), Qt::ISODate);
    transaction.cash_source_id = json["cash_source_id"].toInt();
    transaction.transaction_type = json["transaction_type"].toString();
    transaction.amount = json["amount"].toDouble();
    transaction.category = json["category"].toString();
    transaction.payment_method = json["payment_method"].toString();
    transaction.description = json["description"].toString();

    if (json.contains("cash_source") && !json["cash_source"].isNull()) {
        transaction.cash_source = json["cash_source"].toObject().toVariantMap();
    }

    if (json.contains("related_document") && !json["related_document"].isNull()) {
        transaction.related_document = json["related_document"].toObject().toVariantMap();
    }

    return transaction;
}

QJsonObject CashTransactionApi::transactionToJson(const CashTransaction &transaction) const
{
    QJsonObject json;
    json["cash_source_id"] = transaction.cash_source_id;
    json["transaction_date"] = transaction.transaction_date.toString(Qt::ISODate);
    json["transaction_type"] = transaction.transaction_type;
    json["amount"] = transaction.amount;
    json["category"] = transaction.category;
    json["payment_method"] = transaction.payment_method;
    json["description"] = transaction.description;
    json["reference_number"] = transaction.reference_number;
    return json;
}

QJsonObject CashTransactionApi::transferToJson(const TransactionTransfer &transfer) const
{
    QJsonObject json;
    json["from_cash_source_id"] = transfer.from_cash_source_id;
    json["to_cash_source_id"] = transfer.to_cash_source_id;
    json["amount"] = transfer.amount;
    json["description"] = transfer.description;
    json["reference_number"] = transfer.reference_number;
    return json;
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
    map["transaction_type"] = transaction.transaction_type;
    map["amount"] = transaction.amount;
    map["category"] = transaction.category;
    map["payment_method"] = transaction.payment_method;
    map["description"] = transaction.description;
    map["cash_source"] = transaction.cash_source;
    map["related_document"] = transaction.related_document;
    return map;
}

// API Methods
QFuture<void> CashTransactionApi::getTransactions(const QString &search, const QString &sortBy,
                                                 const QString &sortDirection, int page,
                                                 const QString &type, const QString &category,
                                                 int cashSourceId)
{
    setLoading(true);
    QString path = "/api/cash-transactions";

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
    if (!category.isEmpty())
        queryParts << QString("category=%1").arg(category);
    if (cashSourceId > 0)
        queryParts << QString("cash_source_id=%1").arg(cashSourceId);

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

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
    QNetworkRequest request = createRequest(QString("/api/cash-transactions/%1").arg(id));
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

QFuture<void> CashTransactionApi::createTransaction(const CashTransaction &transaction)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/cash-transactions");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = transactionToJson(transaction);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashTransaction createdTransaction = transactionFromJson(response.data->value("transaction").toObject());
            emit transactionCreated(createdTransaction);
        } else {
            emit errorTransactionCreated(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::updateTransaction(int id, const CashTransaction &transaction)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-transactions/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = transactionToJson(transaction);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            CashTransaction updatedTransaction = transactionFromJson(response.data->value("transaction").toObject());
            emit transactionUpdated(updatedTransaction);
        } else {
            emit errorTransactionUpdated(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::deleteTransaction(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/cash-transactions/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit transactionDeleted(id);
        } else {
            emit errorTransactionDeleted(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::createTransfer(const TransactionTransfer &transfer)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/cash-transactions/transfer");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = transferToJson(transfer);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit transferCreated(response.data->value("transfer").toObject().toVariantMap());
        } else {
            emit errorTransferCreated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getCategories()
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/cash-transactions/categories");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit categoriesReceived(response.data->value("categories").toArray().toVariantList());
        } else {
            emit errorCategoriesReceived(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::getCashFlow(const QString &period, int cashSourceId)
{
    setLoading(true);
    QString path = "/api/cash-transactions/cash-flow";
    QStringList queryParts;

    if (!period.isEmpty())
        queryParts << QString("period=%1").arg(period);
    if (cashSourceId > 0)
        queryParts << QString("cash_source_id=%1").arg(cashSourceId);

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit cashFlowReceived(response.data->value("cash_flow").toObject().toVariantMap());
        } else {
            emit errorCashFlowReceived(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> CashTransactionApi::generateReport(const QDateTime &startDate,
                                                const QDateTime &endDate,
                                                int cashSourceId)
{
    setLoading(true);
    QString path = "/api/cash-transactions/generate-report";
    QStringList queryParts;

    queryParts << QString("start_date=%1").arg(startDate.toString(Qt::ISODate));
    queryParts << QString("end_date=%1").arg(endDate.toString(Qt::ISODate));
    if (cashSourceId > 0)
        queryParts << QString("cash_source_id=%1").arg(cashSourceId);

    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QByteArray());
    }).then([=](JsonResponse response) {
        if (response.success) {
            emit reportGenerated(response.data->value("report_url").toString());
        } else {
            emit errorReportGenerated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QString CashTransactionApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void CashTransactionApi::saveToken(const QString &token) {
    m_token = token;
    m_settings.setValue("auth/token", token);
}

} // namespace NetworkApi
