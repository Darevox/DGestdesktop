#include "barcodemodel.h"

namespace NetworkApi {
using namespace Qt::StringLiterals;
BarcodeModel::BarcodeModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_api(nullptr)
    , m_loading(false)
    , m_productId(-1)
{
}

void BarcodeModel::setApi(ProductApi* api)
{
    if (m_api != api) {
        m_api = api;

        connect(m_api, &ProductApi::productBarcodesReceived, this, &BarcodeModel::handleBarcodesReceived);
        connect(m_api, &ProductApi::barcodeAdded, this, &BarcodeModel::handleBarcodeAdded);
        connect(m_api, &ProductApi::barcodeRemoved, this, &BarcodeModel::handleBarcodeRemoved);
        connect(m_api, &ProductApi::productError, this, &BarcodeModel::handleProductError);
    }
        refresh();
}

void BarcodeModel::setProductId(int productId)
{
    if (m_productId != productId) {
        m_productId = productId;
        refresh();
    }
}

int BarcodeModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_barcodes.count();
}

int BarcodeModel::columnCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return 1; // ID, Barcode, Primary
}

QVariant BarcodeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_barcodes.count())
        return QVariant();

    const QJsonObject &barcode = m_barcodes.at(index.row());

    if (role == Qt::DisplayRole) {
        switch (index.column()) {
        case 0: return barcode["id"_L1].toInt();
        case 1: return barcode["barcode"_L1].toString();
        case 2: return barcode["is_primary"_L1].toBool() ? tr("Yes") : tr("No");
        }
    }

    if (role >= IdRole) {
        switch (role) {
        case IdRole: return barcode["id"_L1].toInt();
        case BarcodeRole: return barcode["barcode"_L1].toString();
        case PrimaryRole: return barcode["is_primary"_L1].toBool();
        }
    }

    return QVariant();
}

QHash<int, QByteArray> BarcodeModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[BarcodeRole] = "barcode";
    roles[PrimaryRole] = "isPrimary";
    return roles;
}

QVariant BarcodeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole)
        return QVariant();

    if (orientation == Qt::Horizontal) {
        switch (section) {
        case 0: return tr("ID");
        case 1: return tr("Barcode");
        case 2: return tr("Primary");
        }
    }
    return QVariant();
}

void BarcodeModel::refresh()
{
    if (!m_api || m_productId == -1)
        return;
    setLoading(true);
    m_api->getProductBarcodes(m_productId);
}

void BarcodeModel::addBarcode(const QString &barcodeValue)
{
    if (!m_api || m_productId == -1)
        return;

    setLoading(true);
    m_api->addProductBarcode(m_productId, barcodeValue);
}

void BarcodeModel::removeBarcode(int barcodeId)
{
    if (!m_api || m_productId == -1)
        return;

    setLoading(true);
    m_api->removeProductBarcode(m_productId, barcodeId);
}

void BarcodeModel::handleBarcodesReceived(const QList<QJsonObject> &barcodes)
{
    beginResetModel();
    m_barcodes = barcodes;
    endResetModel();

    setLoading(false);
    setErrorMessage(QString());
}

void BarcodeModel::handleBarcodeAdded(const QJsonObject &barcode)
{
    beginInsertRows(QModelIndex(), m_barcodes.count(), m_barcodes.count());
    m_barcodes.append(barcode);
    endInsertRows();

    setLoading(false);
    setErrorMessage(QString());
}

void BarcodeModel::handleBarcodeRemoved(int productId, int barcodeId)
{
    for (int i = 0; i < m_barcodes.count(); ++i) {
        if (m_barcodes[i]["id"_L1].toInt() == barcodeId) {
            beginRemoveRows(QModelIndex(), i, i);
            m_barcodes.removeAt(i);
            endRemoveRows();
            break;
        }
    }

    setLoading(false);
    setErrorMessage(QString());
}

void BarcodeModel::handleProductError(const QString &message, ApiStatus status)
{
    setLoading(false);
    setErrorMessage(message);
}

void BarcodeModel::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void BarcodeModel::setErrorMessage(const QString &message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        Q_EMIT errorMessageChanged();
    }
}

} // namespace NetworkApi
