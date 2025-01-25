// teamapi.cpp
#include "teamapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QUuid>

namespace NetworkApi {

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
    , m_settings("Dervox", "DGest")
{
    ensureSharedNetworkManager();
    setNetworkManager(netManager);
}

TeamApi::TeamApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

QFuture<void> TeamApi::getTeams(const QString &search, const QString &sortBy,
                               const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = "/api/v1/teams";

    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QString("search=%1").arg(search);
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
            PaginatedTeams paginatedTeams = paginatedTeamsFromJson(*response.data);
            emit teamsReceived(paginatedTeams);
        } else {
            emit errorTeamsReceived(response.error->message, response.error->status,
                                  QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::getTeam(int id)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/teams/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team").toObject();
            Team team = teamFromJson(teamData);
            QVariantMap teamMap = teamToVariantMap(team);
            emit teamReceived(teamMap);
        } else {
            emit errorTeamReceived(response.error->message, response.error->status,
                                 QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::createTeam(const Team &team)
{
    setLoading(true);

    QNetworkRequest request = createRequest("/api/v1/teams");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = teamToJson(team);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team").toObject();
            Team createdTeam = teamFromJson(teamData);
            emit teamCreated(createdTeam);
        } else {
            emit errorTeamCreated(response.error->message, response.error->status,
                                QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::updateTeam(int id, const QVariantMap &team)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/teams/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());
    Team teamDate = teamFromVariantMap(team);
    QJsonObject jsonData = teamToJson(teamDate);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team").toObject();
            Team updatedTeam = teamFromJson(teamData);
            emit teamUpdated(updatedTeam);
        } else {
            emit errorTeamUpdated(response.error->message, response.error->status,
                                QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::deleteTeam(int id)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/teams/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit teamDeleted(id);
        } else {
            emit errorTeamDeleted(response.error->message, response.error->status,
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
        if (localPath.startsWith("file://")) {
            localPath = localPath.mid(7);
        }
    }

    QString path = QString("/api/v1/teams/%1/image").arg(teamId);
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    QString boundary = "boundary" + QUuid::createUuid().toString(QUuid::WithoutBraces);
    multiPart->setBoundary(boundary.toLatin1());

    QFile *file = new QFile(localPath);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        delete multiPart;
        emit uploadImageError("Failed to open image file");
        setLoading(false);
        return QtFuture::makeReadyVoidFuture();
    }

    QHttpPart imagePart;
    imagePart.setHeader(QNetworkRequest::ContentTypeHeader,
                       QVariant(localPath.endsWith(".png", Qt::CaseInsensitive) ? "image/png" : "image/jpeg"));
    imagePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                       QVariant(QString("form-data; name=\"image\"; filename=\"%1\"")
                               .arg(QFileInfo(localPath).fileName())));

    QByteArray fileData = file->readAll();
    file->close();
    delete file;

    imagePart.setBody(fileData);
    multiPart->append(imagePart);

    request.setHeader(QNetworkRequest::ContentTypeHeader,
                     QString("multipart/form-data; boundary=%1").arg(boundary));

    auto future = makeRequest<QJsonObject>([=]() {
        QNetworkReply* reply = m_netManager->post(request, multiPart);
        multiPart->setParent(reply);
        return reply;
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &teamData = response.data->value("team").toObject();
            Team updatedTeam = teamFromJson(teamData);
            emit teamUpdated(updatedTeam);
        } else {
            emit teamError(response.error->message, response.error->status,
                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> TeamApi::removeTeamImage(int teamId)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/teams/%1/image").arg(teamId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit imageRemoved(teamId);
        } else {
            emit teamError(response.error->message, response.error->status,
                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

Team TeamApi::teamFromJson(const QJsonObject &json) const
{
    Team team;
    team.id = json["id"].toInt();
    team.name = json["name"].toString();
    team.email = json["email"].toString();
    team.phone = json["phone"].toString();
    team.address = json["address"].toString();
    team.image_path = json["image_path"].toString();
    return team;
}

QJsonObject TeamApi::teamToJson(const Team &team) const
{
    QJsonObject json;
    json["name"] = team.name;
    json["email"] = team.email;
    json["phone"] = team.phone;
    json["address"] = team.address;
    return json;
}

PaginatedTeams TeamApi::paginatedTeamsFromJson(const QJsonObject &json) const
{
    PaginatedTeams result;
    const QJsonObject &meta = json["teams"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(teamFromJson(value.toObject()));
    }

    return result;
}

QVariantMap TeamApi::teamToVariantMap(const Team &team) const
{
    QVariantMap map;
    map["id"] = team.id;
    map["name"] = team.name;
    map["email"] = team.email;
    map["phone"] = team.phone;
    map["address"] = team.address;
    map["image_path"] = team.image_path;
    return map;
}

Team TeamApi::teamFromVariantMap(const QVariantMap &map) const
{
    Team team;
    team.name = map.value("name").toString();
    team.email = map.value("email").toString();
    team.phone = map.value("phone").toString();
    team.address = map.value("address").toString();
    return team;
}

QString TeamApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void TeamApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
