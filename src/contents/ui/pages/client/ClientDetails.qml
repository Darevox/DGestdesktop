import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.PromptDialog {
    id: clientDialog
    title: "Client Details"
    preferredWidth: Kirigami.Units.gridUnit * 50
    standardButtons: Kirigami.Dialog.NoButton
    property int dialogClientId: 0
    property var clientData: ({})
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
        running: clientApi.isLoading
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

    // Main form content i18n(
    GridLayout {
        columns: 2
        rows: 1
        enabled: !clientApi.isLoading

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
                text: i18n("Status")
                model: [
                    { text: i18n("Active"), value: "active" },
                    { text: i18n("Inactive"), value: "inactive" }
                ]
                textRole: "text"
                valueRole: "value"
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
            text: dialogClientId > 0 ? i18n("Save") : i18n("Add")
            icon.name: dialogClientId > 0 ? "document-save" : "list-add-symbolic"
            enabled: !clientApi.isLoading
            onTriggered: {
                inlineMsg.visible = false
                clientDialog.isCreateAnother = false
                clearStatusMessages()
                let updatedClient = updateClient()
                if (dialogClientId > 0) {
                    clientModel.updateClient(dialogClientId, updatedClient)
                } else {
                    clientModel.createClient(updatedClient)
                }
            }
        },
        Kirigami.Action {
            text: i18n("Add & Add another")
            icon.name: "list-add-symbolic"
            visible: dialogClientId <= 0
            enabled: !clientApi.isLoading
            onTriggered: {
                inlineMsg.visible = false
                clearStatusMessages()
                isCreateAnother = true
                let updatedClient = updateClient()
                clientModel.createClient(updatedClient)
            }
        },
        Kirigami.Action {
            text: i18n("Delete")
            icon.name: "edit-delete"
            visible: dialogClientId > 0
            enabled: !clientApi.isLoading
            onTriggered: {
                inlineMsg.visible = false
                clearStatusMessages()
                clientModel.deleteClient(dialogClientId)
            }
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                clientDialog.close()
            }
        }
    ]
    footerLeadingComponent : RowLayout {

        QQC2.Button {
            text: i18n("Sales History")
            icon.name: "view-list-details"
            visible: dialogClientId > 0
            enabled: !clientApi.isLoading
            onClicked: {
                clientSalesDialog.clientId = dialogClientId
                clientSalesDialog.clientName = nameField.text
                clientSalesDialog.active = true
            }
        }
        QQC2.Button{
            text: i18n("Payments")
            icon.name: "office-chart-line"
            visible: dialogClientId > 0
            enabled: !clientApi.isLoading
            onClicked: {
                clientPaymentsDialog.clientId = dialogClientId
                clientPaymentsDialog.clientName = nameField.text
                clientPaymentsDialog.active = true
            }
        }
        QQC2.Button {
            text: i18n("Statistics")
            icon.name: "office-chart-bar"
            visible: dialogClientId > 0
            enabled: !clientApi.isLoading
            onClicked: {
                clientStatisticsDialog.clientId = dialogClientId
                clientStatisticsDialog.clientName = nameField.text
                clientStatisticsDialog.active = true
            }
        }
    }
    // Helper functions
    function updateClient() {
        return {
            name: nameField.text,
            email: emailField.text,
            phone: phoneField.text,
            address: addressField.text,
            tax_number: taxNumberField.text,
            payment_terms: paymentTermsField.text,
            status: statusCombo.currentValue || statusCombo.currentText,
            notes: notesField.text
        }
    }

    function loadData(client) {
        nameField.text = client.name || ""
        emailField.text = client.email || ""
        phoneField.text = client.phone || ""
        addressField.text = client.address || ""
        taxNumberField.text = client.taxNumber || ""
        paymentTermsField.text = client.paymentTerms || ""
        notesField.text = client.notes || ""
         let statusIndex =  statusCombo.model.findIndex(item => item.value === client.status)
        statusCombo.currentIndex =  statusIndex !== -1 ? statusIndex : 0
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
        target: clientApi
        function onClientReceived(client) {
            loadData(client)
        }

        function onErrorClientReceived(message, status, details) {
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            } else {
                inlineMsg.text = message
                inlineMsg.visible = true
                inlineMsg.type = Kirigami.MessageType.Error
            }
        }

        function onClientCreated() {
            if (!isCreateAnother) {
                applicationWindow().gnotification.showNotification("",
                                                                   i18n("Client created successfully"),
                                                                   Kirigami.MessageType.Positive,
                                                                   "short",
                                                                   "dialog-close"
                                                                   )
                clientDialog.close()
            } else {
                inlineMsg.text = "Client " + nameField.text + " added successfully"
                inlineMsg.visible = true
                cleanFields()
            }
            isCreateAnother = false
        }

        function onClientUpdated() {
            applicationWindow().gnotification.showNotification("",
                                                               i18n("Client %1 updated successfully", nameField.text),
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            clientDialog.close()
        }

        function onClientDeleted() {
            applicationWindow().gnotification.showNotification("",
                                                             i18n("Client %1 deleted successfully", nameField.text),
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            clientDialog.close()
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
    Loader {
        id: clientSalesDialog
        active: false
        asynchronous: true
        sourceComponent: ClientSalesDialog {}
        property int clientId: 0
        property string clientName: ""
        onLoaded: {
            item.dialogClientId = clientSalesDialog.clientId
            item.dialogClientName = clientSalesDialog.clientName
            item.open()
        }

        Connections {
            target: clientSalesDialog.item
            function onClosed() {
                clientSalesDialog.active = false
            }
        }
    }

    Loader {
        id: clientPaymentsDialog
        active: false
        asynchronous: true
        sourceComponent: ClientPaymentsDialog {}
        property int clientId: 0
        property string clientName: ""
        onLoaded: {
            item.dialogClientId = clientPaymentsDialog.clientId
            item.dialogClientName = clientPaymentsDialog.clientName
            item.open()
        }

        Connections {
            target: clientPaymentsDialog.item
            function onClosed() {
                clientPaymentsDialog.active = false
            }
        }
    }

    Loader {
        id: clientStatisticsDialog
        active: false
        asynchronous: true
        sourceComponent: ClientStatisticsDialog {}
        property int clientId: 0
        property string clientName: ""
        onLoaded: {
            item.dialogClientId = clientStatisticsDialog.clientId
            item.dialogClientName = clientStatisticsDialog.clientName
            item.open()
        }

        Connections {
            target: clientStatisticsDialog.item
            function onClosed() {
                clientStatisticsDialog.active = false
            }
        }
    }
    onDialogClientIdChanged: {
        if (dialogClientId > 0) {
            clientApi.getClient(dialogClientId)
        }
    }
}
