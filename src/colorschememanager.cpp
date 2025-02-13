#include "colorschememanager.h"

ColorSchemeManager::ColorSchemeManager(QObject *parent)
    : QAbstractListModel{parent}, m_activeSchemeIndex{-1}
{  // Get the singleton instance instead of creating new instance
    m_schemeManager = KColorSchemeManager::instance();

    // Store the instance as member if needed
    if (m_schemeManager) {
        QString theme = m_schemeManager->activeSchemeId();
        QModelIndex schemeIndex = m_schemeManager->indexForScheme(theme);
        if (schemeIndex.isValid()) {
            m_activeSchemeIndex = schemeIndex.row();
        }
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
    Q_EMIT activeSchemeIndexChanged();
}
