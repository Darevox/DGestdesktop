// activitylogmodel.h
#ifndef ACTIVITYLOGMODEL_H
#define ACTIVITYLOGMODEL_H

#include "../api/activitylogapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class ActivityLogModel : public QAbstractTableModel
{
    Q_OBJECT

    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY totalItemsChanged)
    Q_PROPERTY(int currentPage READ currentPage NOTIFY currentPageChanged)
    Q_PROPERTY(int totalPages READ totalPages NOTIFY totalPagesChanged)
    Q_PROPERTY(QString sortField READ sortField WRITE setSortField NOTIFY sortFieldChanged)
    Q_PROPERTY(QString sortDirection READ sortDirection WRITE setSortDirection NOTIFY sortDirectionChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY searchQueryChanged)
    QString searchQuery() const { return m_searchQuery; }
public:
    enum ActivityLogRoles {
        IdRole = Qt::UserRole + 1,
        LogTypeRole,
        ModelTypeRole,
        ModelIdentifierRole,
        UserIdentifierRole,
        CreatedAtRole,
        DetailsRole
    };
    Q_ENUM(ActivityLogRoles)

    explicit ActivityLogModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(ActivityLogApi* api);

    // QAbstractTableModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;

    // Properties
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }
    int totalItems() const { return m_totalItems; }
    int currentPage() const { return m_currentPage; }
    int totalPages() const { return m_totalPages; }
    QString sortField() const { return m_sortField; }
    QString sortDirection() const { return m_sortDirection; }

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void loadPage(int page);
    Q_INVOKABLE QVariantMap getLog(int row) const;
    Q_INVOKABLE void getStatistics(int days = 30);
    Q_INVOKABLE void getFilterOptions();

public Q_SLOTS:
    void setSortField(const QString &field);
    void setSortDirection(const QString &direction);
    void setSearchQuery(const QString &query);
    void filterByLogType(const QString &logType);
    void filterByModelType(const QString &modelType);
    void filterByUserIdentifier(const QString &userIdentifier);
    void filterByDateRange(const QDateTime &startDate, const QDateTime &endDate);
    void applyFilters();
    void clearFilters();
Q_SIGNALS:
    void loadingChanged();
    void errorMessageChanged();
    void totalItemsChanged();
    void currentPageChanged();
    void totalPagesChanged();
    void sortFieldChanged();
    void sortDirectionChanged();
    void statisticsReceived(const LogStatistics &statistics);
    void filterOptionsReceived(const QStringList &logTypes, const QStringList &modelTypes);
    void rowCountChanged();
    void searchQueryChanged();
private Q_SLOTS:
    void handleLogsReceived(const PaginatedLogs &logs);
    void handleLogError(const QString &message, ApiStatus status);
    void handleStatisticsReceived(const LogStatistics &statistics);
    void handleFilterOptionsReceived(const QStringList &logTypes, const QStringList &modelTypes);

private:
    ActivityLogApi* m_api;
    QList<ActivityLog> m_logs;
    bool m_loading;
    QString m_errorMessage;
    int m_totalItems;
    int m_currentPage;
    int m_totalPages;
    QString m_sortField;
    QString m_sortDirection;

    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    QVariantMap logToVariantMap(const ActivityLog &log) const;

    QString m_searchQuery;
    QString m_currentLogType;
    QString m_currentModelType;
    QString m_currentUserIdentifier;
    QDateTime m_startDate;
    QDateTime m_endDate;
};

} // namespace NetworkApi

#endif // ACTIVITYLOGMODEL_H
