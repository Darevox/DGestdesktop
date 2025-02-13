// activitylogmodel.cpp
#include "activitylogmodel.h"

namespace NetworkApi {
using namespace Qt::StringLiterals;
ActivityLogModel::ActivityLogModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_totalItems(0)
    , m_currentPage(1)
    , m_totalPages(1)
    , m_sortField(QStringLiteral("created_at"))
    , m_sortDirection(QStringLiteral("desc"))
{
}

void ActivityLogModel::setApi(ActivityLogApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &ActivityLogApi::logsReceived, this, &ActivityLogModel::handleLogsReceived);
        connect(m_api, &ActivityLogApi::logError, this, &ActivityLogModel::handleLogError);
        connect(m_api, &ActivityLogApi::statisticsReceived, this, &ActivityLogModel::handleStatisticsReceived);
        connect(m_api, &ActivityLogApi::filterOptionsReceived, this, &ActivityLogModel::handleFilterOptionsReceived);

        refresh();
    }
}

int ActivityLogModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_logs.count();
}

int ActivityLogModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 6; // Number of columns in our data
}

QVariant ActivityLogModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_logs.count())
        return QVariant();

    const ActivityLog &log = m_logs.at(index.row());

    if (role == Qt::DisplayRole || role == Qt::EditRole) {
        switch (index.column()) {
        case 0: return log.id;
        case 1: return log.logType;
        case 2: return log.modelType;
        case 3: return log.modelIdentifier;
        case 4: return log.userIdentifier;
        case 5: return log.createdAt;
        }
    } else if (role >= IdRole) {
        switch (role) {
        case IdRole: return log.id;
        case LogTypeRole: return log.logType;
        case ModelTypeRole: return log.modelType;
        case ModelIdentifierRole: return log.modelIdentifier;
        case UserIdentifierRole: return log.userIdentifier;
        case CreatedAtRole: return log.createdAt;
        case DetailsRole: return log.details;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> ActivityLogModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[LogTypeRole] = "logType";
    roles[ModelTypeRole] = "modelType";
    roles[ModelIdentifierRole] = "modelIdentifier";
    roles[UserIdentifierRole] = "userIdentifier";
    roles[CreatedAtRole] = "createdAt";
    roles[DetailsRole] = "details";
    return roles;
}

QVariant ActivityLogModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Log Type");
        case 2: return tr("Model Type");
        case 3: return tr("Model ID");
        case 4: return tr("User");
        case 5: return tr("Created At");
        }
    }
    return QVariant();
}

void ActivityLogModel::refresh()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getLogs(
        m_currentLogType,
        m_currentModelType,
        QString(), // modelIdentifier not filtered directly
        m_currentUserIdentifier,
        m_startDate.date(),
        m_endDate.date(),
        m_sortField,
        m_sortDirection,
        m_currentPage
    );
}

void ActivityLogModel::loadPage(int page)
{
    if (page != m_currentPage && page > 0 && page <= m_totalPages) {
        m_currentPage = page;
        Q_EMIT currentPageChanged();
        refresh();
    }
}

QVariantMap ActivityLogModel::getLog(int row) const
{
    if (row < 0 || row >= m_logs.count())
        return QVariantMap();

    return logToVariantMap(m_logs.at(row));
}

void ActivityLogModel::getStatistics(int days)
{
    if (!m_api)
        return;
    setLoading(true);
    m_api->getStatistics(days);
}

void ActivityLogModel::getFilterOptions()
{
    if (!m_api)
        return;
    setLoading(true);
    m_api->getFilterOptions();
}

void ActivityLogModel::setSortField(const QString &field)
{
    if (m_sortField != field) {
        m_sortField = field;
        Q_EMIT sortFieldChanged();
        refresh();
    }
}

void ActivityLogModel::setSortDirection(const QString &direction)
{
    if (m_sortDirection != direction) {
        m_sortDirection = direction;
        Q_EMIT sortDirectionChanged();
        refresh();
    }
}

void ActivityLogModel::handleLogsReceived(const PaginatedLogs &logs)
{
    beginResetModel();
    m_logs = logs.data;
    endResetModel();

    m_totalItems = logs.total;
    Q_EMIT totalItemsChanged();

    m_currentPage = logs.currentPage;
    Q_EMIT currentPageChanged();

    m_totalPages = logs.lastPage;
    Q_EMIT totalPagesChanged();

    setLoading(false);
    setErrorMessage(QString());

    Q_EMIT dataChanged(createIndex(0, 0), createIndex(rowCount() - 1, columnCount() - 1));
}

void ActivityLogModel::handleLogError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void ActivityLogModel::handleStatisticsReceived(const LogStatistics &statistics)
{
    Q_EMIT statisticsReceived(statistics);
    setLoading(false);
}

void ActivityLogModel::handleFilterOptionsReceived(const QStringList &logTypes, const QStringList &modelTypes)
{
    Q_EMIT filterOptionsReceived(logTypes, modelTypes);
    setLoading(false);
}

void ActivityLogModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void ActivityLogModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        Q_EMIT errorMessageChanged();
    }
}

QVariantMap ActivityLogModel::logToVariantMap(const ActivityLog &log) const
{
    QVariantMap map;
    map["id"_L1] = log.id;
    map["logType"_L1] = log.logType;
    map["modelType"_L1] = log.modelType;
    map["modelIdentifier"_L1] = log.modelIdentifier;
    map["userIdentifier"_L1] = log.userIdentifier;
    map["createdAt"_L1] = log.createdAt;
    map["details"_L1] = log.details;
    return map;
}
void ActivityLogModel::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        Q_EMIT searchQueryChanged();
        refresh(); // Refresh with new search query
    }
}

void ActivityLogModel::filterByLogType(const QString &logType)
{
    m_currentLogType = logType;
    // Don't refresh immediately - wait for applyFilters()
}

void ActivityLogModel::filterByModelType(const QString &modelType)
{
    m_currentModelType = modelType;
    // Don't refresh immediately - wait for applyFilters()
}

void ActivityLogModel::filterByUserIdentifier(const QString &userIdentifier)
{
    m_currentUserIdentifier = userIdentifier;
    // Don't refresh immediately - wait for applyFilters()
}

void ActivityLogModel::filterByDateRange(const QDateTime &startDate, const QDateTime &endDate)
{
    m_startDate = startDate;
    m_endDate = endDate;
    // Don't refresh immediately - wait for applyFilters()
}

void ActivityLogModel::applyFilters()
{
    if (!m_api)
        return;

    setLoading(true);
    m_api->getLogs(
        m_currentLogType,
        m_currentModelType,
        QString(), // modelIdentifier not filtered directly
        m_currentUserIdentifier,
        m_startDate.date(),
        m_endDate.date(),
        m_sortField,
        m_sortDirection,
        m_currentPage
    );
}

void ActivityLogModel::clearFilters()
{
    m_currentLogType = QString();
    m_currentModelType = QString();
    m_currentUserIdentifier = QString();
    m_startDate = QDateTime();
    m_endDate = QDateTime();
    m_searchQuery = QString();

    // Refresh with cleared filters
    refresh();
}

} // namespace NetworkApi
