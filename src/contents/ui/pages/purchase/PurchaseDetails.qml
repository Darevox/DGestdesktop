// PurchaseDetails.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.Dialog{
    id: purchaseDialog
    title: dialogPurchaseId > 0 ? i18n("Edit Purchase") : i18n("New Purchase")
    padding: Kirigami.Units.largeSpacing
    width: Kirigami.Units.gridUnit * 50
    height : Kirigami.Units.gridUnit * 30

    property int dialogPurchaseId: 0
    property bool isCreateAnother: false
    property bool isEditing: dialogPurchaseId > 0
    property var selectedProducts: []
    property var currentPurchase: null  // Add this property
    standardButtons: Kirigami.Dialog.NoButton
    property double remainingAmount: currentPurchase ? (currentPurchase.total_amount - currentPurchase.paid_amount) : 0
    DBusyIndicator {
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
    contentItem:   ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.TabBar {
            id: tabBar
            Layout.fillWidth: true

            QQC2.TabButton {
                text: i18n("Purchase Details")
            }
            QQC2.TabButton {
                text: i18n("Products")
            }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                RowLayout{
                    Layout.fillWidth: true
                    FormCard.FormCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        FormCard.FormComboBoxDelegate {
                            id: supplierField
                            text: i18n("Supplier")
                            model: supplierModel
                            textRole: "name"
                            valueRole: "id"
                            enabled: !isEditing
                        }

                        DSearchableComboBoxCashSource {
                             id: cashSourceField
                             model: cashSourceModel
                             textRole: "name"
                             valueRole: "id"
                             enabled: !isEditing
                         }
                        FormCard.FormDateTimeDelegate {
                            id: purchaseDateField
                            text: i18n("Purchase Date")
                            value: new Date()
                            dateTimeDisplay:FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                        }

                        FormCard.FormDateTimeDelegate {
                            id: dueDateField
                            dateTimeDisplay:FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                            text: i18n("Due Date")
                            value: new Date()
                        }

                    }

                    // Totals Section
                    FormCard.FormCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
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
                            label:  i18n("Discount")
                            from: 0
                            to: calculateSubtotal()
                            onValueChanged: calculateTotal()
                        }

                        FormCard.FormTextDelegate {
                            text: i18n("Total")
                            description: calculateTotal().toLocaleString(Qt.locale(), 'f', 2)
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


                }
            }


            // Items Section
            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing
                Layout.fillWidth: true
                Layout.fillHeight: true

                Kirigami.Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    //  width: parent.width
                    // Layout.preferredWidth : parent.width
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.largeSpacing
                        anchors.margins : Kirigami.Units.smallSpacing
                        Kirigami.Heading {
                            text: i18n("Sale Items")
                            Layout.fillWidth: true
                        }
                        RowLayout{
                            QQC2.Button {
                                text: i18n("Add Products")
                                icon.name: "list-add"
                                onClicked: productSelectorDialog.open()
                            }
                            DSearchableComboBox {
                                id: productComboBox
                                Layout.fillWidth: true

                                onItemSelected: function(item) {
                                    console.log("Selected product:", JSON.stringify(item))
                                    addOrUpdateProduct(item)
                                    // Handle selection with full product data
                                }

                                onEnterPressed: function(text) {
                                    productModelFetch.setSortField("barcode")
                                    productModelFetch.setSearchQuery(text)

                                    // Wait for the search to complete and select the item if found
                                    const searchTimer = Qt.createQmlObject('import QtQuick; Timer {interval: 300; repeat: false;}', productComboBox);
                                    searchTimer.triggered.connect(function() {
                                        if (productModelFetch.rowCount > 0) {
                                            // Get the first item's ID (assuming barcode is unique)
                                            const product = productModelFetch.getProduct(0)  // Get first item                                            console.log("productId : ",productId)
                                            // Call API to get full product details
                                            if (product && product.id) {
                                                productApiFetch.getProduct(product.id)
                                            }
                                        }
                                    });
                                    searchTimer.start()

                                    productModelFetch.setSortField("name") // Reset sort field after search
                                }
                            }



                        }
                        // Selected products list
                        ListView {
                            id: selectedProductsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
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
                                    spacing: Kirigami.Units.largeSpacing * 2

                                    QQC2.Label {
                                        text: i18n("Product")
                                        // Layout.fillWidth: true
                                        Layout.preferredWidth: parent.width * 0.15
                                        font.bold: true
                                    }

                                    QQC2.Label {
                                        text: i18n("Package")
                                        Layout.preferredWidth: parent.width * 0.13
                                        font.bold: true
                                    }
                                    QQC2.Label {
                                        text: i18n("Quantity")
                                        Layout.preferredWidth: parent.width * 0.13
                                        font.bold: true
                                    }
                                    QQC2.Label {
                                        id : headerPrice
                                        text: i18n("Price")
                                        Layout.preferredWidth: parent.width * 0.13
                                        font.bold: true
                                    }
                                    QQC2.Label {
                                        text: i18n("Tax Rate")
                                        Layout.preferredWidth: parent.width * 0.15
                                        font.bold: true
                                    }
                                    QQC2.Label {
                                        text: i18n("Total")
                                        Layout.preferredWidth: parent.width * 0.10
                                        font.bold: true
                                    }
                                    Item {
                                        Layout.preferredWidth: parent.width * 0.01
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
                                        Layout.preferredWidth:  Kirigami.Units.gridUnit  * 6
                                        elide: Text.ElideRight
                                    }

                                    QQC2.ComboBox {
                                        id: packageTypeCombo
                                        Layout.preferredWidth:  Kirigami.Units.gridUnit  * 6

                                        property var options: {
                                            let opts = [i18n("Piece (1)")]
                                            let packages = JSON.parse(selectedProductsModel.get(index).packagesJson || '[]')
                                            packages.forEach(pkg => {
                                                                 if (pkg && pkg.name) {
                                                                     opts.push(pkg.name+" ("+pkg.pieces_per_package+")")
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
                                                    selectedProductsModel.setProperty(index, "purchase_price", item.product.purchase_price)

                                                } else {
                                                    let pkg = packages[currentIndex - 1]
                                                    if (pkg) {
                                                        console.log("Selected package:", JSON.stringify(pkg))

                                                        selectedProductsModel.setProperty(index, "packageId", pkg.id)
                                                        selectedProductsModel.setProperty(index, "isPackage", true)
                                                        selectedProductsModel.setProperty(index, "piecesPerUnit", pkg.pieces_per_package || 1)
                                                        selectedProductsModel.setProperty(index, "unitPrice", pkg.selling_price || 0)
                                                        selectedProductsModel.setProperty(index, "purchase_price",  pkg.purchase_price ||0 )

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
                                        Layout.preferredWidth:  Kirigami.Units.gridUnit  * 5
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
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                        value: model.unitPrice
                                        from: 0
                                        to: 999999

                                        // Add warning color to the text when price is below purchase price
                                        contentItem: TextInput {
                                            text: parent.textFromValue(parent.value, parent.locale)
                                            font: parent.font
                                            color: {
                                                if (model.isPackage) {
                                                    let packagePurchasePrice = model.purchase_price // * model.piecesPerUnit
                                                    return parent.value < packagePurchasePrice ?
                                                                Kirigami.Theme.negativeTextColor :
                                                                Kirigami.Theme.textColor
                                                } else {
                                                    return parent.value < model.purchase_price ?
                                                                Kirigami.Theme.negativeTextColor :
                                                                Kirigami.Theme.textColor
                                                }
                                            }
                                            selectionColor: parent.palette.highlight
                                            selectedTextColor: parent.palette.highlightedText
                                            horizontalAlignment: Qt.AlignHCenter
                                            verticalAlignment: Qt.AlignVCenter
                                            readOnly: !parent.editable
                                            validator: parent.validator
                                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        }

                                        onValueModified: {
                                            selectedProductsModel.setProperty(index, "unitPrice", value)
                                            calculateItemTotal(index)
                                        }
                                    }


                                    QQC2.SpinBox {
                                        Layout.preferredWidth:  Kirigami.Units.gridUnit  * 5
                                        value: model.taxRate
                                        from: 0
                                        to: 100
                                        onValueModified: {
                                            selectedProductsModel.setProperty(index, "taxRate", value)
                                            calculateItemTotal(index)
                                        }
                                    }

                                    QQC2.Label {
                                        Layout.preferredWidth:  Kirigami.Units.gridUnit  * 4
                                        text: model.totalPrice.toLocaleString(Qt.locale(), 'f', 2)
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    QQC2.ToolButton {
                                        Layout.preferredWidth:  Kirigami.Units.gridUnit  * 2
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
            visible: !purchaseDialog.isEditing
            enabled: !purchaseModel.loading && validateForm()
            onTriggered: {
                isCreateAnother = true
                savePurchase()
            }
        },
        Kirigami.Action {
            text: i18n("Add Payment")
            icon.name: "money-management"
            visible: isEditing && currentPurchase?.payment_status !== "paid"
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
    function addOrUpdateProduct(product) {
        console.log("Adding product with packages:", JSON.stringify(product.packages));

        // Check if product exists
        for (let i = 0; i < selectedProductsModel.count; i++) {
            if (selectedProductsModel.get(i).productId === parseInt(product.id)) {
                return;
            }
        }

        // Ensure packages have IDs and required fields
        let processedPackages = (product.packages || []).map(pkg => ({
            id: pkg.id || null,  // Ensure ID exists
            name: pkg.name || "",
            pieces_per_package: pkg.pieces_per_package || 1,
            purchase_price: pkg.purchase_price || 0,
            selling_price: pkg.selling_price || 0,
            barcode: pkg.barcode || ""
        }));

        console.log("Processed packages:", JSON.stringify(processedPackages));

        let newProduct = {
            productId: parseInt(product.id),
            name: product.name,
            quantity: 1,
            unitPrice: parseFloat(product.purchase_price) || 0,
            originalUnitPrice: parseFloat(product.purchase_price) || 0,
            sellingPrice: parseFloat(product.price) || 0,
            originalSellingPrice: parseFloat(product.price) || 0,
            taxRate: 0,
            totalPrice: parseFloat(product.purchase_price) || 0,
            packagesJson: JSON.stringify(processedPackages),
            packageId: null,
            isPackage: false,
            piecesPerUnit: 1,
            totalPieces: 1,
            product: product  // Store the full product object
        };

        console.log("Adding new product:", JSON.stringify(newProduct));
        selectedProductsModel.append(newProduct);
        calculateItemTotal(selectedProductsModel.count - 1);
    }


    // Add this helper function to verify the model
    function debugModelItem(index) {
        let item = selectedProductsModel.get(index)
        console.log("Model item at index", index, ":", JSON.stringify({
            name: item.name,
            packagesJson: item.packagesJson,
            packages: JSON.parse(item.packagesJson || '[]')
        }))
    }    ProductSelectorDialog {
        id: productSelectorDialog
        onProductsSelected: function(products) {
            console.log("Received products in PurchaseDetails:", JSON.stringify(products))  // Add debug
            products.forEach(product => {
                                 addOrUpdateProduct(product);
                             });
        }
    }

    // Payment Dialog
    Kirigami.PromptDialog {
        id: paymentDialog
        title: i18n("Add Payment")
        standardButtons: Kirigami.Dialog.NoButton

        // Add property for reference number
        property string generatedReference: "PAY-" + Qt.formatDateTime(new Date(), "yyyyMMdd-hhmmss")

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

                // Optional: Add helper text showing remaining amount
                //description: i18n("Remaining amount: %1", remainingAmount.toLocaleString(Qt.locale(), 'f', 2))
            }

            FormCard.FormTextFieldDelegate {
                id: paymentReferenceField
                label: i18n("Reference Number")
                text: paymentDialog.generatedReference
                readOnly: true  // Make it read-only since it's auto-generated
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
                enabled: {
                    let amount = parseFloat(paymentAmountField.text) || 0
                    return amount > 0 &&
                    amount <= remainingAmount &&
                    paymentCashSourceField.currentValue != -1
                }
                onTriggered: {
                    purchaseModel.addPayment(dialogPurchaseId, {
                                                 cashSourceId: paymentCashSourceField.currentValue,
                                                 amount: parseFloat(paymentAmountField.text),
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

        // Reset fields when dialog is opened
        onOpened: {
            paymentCashSourceField.currentIndex = -1
            paymentAmountField.text = remainingAmount.toString()
            paymentMethodField.currentIndex = 0
            paymentNotesField.text = ""
            // Generate new reference number
            generatedReference = "PAY-" + Qt.formatDateTime(new Date(), "yyyyMMdd-hhmmss")
        }
    }

    // function calculateItemTotal(row) {
    //     let item = selectedProductsModel.get(row)
    //     let subtotal = item.quantity * item.unitPrice
    //     let tax = (subtotal * item.taxRate) / 100
    //     let total = subtotal + tax
    //     selectedProductsModel.setProperty(row, "totalPrice", total)
    //     return total
    // }
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

    // function savePurchase() {
    //     // let items = []
    //     // for (let i = 0; i < selectedProductsModel.count; i++) {
    //     //     let item = selectedProductsModel.get(i)
    //     //     items.push({
    //     //                    product_id: item.productId,
    //     //                    quantity: item.quantity,
    //     //                    unit_price: item.unitPrice,
    //     //                    tax_rate: item.taxRate || 0,
    //     //                    notes: ""
    //     //                })
    //     // }
    //     let items = []
    //     for (let i = 0; i < selectedProductsModel.count; i++) {
    //         let item = selectedProductsModel.get(i);
    //         let pkg = packageTypesModel.get(packageTypeCombo.currentIndex);

    //         items.push({
    //                        product_id: parseInt(item.productId),
    //                        package_id: pkg ? pkg.id : null,
    //                        is_package: pkg ? true : false,
    //                        quantity: parseInt(item.quantity),
    //                        unit_price: parseFloat(item.unitPrice),
    //                        tax_rate: parseFloat(item.taxRate) || 0,
    //                        notes: ""
    //                    });
    //     }
    //     let purchaseData = {
    //         supplier_id: supplierField.currentValue,
    //         cash_source_id: cashSourceField.currentValue,
    //         purchase_date: purchaseDateField.value.toISOString(),
    //         due_date: dueDateField.value.toISOString(),
    //         notes: notesField.text || "",
    //         items: items
    //     }

    //     if (isEditing) {
    //         purchaseModel.updatePurchase(dialogPurchaseId, purchaseData)
    //     } else {
    //         purchaseModel.createPurchase(purchaseData)
    //     }
    // }


    function savePurchase() {
        let items = [];
        for (let i = 0; i < selectedProductsModel.count; i++) {
            let item = selectedProductsModel.get(i);

            console.log("Processing item:", JSON.stringify(item));

            let isPackage = item.isPackage === true;
            let hasValidPackageId = item.packageId && parseInt(item.packageId) > 0;

            let itemData = {
                product_id: item.productId,
                quantity: item.quantity,
                unit_price: item.unitPrice,
                selling_price: item.sellingPrice,
                tax_rate: item.taxRate || 0,
                total_pieces: item.totalPieces,
                is_package: isPackage,
                package_id: hasValidPackageId ? parseInt(item.packageId) : null,
                notes: ""
            };

            if (isPackage && hasValidPackageId) {
                console.log("Processing as package item with ID:", item.packageId);
                itemData.update_package_prices = true;
                itemData.package_purchase_price = item.unitPrice;
                itemData.package_selling_price = item.sellingPrice;
                itemData.update_prices = false;
            } else {
                console.log("Processing as regular item");
                itemData.update_prices = true;
                itemData.update_package_prices = false;
                itemData.is_package = false;
                itemData.package_id = null;
            }

            console.log("Final item data:", JSON.stringify(itemData));
            items.push(itemData);
        }

        let purchaseData = {
            supplier_id: supplierField.currentValue,
            cash_source_id: cashSourceField.currentValue,
            purchase_date: purchaseDateField.value.toISOString(),
            due_date: dueDateField.value.toISOString(),
            notes: notesField.text || "",
            items: items
        };

        console.log("Final purchase data:", JSON.stringify(purchaseData, null, 2));

        if (isEditing) {
            purchaseModel.updatePurchase(dialogPurchaseId, purchaseData);
        } else {
            purchaseModel.createPurchase(purchaseData);
        }
    }







    function findModelIndex(model, id) {
        for (let i = 0; i < model.rowCount; i++) {
            if (model.data(model.index(i, 0), model.IdRole) === id) {
                return i;
            }
        }
        return -1;
    }
    function getProductName(productId) {
        console.log("Looking for product ID:", productId);

        for (let i = 0; i < productModel.rowCount; i++) {
            let index = productModel.index(i, 0);
            let id = productModel.data(index, Qt.UserRole + 1);  // IdRole
            let name = productModel.data(index, Qt.UserRole + 3); // NameRole

            console.log("Checking product:",
                        "ID =", id,
                        "Name =", name);

            if (id === productId) {
                console.log("Found product:", name);
                return name;
            }
        }
        console.log("Product not found");
        return "Unknown Product";
    }

    function loadData(purchase) {
        supplierField.currentIndex = findModelIndex(supplierModel, purchase.supplier_id);
        console.log("")
        cashSourceField.currentIndex = findModelIndex(cashSourceModel, purchase.cash_source_id);

        purchaseDateField.value = new Date(purchase.purchase_date)
        dueDateField.value = purchase.due_date ? new Date(purchase.due_date) : new Date()
        notesField.text = purchase.notes || ""

        selectedProductsModel.clear();
        purchase.items.forEach(item => {
                                   selectedProductsModel.append({
                                                                    productId: item.product_id,
                                                                    name: getProductName(item.product_id),
                                                                    quantity: item.quantity,
                                                                    unitPrice: item.unit_price,
                                                                    taxRate: item.tax_rate || 0,
                                                                    totalPrice: item.total_price,
                                                                    packageId: item.package_id || -1,
                                                                    piecesPerUnit: item.is_package ? item.pieces_per_package : 1,
                                                                    totalPieces: item.total_pieces,
                                                                    packages: item.product.packages || []
                                                                });
                               });
    }
    function updateRemainingAmount() {
        remainingAmount = currentPurchase ? (currentPurchase.total_amount - currentPurchase.paid_amount) : 0
    }

    function clearForm() {
        currentPurchase = null
        supplierField.currentIndex = 0
        cashSourceField.currentIndex = 0
        purchaseDateField.value = new Date()
        dueDateField.value = new Date()
        notesField.text = ""
        selectedProductsModel.clear()
        discountField.value = 0
    }

    Connections {
        target: purchaseApi
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

        function onPurchaseReceived(purchase) {
            currentPurchase = purchase  // Store the purchase data
            updateRemainingAmount()
            loadData(purchase)
        }
    }
    onDialogPurchaseIdChanged:{
        if (dialogPurchaseId > 0) {

            purchaseApi.getPurchase(dialogPurchaseId)
        }

    }
    Component.onCompleted: {
        supplierModel.setApi(supplierApi)
        cashSourceModel.setApi(cashSourceApi)

    }
}
