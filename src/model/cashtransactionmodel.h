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
    Q_PROPERTY(int cashSourceId READ cashSourceId WRITE setCashSourceId NOTIFY cashSourceIdChanged)
    Q_PROPERTY(bool hasCheckedItems READ hasCheckedItems NOTIFY hasCheckedItemsChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)
    Q_PROPERTY(QVariantMap summary READ summary NOTIFY summaryChanged)
    Q_PROPERTY(double minAmount READ minAmount WRITE setMinAmount NOTIFY minAmountChanged)
    Q_PROPERTY(double maxAmount READ maxAmount WRITE setMaxAmount NOTIFY maxAmountChanged)
    Q_PROPERTY(QDateTime startDate READ startDate WRITE setStartDate NOTIFY startDateChanged)
    Q_PROPERTY(QDateTime endDate READ endDate WRITE setEndDate NOTIFY endDateChanged)
public:
    enum CashTransactionRoles {
        IdRole = Qt::UserRole + 1,
        ReferenceNumberRole,
        TransactionDateRole,
        CashSourceIdRole,
        TypeRole,
        AmountRole,
        CategoryRole,
        PaymentMethodRole,
        DescriptionRole,
        CashSourceRole,
        TransferDestinationRole,
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
    int cashSourceId() const { return m_cashSourceId; }
    bool hasCheckedItems() const { return m_hasCheckedItems; }
    QVariantMap summary() const { return m_summary; }

    // Q_INVOKABLE methods for QML
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void loadPage(int page);
    Q_INVOKABLE void loadTransactionsBySource(int sourceId, int page = 1);
    Q_INVOKABLE QVariantMap getTransaction(int row) const;
    Q_INVOKABLE void updateSummary(const QDateTime &startDate = QDateTime(),
                                   const QDateTime &endDate = QDateTime());

    // Selection methods
    Q_INVOKABLE void setChecked(int row, bool checked);
    Q_INVOKABLE QVariantList getCheckedTransactionIds() const;
    Q_INVOKABLE void clearAllChecked();
    Q_INVOKABLE void toggleAllTransactionsChecked();


    double minAmount() const { return m_minAmount; }
    double maxAmount() const { return m_maxAmount; }
    QDateTime startDate() const { return m_startDate; }
    QDateTime endDate() const { return m_endDate; }

public slots:
    void setSortField(const QString &field);
    void setSortDirection(const QString &direction);
    void setSearchQuery(const QString &query);
    void setTransactionType(const QString &type);
    void setCashSourceId(int id);

    void setMinAmount(double amount);
    void setMaxAmount(double amount);
    void setStartDate(const QDateTime &date);
    void setEndDate(const QDateTime &date);
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
    void cashSourceIdChanged();
    void hasCheckedItemsChanged();
    void rowCountChanged();
    void summaryChanged();

    void minAmountChanged();
    void maxAmountChanged();
    void startDateChanged();
    void endDateChanged();

private slots:
    void handleTransactionsReceived(const PaginatedCashTransactions &transactions);
    void handleTransactionsBySourceReceived(const PaginatedCashTransactions &transactions);
    void handleSummaryReceived(const QVariantMap &summary);
    void handleApiError(const QString &message, ApiStatus status);

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
    int m_cashSourceId;
    bool m_hasCheckedItems;
    QVariantMap m_summary;

    void setLoading(bool loading);
    void setErrorMessage(const QString &message);
    void updateHasCheckedItems();

    double m_minAmount;
    double m_maxAmount;
    QDateTime m_startDate;
    QDateTime m_endDate;
};

} // namespace NetworkApi

#endif // CASHTRANSACTIONMODEL_H
