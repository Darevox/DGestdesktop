#ifndef CLIENTMODELFETCH_H
#define CLIENTMODELFETCH_H

#include "clientmodel.h"
#include <QObject>
namespace NetworkApi {
class ClientModelFetch : public ClientModel
{
    Q_OBJECT
public:
    explicit ClientModelFetch(QObject *parent = nullptr);

    // Override methods that need different behavior
    Q_INVOKABLE void loadPage(int page) override;
    Q_INVOKABLE void refresh() override;
protected:
    // Override handler for pagination behavior
    void  handleClientsReceived(const PaginatedClients &clients) override;
};
}
#endif // CLIENTMODELFETCH_H

