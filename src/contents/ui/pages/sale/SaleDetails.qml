// SaleDetails.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.PromptDialog {
    id: saleDialog
    title: dialogSaleId > 0 ? i18n("Edit Sale") : i18n("New Sale")
    preferredWidth: Kirigami.Units.gridUnit * 60

    property int dialogSaleId: 0
    property bool isCreateAnother: false
    property bool isEditing: dialogSaleId > 0
    property var selectedProducts: []
    property var currentSale: null
    standardButtons: Kirigami.Dialog.NoButton
    property double remainingAmount: 0
    QQC2.BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: saleModel.loading
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

        // Sale Details Section
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormCheckDelegate {
                id: hasClientCheckbox
                text: i18n("Assign to Client")
                checked: false
                enabled: !isEditing
            }

            FormCard.FormComboBoxDelegate {
                id: clientField
                text: i18n("Client")
                model: clientModel
                textRole: "name"
                valueRole: "id"
                enabled: !isEditing && hasClientCheckbox.checked
                visible: hasClientCheckbox.checked
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
                id: saleDateField
                text: i18n("Sale Date")
                value: new Date()
            }

            FormCard.FormDateTimeDelegate {
                id: dueDateField
                text: i18n("Due Date")
                value: new Date()
                enabled: hasClientCheckbox.checked
                visible: hasClientCheckbox.checked
            }
        }

        // Items Section
        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Sale Items")
            }

            // Add Product Button and Items List
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
                        width: selectedProductsList.width
                        height: 40
                        color: Kirigami.Theme.alternateBackgroundColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.largeSpacing

                            QQC2.Label {
                                text: i18n("Product")
                                Layout.preferredWidth: 100
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Quantity")
                                Layout.preferredWidth: 100
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Unit Price")
                                Layout.preferredWidth: 100
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Tax Rate")
                                Layout.preferredWidth: 100
                                font.bold: true
                            }
                            QQC2.Label {
                                text: i18n("Total")
                                Layout.preferredWidth: 100
                                font.bold: true
                            }
                            // Spacer for remove button
                            Item {
                                Layout.preferredWidth: 40
                            }
                        }
                    }

                    // Delegate
                    delegate: Rectangle {
                        width: selectedProductsList.width
                        height: 50
                        color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.largeSpacing

                            QQC2.Label {
                                text: model.name
                                Layout.preferredWidth: 100
                                elide: Text.ElideRight
                            }

                            QQC2.ComboBox {
                                     id: packageTypeCombo
                                     Layout.preferredWidth: 150

                                     property var options: {
                                         let opts = [i18n("Piece")]
                                         let packages = JSON.parse(selectedProductsModel.get(index).packagesJson || '[]')
                                         packages.forEach(pkg => {
                                             if (pkg && pkg.name) {
                                                 opts.push(pkg.name)
                                             }
                                         })
                                         return opts
                                     }

                                     model: options

                                     onCurrentIndexChanged: {
                                         if (currentIndex >= 0) {
                                             let item = selectedProductsModel.get(index)
                                             let packages = JSON.parse(item.packagesJson || '[]')

                                             if (currentIndex === 0) {
                                                 console.log("Selected piece mode")
                                                 selectedProductsModel.setProperty(index, "packageId", null)
                                                 selectedProductsModel.setProperty(index, "isPackage", false)
                                                 selectedProductsModel.setProperty(index, "piecesPerUnit", 1)
                                                 selectedProductsModel.setProperty(index, "unitPrice", item.originalUnitPrice)
                                                 selectedProductsModel.setProperty(index, "maxQuantity", item.product.quantity)
                                             } else {
                                                 let pkg = packages[currentIndex - 1]
                                                 if (pkg) {
                                                     console.log("Selected package:", JSON.stringify(pkg))

                                                     selectedProductsModel.setProperty(index, "packageId", pkg.id)
                                                     selectedProductsModel.setProperty(index, "isPackage", true)
                                                     selectedProductsModel.setProperty(index, "piecesPerUnit", pkg.pieces_per_package || 1)
                                                     selectedProductsModel.setProperty(index, "unitPrice", pkg.selling_price || 0)
                                                     // Calculate max quantity based on available pieces
                                                     let maxPackages = Math.floor(item.product.quantity / pkg.pieces_per_package)
                                                     selectedProductsModel.setProperty(index, "maxQuantity", maxPackages)
                                                 }
                                             }

                                             // Update totals
                                             let totalPieces = item.quantity * item.piecesPerUnit
                                             selectedProductsModel.setProperty(index, "totalPieces", totalPieces)
                                             calculateItemTotal(index)
                                         }
                                     }
                                 }

                                 // Update the quantity SpinBox
                                 QQC2.SpinBox {
                                     id: quantitySpinBox
                                     Layout.preferredWidth: 100
                                     value: model.quantity
                                     from: 1
                                     to: model.maxQuantity
                                     editable: true

                                     onValueChanged: {
                                         if (value !== model.quantity) {
                                             selectedProductsModel.setProperty(index, "quantity", value);
                                             let item = selectedProductsModel.get(index);
                                             let totalPieces = value * item.piecesPerUnit;
                                             selectedProductsModel.setProperty(index, "totalPieces", totalPieces);
                                             calculateItemTotal(index);
                                         }
                                     }
                                 }




                            QQC2.SpinBox {
                                Layout.preferredWidth: 100
                                value: model.unitPrice
                                from: 0
                                to: 999999
                                onValueModified: {
                                    selectedProductsModel.setProperty(index, "unitPrice", value)
                                    calculateItemTotal(index)
                                }
                            }

                            QQC2.SpinBox {
                                Layout.preferredWidth: 100
                                value: model.taxRate
                                from: 0
                                to: 100
                                onValueModified: {
                                    selectedProductsModel.setProperty(index, "taxRate", value)
                                    calculateItemTotal(index)
                                }
                            }

                            QQC2.Label {
                                Layout.preferredWidth: 100
                                text: model.totalPrice.toLocaleString(Qt.locale(), 'f', 2)
                                horizontalAlignment: Text.AlignRight
                            }

                            QQC2.ToolButton {
                                Layout.preferredWidth: 40
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
                        explanation: i18n("Click 'Add Products' to select products for this sale")
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
                label: "Discount"
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
            text: isEditing ? i18n("Save Changes") : i18n("Create Sale")
            icon.name: isEditing ? "document-save" : "list-add"
            enabled: !saleModel.loading && validateForm()
            onTriggered: {
                isCreateAnother = false
                saveSale()
            }
        },
        Kirigami.Action {
            text: i18n("Create & Add Another")
            icon.name: "list-add"
            visible: !isEditing
            enabled: !saleModel.loading && validateForm()
            onTriggered: {
                isCreateAnother = true
                saveSale()
            }
        },
        Kirigami.Action {
            text: i18n("Add Payment")
            icon.name: "money-management"
            visible: isEditing && currentSale?.payment_status !== "paid"
            enabled: !saleModel.loading
            onTriggered: paymentDialog.open()
        },
        Kirigami.Action {
            text: i18n("Generate Invoice")
            icon.name: "document-print"
            visible: isEditing
            enabled: !saleModel.loading
            onTriggered: saleModel.generateInvoice(dialogSaleId)
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: saleDialog.close()
        }
    ]

    // Payment Dialog
    Kirigami.PromptDialog {
        id: paymentDialog
        title: i18n("Add Payment")
        standardButtons: Kirigami.Dialog.NoButton
        property string generatedReference: "PAY-" + Qt.formatDateTime(new Date(), "yyyyMMdd-hhmmss")
        onOpened: {
            console.log("Payment dialog opened. Remaining amount:", remainingAmount);
            paymentAmountField.text = remainingAmount.toString();
            paymentCashSourceField.currentIndex = -1;
            paymentNotesField.text = "";
            // Generate new reference number
            generatedReference = "PAY-" + Qt.formatDateTime(new Date(), "yyyyMMdd-hhmmss");
        }
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormComboBoxDelegate {
                id: paymentCashSourceField
                text: i18n("Cash Source")
                model: cashSourceModel
                textRole: "name"
                valueRole: "id"
            }

            FormCard.FormTextFieldDelegate {
                id: paymentAmountField
                label: i18n("Amount")
                text: remainingAmount.toString()
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator {
                    bottom: 0
                    top: remainingAmount
                    decimals: 2
                    notation: DoubleValidator.StandardNotation
                }
                // Add onTextChanged for debugging
                onTextChanged: {
                    console.log("Payment amount changed to:", text);
                }
            }

            FormCard.FormTextFieldDelegate {
                id: paymentReferenceField
                label: i18n("Reference Number")
                text: paymentDialog.generatedReference
                readOnly: true
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
                enabled: {
                    let amount = parseFloat(paymentAmountField.text) || 0
                    return amount > 0 &&
                    amount <= remainingAmount &&
                    paymentCashSourceField.currentValue != -1
                }
                onTriggered: {
                    saleModel.addPayment(dialogSaleId, {
                                             cashSourceId: paymentCashSourceField.currentValue,
                                             amount: parseFloat(paymentAmountField.text),
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


    function addOrUpdateProduct(product) {
        console.log("Adding product with packages:", JSON.stringify(product.packages));

        // Check if product exists
        for (let i = 0; i < selectedProductsModel.count; i++) {
            if (selectedProductsModel.get(i).productId === parseInt(product.id)) {
                return;
            }
        }

        // Process packages if they exist
        let processedPackages = (product.packages || []).map(pkg => ({
            id: pkg.id || null,
            name: pkg.name || "",
            pieces_per_package: pkg.pieces_per_package || 1,
            purchase_price: pkg.purchase_price || 0,
            selling_price: pkg.selling_price || 0,
            barcode: pkg.barcode || ""
        }));

        let newProduct = {
            productId: parseInt(product.id),
            name: product.name,
            quantity: 1,
            unitPrice: parseFloat(product.price) || 0,
            originalUnitPrice: parseFloat(product.price) || 0,
            maxQuantity: product.quantity || 0,
            taxRate: 0,
            totalPrice: parseFloat(product.price) || 0,
            packagesJson: JSON.stringify(processedPackages),
            packageId: null,
            isPackage: false,
            piecesPerUnit: 1,
            totalPieces: 1,
            product: product
        };

        console.log("Adding new product:", JSON.stringify(newProduct));
        selectedProductsModel.append(newProduct);
        calculateItemTotal(selectedProductsModel.count - 1);
    }

    // Product Selector Dialog
    ProductSelectorDialog {
        id: productSelectorDialog
        onProductsSelected: function(products) {
            products.forEach(product => {
                                 addOrUpdateProduct(product);
                             });
        }
    }


    // Helper functions
    function calculateItemTotal(row) {
        let item = selectedProductsModel.get(row);
        let totalPieces = item.quantity * item.piecesPerUnit;
        let subtotal = item.quantity * item.unitPrice;
        let tax = (subtotal * item.taxRate) / 100;
        let total = subtotal + tax;

        selectedProductsModel.setProperty(row, "totalPrice", total);
        selectedProductsModel.setProperty(row, "totalPieces", totalPieces);
        return total;
    }



    function calculateSubtotal() {


        let subtotal = 0;
        for (let i = 0; i < selectedProductsModel.count; i++) {
            let item = selectedProductsModel.get(i);
            subtotal += item.quantity * item.unitPrice;
        }

        return subtotal;
    }

    function calculateTotalTax() {

        let totalTax = 0;
        for (let i = 0; i < selectedProductsModel.count; i++) {
            let item = selectedProductsModel.get(i);
            let subtotal = item.quantity * item.unitPrice;
            totalTax += (subtotal * item.taxRate) / 100;
        }

        return totalTax;
    }

    function calculateTotal() {

        let total = calculateSubtotal() + calculateTotalTax() - (discountField.value || 0);
        return total;
    }


    function validateForm() {
        return (!hasClientCheckbox.checked || clientField.currentIndex >= 0) &&
                cashSourceField.currentIndex >= 0 &&
                selectedProductsModel.count > 0;
    }

    function findModelIndex(model, id) {
        for (let i = 0; i < model.rowCount; i++) {
            if (model.data(model.index(i, 0), model.IdRole) === id) {
                return i;
            }
        }
        return -1;
    }
    function saveSale() {
        let items = [];
        for (let i = 0; i < selectedProductsModel.count; i++) {
            let item = selectedProductsModel.get(i);

            let isPackage = item.isPackage === true;
            let hasValidPackageId = item.packageId && parseInt(item.packageId) > 0;

            let itemData = {
                product_id: item.productId,
                quantity: item.quantity,
                unit_price: item.unitPrice,
                tax_rate: item.taxRate || 0,
                total_pieces: item.totalPieces,
                is_package: isPackage,
                package_id: hasValidPackageId ? parseInt(item.packageId) : null,
                notes: ""
            };

            items.push(itemData);
        }

        let saleData = {
            client_id: hasClientCheckbox.checked ? clientField.currentValue : null,
            cash_source_id: cashSourceField.currentValue,
            sale_date: saleDateField.value.toISOString(),
            due_date: hasClientCheckbox.checked ? dueDateField.value.toISOString() : null,
            notes: notesField.text || "",
            items: items
        };

        if (isEditing) {
            saleModel.updateSale(dialogSaleId, saleData);
        } else {
            saleModel.createSale(saleData);
        }
    }



    function clearForm() {
        currentSale = null;
        hasClientCheckbox.checked = false;
        clientField.currentIndex = -1;
        cashSourceField.currentIndex = -1;
        saleDateField.value = new Date();
        dueDateField.value = new Date();
        notesField.text = "";
        selectedProductsModel.clear();
        discountField.value = 0;
    }

    function updateRemainingAmount() {
        if (currentSale) {
            let total = parseFloat(currentSale.total_amount) || 0;
            let paid = parseFloat(currentSale.paid_amount) || 0;
            remainingAmount = total - paid;
            console.log("Updated remaining amount:", remainingAmount);

            // Force update of payment amount field if dialog is open
            if (paymentDialog.visible) {
                paymentAmountField.text = remainingAmount.toString();
            }
        } else {
            remainingAmount = 0;
        }
    }

    function loadData(sale) {
        if (!sale) return;

        // Update client field using findModelIndex
        hasClientCheckbox.checked = sale.client_id ? true : false;
        if (sale.client_id) {
            clientField.currentIndex = findModelIndex(clientModel, sale.client_id);
        }

        // Update cash source field using findModelIndex
        cashSourceField.currentIndex = findModelIndex(cashSourceModel, sale.cash_source_id);

        // Update other fields
        saleDateField.value = new Date(sale.sale_date);
        if (sale.due_date) {
            dueDateField.value = new Date(sale.due_date);
        }
        notesField.text = sale.notes || "";
        discountField.value = sale.discount_amount || 0;

        // Clear and reload items
        selectedProductsModel.clear();
        sale.items.forEach(item => {
                               selectedProductsModel.append({
                                                                productId: item.product_id,
                                                                name: item.product.name,
                                                                quantity: item.quantity,
                                                                maxQuantity: item.product.quantity + item.quantity,
                                                                unitPrice: item.unit_price,
                                                                taxRate: item.tax_rate || 0,
                                                                totalPrice: item.total_price
                                                            });
                           });

        updateRemainingAmount();
    }
    Connections {
        target: selectedProductsModel
        function onDataChanged() {
            Qt.callLater(function() {
                calculateSubtotal();
                calculateTotalTax();
                calculateTotal();
            });

        }
    }

    // Data loading
    Connections {
        target: saleApi
        function onSaleCreated() {
            if (!isCreateAnother) {
                saleDialog.close()
            } else {
                inlineMsg.type = Kirigami.MessageType.Positive
                inlineMsg.text = i18n("Sale created successfully")
                inlineMsg.visible = true
                clearForm()
            }
        }

        function onSaleUpdated() {
            saleDialog.close()
        }

        function onSaleReceived(sale) {
            console.log("DDDDDDDDDDDDDDD")
            console.log("Received sale data:", JSON.stringify(sale, null, 2));
            console.log("Total amount:", sale.total_amount);
            console.log("Paid amount:", sale.paid_amount);
            currentSale = sale
            updateRemainingAmount()
            loadData(sale)
        }
    }

    onDialogSaleIdChanged: {
        if (dialogSaleId > 0) {
            saleApi.getSale(dialogSaleId)
        }
    }

    Component.onCompleted: {
        clientModel.setApi(clientApi)
        cashSourceModel.setApi(cashSourceApi)
    }
}