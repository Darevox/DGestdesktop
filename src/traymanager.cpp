#include "traymanager.h"
#include <QMenu>
#include <QSettings>
#include <QApplication>
#include <KLocalizedString>

TrayManager::TrayManager(QObject *parent)
    : QObject(parent)
    , notifierItem(nullptr)
    , m_window(nullptr)
    , m_showInTray(true)
{
    loadSettings();
    setupTrayIcon();
}

TrayManager::~TrayManager()
{
    delete notifierItem;
}

void TrayManager::setupTrayIcon()
{
    notifierItem = new KStatusNotifierItem(this);
    notifierItem->setIconByName("dgest");  // Use your app icon name
    notifierItem->setCategory(KStatusNotifierItem::ApplicationStatus);
    notifierItem->setStatus(KStatusNotifierItem::Active);
    notifierItem->setTitle(i18n("DGest"));

    // // Create context menu
    // QMenu* menu = new QMenu();
    // QAction* closeAction = new QAction(i18n("Close"), this);
    // menu->addAction(closeAction);

    // notifierItem->setContextMenu(menu);

    // Connect signals
    connect(notifierItem, &KStatusNotifierItem::activateRequested,
            this, [this](bool active, const QPoint&) { handleActivated(active); });
   // connect(closeAction, &QAction::triggered, qApp, &QCoreApplication::quit);

    updateTrayVisibility();
}

void TrayManager::loadSettings()
{
    QSettings settings(QStringLiteral("Dervox"), QStringLiteral("DGest"));
    m_showInTray = settings.value("showInTray", true).toBool();
}

void TrayManager::saveSettings()
{
    QSettings settings(QStringLiteral("Dervox"), QStringLiteral("DGest"));
    settings.setValue("showInTray", m_showInTray);
}

bool TrayManager::showInTray() const
{
    return m_showInTray;
}

void TrayManager::setShowInTray(bool show)
{
    if (m_showInTray != show) {
        m_showInTray = show;
        saveSettings();
        updateTrayVisibility();
        emit showInTrayChanged();
    }
}

void TrayManager::toggleWindow()
{
    if (m_window) {
        if (m_window->isVisible()) {
            m_window->hide();
        } else {
            m_window->show();
            m_window->raise();
            m_window->requestActivate();
        }
    }
}

void TrayManager::setMainWindow(QQuickWindow* window)
{
    m_window = window;
}

void TrayManager::handleActivated(bool active)
{
    Q_UNUSED(active)
    toggleWindow();
}

void TrayManager::handleSecondaryActivated(const QPoint &pos)
{
    Q_UNUSED(pos)
    if (notifierItem && notifierItem->contextMenu()) {
        notifierItem->contextMenu()->popup(QCursor::pos());
    }
}

void TrayManager::updateTrayVisibility()
{
    if (notifierItem) {
        notifierItem->setStatus(m_showInTray ? KStatusNotifierItem::Active : KStatusNotifierItem::Passive);
    }
}
