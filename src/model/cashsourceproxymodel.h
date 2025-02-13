#ifndef CASHSOURCEPROXYMODEL_H
#define CASHSOURCEPROXYMODEL_H

#include <QSortFilterProxyModel>

class CashSourceProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(bool rtl READ isRTL WRITE setRTL NOTIFY rtlChanged)

public:
    explicit CashSourceProxyModel(QObject *parent = nullptr);

    bool isRTL() const { return m_rtl; }
    void setRTL(bool rtl);

    Q_INVOKABLE virtual QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    Q_INVOKABLE virtual void sort(int column, Qt::SortOrder order = Qt::AscendingOrder) override;

    // Helper methods for column mapping
    Q_INVOKABLE int mapToSourceColumn(int proxyColumn) const;
    Q_INVOKABLE int mapFromSourceColumn(int sourceColumn) const;

Q_SIGNALS:
    void rtlChanged();

protected:
    QModelIndex mapToSource(const QModelIndex &proxyIndex) const override;
    QModelIndex mapFromSource(const QModelIndex &sourceIndex) const override;

private:
    bool m_rtl = false;
};

#endif // CASHSOURCEPROXYMODEL_H
