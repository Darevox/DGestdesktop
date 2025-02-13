// teamapi.h
#ifndef TEAMAPI_H
#define TEAMAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>
#include <QHttpMultiPart>
#include <QFile>
#include <QFileInfo>

namespace NetworkApi {

struct Team {
    int id;
    QString name;
    QString email;
    QString phone;
    QString address;
    QString image_path;
    QString locale; // Add this field
};

struct PaginatedTeams {
    QList<Team> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

class TeamApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit TeamApi(QObject *parent = nullptr);
    explicit TeamApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getTeams(const QString &search = QString(),
                                       const QString &sortBy = QStringLiteral("created_at"),
                                       const QString &sortDirection = QStringLiteral("desc"),
                                       int page = 1);
    Q_INVOKABLE QFuture<void> getTeam(int id);
    Q_INVOKABLE QFuture<void> createTeam(const Team &team);
    Q_INVOKABLE QFuture<void> updateTeam(int id, const QVariantMap &map);
    Q_INVOKABLE QFuture<void> deleteTeam(int id);

    // Image operations
    Q_INVOKABLE QFuture<void> uploadTeamImage(int teamId, const QString &imagePath);
    Q_INVOKABLE QFuture<void> removeTeamImage(int teamId);

    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);
    bool isLoading() const { return m_isLoading; }

    static void setSharedNetworkManager(QNetworkAccessManager* manager);
    Q_INVOKABLE QFuture<void> getTeamLocale(int teamId);
    Q_INVOKABLE QFuture<void> updateTeamLocale(int teamId, const QString &locale);

    // Helper method to validate locale
    static bool isValidLocale(const QString &locale);

Q_SIGNALS:
    // Success signals
    void teamsReceived(const PaginatedTeams &teams);
    void teamReceived(const QVariantMap &team);
    void teamCreated(const Team &team);
    void teamUpdated(const Team &team);
    void teamDeleted(int id);
    void imageUploaded(const QString &imageUrl);
    void imageRemoved(int teamId);

    // Error signals
    void teamError(const QString &message, ApiStatus status, const QByteArray &details);
    void errorTeamsReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorTeamReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorTeamCreated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorTeamUpdated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorTeamDeleted(const QString &message, ApiStatus status, const QByteArray &details);
    void uploadImageError(const QString &message);

    void isLoadingChanged();
    void localeReceived(const QString &locale);
    void localeUpdated(const QString &locale);
    void localeError(const QString &message, ApiStatus status, const QByteArray &details);

private:
    Team teamFromJson(const QJsonObject &json) const;
    QJsonObject teamToJson(const Team &team) const;
    PaginatedTeams paginatedTeamsFromJson(const QJsonObject &json) const;
    QVariantMap teamToVariantMap(const Team &team) const;
    Team teamFromVariantMap(const QVariantMap &map) const;
    QSettings m_settings;
    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            Q_EMIT isLoadingChanged();
        }
    }

    static QNetworkAccessManager* netManager;
    static void ensureSharedNetworkManager();
     const QStringList m_supportedLocales{QStringLiteral("en"), QStringLiteral("fr")};
};

} // namespace NetworkApi

#endif // TEAMAPI_H
