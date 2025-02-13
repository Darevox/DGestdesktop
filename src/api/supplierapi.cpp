// supplierapi.cpp
#include "supplierapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrlQuery>

namespace NetworkApi {
using namespace Qt::StringLiterals;

SupplierApi::SupplierApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
}

QFuture<void> SupplierApi::getSuppliers(const QString &search, const QString &sortBy,
                                       const QString &sortDirection, int page)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/suppliers");

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

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedSuppliers paginatedSuppliers = paginatedSuppliersFromJson(*response.data);
            Q_EMIT suppliersReceived(paginatedSuppliers);
        } else {
            Q_EMIT errorSuppliersReceived(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::getSupplier(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/suppliers/%1").arg(id));

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            Supplier supplier = supplierFromJson(response.data->value("supplier"_L1).toObject());
            Q_EMIT supplierReceived(supplierToVariantMap(supplier));
        } else {
                Q_EMIT errorSupplierReceived(response.error->message, response.error->status,
                                         QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::createSupplier(const Supplier &supplier)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral( "/api/v1/suppliers"));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));

    QJsonObject jsonData = supplierToJson(supplier);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Supplier createdSupplier = supplierFromJson(response.data->value("supplier"_L1).toObject());
            Q_EMIT supplierCreated(createdSupplier);
        } else {
            Q_EMIT errorSupplierCreated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::updateSupplier(int id, const Supplier &supplier)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/suppliers/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader,QStringLiteral( "application/json"));

    QJsonObject jsonData = supplierToJson(supplier);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            Supplier updatedSupplier = supplierFromJson(response.data->value("supplier"_L1).toObject());
            Q_EMIT supplierUpdated(updatedSupplier);
        } else {
            Q_EMIT errorSupplierUpdated(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> SupplierApi::deleteSupplier(int id)
{
    setLoading(true);
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/suppliers/%1").arg(id));

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT supplierDeleted(id);
        } else {
            Q_EMIT errorSupplierDeleted(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

Supplier SupplierApi::supplierFromJson(const QJsonObject &json) const
{
    Supplier supplier;
    supplier.id = json["id"_L1].toInt();
    supplier.name = json["name"_L1].toString();
    supplier.email = json["email"_L1].toString();
    supplier.phone = json["phone"_L1].toString();
    supplier.address = json["address"_L1].toString();
    supplier.payment_terms = json["payment_terms"_L1].toString();
    supplier.tax_number = json["tax_number"_L1].toString();
    supplier.notes = json["notes"_L1].toString();
    supplier.status = json["status"_L1].toString();
    supplier.balance = json["balance"_L1].toString().toDouble();
    return supplier;
}

QJsonObject SupplierApi::supplierToJson(const Supplier &supplier) const
{
    QJsonObject json;
    json["name"_L1] = supplier.name;
    json["email"_L1] = supplier.email;
    json["phone"_L1] = supplier.phone;
    json["address"_L1] = supplier.address;
    json["payment_terms"_L1] = supplier.payment_terms;
    json["tax_number"_L1] = supplier.tax_number;
    json["notes"_L1] = supplier.notes;
    json["status"_L1] = supplier.status;
    return json;
}

PaginatedSuppliers SupplierApi::paginatedSuppliersFromJson(const QJsonObject &json) const
{
    PaginatedSuppliers result;
    const QJsonObject &meta = json["suppliers"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(supplierFromJson(value.toObject()));
    }

    return result;
}

QVariantMap SupplierApi::supplierToVariantMap(const Supplier &supplier) const
{
    QVariantMap map;
    map["id"_L1] = supplier.id;
    map["name"_L1] = supplier.name;
    map["email"_L1] = supplier.email;
    map["phone"_L1] = supplier.phone;
    map["address"_L1] = supplier.address;
    map["payment_terms"_L1] = supplier.payment_terms;
    map["tax_number"_L1] = supplier.tax_number;
    map["notes"_L1] = supplier.notes;
    map["status"_L1] = supplier.status;
    map["balance"_L1] = supplier.balance;
    return map;
}
QString SupplierApi::getToken() const {
    return m_settings.value("auth/token").toString();
}

void SupplierApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
