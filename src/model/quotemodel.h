#ifndef QUOTEMODEL_H
#define QUOTEMODEL_H

#include "salemodel.h"

namespace NetworkApi {

class QuoteModel : public SaleModel
{
    Q_OBJECT

public:
    explicit QuoteModel(QObject *parent = nullptr);

    // Additional methods specific to quotes could be added here, such as:
    void refresh() override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
public Q_SLOTS:
    // Additional slots specific to quotes could be added here

Q_SIGNALS:
    // Additional signals specific to quotes could be added here

private:
    // Additional private methods specific to quotes could be added here
};

} // namespace NetworkApi

#endif // QUOTEMODEL_H
