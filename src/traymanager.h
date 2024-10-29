// traymanager.h
#ifndef TRAYMANAGER_H
#define TRAYMANAGER_H

#include <QObject>
#include <QQuickWindow>
#include <KStatusNotifierItem>

class TrayManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool showInTray READ showInTray WRITE setShowInTray NOTIFY showInTrayChanged)

public:
    explicit TrayManager(QObject *parent = nullptr);
    ~TrayManager();

    bool showInTray() const;
    void setShowInTray(bool show);
    void setMainWindow(QQuickWindow* window);

    Q_INVOKABLE void toggleWindow();

signals:
    void showInTrayChanged();

private slots:
    void handleActivated(bool active);
    void handleSecondaryActivated(const QPoint &pos);

private:
    void updateTrayVisibility();
    void setupTrayIcon();
    void loadSettings();
    void saveSettings();

    KStatusNotifierItem* notifierItem;  // Using KStatusNotifierItem instead of QSystemTrayIcon
    QQuickWindow* m_window;
    bool m_showInTray;
};

#endif // TRAYMANAGER_H
