import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.PromptDialog {
    id: invoiceDialog
    title: dialogInvoiceId > 0 ? i18n("Edit Invoice") : i18n("Create Invoice")
    preferredWidth: Kirigami.Units.gridUnit * 50
    standardButtons: Kirigami.Dialog.NoButton

    property int dialogInvoiceId: 0
    property var invoiceData: ({})
    property bool isCreateAnother: false
    property var statusMapping: {
        "Draft": "draft",
        "Sent": "sent",
        "Paid": "paid",
        "Overdue": "overdue",
        "Cancelled": "cancelled",
        "draft": "Draft",
        "sent": "Sent",
        "paid": "Paid",
        "overdue": "Overdue",
        "cancelled": "Cancelled"
    }

    QQC2.BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: invoiceApi.isLoading
        visible: running
        z: 999
    }

    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        text: "Invoice operation completed successfully!"
        showCloseButton: true
        type: Kirigami.MessageType.Positive
        visible: false
    }

    GridLayout {
        columns: 2
        rows: 1
        enabled: !invoiceApi.loading

        // Left column
        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: referenceField
                label: i18n("Reference Number")
                text: ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormComboBoxDelegate {
                id: invoiceableTypeCombo
                description: i18n("Invoiceable Type")
                model: ["Order", "Project", "Contract"]
                currentIndex: -1
            }
            FormCard.FormTextDelegate {
                 id: sourceInfoText
                 text: i18n("Source")
                 description: ""
                 visible: description !== ""
             }

             FormCard.FormTextDelegate {
                 id: contactInfoText
                 text: i18n("Contact")
                 description: ""
                 visible: description !== ""
             }
            FormCard.FormSpinBoxDelegate {
                id: invoiceableIdField
                label: i18n("Invoiceable ID")
                from: 1
                value: 0
            }

            FormCard.FormComboBoxDelegate {
                id: statusCombo
                description: i18n("Status")
                model: ["Draft", "Sent", "Paid", "Overdue", "Cancelled"]
                currentIndex: 0
            }

            FormCard.FormDateTimeDelegate {
                id: issueDateField
                text: i18n("Issue Date")
                dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                value: new Date()
            }

            FormCard.FormDateTimeDelegate {
                id: dueDateField
                text: i18n("Due Date")
                dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                value: new Date(new Date().setDate(new Date().getDate() + 30))
            }
        }

        // Right column
        FormCard.FormCard {
            FormCard.FormSpinBoxDelegate {
                id: taxField
                label: i18n("Tax Amount")
                from: 0
                to: 999999
                value: 0
                onValueChanged: updateTotals()
            }

            FormCard.FormSpinBoxDelegate {
                id: discountField
                label: i18n("Discount Amount")
                from: 0
                to: 999999
                value: 0
                onValueChanged: updateTotals()
            }

            FormCard.FormTextDelegate {
                text: i18n("Subtotal")
                description: calculateSubtotal()
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Amount")
                description: calculateTotal()
            }

            FormCard.FormTextAreaDelegate {
                id: notesField
                label: i18n("Notes")
                text: ""
            }
        }

        // Items section
        FormCard.FormCard {
            Layout.columnSpan: 2
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Kirigami.Heading {
                        text: i18n("Invoice Items")
                        level: 2
                    }
                    Item { Layout.fillWidth: true }
                    QQC2.Button {
                        text: i18n("Add Item")
                        icon.name: "list-add"
                        onClicked: {
                            clearItemDialog()
                            itemDialog.open()
                        }
                    }
                }

                ListView {
                    id: itemsList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight + 60, 200)
                    model: ListModel { id: itemsModel }
                    clip: true

                    delegate: Kirigami.SwipeListItem {
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing

                            QQC2.Label {
                                text: model.description
                                Layout.fillWidth: true
                            }
                            QQC2.Label {
                                text: i18nc("quantity", "Qty: %1", model.quantity)
                                Layout.preferredWidth: 100
                            }
                            QQC2.Label {
                                text: i18nc("price", "%1", model.unit_price)
                                Layout.preferredWidth: 100
                                horizontalAlignment: Text.AlignRight
                            }
                            QQC2.Label {
                                text: i18nc("total", "%1", model.total_price)
                                Layout.preferredWidth: 100
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        actions: [
                            Kirigami.Action {
                                icon.name: "edit-entry"
                                onTriggered: editItem(model.index)
                            },
                            Kirigami.Action {
                                icon.name: "edit-delete"
                                onTriggered: deleteItem(model.index)
                            }
                        ]
                    }
                }
            }
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: dialogInvoiceId > 0 ? i18n("Save") : i18n("Add")
            icon.name: dialogInvoiceId > 0 ? "document-save" : "list-add-symbolic"
            enabled: !invoiceApi.loading
            onTriggered: {
                inlineMsg.visible = false
                isCreateAnother = false
                clearStatusMessages()
                if (isValidInvoice()) {
                    let updatedInvoice = updateInvoice()
                    if (dialogInvoiceId > 0) {
                        invoiceModel.updateInvoice(dialogInvoiceId, updatedInvoice)
                    } else {
                        invoiceModel.createInvoice(updatedInvoice)
                    }
                }
            }
        },
        Kirigami.Action {
            text: i18n("Add & Add another")
            icon.name: "list-add-symbolic"
            visible: dialogInvoiceId <= 0
            enabled: !invoiceApi.loading
            onTriggered: {
                inlineMsg.visible = false
                clearStatusMessages()
                if (isValidInvoice()) {
                    isCreateAnother = true
                    let updatedInvoice = updateInvoice()
                    invoiceModel.createInvoice(updatedInvoice)
                }
            }
        },
        Kirigami.Action {
            text: i18n("Delete")
            icon.name: "edit-delete"
            visible: dialogInvoiceId > 0
            enabled: !invoiceApi.loading
            onTriggered: {
                inlineMsg.visible = false
                clearStatusMessages()
                invoiceModel.deleteInvoice(dialogInvoiceId)
            }
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: invoiceDialog.close()
        }
    ]

    // Item Dialog
    Kirigami.Dialog {
        id: itemDialog
        title: editingItemIndex >= 0 ? i18n("Edit Item") : i18n("Add Item")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        property int editingItemIndex: -1

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: itemDescriptionField
                label: i18n("Description")
                placeholderText: i18n("Item description")
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormSpinBoxDelegate {
                id: itemQuantityField
                label: i18n("Quantity")
                from: 1
                to: 999999
                value: 1
            }

            FormCard.FormSpinBoxDelegate {
                id: itemUnitPriceField
                label: i18n("Unit Price")
                from: 0
                to: 999999
                value: 0
            }

            FormCard.FormTextAreaDelegate {
                id: itemNotesField
                label: i18n("Notes")
            }

            FormCard.FormTextDelegate {
                text: i18n("Total")
                description: itemQuantityField.value * itemUnitPriceField.value
            }
        }

        onAccepted: {
            if (!validateItem()) {
                return
            }

            if (editingItemIndex >= 0) {
                itemsModel.set(editingItemIndex, {
                    description: itemDescriptionField.text,
                    quantity: itemQuantityField.value,
                    unit_price: itemUnitPriceField.value,
                    total_price: itemQuantityField.value * itemUnitPriceField.value,
                    notes: itemNotesField.text
                })
            } else {
                itemsModel.append({
                    description: itemDescriptionField.text,
                    quantity: itemQuantityField.value,
                    unit_price: itemUnitPriceField.value,
                    total_price: itemQuantityField.value * itemUnitPriceField.value,
                    notes: itemNotesField.text
                })
            }
            updateTotals()
            itemDialog.close()
        }

        onRejected: itemDialog.close()
    }

    // Helper functions
    function updateInvoice() {
        let currentMetaData = invoiceData.meta_data || {}
        return {
            reference_number: referenceField.text,
            invoiceable_type: invoiceableTypeCombo.currentText,
            invoiceable_id: invoiceableIdField.value,
            status: statusMapping[statusCombo.currentText],
            issue_date: issueDateField.value.toISOString(),
            due_date: dueDateField.value.toISOString(),
            total_amount: calculateTotal(),
            tax_amount: taxField.value,
            discount_amount: discountField.value,
            notes: notesField.text,
            items: getItemsArray(),
            meta_data: {
                currentMetaData,  // Preserve existing meta_data
                last_modified: new Date().toISOString(),
                total_items: itemsModel.count,
                subtotal: calculateSubtotal()
            }
        }
    }


    function loadData(invoice) {
        referenceField.text = invoice.reference_number || ""
        invoiceableTypeCombo.currentIndex = invoiceableTypeCombo.model.indexOf(invoice.invoiceable_type)
        invoiceableIdField.value = invoice.invoiceable_id || 0
        statusCombo.currentIndex = statusCombo.model.indexOf(statusMapping[invoice.status]) || 0
        issueDateField.value = parseDate(invoice.issue_date)
        dueDateField.value = parseDate(invoice.due_date)
        notesField.text = invoice.notes || ""
        taxField.value = invoice.tax_amount || 0
        discountField.value = invoice.discount_amount || 0

        // Handle meta_data
        if (invoice.meta_data) {
            // You might want to show this information in the UI
            let sourceType = invoice.meta_data.source_type
            let sourceRef = invoice.meta_data.source_reference
            let contact = invoice.meta_data.contact

            // You could add additional FormTextDelegate components to show this info:
            sourceInfoText.description = i18n("Generated from %1 %2", sourceType, sourceRef)
            contactInfoText.description = contact ?
                i18n("%1: %2", contact.type, contact.data.name) : ""
        }

        // Load items - prefer items_data from meta_data if available
        itemsModel.clear()
        let items = invoice.meta_data?.items_data || invoice.items || []
        items.forEach(item => {
            itemsModel.append({
                description: item.description || item.product_name,
                quantity: item.quantity,
                unit_price: item.unit_price,
                total_price: item.total_price,
                notes: item.notes || "",
                // Additional meta info
                product_id: item.product_id,
                is_package: item.is_package,
                package_id: item.package_id,
                total_pieces: item.total_pieces,
                tax_rate: item.tax_rate,
                discount_amount: item.discount_amount
            })
        })
        updateTotals()
    }

    function calculateSubtotal() {
        let subtotal = 0
        for (let i = 0; i < itemsModel.count; i++) {
            let item = itemsModel.get(i)
            subtotal += item.total_price
        }
        return subtotal
    }

    function calculateTotal() {
        return calculateSubtotal() + taxField.value - discountField.value
    }

    function updateTotals() {
        // Force update of the FormTextDelegates showing totals
        let total = calculateTotal()
        itemsList.model = itemsModel
    }

    function clearItemDialog() {
        itemDialog.editingItemIndex = -1
        itemDescriptionField.text = ""
        itemDescriptionField.statusMessage = ""
        itemQuantityField.value = 1
        itemUnitPriceField.value = 0
        itemNotesField.text = ""
    }

    function editItem(index) {
        let item = itemsModel.get(index)
        itemDialog.editingItemIndex = index
        itemDescriptionField.text = item.description
        itemQuantityField.value = item.quantity
        itemUnitPriceField.value = item.unit_price
        itemNotesField.text = item.notes || ""
        itemDialog.open()
    }

    function deleteItem(index) {
        itemsModel.remove(index)
        updateTotals()
    }

    function clearStatusMessages() {
        referenceField.statusMessage = ""
        itemDescriptionField.statusMessage = ""
        // Add other fields as needed
    }

    function cleanFields() {
        referenceField.text = ""
        invoiceableTypeCombo.currentIndex = 0
        invoiceableIdField.value = 0
        statusCombo.currentIndex = 0
        issueDateField.value = new Date()
        dueDateField.value = new Date(new Date().setDate(new Date().getDate() + 30))
        notesField.text = ""
        taxField.value = 0
        discountField.value = 0
        itemsModel.clear()
        updateTotals()
    }

    function handleValidationErrors(errorDetails) {
        clearStatusMessages()

        let errorObj = {}
        try {
            errorObj = JSON.parse(errorDetails)
        } catch (e) {
            console.error("Error parsing validation details:", e)
            return
        }

        const fieldMap = {
            'reference_number': referenceField,
            'invoiceable_type': invoiceableTypeCombo,
            'invoiceable_id': invoiceableIdField,
            'status': statusCombo,
            'issue_date': issueDateField,
            'due_date': dueDateField,
            'tax_amount': taxField,
            'discount_amount': discountField,
            'notes': notesField
        }

        Object.keys(errorObj).forEach(fieldName => {
            const field = fieldMap[fieldName]
            if (field) {
                field.statusMessage = errorObj[fieldName][0]
                field.status = Kirigami.MessageType.Error
            }
        })

        if (errorObj.items) {
            showError(i18n("There are errors in invoice items"))
        }
    }

    function formatDate(date) {
        return date ? date.toLocaleDateString(Qt.locale(), "yyyy-MM-dd") : ""
    }

    function parseDate(dateString) {
        if (!dateString) return new Date()
        const parsed = new Date(dateString)
        return isNaN(parsed.getTime()) ? new Date() : parsed
    }

    function getStatusColor(status) {
        switch(status.toLowerCase()) {
            case "draft": return Kirigami.Theme.neutralTextColor
            case "sent": return Kirigami.Theme.positiveTextColor
            case "paid": return Kirigami.Theme.positiveTextColor
            case "overdue": return Kirigami.Theme.negativeTextColor
            case "cancelled": return Kirigami.Theme.disabledTextColor
            default: return Kirigami.Theme.textColor
        }
    }

    function isValidInvoice() {
        if (!referenceField.text) {
            showError(i18n("Reference number is required"))
            return false
        }

        if (invoiceableTypeCombo.currentIndex === -1) {
            showError(i18n("Please select an invoiceable type"))
            return false
        }

        if (invoiceableIdField.value <= 0) {
            showError(i18n("Please enter a valid invoiceable ID"))
            return false
        }

        if (itemsModel.count === 0) {
            showError(i18n("Please add at least one item"))
            return false
        }

        return true
    }

    function showError(message) {
        inlineMsg.text = message
        inlineMsg.type = Kirigami.MessageType.Error
        inlineMsg.visible = true
    }

    function formatCurrency(amount) {
        return Number(amount).toLocaleString(Qt.locale(), 'f', 2)
    }

    function validateItem() {
        if (!itemDescriptionField.text) {
            itemDescriptionField.statusMessage = i18n("Item description is required")
            itemDescriptionField.status = Kirigami.MessageType.Error
            return false
        }

        if (itemQuantityField.value <= 0) {
            showError(i18n("Quantity must be greater than zero"))
            return false
        }

        if (itemUnitPriceField.value < 0) {
            showError(i18n("Unit price cannot be negative"))
            return false
        }

        return true
    }

    function getMetaData() {
        return {
            last_modified: new Date().toISOString(),
            total_items: itemsModel.count,
            subtotal: calculateSubtotal()
        }
    }

    function getItemsArray() {
        let items = []
        for (let i = 0; i < itemsModel.count; i++) {
            let item = itemsModel.get(i)
            items.push({
                description: item.description,
                quantity: item.quantity,
                unit_price: item.unit_price,
                total_price: item.total_price,
                notes: item.notes
            })
        }
        return items
    }

    // API Connections
    Connections {
        target: invoiceApi
        function onInvoiceReceived(invoice) {
            loadData(invoice)
        }

        function onErrorInvoiceReceived(message, status, details) {
            if (status === 1) {
                handleValidationErrors(details)
            } else {
                inlineMsg.text = message
                inlineMsg.visible = true
                inlineMsg.type = Kirigami.MessageType.Error
            }
        }

        function onInvoiceCreated() {
            if (!isCreateAnother) {
                applicationWindow().gnotification.showNotification(
                    "",
                    i18n("Invoice created successfully"),
                    Kirigami.MessageType.Positive,
                    "short",
                    "dialog-close"
                )
                invoiceDialog.close()
            } else {
                inlineMsg.text = i18n("Invoice %1 created successfully", referenceField.text)
                inlineMsg.visible = true
                cleanFields()
            }
            isCreateAnother = false
        }

        function onInvoiceUpdated() {
            applicationWindow().gnotification.showNotification(
                "",
                i18n("Invoice %1 updated successfully", referenceField.text),
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
            invoiceDialog.close()
        }

        function onInvoiceDeleted() {
            applicationWindow().gnotification.showNotification(
                "",
                i18n("Invoice %1 deleted successfully", referenceField.text),
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
            invoiceDialog.close()
        }
    }

    onDialogInvoiceIdChanged: {
        if (dialogInvoiceId > 0) {
            invoiceApi.getInvoice(dialogInvoiceId)
        } else {
            cleanFields()
        }
    }
}
