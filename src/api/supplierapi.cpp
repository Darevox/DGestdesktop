// supplierapi.cpp
#include "supplierapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {

SupplierApi::SupplierApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

QFuture<void> SupplierApi::getSuppliers(const QString &search, const QString &sortBy,
                                       const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = "/api/v1/suppliers";

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

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedSuppliers paginatedSuppliers = paginatedSuppliersFromJson(*response.data);
            emit suppliersReceived(paginatedSuppliers);
        } else {
            emit errorSuppliersReceived(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::getSupplier(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/suppliers/%1").arg(id));

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Supplier supplier = supplierFromJson(response.data->value("supplier").toObject());
            emit supplierReceived(supplierToVariantMap(supplier));
        } else {
                emit errorSupplierReceived(response.error->message, response.error->status,
                                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::createSupplier(const Supplier &supplier)
{
    setLoading(true);
    QNetworkRequest request = createRequest("/api/v1/suppliers");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject jsonData = supplierToJson(supplier);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Supplier createdSupplier = supplierFromJson(response.data->value("supplier").toObject());
            emit supplierCreated(createdSupplier);
        } else {
            emit errorSupplierCreated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::updateSupplier(int id, const Supplier &supplier)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/suppliers/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject jsonData = supplierToJson(supplier);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Supplier updatedSupplier = supplierFromJson(response.data->value("supplier").toObject());
            emit supplierUpdated(updatedSupplier);
        } else {
            emit errorSupplierUpdated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::deleteSupplier(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QString("/api/v1/suppliers/%1").arg(id));

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit supplierDeleted(id);
        } else {
            emit errorSupplierDeleted(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

Supplier SupplierApi::supplierFromJson(const QJsonObject &json) const
{
    Supplier supplier;
    supplier.id = json["id"].toInt();
    supplier.name = json["name"].toString();
    supplier.email = json["email"].toString();
    supplier.phone = json["phone"].toString();
    supplier.address = json["address"].toString();
    supplier.payment_terms = json["payment_terms"].toString();
    supplier.tax_number = json["tax_number"].toString();
    supplier.notes = json["notes"].toString();
    supplier.status = json["status"].toString();
    supplier.balance = json["balance"].toDouble();
    return supplier;
}

QJsonObject SupplierApi::supplierToJson(const Supplier &supplier) const
{
    QJsonObject json;
    json["name"] = supplier.name;
    json["email"] = supplier.email;
    json["phone"] = supplier.phone;
    json["address"] = supplier.address;
    json["payment_terms"] = supplier.payment_terms;
    json["tax_number"] = supplier.tax_number;
    json["notes"] = supplier.notes;
    json["status"] = supplier.status;
    return json;
}

PaginatedSuppliers SupplierApi::paginatedSuppliersFromJson(const QJsonObject &json) const
{
    PaginatedSuppliers result;
    const QJsonObject &meta = json["suppliers"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(supplierFromJson(value.toObject()));
    }

    return result;
}

QVariantMap SupplierApi::supplierToVariantMap(const Supplier &supplier) const
{
    QVariantMap map;
    map["id"] = supplier.id;
    map["name"] = supplier.name;
    map["email"] = supplier.email;
    map["phone"] = supplier.phone;
    map["address"] = supplier.address;
    map["payment_terms"] = supplier.payment_terms;
    map["tax_number"] = supplier.tax_number;
    map["notes"] = supplier.notes;
    map["status"] = supplier.status;
    map["balance"] = supplier.balance;
    return map;
}
QString SupplierApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void SupplierApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
