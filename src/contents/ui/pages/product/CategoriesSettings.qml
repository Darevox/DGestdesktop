// CategoriesSettings.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

ColumnLayout {
    id: root
    spacing: Kirigami.Units.largeSpacing

    // Property to expose the current category list model
    property alias categoriesModel: listCategories.model

    // Signal when categories change
    signal categoriesChanged()

    Kirigami.Card {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.preferredHeight: Kirigami.Units.gridUnit * 28
        Layout.margins:Kirigami.Units.smallSpacing
        header: RowLayout {
            Kirigami.Heading {
                text: i18n("Categories")
                level: 2
            }
            Item { Layout.fillWidth: true }
            QQC2.Button {
                icon.name: "list-add"
                text: i18n("Add Category")
                onClicked: newCategoryDialog.open()
            }
        }

        contentItem: ListView {
            id: listCategories
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            clip: true
            Layout.margins:Kirigami.Units.smallSpacing
            model: favoriteManager.getCategories()

            delegate: Kirigami.SwipeListItem {
                width: ListView.view.width
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    QQC2.Label {
                        text: modelData.name || ""
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                actions: [
                    Kirigami.Action {
                        icon.name: "edit-entry"
                        onTriggered: {
                            editCategoryDialog.categoryId = modelData.id
                            editCategoryDialog.categoryName = modelData.name
                            editCategoryDialog.open()
                        }
                    },
                    Kirigami.Action {
                        icon.name: "edit-delete"
                        onTriggered: {
                            deleteCategoryDialog.categoryId = modelData.id
                            deleteCategoryDialog.categoryName = modelData.name
                            deleteCategoryDialog.open()
                        }
                    }
                ]
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - (Kirigami.Units.largeSpacing * 4)
                visible: listCategories.count === 0
                text: i18n("No categories yet")
                icon.name: "folder-symbolic"
            }
        }
    }

    // Dialogs
    Kirigami.Dialog {
        id: newCategoryDialog
        title: i18n("New Category")
        property bool isValid: categoryNameField.text.trim() !== ""

        // Don't set standardButtons here, set them in Component.onCompleted
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: categoryNameField
                label: i18n("Category Name")
                placeholderText: i18n("Enter category name")
                onAccepted: if (newCategoryDialog.isValid) newCategoryDialog.accept()

                // Only show error message if field has been touched
                property bool isDirty: false

                onTextChanged: {
                    isDirty = true
                    validateInput()
                }

                statusMessage: isDirty && text.trim() === "" ? i18n("Category name cannot be empty") : ""
                status: isDirty && text.trim() === "" ?
                       Kirigami.MessageType.Error :
                       text.trim() !== "" ?
                       Kirigami.MessageType.Positive :
                       Kirigami.MessageType.Information
            }
        }

        function validateInput() {
            // Update OK button state
            newCategoryDialog.standardButtons = categoryNameField.text.trim() !== "" ?
                (QQC2.Dialog.Ok | QQC2.Dialog.Cancel) :
                QQC2.Dialog.Cancel
        }

        onAccepted: {
            if (categoryNameField.text.trim() !== "") {
                favoriteManager.createCategory(categoryNameField.text.trim())
                root.categoriesChanged()
            }
        }

        onOpened: {
            categoryNameField.text = ""
            categoryNameField.isDirty = false
            categoryNameField.forceActiveFocus()
            // Reset buttons state
            standardButtons = QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        }

        onClosed: {
            categoryNameField.isDirty = false
            categoryNameField.text = ""
        }
    }

    Kirigami.Dialog {
        id: editCategoryDialog
        title: i18n("Edit Category")
        property int categoryId: -1
        property string categoryName: ""
        property bool isValid: editCategoryNameField.text.trim() !== ""
        standardButtons: isValid ? (QQC2.Dialog.Ok | QQC2.Dialog.Cancel) : QQC2.Dialog.Cancel

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: editCategoryNameField
                label: i18n("Category Name")
                text: editCategoryDialog.categoryName
                placeholderText: i18n("Enter category name")
                onAccepted: if (editCategoryDialog.isValid) editCategoryDialog.accept()
                statusMessage: text.trim() === "" ? i18n("Category name cannot be empty") : ""
                status: text.trim() === "" ? Kirigami.MessageType.Error : Kirigami.MessageType.Positive
            }
        }

        onAccepted: {
            if (isValid) {
                favoriteManager.updateCategory(categoryId, editCategoryNameField.text.trim())
                root.categoriesChanged()
            }
        }

        onOpened: {
            editCategoryNameField.text = categoryName
            editCategoryNameField.forceActiveFocus()
        }
    }

    Kirigami.Dialog {
        id: deleteCategoryDialog
        title: i18n("Delete Category")
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No

        property int categoryId: -1
        property string categoryName: ""

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: i18n("Are you sure you want to delete the category '%1'?", deleteCategoryDialog.categoryName)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.Label {
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
                root.categoriesChanged()
            }
        }
    }

    // Connect to FavoriteManager signals
    Connections {
        target: favoriteManager
        function onCategoriesChanged() {
            listCategories.model = favoriteManager.getCategories()
            root.categoriesChanged()
        }
    }

    Component.onCompleted: {
        listCategories.model = favoriteManager.getCategories()
    }
}
