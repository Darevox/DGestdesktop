#ifndef PRODUCTMODELFETCH_H
#define PRODUCTMODELFETCH_H

#include "productmodel.h"

namespace NetworkApi {

class ProductModelFetch : public ProductModel
{
    Q_OBJECT

public:
    explicit ProductModelFetch(QObject *parent = nullptr);

    // Override methods that need different behavior
    Q_INVOKABLE void loadPage(int page) override;
    Q_INVOKABLE void refresh() override;

protected:
    // Override handler for pagination behavior
    void handleProductsReceived(const PaginatedProducts& products) override;
};

} // namespace NetworkApi

#endif // PRODUCTMODELFETCH_H
