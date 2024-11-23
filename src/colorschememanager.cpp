#include "colorschememanager.h"

ColorSchemeManager::ColorSchemeManager(QObject *parent)
    : QAbstractListModel{parent}, m_activeSchemeIndex{-1}
{
    m_schemeManager = new KColorSchemeManager(this);
    QString theme = m_schemeManager->activeSchemeId();
    QModelIndex schemeIndex  = m_schemeManager->indexForScheme(theme);
    if (schemeIndex.isValid()) {
        m_activeSchemeIndex = schemeIndex.row();
       // emit activeSchemeIndexChanged();
    }
}

int ColorSchemeManager::activeSchemeIndex() const {
    return m_activeSchemeIndex;
}

int ColorSchemeManager::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;

    return m_schemeManager->model()->rowCount();
}

QVariant ColorSchemeManager::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || role != Qt::DisplayRole)
        return QVariant();

    return m_schemeManager->model()->data(index, role);
}

void ColorSchemeManager::activateScheme(int index)
{
    QModelIndex schemeIndex = m_schemeManager->model()->index(index, 0);
    QModelIndex updatedIndex = m_schemeManager->model()->index(0, 0);
    m_schemeManager->activateScheme(updatedIndex);
    m_schemeManager->activateScheme(schemeIndex);
    m_activeSchemeIndex = index;
    emit activeSchemeIndexChanged();
}
