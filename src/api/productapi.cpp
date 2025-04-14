#include "productapi.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <qstandardpaths.h>

namespace NetworkApi {
using namespace Qt::StringLiterals;
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
    , m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))

{
    ensureSharedNetworkManager();
    setNetworkManager(netManager);
    m_favoriteManager = new FavoriteManager(this);
}

ProductApi::ProductApi(QNetworkAccessManager *netManager, QObject *parent)
    : AbstractApi(netManager, parent)
    ,  m_settings(QStringLiteral("Dervox"), QStringLiteral("DGest"))
{
    m_favoriteManager = new FavoriteManager(this);
}

QFuture<void> ProductApi::getProducts(const QString &search, const QString &sortBy,
                                      const QString &sortDirection,int page, bool lowStock,
                                      bool expiringSoon, const QString &status)
{
    setLoading(true);
    QString path = QStringLiteral("/api/v1/products");

    // Build query string manually
    QStringList queryParts;
    if (!search.isEmpty())
        queryParts << QStringLiteral("search=%1").arg(search);
    if (!sortBy.isEmpty())
        queryParts << QStringLiteral("sort_by=%1").arg(sortBy);
    if (!sortDirection.isEmpty())
        queryParts << QStringLiteral("sort_direction=%1").arg(sortDirection);
    if (lowStock)
        queryParts <<QStringLiteral( "low_stock=1");
    if (expiringSoon)
        queryParts <<QStringLiteral( "expiring_soon=1");
    if (page > 0)
        queryParts << QStringLiteral("page=%1").arg(page);
    if (!status.isEmpty())
        queryParts << QStringLiteral("status=%1").arg(status);

    // Add query parameters to path if there are any
    if (!queryParts.isEmpty()) {
      path += QStringLiteral("?") + queryParts.join(QLatin1String("&"));
    }

    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            PaginatedProducts paginatedProducts = paginatedProductsFromJson(*response.data);
            Q_EMIT productsReceived(paginatedProducts);
        } else {
            Q_EMIT errorProductsReceived(response.error->message, response.error->status,
                                       QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::getProduct(int id)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products/%1").arg(id));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product"_L1).toObject();
            Product product = productFromJson(productData);
            QVariantMap productMap= productToVariantMap(product);
            Q_EMIT productReceived(productMap);
        } else {
            Q_EMIT errorProductReceived(response.error->message, response.error->status,
                                      QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::createProduct(const Product &product)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = productToJson(product);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product"_L1).toObject();
            Product createdProduct = productFromJson(productData);
            QVariantMap productMap= productToVariantMap(createdProduct);
            Q_EMIT productReceivedForBarcode(productMap);
            Q_EMIT productCreated(createdProduct);
        } else {
            Q_EMIT errorProductCreated(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::updateProduct(int id, const Product &product)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData = productToJson(product);

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product"_L1).toObject();
            Product updatedProduct = productFromJson(productData);
            Q_EMIT productUpdated(updatedProduct);
        } else {
            Q_EMIT errorProductUpdated(response.error->message, response.error->status,
                                     QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::deleteProduct(int id)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products/%1").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT productDeleted(id);
          //  m_favoriteManager->removeProductFromAllCategories(id);
        } else {
            Q_EMIT errorPoductDeleted(response.error->message, response.error->status,
                                    QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::updateStock(int id, int quantity, const QString &operation)
{

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products/%1/stock").arg(id));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["quantity"_L1] = quantity;
    jsonData["operation"_L1] = operation;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &productData = response.data->value("product"_L1).toObject();
            Product updatedProduct = productFromJson(productData);
            Q_EMIT stockUpdated(updatedProduct);
        } else {
            Q_EMIT productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::getLowStockProducts()
{
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products/low-stock"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QList<Product> products;
            const QJsonArray &productsArray = response.data->value("products"_L1).toArray();
            for (const QJsonValue &value : productsArray) {
                products.append(productFromJson(value.toObject()));
            }
            Q_EMIT lowStockProductsReceived(products);
        } else {
            Q_EMIT productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::getProductUnits()
{
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/product-units"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QList<ProductUnit> units;
            const QJsonArray &unitsArray = response.data->value("units"_L1).toArray();
            for (const QJsonValue &value : unitsArray) {
                units.append(productUnitFromJson(value.toObject()));
            }
            Q_EMIT productUnitsReceived(units);
        } else {
            Q_EMIT productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
    });

    return future.then([=]() {});
}

QFuture<void> ProductApi::addProductBarcode(int productId, const QString &barcode)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products/%1/barcodes").arg(productId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["barcode"_L1] = barcode;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->post(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &barcodeData = response.data->value("barcode"_L1).toObject();
            // You might want to define a Barcode struct/class similar to Product
            Q_EMIT barcodeAdded(barcodeData);
        } else {
            Q_EMIT errorBarcodeAdded(response.error->message, response.error->status,
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
                QStringLiteral("/api/v1/products/%1/barcodes/%2").arg(productId).arg(barcodeId)
                );
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    QJsonObject jsonData;
    jsonData["barcode"_L1] = newBarcode;

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->put(request, QJsonDocument(jsonData).toJson());
    }).then([=](JsonResponse response) {
        if (response.success) {
            const QJsonObject &barcodeData = response.data->value("barcode"_L1).toObject();
            Q_EMIT barcodeUpdated(barcodeData);
        } else {
            Q_EMIT errorBarcodeUpdated(response.error->message, response.error->status,
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
                QStringLiteral("/api/v1/products/%1/barcodes/%2").arg(productId).arg(barcodeId)
                );
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT barcodeRemoved(productId, barcodeId);
        } else {
            Q_EMIT errorBarcodeRemoved(response.error->message, response.error->status,
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
                QStringLiteral("/api/v1/products/%1/barcodes").arg(productId)
                );
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<QJsonObject>([=]() {
        return m_netManager->get(request);
    }).then([=](JsonResponse response) {
        if (response.success) {
            QList<QJsonObject> barcodes;
            const QJsonArray &barcodesArray = response.data->value("barcodes"_L1).toArray();
            for (const QJsonValue &value : barcodesArray) {
                barcodes.append(value.toObject());
            }
            Q_EMIT productBarcodesReceived(barcodes);
        } else {
            Q_EMIT errorProductBarcodesReceived(response.error->message, response.error->status,
                                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}



Product ProductApi::productFromJson(const QJsonObject &json) const
{
    Product product;
    product.id = json["id"_L1].toInt();
    product.reference = json["reference"_L1].toString();
    product.name = json["name"_L1].toString();
    product.description = json["description"_L1].toString();
    product.price = json["price"_L1].toInt();
    product.purchase_price = json["purchase_price"_L1].toInt();
    product.expiredDate = QDateTime::fromString(json["expired_date"_L1].toString(), Qt::ISODate);
    product.quantity = json["quantity"_L1].toInt();
    product.productUnitId = json["product_unit_id"_L1].toInt();
    product.sku = json["sku"_L1].toString();
    //product.barcode = json["barcode"_L1].toString();
    product.minStockLevel = json["min_stock_level"_L1].toInt();
    product.maxStockLevel = json["max_stock_level"_L1].toInt();
    product.reorderPoint = json["reorder_point"_L1].toInt();
    product.location = json["location"_L1].toString();
    product.image_path = json["image_path"_L1].toString();
    if (json.contains("unit"_L1)) {
        product.unit = productUnitFromJson(json["unit"_L1].toObject());
    }
    if (json.contains("packages"_L1) && json["packages"_L1].isArray()) {
        QJsonArray packagesArray = json["packages"_L1].toArray();
        for (const QJsonValue &value : packagesArray) {
            QJsonObject packageObj = value.toObject();
            ProductPackageProduct package;
            package.id = packageObj["id"_L1].toInt();
            package.name = packageObj["name"_L1].toString();
            package.pieces_per_package = packageObj["pieces_per_package"_L1].toInt();
            package.purchase_price = packageObj["purchase_price"_L1].toDouble();
            package.selling_price = packageObj["selling_price"_L1].toDouble();
            package.barcode = packageObj["barcode"_L1].toString();
            product.packages.append(package);
        }
    }
    return product;
}

ProductUnit ProductApi::productUnitFromJson(const QJsonObject &json) const
{
    ProductUnit unit;
    unit.id = json["id"_L1].toInt();
    unit.name = json["name"_L1].toString();
    return unit;
}

QJsonObject ProductApi::productToJson(const Product &product) const
{
    QJsonObject json;
    json["reference"_L1] = product.reference;
    json["name"_L1] = product.name;
    json["description"_L1] = product.description;
    json["price"_L1] = product.price;
    json["purchase_price"_L1] = product.purchase_price;
    json["expired_date"_L1] = product.expiredDate.toString(Qt::ISODate);
    json["quantity"_L1] = product.quantity;
    //json["product_unit_id"_L1] = product.productUnitId;
    if (product.productUnitId == 0 || product.productUnitId == -1) {  // Assuming 0 represents null/unset
        json["product_unit_id"_L1] = QJsonValue::Null;
    } else {
        json["product_unit_id"_L1] = product.productUnitId;
    }

    json["sku"_L1] = product.sku;
    //json["barcode"_L1] = product.barcode;
    json["min_stock_level"_L1] = product.minStockLevel;
    json["max_stock_level"_L1] = product.maxStockLevel;
    json["reorder_point"_L1] = product.reorderPoint;
    json["location"_L1] = product.location;
    qDebug() << "Converting product to JSON";
    qDebug() << "Packages count:" << product.packages.size();

    if (!product.packages.isEmpty()) {
        qDebug() << "Creating packages array";
        QJsonArray packagesArray;
        for (const ProductPackageProduct &package : product.packages) {
            QJsonObject packageObj;
            packageObj["name"_L1] = package.name;
            packageObj["pieces_per_package"_L1] = package.pieces_per_package;
            packageObj["purchase_price"_L1] = package.purchase_price;
            packageObj["selling_price"_L1] = package.selling_price;
            packageObj["barcode"_L1] = package.barcode;
            packagesArray.append(packageObj);
            qDebug() << "Added package:" << packageObj;
        }
        json["packages"_L1] = packagesArray;
    }

    qDebug() << "Final JSON:" << json;
    return json;
}

PaginatedProducts ProductApi::paginatedProductsFromJson(const QJsonObject &json) const
{
    PaginatedProducts result;
    const QJsonObject &meta = json["products"_L1].toObject();
    result.currentPage = meta["current_page"_L1].toInt();
    result.lastPage = meta["last_page"_L1].toInt();
    result.perPage = meta["per_page"_L1].toInt();
    result.total = meta["total"_L1].toInt();

    const QJsonArray &dataArray = meta["data"_L1].toArray();
    for (const QJsonValue &value : dataArray) {
        result.data.append(productFromJson(value.toObject()));
    }

    return result;
}
QVariantMap ProductApi::productToVariantMap(const Product &product) const
{
    QVariantMap map;
    map["id"_L1] = product.id;
    map["reference"_L1] = product.reference;
    map["name"_L1] = product.name;
    map["description"_L1] = product.description;
    map["price"_L1] = product.price;
    map["purchase_price"_L1] = product.purchase_price;
    map["expiredDate"_L1] = product.expiredDate;
    map["quantity"_L1] = product.quantity;
    map["productUnitId"_L1] = product.productUnitId;
    map["sku"_L1] = product.sku;
    // map["barcode"_L1] = product.barcode;
    map["minStockLevel"_L1] = product.minStockLevel;
    map["maxStockLevel"_L1] = product.maxStockLevel;
    map["reorderPoint"_L1] = product.reorderPoint;
    map["location"_L1] = product.location;
    map["image_path"_L1] = product.image_path;
    // Handle the unit
    QVariantMap unitMap;
    unitMap["id"_L1] = product.unit.id;
    unitMap["name"_L1] = product.unit.name;
    map["unit"_L1] = unitMap;
    QVariantList packagesList;
    for (const ProductPackageProduct &package : product.packages) {
        QVariantMap packageMap;
        packageMap["id"_L1] = package.id;           // Make sure to include the ID
        packageMap["name"_L1] = package.name;
        packageMap["pieces_per_package"_L1] = package.pieces_per_package;
        packageMap["purchase_price"_L1] = package.purchase_price;
        packageMap["selling_price"_L1] = package.selling_price;
        packageMap["barcode"_L1] = package.barcode;
        packagesList.append(packageMap);
    }
    map["packages"_L1] = packagesList;
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
//         QString path = QStringLiteral("/api/v1/products/%1/image").arg(productId);
//     QNetworkRequest request = createRequest(path);
//     request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

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
//         Q_EMIT uploadImageError("Failed to open image file ");
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
//             Q_EMIT productUpdated(updatedProduct);
//             qDebug()<<"===================================Works";

//         } else {
//             qDebug()<<"===================================Error";

//             Q_EMIT productError(response.error->message, response.error->status,
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
        if (localPath.startsWith(QStringLiteral("file://"))) {
            localPath = localPath.mid(7);
        }
    }

    QString path = QStringLiteral("/api/v1/products/%1/image").arg(productId);
    QNetworkRequest request = createRequest(path);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    // Create multipart with explicit boundary
    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    QString boundary = QStringLiteral("boundary%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    multiPart->setBoundary(boundary.toLatin1());

    // Add image file
    QFile *file = new QFile(localPath);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        delete multiPart;
        Q_EMIT uploadImageError(QStringLiteral("Failed to open image file"));
        setLoading(false);
        return QtFuture::makeReadyVoidFuture();
    }

    QHttpPart imagePart;

    // Set headers
    imagePart.setHeader(QNetworkRequest::ContentTypeHeader,
                        QVariant(localPath.endsWith(QStringLiteral(".png"), Qt::CaseInsensitive) ? QStringLiteral("image/png") : QStringLiteral("image/jpeg")));

    imagePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                        QVariant(QStringLiteral("form-data; name=\"image\"; filename=\"%1\"")
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
                      QStringLiteral("multipart/form-data; boundary=%1").arg(boundary));

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
            const QJsonObject &productData = response.data->value("product"_L1).toObject();
            Product updatedProduct = productFromJson(productData);
            Q_EMIT productUpdated(updatedProduct);
            qDebug() << "Image upload successful";
        } else {
            qDebug() << "Image upload failed";
            qDebug() << "Error details:" << response.error->details;
            Q_EMIT productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}



QFuture<void> ProductApi::removeProductImage(int productId)
{
    setLoading(true);

    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/products/%1/image").arg(productId));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_token).toUtf8());

    auto future = makeRequest<std::monostate>([=]() {
        return m_netManager->deleteResource(request);
    }).then([=](VoidResponse response) {
        if (response.success) {
            Q_EMIT imageRemoved(productId);
        } else {
            Q_EMIT productError(response.error->message, response.error->status,
                              QJsonDocument(response.error->details).toJson());
        }
        setLoading(false);
    });

    return future.then([=]() {});
}
QFuture<QByteArray> ProductApi::generateProductBarcode(int productId, const QString &barcodeType, const QVariantMap &options)
{
    setLoading(true);

    // Build the JSON data with all parameters
    QJsonObject jsonData;
    jsonData["product_id"_L1] = productId;
    jsonData["barcode_type"_L1] = barcodeType;

    // Extract display options
    jsonData["show_team_name"_L1] = options.value(QStringLiteral("showTeamName"), false).toBool();
    jsonData["show_price"_L1] = options.value(QStringLiteral("showPrice"), false).toBool();
    jsonData["show_product_name"_L1] = options.value(QStringLiteral("showProductName"), false).toBool();
    jsonData["show_content"_L1] = options.value(QStringLiteral("showContent"), false).toBool();
    jsonData["paper_width"_L1] = options.value(QStringLiteral("paperWidth"), 80).toInt();
    jsonData["paper_height"_L1] = options.value(QStringLiteral("paperHeight"), 30).toInt();

    // Prepare the request
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/barcodes/generate"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto promise = std::make_shared<QPromise<QByteArray>>();

    // Make the POST request
    m_currentReply = m_netManager->post(request, QJsonDocument(jsonData).toJson());

    connect(m_currentReply, &QNetworkReply::finished, this, [this, promise]() {
        setLoading(false);

        if (m_currentReply->error() == QNetworkReply::NoError) {
            QString contentType = m_currentReply->header(QNetworkRequest::ContentTypeHeader).toString();

            if (contentType.contains("application/pdf"_L1)) {
                QByteArray pdfData = m_currentReply->readAll();

                // Extract dimension metadata from response headers
                int paperWidthMM = m_currentReply->rawHeader(QStringLiteral("X-Paper-Width")).toInt();
                int paperHeightMM = m_currentReply->rawHeader(QStringLiteral("X-Paper-Height")).toInt();

                // Save to app's data location
                QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
                QDir().mkpath(QStringLiteral("%1/pdfs").arg(appDataPath));

                QString fileName = QStringLiteral("barcode-%1.pdf").arg(QDateTime::currentMSecsSinceEpoch());
                QString filePath = QStringLiteral("%1/pdfs/%2").arg(appDataPath, fileName);

                QFile file(filePath);
                if (file.open(QIODevice::WriteOnly)) {
                    file.write(pdfData);
                    file.close();

                    // Ensure we create a proper URL using QUrl
                    QUrl fileUrl = QUrl::fromLocalFile(filePath);
                    QString fileUrlString = fileUrl.toString();

                    qDebug() << "Barcode PDF saved to:" << fileUrlString;
                    qDebug() << "PDF dimensions: Width=" << paperWidthMM << "mm, Height=" << paperHeightMM << "mm";

                    // Create dimensioned URL with metadata
                    QUrl pdfUrl(fileUrlString);
                    QUrlQuery urlQuery;
                    urlQuery.addQueryItem(QStringLiteral("paperWidth"), QString::number(paperWidthMM));
                    urlQuery.addQueryItem(QStringLiteral("paperHeight"), QString::number(paperHeightMM));
                    pdfUrl.setQuery(urlQuery);

                    // Emit signal with dimensioned URL
                    Q_EMIT barcodeGenerated(pdfUrl.toString());
                    promise->addResult(pdfData);
                    setLoading(false);
                } else {
                    Q_EMIT errorBarcodeGenerated(QStringLiteral("Failed to save PDF"), file.errorString());
                    promise->addResult(QByteArray());
                }
            } else if (contentType.contains("application/json"_L1)) {
                // Handle error response
                QJsonDocument jsonResponse = QJsonDocument::fromJson(m_currentReply->readAll());
                QJsonObject jsonObject = jsonResponse.object();
                QString errorMessage = jsonObject["message"_L1].toString();
                Q_EMIT errorBarcodeGenerated(QStringLiteral("Error"), errorMessage);
                promise->addResult(QByteArray());
            }
        } else {
            Q_EMIT errorBarcodeGenerated(QStringLiteral("Network Error"), m_currentReply->errorString());
            promise->addResult(QByteArray());
        }

        promise->finish();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    });

    return promise->future();
}

QFuture<QByteArray> ProductApi::generateCustomBarcode(const QString &content, const QString &barcodeType, const QString &customName, const QString &customPrice, const QVariantMap &options)
{
    setLoading(true);

    // Build the JSON data with all parameters
    QJsonObject jsonData;
    jsonData["content"_L1] = content;
    jsonData["barcode_type"_L1] = barcodeType;
    jsonData["custom_name"_L1] = customName;
    jsonData["custom_price"_L1] = customPrice;

    // Extract display options
    jsonData["show_team_name"_L1] = options.value(QStringLiteral("showTeamName"), false).toBool();
    jsonData["show_price"_L1] = options.value(QStringLiteral("showPrice"), false).toBool();
    jsonData["show_product_name"_L1] = options.value(QStringLiteral("showProductName"), false).toBool();
    jsonData["show_content"_L1] = options.value(QStringLiteral("showContent"), false).toBool();
    jsonData["paper_width"_L1] = options.value(QStringLiteral("paperWidth"), 80).toInt();
    jsonData["paper_height"_L1] = options.value(QStringLiteral("paperHeight"), 30).toInt();

    // Prepare the request
    QNetworkRequest request = createRequest(QStringLiteral("/api/v1/barcodes/generate"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(getToken()).toUtf8());

    auto promise = std::make_shared<QPromise<QByteArray>>();

    // Make the POST request
    m_currentReply = m_netManager->post(request, QJsonDocument(jsonData).toJson());

    connect(m_currentReply, &QNetworkReply::finished, this, [this, promise]() {
        setLoading(false);

        if (m_currentReply->error() == QNetworkReply::NoError) {
            QString contentType = m_currentReply->header(QNetworkRequest::ContentTypeHeader).toString();

            if (contentType.contains("application/pdf"_L1)) {
                QByteArray pdfData = m_currentReply->readAll();

                // Extract dimension metadata from response headers
                int paperWidthMM = m_currentReply->rawHeader(QStringLiteral("X-Paper-Width")).toInt();
                int paperHeightMM = m_currentReply->rawHeader(QStringLiteral("X-Paper-Height")).toInt();

                // Save to app's data location
                QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
                QDir().mkpath(QStringLiteral("%1/pdfs").arg(appDataPath));

                QString fileName = QStringLiteral("barcode-%1.pdf").arg(QDateTime::currentMSecsSinceEpoch());
                QString filePath = QStringLiteral("%1/pdfs/%2").arg(appDataPath, fileName);

                QFile file(filePath);
                if (file.open(QIODevice::WriteOnly)) {
                    file.write(pdfData);
                    file.close();

                    // Ensure we create a proper URL using QUrl
                    QUrl fileUrl = QUrl::fromLocalFile(filePath);
                    QString fileUrlString = fileUrl.toString();

                    qDebug() << "Barcode PDF saved to:" << fileUrlString;
                    qDebug() << "PDF dimensions: Width=" << paperWidthMM << "mm, Height=" << paperHeightMM << "mm";

                    // Create dimensioned URL with metadata
                    QUrl pdfUrl(fileUrlString);
                    QUrlQuery urlQuery;
                    urlQuery.addQueryItem(QStringLiteral("paperWidth"), QString::number(paperWidthMM));
                    urlQuery.addQueryItem(QStringLiteral("paperHeight"), QString::number(paperHeightMM));
                    pdfUrl.setQuery(urlQuery);

                    // Emit signal with dimensioned URL
                    Q_EMIT barcodeGenerated(pdfUrl.toString());
                    promise->addResult(pdfData);
                    setLoading(false);
                } else {
                    Q_EMIT errorBarcodeGenerated(QStringLiteral("Failed to save PDF"), file.errorString());
                    promise->addResult(QByteArray());
                }
            } else if (contentType.contains("application/json"_L1)) {
                // Handle error response
                QJsonDocument jsonResponse = QJsonDocument::fromJson(m_currentReply->readAll());
                QJsonObject jsonObject = jsonResponse.object();
                QString errorMessage = jsonObject["message"_L1].toString();
                Q_EMIT errorBarcodeGenerated(QStringLiteral("Error"), errorMessage);
                promise->addResult(QByteArray());
            }
        } else {
            Q_EMIT errorBarcodeGenerated(QStringLiteral("Network Error"), m_currentReply->errorString());
            promise->addResult(QByteArray());
        }

        promise->finish();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    });

    return promise->future();
}

QString ProductApi::getToken() const {
    QString token=m_settings.value("auth/token").toString();
    return token;
}
void ProductApi::saveToken(const QString &token) {
    m_token = token;
}

} // namespace NetworkApi
