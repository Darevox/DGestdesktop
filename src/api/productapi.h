// productapi.h
#ifndef PRODUCTAPI_H
#define PRODUCTAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>
namespace NetworkApi {

struct ProductUnit {
    int id;
    QString name;
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
    bool checked = false;
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
    Q_INVOKABLE QFuture<void> removeProductBarcode(int productId, int barcodeId);
    Q_INVOKABLE QFuture<void> getProductBarcodes(int productId);




    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);
    bool isLoading() const { return m_isLoading; }
signals:
    // Success signals
    void productsReceived(const PaginatedProducts &products);
    void productReceived(const QVariantMap &product);
    void productCreated(const Product &product);
    void productUpdated(const Product &product);
    void productDeleted(int id);
    void stockUpdated(const Product &product);
    void lowStockProductsReceived(const QList<Product> &products);
    void productUnitsReceived(const QList<ProductUnit> &units);

    // Error signals
    void productError(const QString &message, ApiStatus status,const QString &details);
    void productNotFound();

    void barcodeAdded(const QJsonObject &barcode);
    void barcodeRemoved(int productId, int barcodeId);
    void productBarcodesReceived(const QList<QJsonObject> &barcodes);

    void isLoadingChanged();

private:
    Product productFromJson(const QJsonObject &json) const;
    ProductUnit productUnitFromJson(const QJsonObject &json) const;
    QJsonObject productToJson(const Product &product) const;
    PaginatedProducts paginatedProductsFromJson(const QJsonObject &json) const;
    QVariantMap productToVariantMap(const Product &product) const;
    QSettings m_settings;

    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            emit isLoadingChanged();
        }
    }
};

} // namespace NetworkApi
#endif // PRODUCTAPI_H
