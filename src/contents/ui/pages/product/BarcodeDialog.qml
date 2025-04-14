import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.dervox.BarcodeModel 1.0
import "../../components"

Kirigami.Dialog {
    id: barcodeDialog
    title: i18n("Barcodes")
    height: Kirigami.Units.gridUnit * 25
    width: Kirigami.Units.gridUnit * 25
    standardButtons: Kirigami.Dialog.NoButton
    property int productId: -1
    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10

    customFooterActions: [
        Kirigami.Action {
            text: i18n("Add")
            icon.name: "list-add-symbolic"
            onTriggered: {
                addDialog.open()
            }
        },
        Kirigami.Action {
            text: i18n("Close")
            icon.name: "dialog-cancel"
            onTriggered: {
                barcodeDialog.close()
            }
        }
    ]

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Kirigami.InlineMessage {
            id: inlineMsgBarcode
            Layout.fillWidth: true
            text: "Hey! Let me tell you something positive!"
            showCloseButton: true
            type: Kirigami.MessageType.Positive
            visible: false
        }

        QQC2.ScrollView {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: listView.contentHeight
            clip: true
            ListView {
                id: listView
                model: barcodeModel
                interactive: true

                header: Rectangle {
                    width: parent.width
                    height: Kirigami.Units.gridUnit * 2
                    color: Kirigami.Theme.backgroundColor

                    RowLayout {
                        id: headerLayout
                        width: parent.width
                        height: parent.height

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18nc("@title:column", "Barcode")
                            font.bold: true
                            padding: Kirigami.Units.smallSpacing

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    let newDirection = barcodeModel.sortDirection === "asc" ? "desc" : "asc"
                                    barcodeModel.sortDirection = newDirection
                                    barcodeModel.sort(BarcodeRoles.BarcodeRole,
                                                      newDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder)
                                }
                            }
                        }
                    }
                }

                delegate: QQC2.ItemDelegate {
                    id: delegate
                    width: listView.width
                    height: deleteButton.implicitHeight
                    padding: 0

                    required property var model
                    required property int index

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.largeSpacing
                            text: model.barcode
                            elide: Text.ElideRight
                        }
                        QQC2.ToolButton {
                            id: printButton
                            icon.name: "document-print"
                            onClicked: {
                                openBarcodePrintDialog(model.barcode);
                            }
                        }
                        QQC2.ToolButton {
                            id: editButton
                            icon.name: "cell_edit"
                            onClicked: {
                                editDialog.barcodeIDToEdit = model.id
                                editDialog.barcodeToEdit = model.barcode
                                editDialog.open()
                            }
                        }
                        QQC2.ToolButton {
                            id: deleteButton
                            icon.name: "delete"
                            onClicked: {
                                deleteDialog.barcodeToDelete = model.id
                                deleteDialog.open()
                            }
                        }
                    }

                    background: Rectangle {
                        color: {
                            if (delegate.pressed) return Kirigami.Theme.highlightColor
                            if (delegate.hovered) return Qt.rgba(Kirigami.Theme.highlightColor.r,
                                                                 Kirigami.Theme.highlightColor.g,
                                                                 Kirigami.Theme.highlightColor.b, 0.2)
                            return index % 2 === 0 ? "transparent" : Kirigami.Theme.alternateBackgroundColor
                        }
                    }

                    onDoubleClicked: {
                        openBarcodePrintDialog(model.barcode);
                    }
                }
            }
        }
    }

    // Function to open the barcode print dialog with the right parameters
    function openBarcodePrintDialog(barcodeContent) {
        // Try to get price and name from product
        let productPrice = "";
        let productName = "";

        // If we're in product details, get price and name from there
        if (applicationWindow().activePage) {
            if (applicationWindow().activePage.priceField) {
                productPrice = applicationWindow().activePage.priceField.text;
            }
            if (applicationWindow().activePage.nameField) {
                productName = applicationWindow().activePage.nameField.text;
            }
        }

        barcodePrint.productId = productId;
        barcodePrint.contentEditText = barcodeContent;
        barcodePrint.priceText = productPrice;
        barcodePrint.productNameText = productName;
        barcodePrint.open();

        // Automatically generate barcode when opening
        barcodePrint.generateOnOpen = true;
    }

    Kirigami.PromptDialog {
        id: addDialog
        title: i18n("New Barcode")
        standardButtons: Kirigami.Dialog.NoButton
        Kirigami.InlineMessage {
            id: inlineMsgAddDialog
            Layout.fillWidth: true
            text: "Hey! Let me tell you something positive!"
            showCloseButton: true
            type: Kirigami.MessageType.Positive
            visible: false
        }
        customFooterActions: [
            Kirigami.Action {
                text: i18n("Create Barcode")
                icon.name: "dialog-ok"
                onTriggered: {
                    productApi.addProductBarcode(productId, barcodeText.text)
                }
            },
            Kirigami.Action {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onTriggered: {
                    addDialog.close();
                }
            }
        ]
        ColumnLayout {
            QQC2.TextField {
                id: barcodeText
                Layout.fillWidth: true
                placeholderText: i18n("Barcode…")
            }
        }
        Connections {
            target: productApi
            function onErrorBarcodeAdded(message, status, details) {
                inlineMsgAddDialog.text = details
                inlineMsgAddDialog.visible = true
                inlineMsgAddDialog.type = Kirigami.MessageType.Error
            }
        }
        onOpened: {
            barcodeText.text = ""
            inlineMsgAddDialog.text = ""
            inlineMsgAddDialog.visible = false
        }
    }

    Kirigami.PromptDialog {
        id: editDialog
        title: i18n("Edit Barcode")
        standardButtons: Kirigami.Dialog.NoButton
        property string barcodeToEdit: ""
        property int barcodeIDToEdit: 0
        Kirigami.InlineMessage {
            id: inlineMsgEditDialog
            Layout.fillWidth: true
            text: "Hey! Let me tell you something positive!"
            showCloseButton: true
            type: Kirigami.MessageType.Positive
            visible: false
        }
        customFooterActions: [
            Kirigami.Action {
                text: i18n("Save Barcode")
                icon.name: "dialog-ok"
                onTriggered: {
                    productApi.updateProductBarcode(productId, editDialog.barcodeIDToEdit, barcodeTextToEdit.text)
                }
            },
            Kirigami.Action {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onTriggered: {
                    editDialog.close();
                }
            }
        ]
        ColumnLayout {
            QQC2.TextField {
                id: barcodeTextToEdit
                text: editDialog.barcodeToEdit
                Layout.fillWidth: true
            }
        }
        Connections {
            target: productApi
            function onErrorBarcodeUpdated(message, status, details) {
                inlineMsgEditDialog.text = details
                inlineMsgEditDialog.visible = true
                inlineMsgEditDialog.type = Kirigami.MessageType.Error
            }
        }
        onOpened: {
            inlineMsgEditDialog.text = ""
            inlineMsgEditDialog.visible = false
        }
    }

    Kirigami.PromptDialog {
        id: deleteDialog
        property int barcodeToDelete: -1
        title: i18n("Delete Barcode")
        subtitle: i18n("Are you sure you'd like to delete this barcode?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            productApi.removeProductBarcode(productId, barcodeToDelete)
        }
    }

    onProductIdChanged: {
        if (productId !== -1) {
            console.log("Product ID Changed:", productId)
            barcodeModel.setApi(productApi)
            barcodeModel.setProductId(productId)
        }
    }

    Connections {
        target: productApi
        function onErrorProductBarcodesReceived(message, status, details) {
            inlineMsgBarcode.text = details
            inlineMsgBarcode.visible = true
            inlineMsgBarcode.type = Kirigami.MessageType.Error
        }
        function onErrorBarcodeRemoved(message, status, details) {
            inlineMsgBarcode.text = details
            inlineMsgBarcode.visible = true
            inlineMsgBarcode.type = Kirigami.MessageType.Error
        }
        function onBarcodeAdded() {
            addDialog.close()
            inlineMsgBarcode.text = i18n("Barcode Created successfully")
            inlineMsgBarcode.visible = true
            inlineMsgBarcode.type = Kirigami.MessageType.Positive
            barcodeModel.refresh()
        }
        function onBarcodeRemoved() {
            inlineMsgBarcode.text = i18n("Barcode Deleted successfully")
            inlineMsgBarcode.visible = true
            inlineMsgBarcode.type = Kirigami.MessageType.Positive
            barcodeModel.refresh()
        }
        function onBarcodeUpdated() {
            editDialog.close()
            inlineMsgBarcode.text = i18n("Barcode Updated successfully")
            inlineMsgBarcode.visible = true
            inlineMsgBarcode.type = Kirigami.MessageType.Positive
            barcodeModel.refresh()
        }
    }

    BarcodePrint {
        id: barcodePrint
    }
}
