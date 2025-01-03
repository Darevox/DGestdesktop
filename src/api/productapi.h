// productapi.h
#ifndef PRODUCTAPI_H
#define PRODUCTAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>
#include <QHttpMultiPart>
#include <QFile>
#include <QFileInfo>
#include "../utils/favoritemanager.h"

namespace NetworkApi {

struct ProductUnit {
    int id;
    QString name;
};
struct ProductPackageProduct {
    int id;
    QString name;
    int pieces_per_package;
    double purchase_price;
    double selling_price;
    QString barcode;
};
struct Product {
    int id;
    QString reference;
    QString name;
    QString description;
    int price;
    int purchase_price;
    QDateTime expiredDate;
    int quantity;
    int productUnitId;
    QString sku;
    QString barcode;
    double minStockLevel;
    double maxStockLevel;
    double reorderPoint;
    QString location;
    ProductUnit unit;
    QList<ProductPackageProduct> packages;
    bool checked = false;
    QString image_path;
};

struct PaginatedProducts {
    QList<Product> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};
class ProductApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
public:
   // explicit ProductApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);
    explicit ProductApi(QObject *parent = nullptr);
    explicit ProductApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);
    // Main CRUD operations
    Q_INVOKABLE QFuture<void> getProducts(const QString &search = QString(),
                                          const QString &sortBy = "created_at",
                                          const QString &sortDirection = "desc",
                                          int page = 1,
                                          bool lowStock = false,
                                          bool expiringSoon = false,
                                          const QString &status = QString());

    Q_INVOKABLE QFuture<void> getProduct(int id);
    Q_INVOKABLE QFuture<void> createProduct(const Product &product);
    Q_INVOKABLE QFuture<void> updateProduct(int id, const Product &product);
    Q_INVOKABLE QFuture<void> deleteProduct(int id);

    // Additional operations
    Q_INVOKABLE QFuture<void> updateStock(int id, int quantity, const QString &operation);
    Q_INVOKABLE QFuture<void> getLowStockProducts();
    Q_INVOKABLE QFuture<void> getProductUnits();


    Q_INVOKABLE QFuture<void> addProductBarcode(int productId, const QString &barcode);
    Q_INVOKABLE QFuture<void> updateProductBarcode(int productId, int barcodeId, const QString &newBarcode);

    Q_INVOKABLE QFuture<void> removeProductBarcode(int productId, int barcodeId);
    Q_INVOKABLE QFuture<void> getProductBarcodes(int productId);

    Q_INVOKABLE QFuture<void> uploadProductImage(int productId, const QString &imagePath);
    Q_INVOKABLE QFuture<void> removeProductImage(int productId);

    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);
    bool isLoading() const { return m_isLoading; }

    static void setSharedNetworkManager(QNetworkAccessManager* manager);
signals:
    // Success signals
    void productsReceived(const PaginatedProducts &products);
    void productReceived(const QVariantMap &product);
    void productReceivedForBarcode(const QVariantMap &product); // to get id from  variantmap

    void productCreated(const Product &product);
    void productUpdated(const Product &product);
    void productDeleted(int id);
    void stockUpdated(const Product &product);
    void lowStockProductsReceived(const QList<Product> &products);
    void productUnitsReceived(const QList<ProductUnit> &units);

    // Error signals
    void productError(const QString &message, ApiStatus status,const QString &details);
    void productNotFound();
    void uploadImageError(const QString &message);

    void errorProductsReceived(const QString &message, ApiStatus status,const QString &details);
    void errorProductReceived(const QString &message, ApiStatus status,const QString &details);
    void errorProductCreated(const QString &message, ApiStatus status,const QString &details);
    void errorProductUpdated(const QString &message, ApiStatus status,const QString &details);
    void errorPoductDeleted(const QString &message, ApiStatus status,const QString &details);
    void errorBarcodeAdded(const QString &message, ApiStatus status,const QString &details);
    void errorBarcodeRemoved(const QString &message, ApiStatus status,const QString &details);
    void errorBarcodeUpdated(const QString &message, ApiStatus status,const QString &details);
    void errorProductBarcodesReceived(const QString &message, ApiStatus status,const QString &details);


    void barcodeAdded(const QJsonObject &barcode);
    void barcodeRemoved(int productId, int barcodeId);
    void barcodeUpdated(const QJsonObject &barcode);
    void productBarcodesReceived(const QList<QJsonObject> &barcodes);


    void imageRemoved(int productId);

    void isLoadingChanged();
    void imageUploaded(const QString &imageUrl);
private:
    Product productFromJson(const QJsonObject &json) const;
    ProductUnit productUnitFromJson(const QJsonObject &json) const;
    QJsonObject productToJson(const Product &product) const;
    PaginatedProducts paginatedProductsFromJson(const QJsonObject &json) const;
    QVariantMap productToVariantMap(const Product &product) const;
    Product productFromVariant(const QVariantMap &data) const;
    QSettings m_settings;
    QNetworkReply* createMultipartRequest(const QString &path, const QString &imagePath);
    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            emit isLoadingChanged();
        }
    }

    static QNetworkAccessManager* netManager;
    static void ensureSharedNetworkManager();

        FavoriteManager* m_favoriteManager;
};

} // namespace NetworkApi
#endif // PRODUCTAPI_H
