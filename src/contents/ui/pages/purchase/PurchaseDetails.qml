// PurchaseDetails.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.PromptDialog {
    id: purchaseDialog
    title: dialogPurchaseId > 0 ? i18n("Edit Purchase") : i18n("New Purchase")
    preferredWidth: Kirigami.Units.gridUnit * 60

    property int dialogPurchaseId: 0
    property bool isCreateAnother: false
    property bool isEditing: dialogPurchaseId > 0
    property var selectedProducts: []

    standardButtons: Kirigami.Dialog.NoButton

    QQC2.BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: purchaseModel.loading
        visible: running
        z: 999
    }

    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // Purchase Details Section
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormComboBoxDelegate {
                id: supplierField
                text: i18n("Supplier")
                model: supplierModel
                textRole: "name"
                valueRole: "id"
                enabled: !isEditing
            }

            FormCard.FormComboBoxDelegate {
                id: cashSourceField
                text: i18n("Cash Source")
                model: cashSourceModel
                textRole: "name"
                valueRole: "id"
                enabled: !isEditing
            }

            FormCard.FormDateTimeDelegate {
                id: purchaseDateField
                text: i18n("Purchase Date")
                value: new Date()
            }

            FormCard.FormDateTimeDelegate {
                id: dueDateField
                text: i18n("Due Date")
                value: new Date()
            }
        }

        // Items Section
        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Purchase Items")
            }

            // Add Product Button
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    text: i18n("Add Products")
                    icon.name: "list-add"
                    onClicked: productSelectorDialog.open()
                }

                // Selected products list
                ListView {
                    id: selectedProductsList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight + 60, 300)
                    model: ListModel { id: selectedProductsModel }
                    clip: true

                    // Header
                    header: Rectangle {
                        width: parent.width
                        height: 40
                        color: Kirigami.Theme.alternateBackgroundColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.largeSpacing

                            QQC2.Label {
                                text: i18n("Product")
                                Layout.fillWidth: true
                                Layout.preferredWidth: 3
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Quantity")
                                Layout.preferredWidth: 1
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Unit Price")
                                Layout.preferredWidth: 1
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Tax Rate")
                                Layout.preferredWidth: 1
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Total")
                                Layout.preferredWidth: 1
                                font.bold: true
                            }
                            // Spacer for remove button
                            Item {
                                Layout.preferredWidth: 40
                            }
                        }
                    }

                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.largeSpacing

                            QQC2.Label {
                                text: model.name
                                Layout.fillWidth: true
                                Layout.preferredWidth: 3
                                elide: Text.ElideRight
                            }

                            QQC2.SpinBox {
                                Layout.preferredWidth: 1
                                value: model.quantity
                                from: 1
                                to: 9999
                                onValueModified: {
                                    selectedProductsModel.setProperty(index, "quantity", value)
                                    calculateItemTotal(index)
                                }
                            }

                            QQC2.SpinBox {
                                Layout.preferredWidth: 1
                                value: model.unitPrice
                                from: 0
                                to: 999999
                                //stepSize: 0.01
                                onValueModified: {
                                    selectedProductsModel.setProperty(index, "unitPrice", value)
                                    calculateItemTotal(index)
                                }
                            }

                            QQC2.SpinBox {
                                Layout.preferredWidth: 1
                                value: model.taxRate
                                from: 0
                                to: 100
                                onValueModified: {
                                    selectedProductsModel.setProperty(index, "taxRate", value)
                                    calculateItemTotal(index)
                                }
                            }

                            QQC2.Label {
                                Layout.preferredWidth: 1
                                text: model.totalPrice.toLocaleString(Qt.locale(), 'f', 2)
                                horizontalAlignment: Text.AlignRight
                            }

                            QQC2.ToolButton {
                                icon.name: "list-remove"
                                onClicked: selectedProductsModel.remove(index)
                            }
                        }
                    }

                    // Empty state message
                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (Kirigami.Units.largeSpacing * 4)
                        visible: selectedProductsModel.count === 0
                        text: i18n("No products added")
                        explanation: i18n("Click 'Add Products' to select products for this purchase")
                        icon.name: "package"
                    }
                }
            }
        }

        // Totals Section
        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Totals")
            }

            FormCard.FormTextDelegate {
                text: i18n("Subtotal")
                description: calculateSubtotal().toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormTextDelegate {
                text: i18n("Tax")
                description: calculateTotalTax().toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormSpinBoxDelegate {
                id: discountField
                label:  "Discount"
                from: 0
                to: calculateSubtotal()
                onValueChanged: calculateTotal()
            }

            FormCard.FormTextDelegate {
                text: i18n("Total")
                description: calculateTotal().toLocaleString(Qt.locale(), 'f', 2)
            }
        }

        // Notes Section
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextAreaDelegate {
                id: notesField
                label: i18n("Notes")
                text: ""
            }
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: isEditing ? i18n("Save Changes") : i18n("Create Purchase")
            icon.name: isEditing ? "document-save" : "list-add"
            enabled: !purchaseModel.loading && validateForm()
            onTriggered: {
                isCreateAnother = false
                savePurchase()
            }
        },
        Kirigami.Action {
            text: i18n("Create & Add Another")
            icon.name: "list-add"
            visible: !isEditing
            enabled: !purchaseModel.loading && validateForm()
            onTriggered: {
                isCreateAnother = true
                savePurchase()
            }
        },
        Kirigami.Action {
            text: i18n("Add Payment")
            icon.name: "money-management"
            visible: isEditing && purchase?.payment_status !== "paid"
            enabled: !purchaseModel.loading
            onTriggered: paymentDialog.open()
        },
        Kirigami.Action {
            text: i18n("Generate Invoice")
            icon.name: "document-print"
            visible: isEditing
            enabled: !purchaseModel.loading
            onTriggered: purchaseModel.generateInvoice(dialogPurchaseId)
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: purchaseDialog.close()
        }
    ]

    // Product Selector Dialog
    ProductSelectorDialog {
        id: productSelectorDialog
        onProductsSelected: function(products) {
            products.forEach(product => {
                selectedProductsModel.append({
                    productId: product.id,
                    name: product.name,
                    quantity: 1,
                    unitPrice: product.price,
                    taxRate: 0,
                    totalPrice: product.price
                })
            })
        }
    }

    // Payment Dialog
    Kirigami.PromptDialog {
        id: paymentDialog
        title: i18n("Add Payment")
        standardButtons: Kirigami.Dialog.NoButton

        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormComboBoxDelegate {
                id: paymentCashSourceField
                text: i18n("Cash Source")
                model: cashSourceModel
                textRole: "name"
                valueRole: "id"
            }

            FormCard.FormSpinBoxDelegate {
                id: paymentAmountField
                label: i18n("Amount")
                from: 0
                to: purchase?.remaining_amount || 0
                value: purchase?.remaining_amount || 0
            }

            FormCard.FormTextFieldDelegate {
                id: paymentReferenceField
                label: i18n("Reference Number")
            }

            FormCard.FormComboBoxDelegate {
                id: paymentMethodField
                text: i18n("Payment Method")
                model: ["Cash", "Bank Transfer", "Check"]
            }

            FormCard.FormTextAreaDelegate {
                id: paymentNotesField
                label: i18n("Notes")
            }
        }

        customFooterActions: [
            Kirigami.Action {
                text: i18n("Add Payment")
                icon.name: "money-management"
                enabled: paymentAmountField.value > 0 && paymentCashSourceField.currentValue > 0
                onTriggered: {
                    purchaseModel.addPayment(dialogPurchaseId, {
                        cashSourceId: paymentCashSourceField.currentValue,
                        amount: paymentAmountField.value,
                        paymentMethod: paymentMethodField.currentText,
                        referenceNumber: paymentReferenceField.text,
                        notes: paymentNotesField.text
                    })
                    paymentDialog.close()
                }
            },
            Kirigami.Action {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onTriggered: paymentDialog.close()
            }
        ]
    }

    function calculateItemTotal(row) {
        let item = selectedProductsModel.get(row)
        let subtotal = item.quantity * item.unitPrice
        let tax = (subtotal * item.taxRate) / 100
        let total = subtotal + tax
        selectedProductsModel.setProperty(row, "totalPrice", total)
        return total
    }

    function calculateSubtotal() {
        let subtotal = 0
        for (let i = 0; i < selectedProductsModel.count; i++) {
            let item = selectedProductsModel.get(i)
            subtotal += item.quantity * item.unitPrice
        }
        return subtotal
    }

    function calculateTotalTax() {
        let totalTax = 0
        for (let i = 0; i < selectedProductsModel.count; i++) {
            let item = selectedProductsModel.get(i)
            let subtotal = item.quantity * item.unitPrice
            totalTax += (subtotal * item.taxRate) / 100
        }
        return totalTax
    }

    function calculateTotal() {
        return calculateSubtotal() + calculateTotalTax() - (discountField.value || 0)
    }

    function validateForm() {
        return supplierField.currentValue > 0 &&
               cashSourceField.currentValue > 0 &&
               selectedProductsModel.count > 0
    }

    function savePurchase() {
        let items = []
        for (let i = 0; i < selectedProductsModel.count; i++) {
            let item = selectedProductsModel.get(i)
            items.push({
                product_id: item.productId,
                quantity: item.quantity,
                unit_price: item.unitPrice,
                tax_rate: item.taxRate,
                notes: item.notes || ""
            })
        }

        let purchaseData = {
            supplier_id: supplierField.currentValue,
            cash_source_id: cashSourceField.currentValue,
            purchase_date: purchaseDateField.value.toISOString(),
            due_date: dueDateField.value.toISOString(),
            notes: notesField.text,
            items: items
        }

        if (isEditing) {
            purchaseModel.updatePurchase(dialogPurchaseId, purchaseData)
        } else {
            purchaseModel.createPurchase(purchaseData)
        }
    }

    function loadData(purchase) {
        supplierField.currentValue = purchase.supplier_id
        cashSourceField.currentValue = purchase.cash_source_id
        purchaseDateField.value = new Date(purchase.purchase_date)
        dueDateField.value = purchase.due_date ? new Date(purchase.due_date) : new Date()
        notesField.text = purchase.notes || ""

        selectedProductsModel.clear()
        purchase.items.forEach(item => {
            selectedProductsModel.append({
                productId: item.product_id,
                name: item.product_name,
                quantity: item.quantity,
                unitPrice: item.unit_price,
                taxRate: item.tax_rate || 0,
                totalPrice: item.total_price
            })
        })
    }

    function clearForm() {
        supplierField.currentIndex = 0
        cashSourceField.currentIndex = 0
        purchaseDateField.value = new Date()
        dueDateField.value = new Date()
        notesField.text = ""
        selectedProductsModel.clear()
        discountField.value = 0
    }

    Connections {
        target: purchaseModel
        function onPurchaseCreated() {
            if (!isCreateAnother) {
                purchaseDialog.close()
            } else {
                inlineMsg.type = Kirigami.MessageType.Positive
                inlineMsg.text = i18n("Purchase created successfully")
                inlineMsg.visible = true
                clearForm()
            }
        }

        function onPurchaseUpdated() {
            purchaseDialog.close()
        }

        // function onPurchaseReceived(purchase) {
        //     loadData(purchase)
        // }
    }

    Component.onCompleted: {
        if (dialogPurchaseId > 0) {
            purchaseModel.getPurchase(dialogPurchaseId)
        }
    }
}
