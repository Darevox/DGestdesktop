// favoritemanager.cpp
#include "favoritemanager.h"

FavoriteManager::FavoriteManager(QObject *parent)
    : QObject(parent)
    , m_settings("Dervox", "DGest")
{
    loadSettings();
}



void FavoriteManager::createCategory(const QString &name)
{
    int newId = m_categories.size() + 1;
    QJsonObject category;
    category["id"] = newId;
    category["name"] = name;

    m_categories[QString::number(newId)] = category;
    saveSettings();
    emit categoriesChanged();
}

void FavoriteManager::updateCategory(int categoryId, const QString &name)
{
    QString id = QString::number(categoryId);
    if (m_categories.contains(id)) {
        QJsonObject category = m_categories[id].toObject();
        category["name"] = name;
        m_categories[id] = category;
        saveSettings();
        emit categoriesChanged();
    }
}

void FavoriteManager::deleteCategory(int categoryId)
{
    QString id = QString::number(categoryId);
    if (m_categories.contains(id)) {
        m_categories.remove(id);
        m_categoryProducts.remove(id);
        saveSettings();
        emit categoriesChanged();
    }
}

QJsonArray FavoriteManager::getCategories()
{
    QJsonArray categories;
    for (const QString &key : m_categories.keys()) {
        categories.append(m_categories[key].toObject());
    }
    return categories;
}


void FavoriteManager::removeProductFromCategory(int categoryId, int productId)
{
    QString id = QString::number(categoryId);
    if (m_categoryProducts.contains(id)) {
        QJsonArray products = m_categoryProducts[id].toArray();
        QJsonArray newProducts;

        for (const QJsonValue &value : products) {
            QJsonObject product = value.toObject();
            if (product["id"].toInt() != productId) {
                newProducts.append(product);
            }
        }

        m_categoryProducts[id] = newProducts;
        saveSettings();
        emit productsChanged(categoryId);
    }
}

// favoritemanager.cpp
void FavoriteManager::addProductToCategory(int categoryId, int productId)
{
    QString id = QString::number(categoryId);
    QJsonArray productIds;
    qDebug()<<"Add product ID "<<productId;
    if (m_categoryProducts.contains(id)) {
        productIds = m_categoryProducts[id].toArray();
        // Check if product already exists in category
        for (const QJsonValue &value : productIds) {
            if (value.toInt() == productId) {
                return;
            }
        }
    }

    productIds.append(productId);
    m_categoryProducts[id] = productIds;
    saveSettings();
    emit productsChanged(categoryId);
}

QJsonArray FavoriteManager::getCategoryProductIds(int categoryId)
{
    QString id = QString::number(categoryId);
    if (m_categoryProducts.contains(id)) {
        return m_categoryProducts[id].toArray();
    }
    return QJsonArray();
}

void FavoriteManager::saveSettings()
{
    QVariantMap categoriesMap;
    for (auto it = m_categories.constBegin(); it != m_categories.constEnd(); ++it) {
        QJsonObject category = it.value().toObject();
        QVariantMap categoryMap;
        categoryMap["id"] = category["id"].toInt();
        categoryMap["name"] = category["name"].toString();
        categoriesMap[it.key()] = categoryMap;
    }
    m_settings.setValue("categories", categoriesMap);

    QVariantMap productsMap;
    for (auto it = m_categoryProducts.constBegin(); it != m_categoryProducts.constEnd(); ++it) {
        QJsonArray productsArray = it.value().toArray();
        QVariantList productsList;
        for (const QJsonValue &value : productsArray) {
            productsList.append(value.toInt());
        }
        productsMap[it.key()] = productsList;
    }
    m_settings.setValue("categoryProducts", productsMap);

    m_settings.sync();
}
// void FavoriteManager::loadSettings()
// {
//     // Load categories
//     QVariantMap categoriesMap = m_settings.value("categories").toMap();
//     for (auto it = categoriesMap.constBegin(); it != categoriesMap.constEnd(); ++it) {
//         QVariantMap categoryMap = it.value().toMap();
//         QJsonObject category;
//         category["id"] = categoryMap["id"].toInt();
//         category["name"] = categoryMap["name"].toString();
//         m_categories[it.key()] = category;
//     }

