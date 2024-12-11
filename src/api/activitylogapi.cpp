// activitylogapi.cpp
#include "activitylogapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>

namespace NetworkApi {

ActivityLogApi::ActivityLogApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

QFuture<void> ActivityLogApi::getLogs(const QString &logType, const QString &modelType,
                                     const QString &modelIdentifier, const QString &userIdentifier,
                                     const QDate &startDate, const QDate &endDate,
                                     const QString &sortBy, const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = "/api/v1/activity-logs";

    QStringList queryParts;
    if (!logType.isEmpty())
        queryParts << QString("log_type=%1").arg(logType);
    if (!modelType.isEmpty())
        queryParts << QString("model_type=%1").arg(modelType);
    if (!modelIdentifier.isEmpty())
        queryParts << QString("model_identifier=%1").arg(modelIdentifier);
    if (!userIdentifier.isEmpty())
        queryParts << QString("user_identifier=%1").arg(userIdentifier);
    if (startDate.isValid())
        queryParts << QString("start_date=%1").arg(startDate.toString(Qt::ISODate));
    if (endDate.isValid())
        queryParts << QString("end_date=%1").arg(endDate.toString(Qt::ISODate));
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
            PaginatedLogs paginatedLogs = paginatedLogsFromJson(*response.data);
            emit logsReceived(paginatedLogs);
        } else {
            emit logError(response.error->message, response.error->status,
                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::getLog(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/activity-logs/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            ActivityLog log = logFromJson(response.data->value("log").toObject());
            emit logReceived(log);
        } else {
            emit logError(response.error->message, response.error->status,
                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::getStatistics(int days)
{
    setLoading(true);
    QString path = QString("/api/v1/activity-logs/statistics?days=%1").arg(days);
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            LogStatistics stats = statisticsFromJson(*response.data);
            emit statisticsReceived(stats);
        } else {
            emit logError(response.error->message, response.error->status,
                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::getFilterOptions()
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/v1/activity-logs/filter-options");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QStringList logTypes, modelTypes;
            const QJsonArray &logTypesArray = response.data->value("log_types").toArray();
            const QJsonArray &modelTypesArray = response.data->value("model_types").toArray();

            for (const QJsonValue &value : logTypesArray) {
                logTypes << value.toString();
            }
            for (const QJsonValue &value : modelTypesArray) {
                modelTypes << value.toString();
            }

            emit filterOptionsReceived(logTypes, modelTypes);
        } else {
            emit logError(response.error->message, response.error->status,
                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::cleanup(int days)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/v1/activity-logs/cleanup");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["days"] = days;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            int deletedCount = response.data->value("deleted_logs_count").toInt();
            emit cleanupCompleted(deletedCount);
        } else {
            emit logError(response.error->message, response.error->status,
                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

ActivityLog ActivityLogApi::logFromJson(const QJsonObject &json) const
{
    ActivityLog log;
    log.id = json["id"].toInt();
    log.logType = json["log_type"].toString();
    log.modelType = json["model_type"].toString();
    log.modelIdentifier = json["model_identifier"].toString();
    log.userIdentifier = json["user_identifier"].toString();
    log.createdAt = QDateTime::fromString(json["created_at"].toString(), Qt::ISODate);
    log.details = json["details"].toObject().toVariantMap();
    return log;
}

PaginatedLogs ActivityLogApi::paginatedLogsFromJson(const QJsonObject &json) const
{
    PaginatedLogs result;
    const QJsonObject &meta = json["logs"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(logFromJson(value.toObject()));
    }

    return result;
}

LogStatistics ActivityLogApi::statisticsFromJson(const QJsonObject &json) const
{
    LogStatistics stats;
    stats.totalLogs = json["total_logs"].toInt();
    stats.analysisPeriodDays = json["analysis_period_days"].toInt();

    const QJsonArray &distribution = json["log_type_distribution"].toArray();
    for (const QJsonValue &value : distribution) {
        QJsonObject obj = value.toObject();
        stats.logTypeDistribution.append({
            obj["log_type"].toString(),
            obj["count"].toInt()
        });
    }

    const QJsonArray &activeModels = json["most_active_models"].toArray();
    for (const QJsonValue &value : activeModels) {
        QJsonObject obj = value.toObject();
        stats.mostActiveModels.append({
            obj["model_type"].toString() + ": " + obj["model_identifier"].toString(),
            obj["count"].toInt()
        });
    }

    return stats;
}

QString ActivityLogApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void ActivityLogApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
