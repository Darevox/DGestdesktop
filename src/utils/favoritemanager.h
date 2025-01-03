// favoritemanager.h (unchanged)
#ifndef FAVORITEMANAGER_H
#define FAVORITEMANAGER_H

#include <QObject>
#include <QSettings>
#include <QJsonObject>
#include <QJsonArray>

class FavoriteManager : public QObject
{
    Q_OBJECT

public:
    explicit FavoriteManager(QObject *parent = nullptr);

    Q_INVOKABLE void createCategory(const QString &name);
    Q_INVOKABLE void updateCategory(int categoryId, const QString &name);
    Q_INVOKABLE void deleteCategory(int categoryId);
    Q_INVOKABLE QJsonArray getCategories();

    Q_INVOKABLE void addProductToCategory(int categoryId, int productId);
    Q_INVOKABLE void removeProductFromCategory(int categoryId, int productId);
    Q_INVOKABLE QJsonArray getCategoryProductIds(int categoryId);

    Q_INVOKABLE void saveSettings();

    Q_INVOKABLE void setDefaultCashSource(int id);
    Q_INVOKABLE int getDefaultCashSource() const;
    Q_INVOKABLE void removeProductFromAllCategories(int productId);
signals:
    void categoriesChanged();
    void productsChanged(int categoryId);
    void error(const QString &message);
    void defaultCashSourceChanged(int id);
private:
    QSettings m_settings;
    QJsonObject m_categories;
    QJsonObject m_categoryProducts;

    void loadSettings(); // Add this method
};

#endif // FAVORITEMANAGER_H
