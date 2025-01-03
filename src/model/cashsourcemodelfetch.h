// cashsourcemodelfetch.h
#ifndef CASHSOURCEMODELFETCH_H
#define CASHSOURCEMODELFETCH_H

#include "cashsourcemodel.h"

namespace NetworkApi {

class CashSourceModelFetch : public CashSourceModel
{
    Q_OBJECT

public:
    explicit CashSourceModelFetch(QObject *parent = nullptr);

    void loadPage(int page) override;
    void refresh() override;

private slots:
    void handleCashSourcesReceived(const PaginatedCashSources &sources) override;
};

} // namespace NetworkApi

#endif // CASHSOURCEMODELFETCH_H
