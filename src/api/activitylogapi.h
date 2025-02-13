// activitylogapi.h
#ifndef ACTIVITYLOGAPI_H
#define ACTIVITYLOGAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QDateTime>

namespace NetworkApi {

struct ActivityLog {
    int id;
    QString logType;
    QString modelType;
    QString modelIdentifier;
    QString userIdentifier;
    QDateTime createdAt;
    QVariantMap details;
};

struct PaginatedLogs {
    QList<ActivityLog> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

struct LogStatistics {
    int totalLogs;
    QList<QPair<QString, int>> logTypeDistribution;
    QList<QPair<QString, int>> mostActiveModels;
    int analysisPeriodDays;
};

class ActivityLogApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit ActivityLogApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // Main operations
    Q_INVOKABLE QFuture<void> getLogs(const QString &logType = QString(),
                                     const QString &modelType = QString(),
                                     const QString &modelIdentifier = QString(),
                                     const QString &userIdentifier = QString(),
                                     const QDate &startDate = QDate(),
                                     const QDate &endDate = QDate(),
                                     const QString &sortBy = QStringLiteral("created_at"),
                                     const QString &sortDirection = QStringLiteral("desc"),
                                     int page = 1);

    Q_INVOKABLE QFuture<void> getLog(int id);
    Q_INVOKABLE QFuture<void> getStatistics(int days = 30);
    Q_INVOKABLE QFuture<void> getFilterOptions();
    Q_INVOKABLE QFuture<void> cleanup(int days);

    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);
    bool isLoading() const { return m_isLoading; }

Q_SIGNALS:
    void logsReceived(const PaginatedLogs &logs);
    void logReceived(const ActivityLog &log);
    void statisticsReceived(const LogStatistics &statistics);
    void filterOptionsReceived(const QStringList &logTypes, const QStringList &modelTypes);
    void cleanupCompleted(int deletedCount);

    void logError(const QString &message, ApiStatus status, const QByteArray &details);
    void isLoadingChanged();

private:
    ActivityLog logFromJson(const QJsonObject &json) const;
    PaginatedLogs paginatedLogsFromJson(const QJsonObject &json) const;
    LogStatistics statisticsFromJson(const QJsonObject &json) const;
    QSettings m_settings;

    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            Q_EMIT isLoadingChanged();
        }
    }
};

} // namespace NetworkApi
#endif // ACTIVITYLOGAPI_H