//     // Load category products
//     QVariantMap productsMap = m_settings.value("categoryProducts").toMap();
//     for (auto it = productsMap.constBegin(); it != productsMap.constEnd(); ++it) {
//         QVariantList productsList = it.value().toList();
//         QJsonArray productsArray;
//         for (const QVariant &productId : productsList) {
//             productsArray.append(productId.toInt());
//         }
//         m_categoryProducts[it.key()] = productsArray;
//     }
// }


void FavoriteManager::loadSettings()
{
    // Load categories
    QVariantMap categoriesMap = m_settings.value("categories").toMap();
    qDebug() << "Loading categories:";
    for (auto it = categoriesMap.constBegin(); it != categoriesMap.constEnd(); ++it) {
        QVariantMap categoryMap = it.value().toMap();
        QJsonObject category;
        category["id"] = categoryMap["id"].toInt();
        category["name"] = categoryMap["name"].toString();
        m_categories[it.key()] = category;
        qDebug() << "Category:" << it.key() << "ID:" << categoryMap["id"].toInt() << "Name:" << categoryMap["name"].toString();
    }

    // Load category products
    QVariantMap productsMap = m_settings.value("categoryProducts").toMap();
    qDebug() << "\nLoading category products:";
    for (auto it = productsMap.constBegin(); it != productsMap.constEnd(); ++it) {
        QVariantList productsList = it.value().toList();
        QJsonArray productsArray;
        qDebug() << "Category" << it.key() << "products:";
        for (const QVariant &productId : productsList) {
            bool ok;
            int id = productId.toInt(&ok);
            qDebug() << "  Loading product ID:" << id << "(conversion success:" << ok << ")";
            productsArray.append(id);
        }
        m_categoryProducts[it.key()] = productsArray;
    }

    // Debug print final loaded state
    qDebug() << "\nFinal loaded state:";
    for (const QString &categoryId : m_categoryProducts.keys()) {
        QJsonArray products = m_categoryProducts[categoryId].toArray();
        qDebug() << "Category" << categoryId << "contains" << products.size() << "products:";
        for (const QJsonValue &value : products) {
            qDebug() << "  Product ID:" << value.toInt();
        }
    }
}

void FavoriteManager::setDefaultCashSource(int id)
{
    m_settings.setValue("defaultCashSource", id);
    m_settings.sync();
    emit defaultCashSourceChanged(id);
}

int FavoriteManager::getDefaultCashSource() const
{
    return m_settings.value("defaultCashSource", 1).toInt();
}
void FavoriteManager::removeProductFromAllCategories(int productId)
{
    qDebug() << "\nAttempting to remove product ID:" << productId;

    // Debug m_categoryProducts content directly
    qDebug() << "m_categoryProducts contains" << m_categoryProducts.size() << "categories";
    qDebug() << "Keys in m_categoryProducts:" << m_categoryProducts.keys();

    bool changed = false;

    // Iterate through all categories
    for (auto it = m_categoryProducts.begin(); it != m_categoryProducts.end(); ++it) {
        QString categoryId = it.key();
        QJsonArray products = it.value().toArray();

        qDebug() << "Processing category:" << categoryId;
        qDebug() << "Current products in category:" << products;

        QJsonArray newProducts;
        bool categoryChanged = false;

        for (const QJsonValue &value : products) {
            int currentProductId = value.toInt();
            qDebug() << "Checking product:" << currentProductId;

            if (currentProductId != productId) {
                newProducts.append(value);
            } else {
                categoryChanged = true;
                qDebug() << "Found matching product to remove";
            }
        }

        if (categoryChanged) {
            m_categoryProducts[categoryId] = newProducts;
            changed = true;
            emit productsChanged(categoryId.toInt());
            qDebug() << "Updated category" << categoryId << "with new products:" << newProducts;
        }
    }

    if (changed) {
        saveSettings();
        qDebug() << "Settings saved after removing product" << productId;
    } else {
        qDebug() << "Product" << productId << "not found in any category";
    }
}
