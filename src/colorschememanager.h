#ifndef COLORSCHEMEMANAGER_H
#define COLORSCHEMEMANAGER_H

#include <QAbstractListModel>
#include <KColorSchemeManager>

class ColorSchemeManager : public QAbstractListModel
{
    Q_OBJECT
        Q_PROPERTY(int activeSchemeIndex READ activeSchemeIndex NOTIFY activeSchemeIndexChanged)
public:
    explicit ColorSchemeManager(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    Q_INVOKABLE void activateScheme(int index);

    // Property accessor for activeSchemeIndex
    int activeSchemeIndex() const;

Q_SIGNALS:
    void activeSchemeIndexChanged();

private:
    KColorSchemeManager *m_schemeManager;
     int m_activeSchemeIndex;
};

#endif // COLORSCHEMEMANAGER_H
