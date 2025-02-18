import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."
// TODO :  tax number / term
// - show validator error on field
Kirigami.PromptDialog {
    id: supplierDialog
    title: "Supplier Details"
    preferredWidth: Kirigami.Units.gridUnit * 50
    standardButtons: Kirigami.Dialog.NoButton
    property int dialogSupplierId: 0
    property var supplierData: ({})
    property bool isCreateAnother: false
    property var statusMapping: {
        "Active": "active",
        "Inactive": "inactive",
        "active": "Active",
        "inactive": "Inactive"
    }
    // Busy indicator
    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: supplierApi.isLoading
        visible: running
        z: 999
    }

    // Inline message for notifications
    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        text: "Hey! Let me tell you something positive!"
        showCloseButton: true
        type: Kirigami.MessageType.Positive
        visible: false
    }

    // Main form content
    GridLayout {
        columns: 2
        rows: 1
        enabled: !supplierApi.isLoading

        FormCard.FormCard {
            // Basic Information
            FormCard.FormTextFieldDelegate {
                id: nameField
                label: i18n("Name")
                text: ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormTextFieldDelegate {
                id: emailField
                label: i18n("Email")
                text: ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormTextFieldDelegate {
                id: phoneField
                label: i18n("Phone")
                text: ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormTextAreaDelegate {
                id: addressField
                label: i18n("Address")
                text: ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }
        }

        FormCard.FormCard {
            // Additional Information
            FormCard.FormTextFieldDelegate {
                id: taxNumberField
                label: i18n("Tax Number")
                text: ""
            }

            FormCard.FormTextFieldDelegate {
                id: paymentTermsField
                label: i18n("Payment Terms")
                text: ""
            }

            FormCard.FormComboBoxDelegate {
                id: statusCombo
                //label: qsTr("Status")
                model: ["Active", "Inactive"]
                currentIndex: 0
            }

            FormCard.FormTextAreaDelegate {
                id: notesField
                label: i18n("Notes")
                text: ""
            }
        }
    }

    // Custom footer actions
    customFooterActions: [
        Kirigami.Action {
            text: dialogSupplierId > 0 ? i18n("Save") : i18n("Add")
            icon.name: dialogSupplierId > 0 ? "document-save" : "list-add-symbolic"
            enabled: !supplierApi.isLoading
            onTriggered: {
                inlineMsg.visible = false
                isCreateAnother = false
                clearStatusMessages()
                let updatedSupplier = updateSupplier()
                if (dialogSupplierId > 0) {
                    supplierModel.updateSupplier(dialogSupplierId, updatedSupplier)
                } else {
                    supplierModel.createSupplier(updatedSuvplier)
                }
            }
        },
        Kirigami.Action {
            text: i18n("Add & Add another")
            icon.name: "list-add-symbolic"
            visible: dialogSupplierId <= 0
            enabled: !supplierApi.isLoading
            onTriggered: {
                inlineMsg.visible = false
                clearStatusMessages()
                isCreateAnother = true
                let updatedSupplier = updateSupplier()
                supplierModel.createSupplier(updatedSupplier)
            }
        },
        Kirigami.Action {
            text: i18n("Delete")
            icon.name: "edit-delete"
            visible: dialogSupplierId > 0
            enabled: !supplierApi.isLoading
            onTriggered: {
                inlineMsg.visible = false
                clearStatusMessages()
                supplierModel.deleteSupplier(dialogSupplierId)
            }
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                supplierDialog.close()
            }
        }
    ]

    // Helper functions
    function updateSupplier() {
        console.log(statusCombo.currentText)
        return {
            name: nameField.text,
            email: emailField.text,
            phone: phoneField.text,
            address: addressField.text,
            tax_number: taxNumberField.text,
            payment_terms: paymentTermsField.text,
            status: statusMapping[statusCombo.currentText], // Convert "Active" to "active"
            notes: notesField.text
        }
    }

    function loadData(supplier) {
        nameField.text = supplier.name || ""
        emailField.text = supplier.email || ""
        phoneField.text = supplier.phone || ""
        addressField.text = supplier.address || ""
        taxNumberField.text = supplier.taxNumber || ""
        paymentTermsField.text = supplier.paymentTerms || ""
        notesField.text = supplier.notes || ""
        statusCombo.currentIndex = statusCombo.model.indexOf(statusMapping[supplier.status]) || 0
    }

    function clearStatusMessages() {
        nameField.statusMessage = ""
        emailField.statusMessage = ""
        phoneField.statusMessage = ""
        addressField.statusMessage = ""
        taxNumberField.statusMessage = ""
        paymentTermsField.statusMessage = ""
    }

    function cleanFields() {
        nameField.text = ""
        emailField.text = ""
        phoneField.text = ""
        addressField.text = ""
        taxNumberField.text = ""
        paymentTermsField.text = ""
        notesField.text = ""
        statusCombo.currentIndex = 0
    }

    // API Connections
    Connections {
        target: supplierApi
        function onSupplierReceived(supplier) {
            loadData(supplier)
        }

        function onErrorSupplierReceived(message, status, details) {
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            } else {
                inlineMsg.text = message
                inlineMsg.visible = true
                inlineMsg.type = Kirigami.MessageType.Error
            }
        }

        function onSupplierCreated() {
            if (!isCreateAnother) {
                applicationWindow().gnotification.showNotification("",
                                                                   i18n("Supplier created successfully"),
                                                                   Kirigami.MessageType.Positive,
                                                                   "short",
                                                                   "dialog-close"
                                                                   )
                supplierDialog.close()
            } else {
                inlineMsg.text = "Supplier " + nameField.text + " added successfully"
                inlineMsg.visible = true
                cleanFields()
            }
            isCreateAnother = false
        }

        function onSupplierUpdated() {
            applicationWindow().gnotification.showNotification("",
                                                               i18n("Supplier %1 updated successfully",nameField.text),
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            supplierDialog.close()
        }

        function onSupplierDeleted() {
            applicationWindow().gnotification.showNotification("",
                                                               i18n("Supplier %1 deleted successfully",nameField.text),
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            supplierDialog.close()
        }
    }

    // Validation error handling
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
            'name': nameField,
            'email': emailField,
            'phone': phoneField,
            'address': addressField,
            'tax_number': taxNumberField,
            'payment_terms': paymentTermsField
        }

        Object.keys(errorObj).forEach(fieldName => {
                                          const field = fieldMap[fieldName]
                                          if (field) {
                                              field.statusMessage = errorObj[fieldName][0]
                                              field.status = Kirigami.MessageType.Error
                                          }
                                      })
    }
    onDialogSupplierIdChanged : {
        if (dialogSupplierId > 0) {
            supplierApi.getSupplier(dialogSupplierId)
        }

    }
    Component.onCompleted: {

    }
}
