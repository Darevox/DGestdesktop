// cashtransactionmodel.h
#ifndef CASHTRANSACTIONMODEL_H
#define CASHTRANSACTIONMODEL_H

#include "../api/cashtransactionapi.h"
#include <QAbstractTableModel>
#include <QQmlEngine>

namespace NetworkApi {

class CashTransactionModel : public QAbstractTableModel
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
    Q_PROPERTY(QString transactionType READ transactionType WRITE setTransactionType NOTIFY transactionTypeChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)
    Q_PROPERTY(int cashSourceId READ cashSourceId WRITE setCashSourceId NOTIFY cashSourceIdChanged)
    Q_PROPERTY(bool hasCheckedItems READ hasCheckedItems NOTIFY hasCheckedItemsChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)

public:
    enum CashTransactionRoles {
        IdRole = Qt::UserRole + 1,
        ReferenceNumberRole,
        TransactionDateRole,
        CashSourceIdRole,
        TransactionTypeRole,
        AmountRole,
        CategoryRole,
        PaymentMethodRole,
        DescriptionRole,
        CashSourceRole,
        RelatedDocumentRole,
        CheckedRole
    };
    Q_ENUM(CashTransactionRoles)

    explicit CashTransactionModel(QObject *parent = nullptr);
    Q_INVOKABLE void setApi(CashTransactionApi* api);

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
    QString transactionType() const { return m_transactionType; }
    QString category() const { return m_category; }
    int cashSourceId() const { return m_cashSourceId; }
    bool hasCheckedItems() const { return m_hasCheckedItems; }

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void loadPage(int page);
    Q_INVOKABLE void createTransaction(const QVariantMap &transactionData);
    Q_INVOKABLE void updateTransaction(int id, const QVariantMap &transactionData);
    Q_INVOKABLE void deleteTransaction(int id);
    Q_INVOKABLE QVariantMap getTransaction(int row) const;
    Q_INVOKABLE void createTransfer(const QVariantMap &transferData);
    Q_INVOKABLE void loadCategories();
    Q_INVOKABLE void getCashFlow(const QString &period = "month", int cashSourceId = 0);
    Q_INVOKABLE void generateReport(const QDateTime &startDate,
                                  const QDateTime &endDate,
                                  int cashSourceId = 0);

    // Selection methods
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedTransactionIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllTransactionsChecked();

public slots:
    void setSortField(const QString &field);
    void setSortDirection(const QString &direction);
    void setSearchQuery(const QString &query);
    void setTransactionType(const QString &type);
    void setCategory(const QString &category);
    void setCashSourceId(int id);

signals:
    void loadingChanged();
    void errorMessageChanged();
    void totalItemsChanged();
    void currentPageChanged();
    void totalPagesChanged();
    void sortFieldChanged();
    void sortDirectionChanged();
    void searchQueryChanged();
    void transactionTypeChanged();
    void categoryChanged();
    void cashSourceIdChanged();
    void transactionCreated();
    void transactionUpdated();
    void transactionDeleted();
    void transferCreated();
    void categoriesLoaded(const QVariantList &categories);
    void cashFlowReceived(const QVariantMap &cashFlow);
    void reportGenerated(const QString &reportUrl);
    void hasCheckedItemsChanged();
    void rowCountChanged();

private slots:
    void handleTransactionsReceived(const PaginatedCashTransactions &transactions);
    void handleTransactionError(const QString &message, ApiStatus status);
    void handleTransactionCreated(const CashTransaction &transaction);
    void handleTransactionUpdated(const CashTransaction &transaction);
    void handleTransactionDeleted(int id);
    void handleTransferCreated(const QVariantMap &transfer);
    void handleCategoriesReceived(const QVariantList &categories);
    void handleCashFlowReceived(const QVariantMap &cashFlow);
    void handleReportGenerated(const QString &reportUrl);

private:
    CashTransactionApi* m_api;
    QList<CashTransaction> m_transactions;
    bool m_loading;
    QString m_errorMessage;
    int m_totalItems;
    int m_currentPage;
    int m_totalPages;
    QString m_sortField;
    QString m_sortDirection;
    QString m_searchQuery;
    QString m_transactionType;
    QString m_category;
    int m_cashSourceId;
    bool m_hasCheckedItems;

    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    CashTransaction transactionFromVariantMap(const QVariantMap &map) const;
    QVariantMap transactionToVariantMap(const CashTransaction &transaction) const;
    TransactionTransfer transferFromVariantMap(const QVariantMap &map) const;
    void updateHasCheckedItems();
};

} // namespace NetworkApi

#endif // CASHTRANSACTIONMODEL_H
