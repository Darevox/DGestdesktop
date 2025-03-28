// SaleDetails.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.dervox.printing 1.0

import "../../components"
import "."

Kirigami.Dialog {
    id: saleDialog
    title: dialogSaleId > 0 ? i18n("Edit %1", currentSale?.type) : i18n("New %1",typeCombo.currentText)
    //  preferredWidth: Kirigami.Units.gridUnit * 60
    padding: Kirigami.Units.largeSpacing
    width: Kirigami.Units.gridUnit * 50
    height : Kirigami.Units.gridUnit * 33
    property int dialogSaleId: 0
    property bool isCreateAnother: false
    property bool isEditing: dialogSaleId > 0
    property var selectedProducts: []
    property var currentSale: null
    standardButtons: Kirigami.Dialog.NoButton
    property double remainingAmount: 0
    // DBusyIndicator {
    //     id: busyIndicator
    //     anchors.centerIn: parent
    //     running: saleModel.loading
    //     visible: running
    //     z: 999
    // }

    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
    }
    Kirigami.InlineMessage {
        id: quoteInfoMessage
        text: i18n("Quotes don't affect inventory until converted to sales.")
        type: Kirigami.MessageType.Information
        visible: false
        Layout.fillWidth: true
    }
    contentItem:   ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        DBusyIndicator {
            id: busyIndicator
            anchors.centerIn: parent
            running: saleApi.isLoading
            visible: running
            z: 999
        }

        QQC2.TabBar {
            id: tabBar
            Layout.fillWidth: true
            visible:!saleApi.isLoading

            QQC2.TabButton {
                text: i18n("%1 Details",typeCombo.currentText)
            }
            QQC2.TabButton {
                text: i18n("Products")
            }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            visible:!saleApi.isLoading

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                RowLayout{
                    Layout.fillWidth: true

                    FormCard.FormCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        FormCard.FormCheckDelegate {
                            id: hasClientCheckbox
                            text: i18n("Assign to Client")
                            checked: false
                            enabled: !isEditing
                        }

                        // FormCard.FormComboBoxDelegate {
                        //     id: clientField
                        //     text: i18n("Client")
                        //     model: clientModel
                        //     textRole: "name"
                        //     valueRole: "id"
                        //     enabled: !isEditing && hasClientCheckbox.checked
                        //     visible: hasClientCheckbox.checked
                        // }
                        DSearchableComboBoxClient {
                            id: clientField
                            Layout.fillWidth: true
                            Layout.margins : Kirigami.Units.smallSpacing
                            enabled: !isEditing && hasClientCheckbox.checked
                            visible: hasClientCheckbox.checked
                            onItemSelected: function(item) {
                                console.log("Selected Client:", JSON.stringify(item))
                                // Handle selection with full product data
                            }

                            onEnterPressed: function(text) {
                            }
                        }
                        DSearchableComboBoxCashSource {
                            id: cashSourceField
                            Layout.fillWidth: true
                            Layout.margins : Kirigami.Units.smallSpacing
                            enabled: !isEditing
                            defaultSourceId: favoriteManager.getDefaultCashSource()
                            onItemSelected: function(item) {
                                console.log("Selected CashSoruce:", JSON.stringify(item))
                                // Handle selection with full product data
                            }

                            onEnterPressed: function(text) {
                            }
                        }
                        FormCard.FormComboBoxDelegate {
                            id: statusCombo
                            text: i18n("Status")
                            model: [
                                { text: i18n("Pending"), value: "pending" },
                                { text: i18n("Completed"), value: "completed" },
                                { text: i18n("Cancelled"), value: "cancelled" }

                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: 0
                        }
                        FormCard.FormComboBoxDelegate {
                            id: typeCombo
                            text: i18n("Type")
                            model: [
                                { text: i18n("Sale"), value: "sale" },
                                { text: i18n("Quote"), value: "quote" }
                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: 0
                            enabled: !isEditing // Can't change type after creation

                            onCurrentValueChanged: {
                                // Show info message when selecting quote
                                if (currentValue === "quote") {
                                    quoteInfoMessage.visible = true
                                } else {
                                    quoteInfoMessage.visible = false
                                }
                            }
                        }
                        // FormCard.FormComboBoxDelegate {
                        //     id: cashSourceField
                        //     text: i18n("Cash Source")
                        //     model: cashSourceModel
                        //     textRole: "name"
                        //     valueRole: "id"
                        //     enabled: !isEditing
                        // }

                        FormCard.FormDateTimeDelegate {
                            id: saleDateField
                            dateTimeDisplay:FormCard.FormDateTimeDelegate.DateTimeDisplay.Date

                            text: i18n("Sale Date")
                            value: new Date()
                        }

                        FormCard.FormDateTimeDelegate {
                            id: dueDateField
                            dateTimeDisplay:FormCard.FormDateTimeDelegate.DateTimeDisplay.Date

                            text: i18n("Due Date")
                            value: new Date()
                            enabled: hasClientCheckbox.checked
                            visible: hasClientCheckbox.checked
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
                            label: "Discount"
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
                                explanation: i18n("Click 'Add Products' to select products for this sale")
                                icon.name: "package"
                            }
                        }
                    }
                }

            }



        }
    }
    footerLeadingComponent : GridLayout{
        enabled:!saleApi.isLoading
        ColumnLayout {
            visible :  tabBar.currentIndex == 0
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Heading {
                text: i18n("Options")
                level: 3
                visible:isEditing
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                QQC2.Button {
                    text: i18n("Convert to Sale")
                    icon.name: "document-export"
                    visible: isEditing && currentSale?.type === "quote"
                    enabled: !saleApi.isLoading
                    onClicked: {
                        convertConfirmDialog.open()
                    }
                }
                QQC2.Button {
                    text: i18n("Generate %1 Document", currentSale?.type === "quote" ? "Quote":"Invoice")
                    icon.name: "document-print"
                    visible: isEditing
                    enabled: !saleModel.loading
                    onClicked: {
                        invoiceGenerationDialogLoader.documentId = dialogSaleId
                        invoiceGenerationDialogLoader.isQuote = currentSale?.type === "quote"
                        invoiceGenerationDialogLoader.active=true
                    }
                }

                QQC2.Button {
                    text: i18n("Print Receipt")
                    icon.name: "document-print"
                    visible:  isEditing && currentSale?.type === "sale"
                    enabled: !saleModel.loading
                    onClicked: saleApi.generateReceipt(dialogSaleId)
                }
                QQC2.Button {
                    text: i18n("Add Payment")
                    icon.name: "money-management"
                    visible: isEditing && currentSale?.payment_status !== "paid" &&  currentSale?.type === "sale"
                    enabled: !saleModel.loading
                    onClicked: paymentDialog.open()
                }

            }
        }
        RowLayout{
            visible :  tabBar.currentIndex == 1
            QQC2.Label {
                Layout.margins : Kirigami.Units.gridUnit

                text: i18n("Tax : ") +  calculateTotalTax().toLocaleString(Qt.locale(), 'f', 2)
                font.bold: true
            }
            QQC2.Label {
                Layout.margins : Kirigami.Units.gridUnit

                text: i18n("Total : ") + calculateTotal().toLocaleString(Qt.locale(), 'f', 2)
                font.bold: true
            }


        }
    }


    customFooterActions: [
        Kirigami.Action {
            text: isEditing ? i18n("Save Changes") : i18n("Create %1",typeCombo.currentText)
            icon.name: isEditing ? "document-save" : "list-add"
            enabled: !saleModel.loading //&& validateForm()
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
            FormCard.FormComboBoxDelegate {
                id: paymentMethodField
                text: i18n("Payment Method")
                model: [
                    { text: i18n("Cash"), value: "cash" },
                    { text: i18n("Bank Transfer"), value: "bank_transfer" },
                    { text: i18n("Credit Card"), value: "credit_card" },
                    { text: i18n("Debit Card"), value: "debit_card" },
                    { text: i18n("Check"), value: "check" },
                    { text: i18n("Online Payment"), value: "online_payment" },
                    { text: i18n("Other"), value: "other" }
                ]
                textRole: "text"
                valueRole: "value"
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
                                             paymentMethod: paymentMethodField.currentValue,
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
            quantity:  product.quantity > 0 ? 1 : 0,
            unitPrice: parseFloat(product.price) || 0,
            originalUnitPrice: parseFloat(product.price) || 0,
            maxQuantity: product.quantity || 0,
            purchase_price : product.purchase_price || 0,
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
        return (!hasClientCheckbox.checked || clientField.selectedId >= 0) &&
                cashSourceField.selectedId >= 0 &&
                selectedProductsModel.count > 0;
        // return true;
    }

    function findModelIndex(model, id) {
        for (let i = 0; i < model.rowCount; i++) {
            if (model.data(model.index(i, 0), model.IdRole) === id) {
                //  return i;
                return model.data(model.index(i, 0),  Qt.UserRole + 2)
            }
        }
        //return -1;
        return ""
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
            client_id: hasClientCheckbox.checked ? clientField.selectedId : null,
            cash_source_id: cashSourceField.selectedId,
            sale_date: saleDateField.value.toISOString(),
            due_date: hasClientCheckbox.checked ? dueDateField.value.toISOString() : null,
            status: statusCombo.currentValue || statusCombo.currentText,
            notes: notesField.text || "",
            type: !isEditing ? typeCombo.currentValue : undefined, // Only include type when creating new
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
        clientField.selectedId = -1;
        clientField.editText=""
        cashSourceField.selectedId = -1;
        cashSourceField.editText=""
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
            clientField.editText = findModelIndex(clientModel, sale.client_id);
        }

        // Update cash source field using findModelIndex
        cashSourceField.editText = findModelIndex(cashSourceModel, sale.cash_source_id);

        // Update other fields
        saleDateField.value = new Date(sale.sale_date);
        if (sale.due_date) {
            dueDateField.value = new Date(sale.due_date);
        }
        notesField.text = sale.notes || "";
        discountField.value = sale.discount_amount || 0;

        // Set status
        let statusIndex = statusCombo.model.findIndex(item => item.value === sale.status)
        statusCombo.currentIndex = statusIndex !== -1 ? statusIndex : 0

        // Set document type
        if (sale.type) {
            let typeIndex = typeCombo.model.findIndex(item => item.value === sale.type)
            typeCombo.currentIndex = typeIndex !== -1 ? typeIndex : 0

            // Show the quote info message if it's a quote
            quoteInfoMessage.visible = sale.type === "quote"
        } else {
            // Default to sale for backward compatibility
            typeCombo.currentIndex = 0
            quoteInfoMessage.visible = false
        }

        // Clear and reload items
        selectedProductsModel.clear();
        sale.items.forEach(item => {
                               selectedProductsModel.append({
                                                                productId: item.product_id,
                                                                name: item.product.name,
                                                                quantity: item.quantity,
                                                                maxQuantity: item.product.quantity + item.quantity,
                                                                unitPrice: item.unit_price,
                                                                originalUnitPrice: item.unit_price,
                                                                taxRate: item.tax_rate || 0,
                                                                totalPrice: item.total_price,
                                                                purchase_price: item.product.purchase_price || 0,
                                                                packagesJson: JSON.stringify(item.product.packages || []),
                                                                packageId: item.package_id || null,
                                                                isPackage: item.is_package === true,
                                                                piecesPerUnit: item.is_package ? (item.total_pieces / item.quantity) : 1,
                                                                totalPieces: item.total_pieces || item.quantity,
                                                                product: item.product || {}
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
            saleModel.refresh()
        }

        function onSaleUpdated() {
            saleDialog.close()
            saleModel.refresh()
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
        function onReceiptGenerated(pdfUrl) {
            printerHelper.printPdfWithPreview(pdfUrl)
        }
        function onErrorReceiptGenerated(title, message) {
            applicationWindow().showPassiveNotification(
                        i18n("Receipt generation failed: %1", message),
                        "long"
                        )
        }
    }
    Kirigami.PromptDialog {
        id: convertConfirmDialog
        title: i18n("Convert Quote to Sale")
        subtitle: i18n("This will convert the quote to a sale and reduce product inventory. Are you sure?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            saleModel.convertToSale(dialogSaleId)
        }
    }

    // Add a connection for the conversion response
    Connections {
        target: saleModel
        function onSaleConverted(id) {
            if (id === dialogSaleId) {
                // Update the current sale to reflect it's now a sale
                if (currentSale) {
                    currentSale.type = "sale"
                }

                // Show success message
                inlineMsg.type = Kirigami.MessageType.Positive
                inlineMsg.text = i18n("Quote successfully converted to sale")
                inlineMsg.visible = true

                // Optionally close the dialog
                // saleDialog.close()
                saleModel.refresh()
            }
        }

        function onSaleConversionError(error) {
            inlineMsg.type = Kirigami.MessageType.Error
            inlineMsg.text = i18n("Failed to convert quote: %1", error)
            inlineMsg.visible = true
            saleModel.refresh()
        }
    }
    onDialogSaleIdChanged: {
        if (dialogSaleId > 0) {
            saleApi.getSale(dialogSaleId)
        }
    }
    PrinterHelper{
        id:printerHelper

    }
    Loader {
        id: invoiceGenerationDialogLoader
        active: false
        property int documentId: -1
        property bool isQuote: false

        sourceComponent: InvoiceGenerationDialog {
            id: generationDialog
            isQuote: invoiceGenerationDialogLoader.isQuote
            documentId: invoiceGenerationDialogLoader.documentId

            onClosed: {
                invoiceGenerationDialogLoader.active = false
            }
        }

        onLoaded: {
            item.open()
        }
    }


    Component.onCompleted: {
        clientModel.setApi(clientApi)
        cashSourceModel.setApi(cashSourceApi)
    }
}
