// clientmodel.h
#ifndef CLIENTMODEL_H
#define CLIENTMODEL_H

#include "../api/clientapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class ClientModel : public QAbstractTableModel
{
    Q_OBJECT

    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(int totalItems READ totalItems NOTIFY totalItemsChanged)
    Q_PROPERTY(int currentPage READ currentPage NOTIFY currentPageChanged)
    Q_PROPERTY(int totalPages READ totalPages NOTIFY totalPagesChanged)
    Q_PROPERTY(QString sortField READ sortField WRITE setSortField NOTIFY sortFieldChanged)
    Q_PROPERTY(QString sortDirection READ sortDirection WRITE setSortDirection NOTIFY sortDirectionChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY searchQueryChanged)
    Q_PROPERTY(bool hasCheckedItems READ hasCheckedItems NOTIFY hasCheckedItemsChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)

public:
    enum ClientRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        EmailRole,
        PhoneRole,
        AddressRole,
        TaxNumberRole,
        PaymentTermsRole,
        NotesRole,
        StatusRole,
        BalanceRole,
        CheckedRole
    };
    Q_ENUM(ClientRoles)

    explicit ClientModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(ClientApi* api);

    // QAbstractTableModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;

    // Properties
    bool loading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }
    int totalItems() const { return m_totalItems; }
    int currentPage() const { return m_currentPage; }
    int totalPages() const { return m_totalPages; }
    QString sortField() const { return m_sortField; }
    QString sortDirection() const { return m_sortDirection; }
    QString searchQuery() const { return m_searchQuery; }
    bool hasCheckedItems() const { return m_hasCheckedItems; }

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE virtual void refresh();
    Q_INVOKABLE virtual void loadPage(int page);
    Q_INVOKABLE void createClient(const QVariantMap &clientData);
    Q_INVOKABLE void updateClient(int id, const QVariantMap &clientData);
    Q_INVOKABLE void deleteClient(int id);
    Q_INVOKABLE QVariantMap getClient(int row) const;


    // Selection methods
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedClientIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllClientsChecked();

public Q_SLOTS:
    void setSortField(const QString &field);
    void setSortDirection(const QString &direction);
    void setSearchQuery(const QString &query);
    void filterByType(const QString &type);

Q_SIGNALS:
    void loadingChanged();
    void errorMessageChanged();
    void totalItemsChanged();
    void currentPageChanged();
    void totalPagesChanged();
    void sortFieldChanged();
    void sortDirectionChanged();
    void searchQueryChanged();
    void clientCreated();
    void clientUpdated();
    void clientDeleted();
    void hasCheckedItemsChanged();
    void rowCountChanged();

private Q_SLOTS:
    virtual void handleClientsReceived(const PaginatedClients &clients);
    void handleClientError(const QString &message, ApiStatus status);
    void handleClientCreated(const Client &client);
    void handleClientUpdated(const Client &client);
    void handleClientDeleted(int id);
protected:
    ClientApi* m_api;
    QList<Client> m_clients;
    bool m_loading;
    QString m_errorMessage;
    int m_totalItems;
    int m_currentPage;
    int m_totalPages;
    QString m_sortField;
    QString m_sortDirection;
    QString m_searchQuery;
    QString m_currentType;
    bool m_hasCheckedItems;

    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    void updateHasCheckedItems();
private:

    Client clientFromVariantMap(const QVariantMap &map) const;
    QVariantMap clientToVariantMap(const Client &client) const;

};

} // namespace NetworkApi

#endif // CLIENTMODEL_H
