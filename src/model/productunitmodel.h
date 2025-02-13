#ifndef PRODUCTUNITMODEL_H
#define PRODUCTUNITMODEL_H

#include <QAbstractListModel>
#include "../api/productapi.h"

namespace NetworkApi {


class ProductUnitModel : public QAbstractListModel {
    Q_OBJECT

public:
    explicit ProductUnitModel(QObject *parent = nullptr);

    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole
    };

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    void setUnits(const QList<ProductUnit>& units);

    Q_INVOKABLE void fetchUnits(ProductApi* api);

private Q_SLOTS:
    void handleUnitsReceived(const QList<ProductUnit>& units);
    void handleError(const ApiError& error);

private:
    QList<ProductUnit> m_units;
};

} // namespace NetworkApi

#endif // PRODUCTUNITMODEL_H
