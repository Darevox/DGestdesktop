#include "productapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>

namespace NetworkApi {

ProductApi::ProductApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
}

QFuture<void> ProductApi::getProducts(const QString &search, const QString &sortBy,
                                      const QString &sortDirection,int page, bool lowStock,
                                      bool expiringSoon, const QString &status)
{
    setLoading(true);
    QString path = "/api/v1/products";

    // Build query string manually
    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QString("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QString("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QString("sort_direction=%1").arg(sortDirection);
    if (lowStock)
        queryParts << "low_stock=1";
    if (expiringSoon)
        queryParts << "expiring_soon=1";
    if (page > 0)
        queryParts << QString("page=%1").arg(page);
    if (!status.isEmpty())
        queryParts << QString("status=%1").arg(status);

    // Add query parameters to path if there are any
    if (!queryParts.isEmpty()) {
        path += "?" + queryParts.join("&");
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedProducts paginatedProducts = paginatedProductsFromJson(*response.data);
            emit productsReceived(paginatedProducts);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::getProduct(int id)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/products/%1").arg(id));
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product").toObject();
            Product product = productFromJson(productData);
            QVariantMap productMap= productToVariantMap(product);
            emit productReceived(productMap);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::createProduct(const Product &product)
{
    setLoading(true);

    QNetworkRequest request = createRequest("/api/v1/products");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = productToJson(product);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product").toObject();
            Product createdProduct = productFromJson(productData);
            emit productCreated(createdProduct);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::updateProduct(int id, const Product &product)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/products/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = productToJson(product);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product").toObject();
            Product updatedProduct = productFromJson(productData);
            emit productUpdated(updatedProduct);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::deleteProduct(int id)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/products/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit productDeleted(id);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::updateStock(int id, int quantity, const QString &operation)
{

    QNetworkRequest request = createRequest(QString("/api/v1/products/%1/stock").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["quantity"] = quantity;
    jsonData["operation"] = operation;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product").toObject();
            Product updatedProduct = productFromJson(productData);
            emit stockUpdated(updatedProduct);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::getLowStockProducts()
{
    QNetworkRequest request = createRequest("/api/v1/products/low-stock");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QList<Product> products;
            const QJsonArray &productsArray = response.data->value("products").toArray();
            for (const QJsonValue &value : productsArray) {
                products.append(productFromJson(value.toObject()));
            }
            emit lowStockProductsReceived(products);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::getProductUnits()
{
    QNetworkRequest request = createRequest("/api/v1/product-units");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QList<ProductUnit> units;
            const QJsonArray &unitsArray = response.data->value("units").toArray();
            for (const QJsonValue &value : unitsArray) {
                units.append(productUnitFromJson(value.toObject()));
            }
            emit productUnitsReceived(units);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::addProductBarcode(int productId, const QString &barcode)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/products/%1/barcodes").arg(productId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["barcode"] = barcode;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &barcodeData = response.data->value("barcode").toObject();
            // You might want to define a Barcode struct/class similar to Product
            emit barcodeAdded(barcodeData);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::removeProductBarcode(int productId, int barcodeId)
{
    setLoading(true);

    QNetworkRequest request = createRequest(
        QString("/api/v1/products/%1/barcodes/%2").arg(productId).arg(barcodeId)
    );
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit barcodeRemoved(productId, barcodeId);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::getProductBarcodes(int productId)
{
    setLoading(true);

    QNetworkRequest request = createRequest(
        QString("/api/v1/products/%1/barcodes").arg(productId)
    );
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QList<QJsonObject> barcodes;
            const QJsonArray &barcodesArray = response.data->value("barcodes").toArray();
            for (const QJsonValue &value : barcodesArray) {
                barcodes.append(value.toObject());
            }
            emit productBarcodesReceived(barcodes);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}



Product ProductApi::productFromJson(const QJsonObject &json) const
{
    Product product;
    product.id = json["id"].toInt();
    product.reference = json["reference"].toString();
    product.name = json["name"].toString();
    product.description = json["description"].toString();
    product.price = json["price"].toInt();
    product.purchase_price = json["purchase_price"].toInt();
    product.expiredDate = QDateTime::fromString(json["expired_date"].toString(), Qt::ISODate);
    product.quantity = json["quantity"].toInt();
    product.productUnitId = json["product_unit_id"].toInt();
    product.sku = json["sku"].toString();
    //product.barcode = json["barcode"].toString();
    product.minStockLevel = json["min_stock_level"].toInt();
    product.maxStockLevel = json["max_stock_level"].toInt();
    product.reorderPoint = json["reorder_point"].toInt();
    product.location = json["location"].toString();

    if (json.contains("unit")) {
        product.unit = productUnitFromJson(json["unit"].toObject());
    }

    return product;
}

ProductUnit ProductApi::productUnitFromJson(const QJsonObject &json) const
{
    ProductUnit unit;
    unit.id = json["id"].toInt();
    unit.name = json["name"].toString();
    return unit;
}

QJsonObject ProductApi::productToJson(const Product &product) const
{
    QJsonObject json;
    json["reference"] = product.reference;
    json["name"] = product.name;
    json["description"] = product.description;
    json["price"] = product.price;
    json["purchase_price"] = product.purchase_price;
    json["expired_date"] = product.expiredDate.toString(Qt::ISODate);
    json["quantity"] = product.quantity;
    //json["product_unit_id"] = product.productUnitId;
    if (product.productUnitId == 0 || product.productUnitId == -1) {  // Assuming 0 represents null/unset
        json["product_unit_id"] = QJsonValue::Null;
    } else {
        json["product_unit_id"] = product.productUnitId;
    }

    json["sku"] = product.sku;
    //json["barcode"] = product.barcode;
    json["min_stock_level"] = product.minStockLevel;
    json["max_stock_level"] = product.maxStockLevel;
    json["reorder_point"] = product.reorderPoint;
    json["location"] = product.location;
    return json;
}

PaginatedProducts ProductApi::paginatedProductsFromJson(const QJsonObject &json) const
{
    PaginatedProducts result;
    const QJsonObject &meta = json["products"].toObject();
    result.currentPage = meta["current_page"].toInt();
    result.lastPage = meta["last_page"].toInt();
    result.perPage = meta["per_page"].toInt();
    result.total = meta["total"].toInt();

    const QJsonArray &dataArray = meta["data"].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(productFromJson(value.toObject()));
    }

    return result;
}
QVariantMap ProductApi::productToVariantMap(const Product &product) const
{
    QVariantMap map;
    map["id"] = product.id;
    map["reference"] = product.reference;
    map["name"] = product.name;
    map["description"] = product.description;
    map["price"] = product.price;
    map["purchase_price"] = product.purchase_price;
    map["expiredDate"] = product.expiredDate;
    map["quantity"] = product.quantity;
    map["productUnitId"] = product.productUnitId;
    map["sku"] = product.sku;
   // map["barcode"] = product.barcode;
    map["minStockLevel"] = product.minStockLevel;
    map["maxStockLevel"] = product.maxStockLevel;
    map["reorderPoint"] = product.reorderPoint;
    map["location"] = product.location;

    // Handle the unit
    QVariantMap unitMap;
    unitMap["id"] = product.unit.id;
    unitMap["name"] = product.unit.name;
    map["unit"] = unitMap;

    return map;
}
QString ProductApi::getToken() const {
    QString token=m_settings.value("auth/token").toString();
    return token;
}
void ProductApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
