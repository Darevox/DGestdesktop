#include "productapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>

namespace NetworkApi {

QNetworkAccessManager* ProductApi::netManager = nullptr;

void ProductApi::setSharedNetworkManager(QNetworkAccessManager* manager)
{
    if (netManager && netManager->parent() == nullptr) {
        delete netManager;
    }
    netManager = manager;
}

void ProductApi::ensureSharedNetworkManager()
{
    if (!netManager) {
        netManager = new QNetworkAccessManager();
    }
}

// Modified constructors
ProductApi::ProductApi(QObject *parent)
    : AbstractApi(nullptr, parent)
    , m_settings("Dervox", "DGest")

{
    ensureSharedNetworkManager();
    setNetworkManager(netManager);
    m_favoriteManager = new FavoriteManager(this);
}

ProductApi::ProductApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    , m_settings("Dervox", "DGest")
{
    m_favoriteManager = new FavoriteManager(this);
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
            emit errorProductsReceived(response.error->message, response.error->status,
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
            emit errorProductReceived(response.error->message, response.error->status,
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
            QVariantMap productMap= productToVariantMap(createdProduct);
            emit productReceivedForBarcode(productMap);
            emit productCreated(createdProduct);
        } else {
            emit errorProductCreated(response.error->message, response.error->status,
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
            emit errorProductUpdated(response.error->message, response.error->status,
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
          //  m_favoriteManager->removeProductFromAllCategories(id);
        } else {
            emit errorPoductDeleted(response.error->message, response.error->status,
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
            emit errorBarcodeAdded(response.error->message, response.error->status,
                                   QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::updateProductBarcode(int productId, int barcodeId, const QString &newBarcode)
{
    setLoading(true);

    QNetworkRequest request = createRequest(
                QString("/api/v1/products/%1/barcodes/%2").arg(productId).arg(barcodeId)
                );
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["barcode"] = newBarcode;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &barcodeData = response.data->value("barcode").toObject();
            emit barcodeUpdated(barcodeData);
        } else {
            emit errorBarcodeUpdated(response.error->message, response.error->status,
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
            emit errorBarcodeRemoved(response.error->message, response.error->status,
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
            emit errorProductBarcodesReceived(response.error->message, response.error->status,
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
    product.image_path = json["image_path"].toString();
    if (json.contains("unit")) {
        product.unit = productUnitFromJson(json["unit"].toObject());
    }
    if (json.contains("packages") && json["packages"].isArray()) {
        QJsonArray packagesArray = json["packages"].toArray();
        for (const QJsonValue &value : packagesArray) {
            QJsonObject packageObj = value.toObject();
            ProductPackageProduct package;
            package.id = packageObj["id"].toInt();
            package.name = packageObj["name"].toString();
            package.pieces_per_package = packageObj["pieces_per_package"].toInt();
            package.purchase_price = packageObj["purchase_price"].toDouble();
            package.selling_price = packageObj["selling_price"].toDouble();
            package.barcode = packageObj["barcode"].toString();
            product.packages.append(package);
        }
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
    qDebug() << "Converting product to JSON";
    qDebug() << "Packages count:" << product.packages.size();

    if (!product.packages.isEmpty()) {
        qDebug() << "Creating packages array";
        QJsonArray packagesArray;
        for (const ProductPackageProduct &package : product.packages) {
            QJsonObject packageObj;
            packageObj["name"] = package.name;
            packageObj["pieces_per_package"] = package.pieces_per_package;
            packageObj["purchase_price"] = package.purchase_price;
            packageObj["selling_price"] = package.selling_price;
            packageObj["barcode"] = package.barcode;
            packagesArray.append(packageObj);
            qDebug() << "Added package:" << packageObj;
        }
        json["packages"] = packagesArray;
    }

    qDebug() << "Final JSON:" << json;
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
    map["image_path"] = product.image_path;
    // Handle the unit
    QVariantMap unitMap;
    unitMap["id"] = product.unit.id;
    unitMap["name"] = product.unit.name;
    map["unit"] = unitMap;
    QVariantList packagesList;
    for (const ProductPackageProduct &package : product.packages) {
        QVariantMap packageMap;
        packageMap["id"] = package.id;           // Make sure to include the ID
        packageMap["name"] = package.name;
        packageMap["pieces_per_package"] = package.pieces_per_package;
        packageMap["purchase_price"] = package.purchase_price;
        packageMap["selling_price"] = package.selling_price;
        packageMap["barcode"] = package.barcode;
        packagesList.append(packageMap);
    }
    map["packages"] = packagesList;
    return map;
}

// QFuture<void> ProductApi::uploadProductImage(int productId, const QString &imagePath)
// {
//     setLoading(true);
//     qDebug() << "Original Path:" << imagePath;

//       // Convert URL to local file path
//       QString localPath = QUrl(imagePath).toLocalFile();
//       if (localPath.isEmpty()) {
//           // If toLocalFile() returns empty, try removing the file:// prefix manually
//           localPath = imagePath;
//           if (localPath.startsWith("file://")) {
//               localPath = localPath.mid(7);  // Remove "file://"
//           }
//       }

//       qDebug() << "Local Path:" << localPath;
//  qDebug()<<"===================================FILE : "<<imagePath;
//         QString path = QString("/api/v1/products/%1/image").arg(productId);
//     QNetworkRequest request = createRequest(path);
//     request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

//     // Create multipart request
//     QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

//     // Add method override for PUT request
//     QHttpPart methodPart;
//     methodPart.setHeader(QNetworkRequest::ContentDispositionHeader,
//                          QVariant("form-data; name=\"_method\""));
//     methodPart.setBody("PUT");
//     multiPart->append(methodPart);
//     qDebug()<<"===================================Upload";
//     // Add image file
//     QFile *file = new QFile(localPath);
//     if (!file->open(QIODevice::ReadOnly)) {
//         delete file;
//         delete multiPart;
//         qDebug()<<"===================================Failed to open image file";
//         emit uploadImageError("Failed to open image file ");
//         setLoading(false);
//         return QtFuture::makeReadyVoidFuture();
//     }
//     qDebug()<<"===================================Upload2";
//     QHttpPart imagePart;
//     imagePart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant("image/jpeg"));
//     imagePart.setHeader(QNetworkRequest::ContentDispositionHeader,
//                         QVariant("form-data; name=\"image\"; filename=\"image.jpg\""));
//     imagePart.setBodyDevice(file);
//     file->setParent(multiPart); // File will be deleted with multiPart
//     multiPart->append(imagePart);

//     auto future = makeRequest<QJsonObject>([=]() {
//         QNetworkReply* reply = m_netManager->post(request, multiPart);
//         multiPart->setParent(reply); // Delete multiPart with reply
//         return reply;
//     }).then([=](JsonResponse response) {
//         if (response.success) {
//             const QJsonObject &productData = response.data->value("product").toObject();
//             Product updatedProduct = productFromJson(productData);
//             emit productUpdated(updatedProduct);
//             qDebug()<<"===================================Works";

//         } else {
//             qDebug()<<"===================================Error";

//             emit productError(response.error->message, response.error->status,
//                               QJsonDocument(response.error->details).toJson());
//         }
//         setLoading(false);
//     });

//     return future.then([=]() {});
// }
QFuture<void> ProductApi::uploadProductImage(int productId, const QString &imagePath)
{
    setLoading(true);

    // Convert URL to local file path
    QString localPath = QUrl(imagePath).toLocalFile();
    if (localPath.isEmpty()) {
        localPath = imagePath;
        if (localPath.startsWith("file://")) {
            localPath = localPath.mid(7);
        }
    }

    QString path = QString("/api/v1/products/%1/image").arg(productId);
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    // Create multipart with explicit boundary
    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    QString boundary = "boundary" + QUuid::createUuid().toString(QUuid::WithoutBraces);
    multiPart->setBoundary(boundary.toLatin1());

    // Add image file
    QFile *file = new QFile(localPath);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        delete multiPart;
        emit uploadImageError("Failed to open image file");
        setLoading(false);
        return QtFuture::makeReadyVoidFuture();
    }

    QHttpPart imagePart;

    // Set headers
    imagePart.setHeader(QNetworkRequest::ContentTypeHeader,
                        QVariant(localPath.endsWith(".png", Qt::CaseInsensitive) ? "image/png" : "image/jpeg"));

    imagePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                        QVariant(QString("form-data; name=\"image\"; filename=\"%1\"")
                                 .arg(QFileInfo(localPath).fileName())));

    // Read file content
    QByteArray fileData = file->readAll();
    file->close();
    delete file;

    // Set the body
    imagePart.setBody(fileData);
    multiPart->append(imagePart);

    // Set the content type for the request
    request.setHeader(QNetworkRequest::ContentTypeHeader,
                      QString("multipart/form-data; boundary=%1").arg(boundary));

    qDebug() << "Sending request:";
    qDebug() << "Boundary:" << boundary;
    qDebug() << "Content-Type:" << request.header(QNetworkRequest::ContentTypeHeader);
    qDebug() << "File size:" << fileData.size();

    auto future = makeRequest<QJsonObject>([=]() {
        QNetworkReply* reply = m_netManager->post(request, multiPart);
        multiPart->setParent(reply);

        connect(reply, &QNetworkReply::uploadProgress,
                [](qint64 bytesSent, qint64 bytesTotal) {
            qDebug() << "Upload progress:" << bytesSent << "/" << bytesTotal;
        });

        return reply;
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product").toObject();
            Product updatedProduct = productFromJson(productData);
            emit productUpdated(updatedProduct);
            qDebug() << "Image upload successful";
        } else {
            qDebug() << "Image upload failed";
            qDebug() << "Error details:" << response.error->details;
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}



QFuture<void> ProductApi::removeProductImage(int productId)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QString("/api/v1/products/%1/image").arg(productId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            emit imageRemoved(productId);
        } else {
            emit productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}


QString ProductApi::getToken() const {
    QString token=m_settings.value("auth/token").toString();
    return token;
}
void ProductApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
