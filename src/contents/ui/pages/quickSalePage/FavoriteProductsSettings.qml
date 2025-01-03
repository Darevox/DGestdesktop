import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
//import com.dervox.FavoriteManager
import com.dervox.ProductFetchApi

import "../../components"

Kirigami.Dialog {
    id: root
    title: i18n("Favorite Products Settings")

    width: Math.min(parent.width - Kirigami.Units.gridUnit * 4,
                    Kirigami.Units.gridUnit * 40)
    height: Math.min(parent.height - Kirigami.Units.gridUnit * 4,
                     Kirigami.Units.gridUnit * 30)

    standardButtons: Dialog.Close

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        TabBar {
            id: settingsTabBar
            Layout.fillWidth: true

            TabButton {
                text: i18n("Favorites")
            }
            TabButton {
                text: i18n("Cash Sources")
            }
        }
        // StackLayout to handle different tabs
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: settingsTabBar.currentIndex
            // Favorites Tab
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.largeSpacing

                    // Categories section
                    // Categories section
                    Kirigami.Card {
                        Layout.fillWidth: true
                        header: RowLayout {
                            Kirigami.Heading {
                                text: i18n("Categories")
                                level: 2
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                icon.name: "list-add"
                                text: i18n("Add Category")
                                onClicked: newCategoryDialog.open()
                            }
                        }

                        ListView {
                            id: listCategories
                            implicitHeight: Kirigami.Units.gridUnit * 10
                            spacing: 2
                            clip: true

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: Kirigami.Units.gridUnit * 2
                                color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.largeSpacing

                                    Label {
                                        text: modelData.name || ""
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Edit button
                                    Button {
                                        icon.name: "edit-entry"
                                        display: Button.IconOnly
                                        onClicked: {
                                            editCategoryDialog.categoryId = modelData.id
                                            editCategoryDialog.categoryName = modelData.name
                                            editCategoryDialog.open()
                                        }
                                    }

                                    // Delete button
                                    Button {
                                        icon.name: "edit-delete"
                                        display: Button.IconOnly
                                        onClicked: favoriteManager.deleteCategory(modelData.id)
                                    }
                                }
                            }

                            Connections {
                                target: favoriteManager
                                function onCategoriesChanged() {
                                    listCategories.model = favoriteManager.getCategories()
                                }
                            }

                            Component.onCompleted: {
                                listCategories.model = favoriteManager.getCategories()
                            }
                        }

                    }

                    // Products section
                    Kirigami.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        header: ColumnLayout {
                            Kirigami.Heading {
                                text: i18n("Category Products")
                                level: 2
                            }
                            ComboBox {
                                id: categoryCombo
                                Layout.fillWidth: true
                                // model: favoriteManager.getCategories()
                                textRole: "name"
                                valueRole: "id"
                                Connections {
                                    target: favoriteManager
                                    function onCategoriesChanged() {
                                        categoryCombo.model = favoriteManager.getCategories()
                                    }
                                }
                                Component.onCompleted:{
                                    categoryCombo.model= favoriteManager.getCategories()

                                }
                            }
                        }

                        contentItem: ColumnLayout {
                            DSearchableComboBox {
                                Layout.fillWidth: true
                                onItemSelected: function(product) {
                                    favoriteManager.addProductToCategory(
                                                categoryCombo.currentValue,
                                                product.id)  // Only store the ID
                                }
                            }
                            ListView {
                                id: productsList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2
                                clip: true

                                model: favoriteManager.getCategoryProductIds(categoryCombo.currentValue)
                                property var loadedProducts: ({})

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: Kirigami.Units.gridUnit * 2
                                    color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: Kirigami.Units.smallSpacing
                                        spacing: Kirigami.Units.largeSpacing

                                        Label {
                                            text: productsList.loadedProducts[modelData]?.name || i18n("Loading...")
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Delete button
                                        Button {
                                            icon.name: "edit-delete"
                                            display: Button.IconOnly
                                            onClicked: favoriteManager.removeProductFromCategory(
                                                           categoryCombo.currentValue,
                                                           modelData
                                                           )
                                        }
                                    }
                                }

                                // Empty state message
                                Label {
                                    anchors.centerIn: parent
                                    text: i18n("No products in this category")
                                    visible: productsList.count === 0
                                    opacity: 0.5
                                }

                                Connections {
                                    target: productFetchApi
                                    function onProductReceived(product) {
                                        productsList.loadedProducts[product.id] = product
                                        productsList.loadedProducts = productsList.loadedProducts // Force update
                                    }
                                }

                                Component.onCompleted: {
                                    // Load products for IDs
                                    if (model) {
                                        model.forEach(id => {
                                                          if (!productsList.loadedProducts[id]) {
                                                              productFetchApi.getProduct(id)
                                                          }
                                                      })
                                    }
                                }

                                // Add this to refresh products when category changes
                                Connections {
                                    target: categoryCombo
                                    function onCurrentValueChanged() {
                                        productsList.model = favoriteManager.getCategoryProductIds(
                                                    categoryCombo.currentValue
                                                    )
                                    }
                                }

                                // Add this to refresh when products change
                                Connections {
                                    target: favoriteManager
                                    function onProductsChanged(categoryId) {
                                        if (categoryId === categoryCombo.currentValue) {
                                            productsList.model = favoriteManager.getCategoryProductIds(
                                                        categoryCombo.currentValue
                                                        )
                                        }
                                    }
                                }
                            }

                        }
                    }


                    // Cash Sources Tab
                }
            }

            Item {
                ColumnLayout {
                    anchors.fill: parent
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Card {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        header: RowLayout {
                            Kirigami.Heading {
                                text: i18n("Default Cash Source")
                                level: 2
                            }
                        }

                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.largeSpacing

                            // Current default cash source display
                            Label {
                                text: i18n("Current Default: %1", defaultSourceName)
                                font.bold: true
                                property string defaultSourceName: {
                                    let defaultId = favoriteManager.getDefaultCashSource()
                                    // You'll need to implement a way to get the cash source name
                                    return "Cash Source " + defaultId
                                }
                            }

                            // Cash source selection
                            DSearchableComboBoxCashSource {
                                Layout.fillWidth: true
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 20
                                onItemSelected: function(source) {
                                    favoriteManager.setDefaultCashSource(source.id)
                                }
                            }

                            // List of all cash sources
                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: cashSourceModel // You'll need to create this

                                delegate: ItemDelegate {
                                    width: ListView.view.width
                                    highlighted: model.id === favoriteManager.getDefaultCashSource()

                                    contentItem: RowLayout {
                                        spacing: Kirigami.Units.largeSpacing

                                        Label {
                                            text: model.name
                                            Layout.fillWidth: true
                                        }

                                        Button {
                                            text: i18n("Set as Default")
                                            visible: !parent.parent.highlighted
                                            onClicked: favoriteManager.setDefaultCashSource(model.id)
                                        }
                                    }
                                }

                                // Empty state
                                Label {
                                    anchors.centerIn: parent
                                    text: i18n("No cash sources available")
                                    visible: parent.count === 0
                                    opacity: 0.5
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    // New category dialog
    Kirigami.Dialog {
        id: newCategoryDialog
        title: i18n("New Category")
        standardButtons: Dialog.Ok | Dialog.Cancel

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: categoryNameField
                label: i18n("Category Name")
            }
        }

        onAccepted: {
            favoriteManager.createCategory(categoryNameField.text)
            categoryNameField.text = ""
        }
    }

    // Edit category dialog
    Kirigami.Dialog {
        id: editCategoryDialog
        title: i18n("Edit Category")
        standardButtons: Dialog.Ok | Dialog.Cancel

        property int categoryId: -1
        property string categoryName: ""

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: editCategoryNameField
                label: i18n("Category Name")
                text: editCategoryDialog.categoryName
            }
        }

        onAccepted: {
            favoriteManager.updateCategory(
                        categoryId,
                        editCategoryNameField.text)
        }
    }
    // FavoriteManager {
    //     id: favoriteManager
    // }
    ProductFetchApi {
        id: productFetchApi
        Component.onCompleted:{
            let token = api.getToken();
            productFetchApi.saveToken(token);
        }
    }


}
