import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.dervox.BarcodeModel 1.0
import "../../components"
import "."

Kirigami.Dialog {
    id: barcodeDialog
    title: "Barcode"
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
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                barcodeDialog.close()
            }
        }
    ]

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Item {
                Layout.fillWidth: true
            }
            QQC2.ToolButton {
                icon.name: "list-add-symbolic"
                text: "Add"
                onClicked:{
                addDialog.open()
                }
            }
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
                                let barCodeProduct = model.barcode
                                console.log("Row Clicked:", index, "Barcode:", barCodeProduct)
                                barcodePrint.contentEditText = barCodeProduct
                                barcodePrint.open()
                            }
                        }
                        QQC2.ToolButton {
                            id: editButton
                            icon.name: "cell_edit"
                            onClicked: {
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
                        let barCodeProduct = model.barcode
                        console.log("Row Clicked:", index, "Barcode:", barCodeProduct)
                        barcodePrint.contentEditText = barCodeProduct
                        barcodePrint.open()
                    }
                }
            }
        }
    }

    Kirigami.PromptDialog {
        id: addDialog
        title: "New Barcode"
        standardButtons: Kirigami.Dialog.NoButton
        customFooterActions: [
            Kirigami.Action {
                text: "Create Barcode"
                icon.name: "dialog-ok"
                onTriggered: {
                    productApi.addProductBarcode(productId,barcodeText.text)
                }
            },
            Kirigami.Action {
                text: "Cancel"
                icon.name: "dialog-cancel"
                onTriggered: {
                    addDialog.close();
                }
            }
        ]
        ColumnLayout {
            QQC2.TextField {
                id:barcodeText
                Layout.fillWidth: true
                placeholderText: "Barcode…"
            }
        }
    }
    Kirigami.PromptDialog {
        id: editDialog
        title: "Edit Barcode"
        standardButtons: Kirigami.Dialog.NoButton
        property string barcodeToEdit: ""
        customFooterActions: [
            Kirigami.Action {
                text: "Save Barcode"
                icon.name: "dialog-ok"
                onTriggered: {
                    productApi.removeProductBarcode(productId,barcodeTextToEdit.text)
                }
            },
            Kirigami.Action {
                text: "Cancel"
                icon.name: "dialog-cancel"
                onTriggered: {
                    editDialog.close();
                }
            }
        ]
        ColumnLayout {
            QQC2.TextField {
                id:barcodeTextToEdit
                text:editDialog.barcodeToEdit
                Layout.fillWidth: true
            }
        }
    }
    Kirigami.PromptDialog {
        id: deleteDialog
        property int barcodeToDelete: -1
        title: i18n("Delete Barcode")
        subtitle: i18n("Are you sure you'd like to delete this barcode?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            productApi.removeProductBarcode(productId,barcodeToDelete)
        }
    }

    onProductIdChanged: {
        if (productId !== -1) {
            console.log("Product ID Changed:", productId)
            barcodeModel.setApi(productApi)
            barcodeModel.setProductId(productId)
        }
    }

    BarcodePrint {
        id: barcodePrint
    }
}
