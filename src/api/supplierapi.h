// supplierapi.h
#ifndef SUPPLIERAPI_H
#define SUPPLIERAPI_H

#include "abstractapi.h"
#include <QSettings>
#include <QJsonArray>

namespace NetworkApi {

struct Supplier {
    int id;
    QString name;
    QString email;
    QString phone;
    QString address;
    QString payment_terms;
    QString tax_number;
    QString notes;
    QString status;
    double balance;
    bool checked = false;
};

struct PaginatedSuppliers {
    QList<Supplier> data;
    int currentPage;
    int lastPage;
    int perPage;
    int total;
};

class SupplierApi : public AbstractApi {
    Q_OBJECT
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit SupplierApi(QNetworkAccessManager *netManager, QObject *parent = nullptr);

    // CRUD operations
    Q_INVOKABLE QFuture<void> getSuppliers(const QString &search = QString(),
                                           const QString &sortBy = QStringLiteral("created_at"),
                                           const QString &sortDirection = QStringLiteral("desc"),
                                           int page = 1);
    Q_INVOKABLE QFuture<void> getSupplier(int id);
    Q_INVOKABLE QFuture<void> createSupplier(const Supplier &supplier);
    Q_INVOKABLE QFuture<void> updateSupplier(int id, const Supplier &supplier);
    Q_INVOKABLE QFuture<void> deleteSupplier(int id);

    bool isLoading() const { return m_isLoading; }
    Q_INVOKABLE QString getToken() const;
    Q_INVOKABLE void saveToken(const QString &token);
Q_SIGNALS:
    // Success signals
    void suppliersReceived(const PaginatedSuppliers &suppliers);
    void supplierReceived(const QVariantMap &supplier);
    void supplierCreated(const Supplier &supplier);
    void supplierUpdated(const Supplier &supplier);
    void supplierDeleted(int id);

    // Error signals for each operation
    void errorSuppliersReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorSupplierReceived(const QString &message, ApiStatus status, const QByteArray &details);
    void errorSupplierCreated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorSupplierUpdated(const QString &message, ApiStatus status, const QByteArray &details);
    void errorSupplierDeleted(const QString &message, ApiStatus status, const QByteArray &details);
    void supplierNotFound();

    void isLoadingChanged();

private:
    Supplier supplierFromJson(const QJsonObject &json) const;
    QJsonObject supplierToJson(const Supplier &supplier) const;
    PaginatedSuppliers paginatedSuppliersFromJson(const QJsonObject &json) const;
    QVariantMap supplierToVariantMap(const Supplier &supplier) const;
    QSettings m_settings;
    bool m_isLoading = false;
    void setLoading(bool loading) {
        if (m_isLoading != loading) {
            m_isLoading = loading;
            Q_EMIT isLoadingChanged();
        }
    }
};

} // namespace NetworkApi
#endif // SUPPLIERAPI_H
