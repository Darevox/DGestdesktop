// teamapi.cpp
#include "teamapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QUuid>

namespace NetworkApi {
using namespace Qt::StringLiterals;

QNetworkAccessManager* TeamApi::netManager = nullptr;

void TeamApi::setSharedNetworkManager(QNetworkAccessManager* manager)
{
    if (netManager && netManager->parent() == nullptr) {
        delete netManager;
    }
    netManager = manager;
}

void TeamApi::ensureSharedNetworkManager()
{
    if (!netManager) {
        netManager = new QNetworkAccessManager();
    }
}

TeamApi::TeamApi(QObject *parent)
    : AbstractApi(nullptr, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
    ensureSharedNetworkManager();
    setNetworkManager(netManager);
}

TeamApi::TeamApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

QFuture<void> TeamApi::getTeams(const QString &search, const QString &sortBy,
                                const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/teams");

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
            PaginatedTeams paginatedTeams = paginatedTeamsFromJson(*response.data);
            Q_EMIT teamsReceived(paginatedTeams);
        } else {
            Q_EMIT errorTeamsReceived(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::getTeam(int id)
{
    setLoading(true);
    qDebug()<<"IDDDDDDDDD : "<<id;
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/teams/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team"_L1).toObject();
            Team team = teamFromJson(teamData);
            QVariantMap teamMap = teamToVariantMap(team);
            Q_EMIT teamReceived(teamMap);
        } else {
            Q_EMIT errorTeamReceived(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::createTeam(const Team &team)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/teams"));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = teamToJson(team);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team"_L1).toObject();
            Team createdTeam = teamFromJson(teamData);
            Q_EMIT teamCreated(createdTeam);
        } else {
            Q_EMIT errorTeamCreated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::updateTeam(int id, const QVariantMap &team)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/teams/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());
    Team teamDate = teamFromVariantMap(team);
    QJsonObject jsonData = teamToJson(teamDate);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team"_L1).toObject();
            Team updatedTeam = teamFromJson(teamData);
            Q_EMIT teamUpdated(updatedTeam);
        } else {
            Q_EMIT errorTeamUpdated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::deleteTeam(int id)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/teams/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT teamDeleted(id);
        } else {
            Q_EMIT errorTeamDeleted(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::uploadTeamImage(int teamId, const QString &imagePath)
{
    setLoading(true);

    QString localPath = QUrl(imagePath).toLocalFile();
    if (localPath.isEmpty()) {
        localPath = imagePath;
        if (localPath.startsWith(QStringLiteral("file://"))) {
            localPath = localPath.mid(7);
        }
    }

    QString path = QStringLiteral("/api/v1/teams/%1/image").arg(teamId);
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    QString boundary = QStringLiteral("boundary%1")
            .arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    multiPart->setBoundary(boundary.toLatin1());

    QFile *file = new QFile(localPath);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        delete multiPart;
        Q_EMIT uploadImageError("Failed to open image file"_L1);
        setLoading(false);
        return QtFuture::makeReadyVoidFuture();
    }

    QHttpPart imagePart;
    imagePart.setHeader(QNetworkRequest::ContentTypeHeader,
                        QVariant(localPath.endsWith(QStringLiteral(".png"), Qt::CaseInsensitive) ? QStringLiteral("image/png") : QStringLiteral("image/jpeg")));
    imagePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                        QVariant(QStringLiteral("form-data; name=\"image\"; filename=\"%1\"")
                                 .arg(QFileInfo(localPath).fileName())));

    QByteArray fileData = file->readAll();
    file->close();
    delete file;

    imagePart.setBody(fileData);
    multiPart->append(imagePart);

    request.setHeader(QNetworkRequest::ContentTypeHeader,
                      QStringLiteral("multipart/form-data; boundary=%1").arg(boundary));

    auto future = makeRequest<QJsonObject>([=]() {
        QNetworkReply* reply = m_netManager->post(request, multiPart);
        multiPart->setParent(reply);
        return reply;
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team"_L1).toObject();
            Team updatedTeam = teamFromJson(teamData);
            Q_EMIT teamUpdated(updatedTeam);
        } else {
            Q_EMIT teamError(response.error->message, response.error->status,
                             QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::removeTeamImage(int teamId)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/teams/%1/image").arg(teamId));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT imageRemoved(teamId);
        } else {
            Q_EMIT teamError(response.error->message, response.error->status,
                             QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

Team TeamApi::teamFromJson(const QJsonObject &json) const
{
    Team team;
    team.id = json["id"_L1].toInt();
    team.name = json["name"_L1].toString();
    team.email = json["email"_L1].toString();
    team.phone = json["phone"_L1].toString();
    team.address = json["address"_L1].toString();
    team.image_path = json["image_path"_L1].toString();
    team.locale = json["locale"_L1].toString();
    return team;
}

QJsonObject TeamApi::teamToJson(const Team &team) const
{
    QJsonObject json;
    json["name"_L1] = team.name;
    json["email"_L1] = team.email;
    json["phone"_L1] = team.phone;
    json["address"_L1] = team.address;
    if (!team.locale.isEmpty()) {
        json["locale"_L1] = team.locale;
    }
    return json;
}

PaginatedTeams TeamApi::paginatedTeamsFromJson(const QJsonObject &json) const
{
    PaginatedTeams result;
    const QJsonObject &meta = json["teams"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(teamFromJson(value.toObject()));
    }

    return result;
}

QVariantMap TeamApi::teamToVariantMap(const Team &team) const
{
    QVariantMap map;
    map["id"_L1] = team.id;
    map["name"_L1] = team.name;
    map["email"_L1] = team.email;
    map["phone"_L1] = team.phone;
    map["address"_L1] = team.address;
    map["image_path"_L1] = team.image_path;
    map["locale"_L1] = team.locale;
    return map;
}

Team TeamApi::teamFromVariantMap(const QVariantMap &map) const
{
    Team team;
    team.name = map.value("name"_L1).toString();
    team.email = map.value("email"_L1).toString();
    team.phone = map.value("phone"_L1).toString();
    team.address = map.value("address"_L1).toString();
    team.locale = map.value("locale"_L1).toString();
    return team;
}
bool TeamApi::isValidLocale(const QString &locale)
{
    return QStringList{QStringLiteral("en"), QStringLiteral("fr")}.contains(locale);
}

QFuture<void> TeamApi::getTeamLocale(int teamId)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/teams/%1/language").arg(teamId));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QString locale = response.data->value("language"_L1).toString();
            Q_EMIT localeReceived(locale);
        } else {
            Q_EMIT localeError(response.error->message, response.error->status,
                               QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::updateTeamLocale(int teamId, const QString &locale)
{
    setLoading(true);


    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/teams/%1/language").arg(teamId));
      request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
      request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

      QJsonObject jsonData;
      jsonData.insert(QStringLiteral("lang"), locale);  // Make sure to use "lang" as the key

      auto future = makeRequest<QJsonObject>([=]() {
          return m_netManager->post(request, QJsonDocument(jsonData).toJson());
      }).then([=](JsonResponse response) {
          if (response.success) {
              Q_EMIT localeUpdated(locale);
          } else {
              Q_EMIT localeError(response.error->message, response.error->status,
                             QJsonDocument(response.error->details).toJson());
          }
          setLoading(false);
      });

      return future.then([=]() {});
}
QString TeamApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void TeamApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
