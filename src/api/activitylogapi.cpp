// activitylogapi.cpp
#include "activitylogapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>

namespace NetworkApi {

ActivityLogApi::ActivityLogApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

QFuture<void> ActivityLogApi::getLogs(const QString &logType, const QString &modelType,
                                      const QString &modelIdentifier, const QString &userIdentifier,
                                      const QDate &startDate, const QDate &endDate,
                                      const QString &sortBy, const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/activity-logs");

    QStringList queryParts;
    if (!logType.isEmpty())
        queryParts << QStringLiteral("log_type=%1").arg(logType);
    if (!modelType.isEmpty())
        queryParts << QStringLiteral("model_type=%1").arg(modelType);
    if (!modelIdentifier.isEmpty())
        queryParts << QStringLiteral("model_identifier=%1").arg(modelIdentifier);
    if (!userIdentifier.isEmpty())
        queryParts << QStringLiteral("user_identifier=%1").arg(userIdentifier);
    if (startDate.isValid())
        queryParts << QStringLiteral("start_date=%1").arg(startDate.toString(Qt::ISODate));
    if (endDate.isValid())
        queryParts << QStringLiteral("end_date=%1").arg(endDate.toString(Qt::ISODate));
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
            PaginatedLogs paginatedLogs = paginatedLogsFromJson(*response.data);
            Q_EMIT logsReceived(paginatedLogs);
        } else {
            Q_EMIT logError(response.error->message, response.error->status,
                          QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::getLog(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/activity-logs/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            ActivityLog log = logFromJson(response.data->value(QStringLiteral("log")).toObject());
            Q_EMIT logReceived(log);
        } else {
            Q_EMIT logError(response.error->message, response.error->status,
                          QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::getStatistics(int days)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/activity-logs/statistics?days=%1").arg(days);
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            LogStatistics stats = statisticsFromJson(*response.data);
            Q_EMIT statisticsReceived(stats);
        } else {
            Q_EMIT logError(response.error->message, response.error->status,
                          QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::getFilterOptions()
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/activity-logs/filter-options"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QStringList logTypes, modelTypes;
            const QJsonArray &logTypesArray = response.data->value(QStringLiteral("log_types")).toArray();
            const QJsonArray &modelTypesArray = response.data->value(QStringLiteral("model_types")).toArray();

            for (const QJsonValue &value : logTypesArray) {
                logTypes << value.toString();
            }
            for (const QJsonValue &value : modelTypesArray) {
                modelTypes << value.toString();
            }

            Q_EMIT filterOptionsReceived(logTypes, modelTypes);
        } else {
            Q_EMIT logError(response.error->message, response.error->status,
                          QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ActivityLogApi::cleanup(int days)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/activity-logs/cleanup"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData[QStringLiteral("days")] = days;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            int deletedCount = response.data->value(QStringLiteral("deleted_logs_count")).toInt();
            Q_EMIT cleanupCompleted(deletedCount);
        } else {
            Q_EMIT logError(response.error->message, response.error->status,
                          QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

ActivityLog ActivityLogApi::logFromJson(const QJsonObject &json) const
{
    ActivityLog log;
    log.id = json[QStringLiteral("id")].toInt();
    log.logType = json[QStringLiteral("log_type")].toString();
    log.modelType = json[QStringLiteral("model_type")].toString();
    log.modelIdentifier = json[QStringLiteral("model_identifier")].toString();
    log.userIdentifier = json[QStringLiteral("user_identifier")].toString();
    log.createdAt = QDateTime::fromString(json[QStringLiteral("created_at")].toString(), Qt::ISODate);
    log.details = json[QStringLiteral("details")].toObject().toVariantMap();
    return log;
}

PaginatedLogs ActivityLogApi::paginatedLogsFromJson(const QJsonObject &json) const
{
    PaginatedLogs result;
    const QJsonObject &meta = json[QStringLiteral("logs")].toObject();
    result.currentPage = meta[QStringLiteral("current_page")].toInt();
    result.lastPage = meta[QStringLiteral("last_page")].toInt();
    result.perPage = meta[QStringLiteral("per_page")].toInt();
    result.total = meta[QStringLiteral("total")].toInt();

    const QJsonArray &dataArray = meta[QStringLiteral("data")].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(logFromJson(value.toObject()));
    }

    return result;
}

LogStatistics ActivityLogApi::statisticsFromJson(const QJsonObject &json) const
{
    LogStatistics stats;
    stats.totalLogs = json[QStringLiteral("total_logs")].toInt();
    stats.analysisPeriodDays = json[QStringLiteral("analysis_period_days")].toInt();

    const QJsonArray &distribution = json[QStringLiteral("log_type_distribution")].toArray();
    for (const QJsonValue &value : distribution) {
        QJsonObject obj = value.toObject();
        stats.logTypeDistribution.append({
                                             obj[QStringLiteral("log_type")].toString(),
                                             obj[QStringLiteral("count")].toInt()
                                         });
    }

    const QJsonArray &activeModels = json[QStringLiteral("most_active_models")].toArray();
    for (const QJsonValue &value : activeModels) {
        QJsonObject obj = value.toObject();
        stats.mostActiveModels.append({
            QStringLiteral("%1: %2").arg(obj[QStringLiteral("model_type")].toString(),
                                 obj[QStringLiteral("model_identifier")].toString()),
            obj[QStringLiteral("count")].toInt()
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
