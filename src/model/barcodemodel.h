#ifndef BARCODEMODEL_H
#define BARCODEMODEL_H

#include <QAbstractTableModel>
#include <QJsonObject>

#include "../api/productapi.h"

namespace NetworkApi {

class BarcodeModel : public QAbstractTableModel
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    enum BarcodeRoles {
        IdRole = Qt::UserRole + 1,
        BarcodeRole,
        PrimaryRole
    };
    Q_ENUM(BarcodeRoles)
    explicit BarcodeModel(QObject *parent = nullptr);

    Q_INVOKABLE void setApi(ProductApi* api);
    Q_INVOKABLE void setProductId(int productId);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void addBarcode(const QString &barcode);
    Q_INVOKABLE void removeBarcode(int barcodeId);

    bool isLoading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }

signals:
    void loadingChanged();
    void errorMessageChanged();

private slots:
    void handleBarcodesReceived(const QList<QJsonObject> &barcodes);
    void handleBarcodeAdded(const QJsonObject &barcode);
    void handleBarcodeRemoved(int productId, int barcodeId);
    void handleProductError(const QString &message, ApiStatus status);

private:
    void setLoading(bool loading);
    void setErrorMessage(const QString &message);

    ProductApi *m_api;
    QList<QJsonObject> m_barcodes;
    bool m_loading;
    QString m_errorMessage;
    int m_productId;
};

} // namespace NetworkApi

#endif // BARCODEMODEL_H
