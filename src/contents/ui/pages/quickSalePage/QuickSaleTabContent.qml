// QuickSaleTabContent.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
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
                    addProductToSale(item)
                }
            }

            // Sale items list
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: saleItems
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

                            property var options: {
                                let opts = [i18n("Piece (1)")]
                                let packages = model.packages || []
                                packages.forEach(pkg => {
                                                     if (pkg && pkg.name) {
                                                         opts.push(pkg.name + " (" + pkg.pieces_per_package + ")")
                                                     }
                                                 })
                                return opts
                            }

                            model: options

                            onCurrentIndexChanged: {
                                if (currentIndex >= 0) {
                                    if (currentIndex === 0) {
                                        saleItems.setProperty(index, "packageId", null)
                                        saleItems.setProperty(index, "isPackage", false)
                                        saleItems.setProperty(index, "piecesPerUnit", 1)
                                        saleItems.setProperty(index, "price", model.originalPrice)
                                        updateItemQuantity(index, model.quantity)
                                    } else {
                                        let pkg = model.packages[currentIndex - 1]
                                        if (pkg) {
                                            saleItems.setProperty(index, "packageId", pkg.id)
                                            saleItems.setProperty(index, "isPackage", true)
                                            saleItems.setProperty(index, "piecesPerUnit", pkg.pieces_per_package)
                                            saleItems.setProperty(index, "price", pkg.selling_price)
                                            updateItemQuantity(index, model.quantity)
                                        }
                                    }
                                }
                            }
                        }

                        QQC2.SpinBox {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            value: model.quantity
                            from: 1
                            to: model.maxQuantity || 999999
                            editable: true
                            onValueChanged: updateItemQuantity(index, value)
                        }

                        QQC2.SpinBox {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            value: model.price
                            from: 0
                            to: 999999
                            editable: true

                            contentItem: TextInput {
                                text: parent.textFromValue(parent.value, parent.locale)
                                font: parent.font
                                color: parent.value < model.purchase_price ?
                                           Kirigami.Theme.negativeTextColor :
                                           Kirigami.Theme.textColor
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                            }

                            onValueModified: {
                                 saleItems.setProperty(index, "price", value)
                                updateTotal()
                            }
                        }

                        QQC2.SpinBox {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            value: model.taxRate || 0
                            from: 0
                            to: 100
                            onValueModified: {
                                saleItems.setProperty(index, "taxRate", value)
                                updateTotal()
                            }
                        }

                        QQC2.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                            text: ((model.price * model.quantity) * (1 + model.taxRate/100)).toLocaleString(Qt.locale(), 'f', 2)
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
            Layout.preferredWidth: Kirigami.Units.gridUnit * 16
            Layout.fillHeight: true
            Kirigami.Card {
                Layout.fillWidth: true

                contentItem: ColumnLayout {
                    // Client Selection
                    // RowLayout {
                    QQC2.CheckBox {
                        id: hasClientCheckbox
                        text: i18n("Assign to Client")
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
                        defaultSourceId: favoriteManager.getDefaultCashSource()  // Add this property
                        onItemSelected: function(source) {
                            selectedCashSourceId = source.id
                        }
                    }

                    // Notes Field
                    QQC2.TextArea {
                        Layout.fillWidth: true
                        placeholderText: i18n("Sale Notes")
                        onTextChanged: saleNotes = text
                    }

                    // Discount Field
                    RowLayout {
                        QQC2.Label {
                            text: i18n("Discount:")
                        }
                        QQC2.SpinBox {
                            from: 0
                            to: total
                            value: discountAmount
                            onValueChanged: {
                                discountAmount = value
                                updateTotal()
                            }
                        }
                    }
                }
            }
            // Totals card
            Kirigami.Card {
                Layout.fillWidth: true

                contentItem: ColumnLayout {
                    QQC2.Label {
                        text: i18n("Subtotal: %1", calculateSubtotal().toFixed(2))
                        font.pointSize: 14
                    }
                    QQC2.Label {
                        text: i18n("Tax: %1", calculateTotalTax().toFixed(2))
                        font.pointSize: 14
                    }
                    QQC2.Label {
                        text: i18n("Discount: %1", discountAmount.toFixed(2))
                        font.pointSize: 14
                        visible: discountAmount > 0
                    }
                    QQC2.Label {
                        text: i18n("Total: %1", total.toFixed(2))
                        font.pointSize: 16
                        font.bold: true
                    }
                    QQC2.Switch {
                        text: i18n("Auto Payment")
                        checked: root.autoPayment
                        onCheckedChanged: root.setAutoPayment(checked)
                    }
                }
            }
            // Enhanced NumPad
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
                    if (mode === "payment") {
                        if (numPad.amountTendered >= total) {
                            completeSale()
                        }
                    }
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
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    text: i18n("Normal")
                    checkable: true
                    checked: numPad.mode === "normal"
                    onClicked: numPad.mode = "normal"
                }
                QQC2.Button {
                    text: i18n("Payment")
                    checkable: true
                    checked: numPad.mode === "payment"
                    onClicked: {
                        numPad.mode = "payment"
                        numPad.reset()
                    }
                }
            }

            // Complete sale button
            QQC2.Button {
                id: completeSaleButton
                Layout.fillWidth: true
                text: i18n("Complete Sale")
                icon.name: "dialog-ok-apply"
                //   enabled: numPad.mode !== "payment" || numPad.amountTendered >= total
                onClicked: completeSale()
            }

        }
    }

    // Functions
    function addProductToSale(product) {
        if (!saleState || !saleState.saleItems) return

        for (let i = 0; i < saleState.saleItems.count; i++) {
            if (saleState.saleItems.get(i).id === product.id) {
                let quantity = saleState.saleItems.get(i).quantity + 1
                saleState.saleItems.setProperty(i, "quantity", quantity)
                updateTotal()
                return
            }
        }

        saleState.saleItems.append({
                                       id: product.id,
                                       name: product.name,
                                       price: product.price,
                                       originalPrice: product.price,
                                       quantity: 1,
                                       maxQuantity: product.quantity,
                                       purchase_price: product.purchase_price,
                                       packages: product.packages || [],
                                       packageId: null,
                                       isPackage: false,
                                       piecesPerUnit: 1,
                                       taxRate: 0,
                                       totalPieces: 1
                                   })
        updateTotal()
    }

    function updateItemQuantity(index, quantity) {
        if (saleState && saleState.saleItems) {
            saleState.saleItems.setProperty(index, "quantity", quantity)
            updateTotal()
        }
    }

    function calculateSubtotal() {
        if (!saleState || !saleState.saleItems) return 0
        let subtotal = 0
        for (let i = 0; i < saleState.saleItems.count; i++) {
            let item = saleState.saleItems.get(i)
            subtotal += item.price * item.quantity
        }
        return subtotal
    }

    function calculateTotalTax() {
        if (!saleState || !saleState.saleItems) return 0
        let totalTax = 0
        for (let i = 0; i < saleState.saleItems.count; i++) {
            let item = saleState.saleItems.get(i)
            let subtotal = item.price * item.quantity
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
                           unit_price: item.price,
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

}
