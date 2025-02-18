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
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 10  // Give it a specific height
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

                        contentItem:  ListView {
                            id: listCategories
                            anchors.fill: parent  // Fill the card's content area
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing
                            clip: true

                            model: favoriteManager.getCategories()  // Set model directly
                            delegate: Kirigami.SwipeListItem {  // Using SwipeListItem for better interaction
                                width: ListView.view.width
                                contentItem: RowLayout {
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
                                        onClicked: {
                                            deleteCategoryDialog.categoryId = modelData.id
                                            deleteCategoryDialog.categoryName = modelData.name
                                            deleteCategoryDialog.open()
                                        }
                                    }
                                }
                            }

                            // Empty state message
                            Kirigami.PlaceholderMessage {
                                anchors.centerIn: parent
                                width: parent.width - (Kirigami.Units.largeSpacing * 4)
                                visible: listCategories.count === 0
                                text: i18n("No categories yet")
                                icon.name: "folder-symbolic"
                            }


                            // delegate: Rectangle {
                            //     width: ListView.view.width
                            //     height: Kirigami.Units.gridUnit * 2
                            //     color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                            //     RowLayout {
                            //         anchors.fill: parent
                            //         anchors.margins: Kirigami.Units.smallSpacing
                            //         spacing: Kirigami.Units.largeSpacing

                            //         Label {
                            //             text: modelData.name || ""
                            //             Layout.fillWidth: true
                            //             elide: Text.ElideRight
                            //         }

                            //         // Edit button
                            //         Button {
                            //             icon.name: "edit-entry"
                            //             display: Button.IconOnly
                            //             onClicked: {
                            //                 editCategoryDialog.categoryId = modelData.id
                            //                 editCategoryDialog.categoryName = modelData.name
                            //                 editCategoryDialog.open()
                            //             }
                            //         }

                            //         // Delete button
                            //         Button {
                            //             icon.name: "edit-delete"
                            //             display: Button.IconOnly
                            //             onClicked: favoriteManager.deleteCategory(modelData.id)
                            //         }
                            //     }
                            // }

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
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 15

                        header: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            RowLayout {
                                Layout.fillWidth: true
                                Kirigami.Heading {
                                    text: i18n("Category Products")
                                    level: 2
                                }
                                Item { Layout.fillWidth: true }
                                Label {
                                    visible: categoryCombo.currentValue !== undefined
                                    text: i18n("Products: %1", productsList.count)
                                    opacity: 0.7
                                }
                            }

                            ComboBox {
                                id: categoryCombo
                                Layout.fillWidth: true
                                textRole: "name"
                                valueRole: "id"
                                enabled: count > 0

                                Connections {
                                    target: favoriteManager
                                    function onCategoriesChanged() {
                                        categoryCombo.model = favoriteManager.getCategories()
                                    }
                                }
                                Component.onCompleted: {
                                    model = favoriteManager.getCategories()
                                }
                            }
                        }

                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.smallSpacing

                            DSearchableComboBox {
                                id: productSearchBox
                                Layout.fillWidth: true
                                enabled: categoryCombo.currentValue !== undefined
                                // placeholderText: categoryCombo.currentValue !== undefined ?
                                //     i18n("Search products to add...") : i18n("Select a category first")
                                onItemSelected: function(product) {
                                    if (categoryCombo.currentValue !== undefined) {
                                        favoriteManager.addProductToCategory(
                                                    categoryCombo.currentValue,
                                                    product.id
                                                    )
                                    }
                                }
                            }

                            ListView {
                                id: productsList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.smallSpacing
                                clip: true

                                model: categoryCombo.currentValue !== undefined ?
                                           favoriteManager.getCategoryProductIds(categoryCombo.currentValue) : []

                                delegate: Kirigami.SwipeListItem {
                                    id: productItem
                                    required property var modelData

                                    contentItem: RowLayout {
                                        spacing: Kirigami.Units.largeSpacing

                                        DBusyIndicator{
                                            running: !productData.loaded
                                            visible: running
                                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            Label {
                                                text: productData.name || i18n("Loading...")
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                text: productData.reference || ""
                                                visible: text !== ""
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                opacity: 0.7
                                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                            }
                                        }

                                        Button {
                                            icon.name: "edit-delete"
                                            display: Button.IconOnly
                                            onClicked: {
                                                favoriteManager.removeProductFromCategory(
                                                            categoryCombo.currentValue,
                                                            modelData
                                                            )
                                            }
                                        }
                                    }

                                    property var productData: ({
                                                                   loaded: false,
                                                                   name: "",
                                                                   reference: ""
                                                               })

                                    Component.onCompleted: {
                                        productFetchApi.getProduct(modelData)
                                    }

                                    Connections {
                                        target: productFetchApi
                                        function onProductReceived(product) {
                                            if (product.id === productItem.modelData) {
                                                productItem.productData = {
                                                    loaded: true,
                                                    name: product.name,
                                                    reference: product.reference
                                                }
                                            }
                                        }
                                    }
                                }

                                // Empty state
                                Kirigami.PlaceholderMessage {
                                    anchors.centerIn: parent
                                    width: parent.width - (Kirigami.Units.largeSpacing * 4)
                                    visible: categoryCombo.currentValue !== undefined && productsList.count === 0
                                    text: i18n("No products in this category")
                                    explanation: i18n("Use the search box above to add products")
                                }

                                // Category selection prompt
                                Kirigami.PlaceholderMessage {
                                    anchors.centerIn: parent
                                    width: parent.width - (Kirigami.Units.largeSpacing * 4)
                                    visible: categoryCombo.currentValue === undefined
                                    text: i18n("Select a Category")
                                    explanation: i18n("Choose a category to manage its products")
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


    Kirigami.Dialog {
        id: deleteCategoryDialog
        title: i18n("Delete Category")
        standardButtons: Dialog.Yes | Dialog.No

        property int categoryId: -1
        property string categoryName: ""

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Label {
                text: i18n("Are you sure you want to delete the category '%1'?", deleteCategoryDialog.categoryName)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: i18n("This will remove all products from this category.")
                font.italic: true
                opacity: 0.7
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            if (categoryId !== -1) {
                favoriteManager.deleteCategory(categoryId)
                // Optional: Show notification
                applicationWindow().showPassiveNotification(
                            i18n("Category deleted successfully"),
                            "short"
                            )
            }
        }

        onClosed: {
            categoryId = -1
            categoryName = ""
        }
    }


    Kirigami.Dialog {
        id: editCategoryDialog
        title: i18n("Edit Category")
        // standardButtons: Dialog.Ok | Dialog.Cancel

        property int categoryId: -1
        property string categoryName: ""
        property bool isValid: editCategoryNameField.text.trim() !== ""

        standardButtons: isValid ? (Dialog.Ok | Dialog.Cancel) : Dialog.Cancel

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: editCategoryNameField
                label: i18n("Category Name")
                text: editCategoryDialog.categoryName
                placeholderText: i18n("Enter category name")
                onAccepted: if (editCategoryDialog.isValid) editCategoryDialog.accept()

                // Optional: Add validation feedback
                statusMessage: text.trim() === "" ? i18n("Category name cannot be empty") : ""
                status: text.trim() === "" ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
            }
        }

        onOpened: {
            editCategoryNameField.text = categoryName
            editCategoryNameField.forceActiveFocus()
        }

        onAccepted: {
            if (isValid) {
                favoriteManager.updateCategory(categoryId, editCategoryNameField.text.trim())
                // Optional: Show notification
                applicationWindow().showPassiveNotification(
                            i18n("Category updated successfully"),
                            "short"
                            )
            }
        }

        onClosed: {
            categoryId = -1
            categoryName = ""
        }
    }

    Kirigami.Dialog {
        id: newCategoryDialog
        title: i18n("New Category")
        // standardButtons: Dialog.Ok | Dialog.Cancel

        property bool isValid: categoryNameField.text.trim() !== ""
        standardButtons: isValid ? (Dialog.Ok | Dialog.Cancel) : Dialog.Cancel

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: categoryNameField
                label: i18n("Category Name")
                placeholderText: i18n("Enter category name")
                onAccepted: if (newCategoryDialog.isValid) newCategoryDialog.accept()

                // Optional: Add validation feedback
                statusMessage: text.trim() === "" ? i18n("Category name cannot be empty") : ""
                status: text.trim() === "" ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
            }
        }

        onOpened: {
            categoryNameField.text = ""
            categoryNameField.forceActiveFocus()
        }

        onAccepted: {
            if (isValid) {
                favoriteManager.createCategory(categoryNameField.text.trim())
                // Optional: Show notification
                applicationWindow().showPassiveNotification(
                            i18n("Category created successfully"),
                            "short"
                            )
            }
        }
    }

    // New category dialog
    // Kirigami.Dialog {
    //     id: newCategoryDialog
    //     title: i18n("New Category")
    //     standardButtons: Dialog.Ok | Dialog.Cancel

    //     FormCard.FormCard {
    //         FormCard.FormTextFieldDelegate {
    //             id: categoryNameField
    //             label: i18n("Category Name")
    //         }
    //     }

    //     onAccepted: {
    //         favoriteManager.createCategory(categoryNameField.text)
    //         categoryNameField.text = ""
    //     }
    // }

    // Edit category dialog
    // Kirigami.Dialog {
    //     id: editCategoryDialog
    //     title: i18n("Edit Category")
    //     standardButtons: Dialog.Ok | Dialog.Cancel

    //     property int categoryId: -1
    //     property string categoryName: ""

    //     FormCard.FormCard {
    //         FormCard.FormTextFieldDelegate {
    //             id: editCategoryNameField
    //             label: i18n("Category Name")
    //             text: editCategoryDialog.categoryName
    //         }
    //     }

    //     onAccepted: {
    //         favoriteManager.updateCategory(
    //                     categoryId,
    //                     editCategoryNameField.text)
    //     }
    // }
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
