// cashsourcemodel.h
#ifndef CASHSOURCEMODEL_H
#define CASHSOURCEMODEL_H

#include "../api/cashsourceapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class CashSourceModel : public QAbstractTableModel
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
    enum CashSourceRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        TypeRole,
        BalanceRole,
        InitialBalanceRole,  // Add this
        AccountNumberRole,    // Add this
        BankNameRole,        // Add this
        StatusRole,
        IsDefaultRole,
        CheckedRole
    };
    Q_ENUM(CashSourceRoles)

    explicit CashSourceModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(CashSourceApi* api);

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
    Q_INVOKABLE bool hasCheckedItems() const { return m_hasCheckedItems; }

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE virtual void refresh();
    Q_INVOKABLE virtual void loadPage(int page);
    Q_INVOKABLE void createCashSource(const QVariantMap &sourceData);
    Q_INVOKABLE void updateCashSource(int id, const QVariantMap &sourceData);
    Q_INVOKABLE void deleteCashSource(int id);
    Q_INVOKABLE QVariantMap getCashSource(int row) const;
    Q_INVOKABLE void deposit(int id, double amount, const QString &notes);
    Q_INVOKABLE void withdraw(int id, double amount, const QString &notes);
    Q_INVOKABLE void transfer(const QVariantMap &transferData);

    // Selection methods
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedCashSourceIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllCashSourcesChecked();
    Q_INVOKABLE QVariantMap getFirstCheckedSource() const {
        for (const auto &source : m_sources) {
            if (source.checked) {
                return cashSourceToVariantMap(source);
            }
        }
        return QVariantMap();
    }
    Q_INVOKABLE QStringList getAvailableDestinations(int excludeId) const {
        QStringList destinations;
        for (const auto &source : m_sources) {
            if (source.id != excludeId) {
                destinations << source.name;
            }
        }
        return destinations;
    }

    Q_INVOKABLE QList<int> getAvailableDestinationIds(int excludeId) const {
        QList<int> ids;
        for (const auto &source : m_sources) {
            if (source.id != excludeId) {
                ids << source.id;
            }
        }
        return ids;
    }

public slots:
    void setSortField(const QString &field);
    void setSortDirection(const QString &direction);
    void setSearchQuery(const QString &query);

signals:
    void loadingChanged();
    void errorMessageChanged();
    void totalItemsChanged();
    void currentPageChanged();
    void totalPagesChanged();
    void sortFieldChanged();
    void sortDirectionChanged();
    void searchQueryChanged();
    void cashSourceCreated();
    void cashSourceUpdated();
    void cashSourceDeleted();
    void depositCompleted();
    void withdrawalCompleted();
    void transferCompleted();
    void hasCheckedItemsChanged();
    void rowCountChanged();

private slots:
    virtual void handleCashSourcesReceived(const PaginatedCashSources &sources);
    void handleCashSourceError(const QString &message, ApiStatus status);
    void handleCashSourceCreated(const CashSource &source);
    void handleCashSourceUpdated(const CashSource &source);
    void handleCashSourceDeleted(int id);
    void handleDepositCompleted(const QVariantMap &transaction);
    void handleWithdrawalCompleted(const QVariantMap &transaction);
    void handleTransferCompleted(const QVariantMap &transaction);
protected:
    CashSourceApi* m_api;
    QList<CashSource> m_sources;
    bool m_loading;
    QString m_errorMessage;
    int m_totalItems;
    int m_currentPage;
    int m_totalPages;
    QString m_sortField;
    QString m_sortDirection;
    QString m_searchQuery;
    bool m_hasCheckedItems;

    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    void updateHasCheckedItems();

private:

    CashSource cashSourceFromVariantMap(const QVariantMap &map) const;
    QVariantMap cashSourceToVariantMap(const CashSource &source) const;
    TransferData transferDataFromVariantMap(const QVariantMap &map) const;
};

} // namespace NetworkApi

#endif // CASHSOURCEMODEL_H
