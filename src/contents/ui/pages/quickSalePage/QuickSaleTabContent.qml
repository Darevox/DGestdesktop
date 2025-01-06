// QuickSaleTabContent.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.dervox.printing 1.0

//import com.dervox.FavoriteManager
import com.dervox.ProductFetchApi
import "."
import "../../components"

Item {
    id: root

    // Properties
    property var saleState: null
    property var sharedLoadedProducts
    property var sharedCurrentProductIds
    property bool isLoadingProducts
    property int selectedClientId: -1
    property int selectedCashSourceId: favoriteManager.getDefaultCashSource()
    property double discountAmount: 0
    property string saleNotes: ""
    // Signals
    signal categoryChanged(int categoryId)

    // Computed properties
    readonly property var saleItems: saleState ? saleState.saleItems : null
    property double total: 0  // Remove readonly and initialize to 0
    readonly property bool autoPayment: saleState ? saleState.autoPayment : false
    Connections {
        target: saleItems
        function onCountChanged() {
            updateTotal()
        }
        function onDataChanged() {
            updateTotal()
        }
    }

    // Update total when saleState changes
    onSaleStateChanged: {
        if (saleState && saleState.saleItems) {
            updateTotal()
        }
    }
    function setAutoPayment(value) {
        if (saleState) {
            saleState.autoPayment = value
        }
    }
    Component.onCompleted: {
        updateTotal()
    }
    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // Left side: Products and favorites
        ColumnLayout {
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6
            Layout.fillHeight: true

            // Favorite categories
            QQC2.TabBar {
                id: categoryBar
                Layout.fillWidth: true
                clip:true
                Repeater {
                    model: favoriteManager.getCategories()
                    QQC2.TabButton {
                        text: modelData.name
                        width: Math.max(100, categoryBar.width / categoryBar.count)
                    }
                }

                onCurrentIndexChanged: {
                    root.categoryChanged(currentIndex + 1)
                }
            }

            // Shared favorites grid
            SharedFavoritesGrid {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 8
                loadedProducts: root.sharedLoadedProducts
                currentProductIds: root.sharedCurrentProductIds
                isLoading: root.isLoadingProducts
                onProductClicked: function(product) {
                    addProductToSale(product)
                }
            }

            // Product search
            DSearchableComboBox {
                Layout.fillWidth: true
                onItemSelected: function(item) {
                    console.log("Processing package:", JSON.stringify(item.packages))


                    addProductToSale(item)
                }
            }

            // Sale items list
            ListView {
                id : saleItemslist
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: saleItems
                clip: true
                property  var packageTypeComboItem: null
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
                    width: ListView.view.width
                    height: 50
                    color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.largeSpacing

                        QQC2.Label {
                            text: model.name
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            elide: Text.ElideRight
                        }

                        QQC2.ComboBox {
                            id: packageTypeCombo
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                            // Initialize with piece option
                            model: [i18n("Piece (1)")]

                            Component.onCompleted: {
                                updatePackageOptions()
                            }

                            function updatePackageOptions() {
                                try {
                                    let opts = [i18n("Piece (1)")]
                                    if (saleItems && index >= 0) {
                                        let item = saleItems.get(index)
                                        if (item && item.packagesJson) {
                                            let packages = JSON.parse(item.packagesJson)
                                            packages.forEach(pkg => {
                                                                 if (pkg && pkg.name) {
                                                                     opts.push(pkg.name + " (" + pkg.pieces_per_package + ")")
                                                                 }
                                                             })
                                        }
                                    }
                                    model = opts
                                } catch (e) {
                                    console.error("Error updating package options:", e)
                                }
                            }

                            // Update options when data changes
                            Connections {
                                target: saleItems
                                function onDataChanged() {
                                    packageTypeCombo.updatePackageOptions()
                                }
                            }

                            onCurrentIndexChanged: {
                                if (currentIndex < 0 || !saleItems) return

                                try {
                                    let item = saleItems.get(index)
                                    if (!item) return

                                    if (currentIndex === 0) {
                                        // Piece mode
                                        saleItems.setProperty(index, "packageId", -1)
                                        saleItems.setProperty(index, "isPackage", false)
                                        saleItems.setProperty(index, "piecesPerUnit", 1)
                                        saleItems.setProperty(index, "unitPrice", item.originalUnitPrice)
                                        updateItemQuantity(index, item.quantity)
                                    } else {
                                        // Package mode
                                        let packages = JSON.parse(item.packagesJson || '[]')
                                        let pkg = packages[currentIndex - 1]
                                        if (pkg) {
                                            saleItems.setProperty(index, "packageId", pkg.id)
                                            saleItems.setProperty(index, "isPackage", true)
                                            saleItems.setProperty(index, "piecesPerUnit", pkg.pieces_per_package || 1)
                                            saleItems.setProperty(index, "unitPrice", pkg.selling_price || 0)

                                            let productData = JSON.parse(item.productData)
                                            let maxPackages = Math.floor(productData.quantity / pkg.pieces_per_package)
                                            saleItems.setProperty(index, "maxQuantity", maxPackages)

                                            updateItemQuantity(index, item.quantity)
                                        }
                                    }
                                } catch (e) {
                                    console.error("Error in package selection:", e)
                                }
                            }
                        }


                        // QQC2.ComboBox {
                        //     id: packageTypeCombo
                        //     Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                        //     property var options: {
                        //         let opts = [i18n("Piece (1)")]
                        //         let packages = model.packages || []
                        //         packages.forEach(pkg => {
                        //                              if (pkg && pkg.name) {
                        //                                  opts.push(pkg.name + " (" + pkg.pieces_per_package + ")")
                        //                              }
                        //                          })
                        //         return opts
                        //     }

                        //     model: options

                        //     onCurrentIndexChanged: {
                        //         if (currentIndex >= 0) {
                        //             if (currentIndex === 0) {
                        //                 saleItems.setProperty(index, "packageId", null)
                        //                 saleItems.setProperty(index, "isPackage", false)
                        //                 saleItems.setProperty(index, "piecesPerUnit", 1)
                        //                 saleItems.setProperty(index, "price", model.originalPrice)
                        //                 updateItemQuantity(index, model.quantity)
                        //             } else {
                        //                 let pkg = model.packages[currentIndex - 1]
                        //                 if (pkg) {
                        //                     saleItems.setProperty(index, "packageId", pkg.id)
                        //                     saleItems.setProperty(index, "isPackage", true)
                        //                     saleItems.setProperty(index, "piecesPerUnit", pkg.pieces_per_package)
                        //                     saleItems.setProperty(index, "price", pkg.selling_price)
                        //                     updateItemQuantity(index, model.quantity)
                        //                 }
                        //             }
                        //         }
                        //     }
                        // }

                        // QQC2.SpinBox {
                        //     Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        //     value: model.quantity
                        //     from: 1
                        //     to: model.maxQuantity || 999999
                        //     editable: true
                        //     onValueChanged: updateItemQuantity(index, value)
                        // }
                        QQC2.SpinBox {
                            id:quantitySpinBox
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            value: model.quantity
                            from: 1
                            to: model.maxQuantity || 999999
                            editable: true

                            contentItem: TextInput {
                                text: parent.textFromValue(parent.value, parent.locale)
                                font: parent.font
                                color: parent.value >= model.maxQuantity ?
                                           Kirigami.Theme.negativeTextColor :
                                           Kirigami.Theme.textColor
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        parent.forceActiveFocus()
                                        numPad.setNormalMode()
                                        numPad.setActiveInput({
                                                                  value: quantitySpinBox.value,
                                                                  name: i18n("Quantity"), // Add name
                                                                  from: quantitySpinBox.from,
                                                                  to: quantitySpinBox.to,
                                                                  setValue: function(newValue) {
                                                                      quantitySpinBox.value = newValue
                                                                      updateItemQuantity(index, newValue)

                                                                  }
                                                              })
                                    }
                                }
                                Connections {
                                    target: quantitySpinBox
                                    function onValueModified() {
                                        numPad.setActiveInput({
                                                                  value: quantitySpinBox.value,
                                                                  name: i18n("Quantity"), // Add name
                                                                  from: quantitySpinBox.from,
                                                                  to: quantitySpinBox.to
                                                              })
                                    }
                                }

                            }

                            onValueModified: {
                                if (value > model.maxQuantity) {
                                    value = model.maxQuantity
                                    applicationWindow().showPassiveNotification(
                                                i18n("Maximum quantity reached"),
                                                "short"
                                                )
                                }
                                updateItemQuantity(index, value)
                            }
                        }

                        QQC2.SpinBox {
                            id:unitPriceSpinBox
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            value: model.unitPrice  // Changed from price to unitPrice
                            from: 0
                            to: 999999
                            editable: true

                            contentItem: TextInput {
                                text: parent.textFromValue(parent.value, parent.locale)
                                font: parent.font
                                color: {
                                    if (model.isPackage) {
                                        return parent.value < model.purchase_price ?
                                                    Kirigami.Theme.negativeTextColor :
                                                    Kirigami.Theme.textColor
                                    } else {
                                        return parent.value < model.purchase_price ?
                                                    Kirigami.Theme.negativeTextColor :
                                                    Kirigami.Theme.textColor
                                    }
                                }
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        parent.forceActiveFocus()
                                        numPad.setNormalMode()
                                        numPad.setActiveInput({
                                                                  value: unitPriceSpinBox.value,
                                                                  name: i18n("Price"), // Add name
                                                                  from: unitPriceSpinBox.from,
                                                                  to: unitPriceSpinBox.to,
                                                                  setValue: function(newValue) {
                                                                      unitPriceSpinBox.value = newValue
                                                                      saleItems.setProperty(index, "unitPrice", newValue)
                                                                      updateTotal()
                                                                  }
                                                              })
                                    }
                                }
                                Connections {
                                    target: unitPriceSpinBox
                                    function onValueModified() {
                                        numPad.setActiveInput({
                                                                  value: unitPriceSpinBox.value,
                                                                  name: i18n("Price"), // Add name
                                                                  from: unitPriceSpinBox.from,
                                                                  to: unitPriceSpinBox.to
                                                              })
                                    }
                                }



                            }

                            onValueModified: {
                                saleItems.setProperty(index, "unitPrice", value)  // Changed from price to unitPrice
                                updateTotal()
                            }


                        }

                        QQC2.SpinBox {
                            id:taxRateSpinBox
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            value: model.taxRate || 0
                            from: 0
                            to: 100
                            onValueModified: {
                                saleItems.setProperty(index, "taxRate", value)
                                updateTotal()
                            }
                            contentItem: TextInput {
                                text: parent.textFromValue(parent.value, parent.locale)
                                font: parent.font
                                color: Kirigami.Theme.textColor
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        parent.forceActiveFocus()
                                        numPad.setNormalMode()
                                        numPad.setActiveInput({
                                                                  value: taxRateSpinBox.value,
                                                                  name: i18n("tax Rate"), // Add name
                                                                  from: taxRateSpinBox.from,
                                                                  to: taxRateSpinBox.to,
                                                                  setValue: function(newValue) {
                                                                      taxRateSpinBox.value = newValue
                                                                      saleItems.setProperty(index, "taxRate", newValue)
                                                                      updateTotal()
                                                                  }
                                                              })
                                    }
                                }
                                Connections {
                                    target: taxRateSpinBox
                                    function onValueModified() {
                                        numPad.setActiveInput({
                                                                  value: taxRateSpinBox.value,
                                                                  name: i18n("tax Rate"), // Add name
                                                                  from: taxRateSpinBox.from,
                                                                  to: taxRateSpinBox.to
                                                              })
                                    }
                                }



                            }
                        }

                        QQC2.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                            text: ((model.unitPrice * model.quantity) * (1 + model.taxRate/100)).toLocaleString(Qt.locale(), 'f', 2)
                            horizontalAlignment: Text.AlignRight
                        }


                        QQC2.ToolButton {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                            icon.name: "list-remove"
                            onClicked: saleItems.remove(index)
                        }
                    }
                }

                // Empty state message
                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - (Kirigami.Units.largeSpacing * 4)
                    visible: saleItems.count === 0
                    text: i18n("No products added")
                    explanation: i18n("Search products above to add them to the sale")
                    icon.name: "package"
                }
            }
        }

        // Right side: Numpad and totals
        ColumnLayout {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
            Layout.fillHeight: true
            Kirigami.Card {
                Layout.fillWidth: true

                contentItem: ColumnLayout {
                    // Client Selection
                    // RowLayout {
                    Layout.margins : Kirigami.Units.smallSpacing
                    RowLayout{
                        QQC2.CheckBox {
                            id: hasClientCheckbox
                            text: i18n("Assign to Client")
                        }
                        Item{
                            Layout.fillWidth:true
                        }
                        QQC2.ToolButton{
                            icon.name: "settings-configure"
                            onClicked:saleSettingsDialog.open()

                        }
                    }
                    DSearchableComboBoxClient {
                        Layout.fillWidth: true
                        enabled: hasClientCheckbox.checked
                        visible: hasClientCheckbox.checked
                        onItemSelected: function(client) {
                            selectedClientId = client.id
                        }
                    }
                    //  }

                    // Cash Source Selection
                    DSearchableComboBoxCashSource {
                        Layout.fillWidth: true
                        visible:false

                        defaultSourceId: favoriteManager.getDefaultCashSource()  // Add this property
                        onItemSelected: function(source) {
                            selectedCashSourceId = source.id
                        }
                    }

                    // Notes Field
                    QQC2.TextArea {
                        Layout.fillWidth: true
                        visible:false
                        placeholderText: i18n("Sale Notes")
                        onTextChanged: saleNotes = text
                    }

                    // Discount Field
                    RowLayout {
                        Layout.fillWidth: true
                        QQC2.Label {
                            text: i18n("Discount:")
                        }
                        QQC2.SpinBox {
                            id:discountAmountSpinBox
                            Layout.fillWidth: true
                            from: 0
                            to: total
                            value: discountAmount
                            onValueChanged: {
                                discountAmount = value
                                updateTotal()
                            }
                            contentItem: TextInput {
                                text: parent.textFromValue(parent.value, parent.locale)
                                font: parent.font
                                color: Kirigami.Theme.textColor
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        parent.forceActiveFocus()
                                        numPad.setNormalMode()
                                        numPad.setActiveInput({
                                                                  value: discountAmountSpinBox.value,
                                                                  name: i18n("Discount"), // Add name
                                                                  from: discountAmountSpinBox.from,
                                                                  to: discountAmountSpinBox.to,
                                                                  setValue: function(newValue) {
                                                                      discountAmountSpinBox.value = newValue
                                                                      discountAmount = newValue
                                                                      updateTotal()
                                                                  }
                                                              })
                                    }
                                }
                                Connections {
                                    target: discountAmountSpinBox
                                    function onValueModified() {
                                        numPad.setActiveInput({
                                                                  value: discountAmountSpinBox.value,
                                                                  name: i18n("Discount"), // Add name
                                                                  from: discountAmountSpinBox.from,
                                                                  to: discountAmountSpinBox.to
                                                              })
                                    }
                                }

                            }

                        }
                    }
                }
            }
            // Totals card
            Kirigami.Card {
                Layout.fillWidth: true

                contentItem: ColumnLayout {
                    Layout.margins : Kirigami.Units.smallSpacing
                    RowLayout {
                        QQC2.Label {
                            text: i18n("Subtotal: %1", calculateSubtotal().toFixed(2))
                            font.pointSize: 14
                        }
                        Item{
                            Layout.fillWidth : true
                        }

                        QQC2.Label {
                            text: i18n("Tax: %1", calculateTotalTax().toFixed(2))
                            font.pointSize: 14
                               color: Kirigami.Theme.neutralTextColor
                        }

                    }
                    QQC2.Label {
                        text: i18n("Discount: %1", discountAmount.toFixed(2))
                        font.pointSize: 14
                        //visible: discountAmount > 0


                    }
                    QQC2.Label {
                        text: i18n("Total: %1", total.toFixed(2))
                        font.pointSize: 16
                        font.bold: true
                        color: Kirigami.Theme.positiveTextColor
                    }
                }

            }
            Kirigami.Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentItem: ColumnLayout{
                    // Enhanced NumPad
                    Layout.margins : Kirigami.Units.smallSpacing
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins : Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing
                        Item{
                            Layout.fillWidth: true

                        }
                        QQC2.Button {
                            text: i18n("Normal")
                            checkable: true
                            checked: numPad.mode === "normal"
                            onClicked: {
                                numPad.setNormalMode()
                            }
                        }
                        QQC2.Button {
                            text: i18n("Payment")
                            checkable: true
                            checked: numPad.mode === "payment"
                            onClicked: {
                                numPad.setPaymentMode(total)
                            }
                        }
                        Item{
                            Layout.fillWidth: true

                        }
                    }

                    NumPad {
                        id: numPad
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        mode: "normal"
                        target: total  // For payment mode calculations

                        onNumberEntered: function(number) {
                            if (mode === "payment") {
                                // Handle payment input
                                let amount = parseFloat(number) || 0
                                if (amount >= total) {
                                    // Enable complete sale button
                                    completeSaleButton.enabled = true
                                }
                            }
                        }

                        onEnterPressed: {
                            // if (mode === "payment") {
                            //     if (numPad.amountTendered >= total) {
                            completeSale()
                            //     }
                            //  }
                        }

                        onQuickAmountSelected: function(amount) {
                            if (mode === "payment") {
                                if (amount >= total) {
                                    completeSaleButton.enabled = true
                                }
                            }
                        }
                    }

                    // Mode selection buttons

                    // Complete sale button
                    // QQC2.Button {
                    //     id: completeSaleButton
                    //     Layout.fillWidth: true
                    //     text: i18n("Complete Sale")
                    //     icon.name: "dialog-ok-apply"
                    //     //   enabled: numPad.mode !== "payment" || numPad.amountTendered >= total
                    //     onClicked: completeSale()
                    // }


                }
            }


        }
    }

    // Functions

    // function addProductToSale(product) {
    //     if (!saleState || !saleState.saleItems) return

    //     // Check existing items
    //     for (let i = 0; i < saleState.saleItems.count; i++) {
    //         let existingItem = saleState.saleItems.get(i)
    //         if (existingItem.id === product.id) {
    //             // Check if we can add one more
    //             if (existingItem.quantity < existingItem.maxQuantity) {
    //                 let newQuantity = existingItem.quantity + 1
    //                 saleState.saleItems.setProperty(i, "quantity", newQuantity)
    //                 updateTotal()
    //             } else {
    //                 // Optional: Show a message that max quantity is reached
    //                 applicationWindow().showPassiveNotification(
    //                     i18n("Maximum quantity reached for %1", product.name),
    //                     "short"
    //                 )
    //             }
    //             return
    //         }
    //     }

    //     // Add new item
    //     saleState.saleItems.append({
    //         id: product.id,
    //         name: product.name,
    //         price: product.price,
    //         originalPrice: product.price,
    //         quantity: 1,
    //         maxQuantity: product.quantity,
    //         purchase_price: product.purchase_price,
    //         packages: product.packages || [],
    //         packageId: null,
    //         isPackage: false,
    //         piecesPerUnit: 1,
    //         taxRate: 0,
    //         totalPieces: 1
    //     })
    //     updateTotal()
    // }

    function addProductToSale(product) {
        if (!saleState || !saleState.saleItems) return
        for (let i = 0; i < saleState.saleItems.count; i++) {
            let existingItem = saleState.saleItems.get(i)
            if (existingItem.id === product.id) {
                // Check if we can add one more
                if (existingItem.quantity < existingItem.maxQuantity) {
                    let newQuantity = existingItem.quantity + 1
                    saleState.saleItems.setProperty(i, "quantity", newQuantity)
                    updateTotal()
                } else {
                    // Optional: Show a message that max quantity is reached
                    applicationWindow().showPassiveNotification(
                                i18n("Maximum quantity reached for %1", product.name),
                                "short"
                                )
                }
                return
            }
        }
        // Process packages
        let packagesJson = JSON.stringify(product.packages || [])

        let newItem = {
            id: product.id,
            name: product.name,
            unitPrice: product.price,
            originalUnitPrice: product.price,
            quantity: 1,
            maxQuantity: product.quantity,
            purchase_price: product.purchase_price,
            packagesJson: packagesJson,
            packageId: -1,
            isPackage: false,
            piecesPerUnit: 1,
            taxRate: 0,
            totalPieces: 1,
            productData: JSON.stringify(product)
        }

        saleState.saleItems.append(newItem)
        updateTotal()
    }



    function updateItemQuantity(index, quantity) {
        if (!saleState || !saleState.saleItems) return

        let item = saleState.saleItems.get(index)
        if (!item) return

        // Ensure quantity doesn't exceed maxQuantity
        let validQuantity = Math.min(quantity, item.maxQuantity)
        validQuantity = Math.max(1, validQuantity) // Ensure minimum is 1

        // Only update if the quantity is different and valid
        if (validQuantity !== item.quantity) {
            saleState.saleItems.setProperty(index, "quantity", validQuantity)

            // Update the total pieces if using packages
            let totalPieces = validQuantity * item.piecesPerUnit
            saleState.saleItems.setProperty(index, "totalPieces", totalPieces)

            updateTotal()
        }
    }

    function calculateSubtotal() {
        if (!saleState || !saleState.saleItems) return 0
        let subtotal = 0
        for (let i = 0; i < saleState.saleItems.count; i++) {
            let item = saleState.saleItems.get(i)
            subtotal += item.unitPrice * item.quantity  // Changed from price to unitPrice
        }
        return subtotal
    }

    function calculateTotalTax() {
        if (!saleState || !saleState.saleItems) return 0
        let totalTax = 0
        for (let i = 0; i < saleState.saleItems.count; i++) {
            let item = saleState.saleItems.get(i)
            let subtotal = item.unitPrice * item.quantity  // Changed from price to unitPrice
            totalTax += (subtotal * item.taxRate) / 100
        }
        return totalTax
    }

    function updateTotal() {
        let newTotal = calculateSubtotal() + calculateTotalTax() - discountAmount
        total = newTotal

        if (numPad.mode === "payment") {
            numPad.target = newTotal
            numPad.changeAmount = numPad.amountTendered - newTotal
        }
    }



    function completeSale() {
        if (!saleState || !saleState.saleItems || saleState.saleItems.count === 0) return

        let items = []
        for (let i = 0; i < saleState.saleItems.count; i++) {
            let item = saleState.saleItems.get(i)
            items.push({
                           product_id: item.id,
                           quantity: item.quantity,
                           unit_price: item.unitPrice,
                           tax_rate: item.taxRate,
                           total_pieces: item.quantity * item.piecesPerUnit,
                           is_package: item.isPackage,
                           package_id: item.packageId,
                           notes: ""
                       })
        }

        // Calculate final total
        let finalTotal = total - discountAmount
        let shouldProcessPayment = saleState.autoPayment || numPad.mode === "payment"
        let paymentAmount = shouldProcessPayment ?
                (numPad.mode === "payment" ? numPad.amountTendered : finalTotal) : 0
        let saleData = {
            client_id: hasClientCheckbox.checked ? selectedClientId : null,
            cash_source_id: selectedCashSourceId,
            sale_date: new Date().toISOString(),
            due_date: hasClientCheckbox.checked ? new Date().toISOString() : null,
            notes: saleNotes,
            discount_amount: discountAmount,
            total_amount: finalTotal,
            tax_amount: calculateTotalTax(),
            items: items,
            auto_payment: shouldProcessPayment,
            payment_amount: paymentAmount
        }

        // Create the sale
        saleModel.createSale(saleData)

        // Show success animation
        saleCompletedAnimation.start()

        // Clear sale after animation
        saleCompletedAnimation.finished.connect(() => {
                                                    // Clear sale items
                                                    saleState.saleItems.clear()
                                                    saleState.total = 0

                                                    // Reset all form fields
                                                    selectedClientId = -1
                                                    selectedCashSourceId = 1
                                                    saleNotes = ""
                                                    discountAmount = 0
                                                    hasClientCheckbox.checked = false

                                                    // Reset payment related fields
                                                    numPad.reset()
                                                    numPad.mode = "normal"

                                                    // Reset auto payment
                                                    saleState.autoPayment = false
                                                })
    }

    ParallelAnimation {
        id: saleCompletedAnimation

        PropertyAnimation {
            target: successOverlay
            property: "opacity"
            from: 0.8
            to: 0
            duration: 1000
        }

        PropertyAnimation {
            target: successIcon
            property: "scale"
            from: 0
            to: 2
            duration: 500
        }

        PropertyAnimation {
            target: successIcon
            property: "opacity"
            from: 1
            to: 0
            duration: 1000
        }
    }
    // Add success overlay
    Rectangle {
        id: successOverlay
        anchors.fill: parent
        color: Kirigami.Theme.positiveBackgroundColor
        opacity: 0
        visible: opacity > 0

        Kirigami.Icon {
            id: successIcon
            anchors.centerIn: parent
            source: "dialog-ok"
            width: Kirigami.Units.iconSizes.huge
            height: width
            scale: 0
            color: Kirigami.Theme.positiveTextColor
        }

        QQC2.Label {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Kirigami.Units.gridUnit * 2
            text: i18n("Sale Completed!")
            color: Kirigami.Theme.positiveTextColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
            opacity: successOverlay.opacity
        }
    }
    Connections {
        target: saleApi

        function onSaleMapCreated(sale) {
            // Now sale is a JavaScript object with properties
            if (printReceiptCheckBox.checked) {
                saleApi.generateReceipt(sale.id)

            }
        }
        function onReceiptGenerated(pdfUrl) {
            printerHelper.printPdf(pdfUrl)
        }
        function onErrorReceiptGenerated(title, message) {
            applicationWindow().showPassiveNotification(
                        i18n("Receipt generation failed: %1", message),
                        "long"
                        )
        }
    }
    Kirigami.Dialog {
        id: saleSettingsDialog
        title: i18n("Sale Settings")
        width : Kirigami.Units.gridUnit * 20
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        FormCard.FormCard {
            FormCard.FormSwitchDelegate {
                text: i18n("Auto Payment")
                checked: root.autoPayment
                onCheckedChanged: root.setAutoPayment(checked)
            }
            FormCard.FormSwitchDelegate {
                id:printReceiptCheckBox
                text: i18n("Print Receipt")

            }
            FormCard.FormSwitchDelegate {
                text: i18n("Make Sale Completed")
            }
        }

        onAccepted: {

        }

        onOpened: {

        }
    }

    PrinterHelper{
        id:printerHelper

    }
}
