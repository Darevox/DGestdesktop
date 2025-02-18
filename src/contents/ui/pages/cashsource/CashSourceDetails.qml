import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.PromptDialog {
    id: sourceDialog
    title: dialogSourceId > 0 ? "Edit Cash Source" : "New Cash Source"
    preferredWidth: Kirigami.Units.gridUnit * 50

    property int dialogSourceId: 0
    property bool isCreateAnother: false
    property bool isEditing: dialogSourceId > 0
    property bool isTransaction: false
    // title :  isEditing ?
    //              qsTr("Editing cash source details") :
    //              qsTr("Create a new cash source to manage your finances")
    // header: ColumnLayout {
    //     Kirigami.Heading {
    //         text: sourceDialog.title
    //         level: 1
    //     }

    //     QQC2.Label {
    //         text: isEditing ?
    //                   qsTr("Editing cash source details") :
    //                   qsTr("Create a new cash source to manage your finances")
    //         wrapMode: Text.WordWrap
    //         Layout.fillWidth: true
    //         opacity: 0.7
    //     }
    // }
    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: cashSourceApi.isLoading
        visible: running
        z: 999
    }

    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
    }
    // Transaction buttons with better visual hierarchy

    footerLeadingComponent : ColumnLayout {
        visible: isEditing
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            text: i18n("Transactions")
            level: 3
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Button {
                text: i18n("Deposit")
                icon.name: "list-add-money"
                highlighted: true
                onClicked: depositDialog.open()
            }

            QQC2.Button {
                text: i18n("Withdraw")
                icon.name: "list-remove-money"
                onClicked: withdrawDialog.open()
            }

            QQC2.Button {
                text: i18n("Transfer")
                icon.name: "transfer"
                visible: false // TODO: Implement transfer functionality
                onClicked: transferDialog.open()
            }
        }
    }
    GridLayout {
        columns: 1
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextFieldDelegate {
                id: nameField
                label: i18n("Name")
                placeholderText: i18n("Enter cash source name")
                text: ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
                //    required: true
            }

            FormCard.FormComboBoxDelegate {
                id: typeField
                //  label: qsTr("Type")
                description: i18n("Select the type of cash source")
                model: [
                    { text: i18n("Cash"), value: "cash" },
                    { text: i18n("Bank Account"), value: "bank" },
                    { text: i18n("Other"), value: "other" }
                ]
                textRole: "text"
                valueRole: "value"
                enabled: !isEditing // Can't change type after creation
                currentIndex : 0
            }

            // Initial Balance (only shown when creating)
            FormCard.FormTextFieldDelegate {
                id: initialBalanceField
                label: i18n("Initial Balance")
                placeholderText: i18n("Enter initial balance")
                text: "0.00"
                validator: DoubleValidator {
                    bottom: 0
                    decimals: 2
                    notation: DoubleValidator.StandardNotation
                }
                visible: !isEditing
                //  required: true
                enabled: !isEditing

                // Format number with 2 decimal places
                onTextChanged: {
                    if (text) {
                        let num = parseFloat(text)
                        if (!isNaN(num)) {
                            text = num.toFixed(2)
                        }
                    }
                }
            }

            // Current Balance (shown when editing)
            FormCard.FormTextFieldDelegate {
                id: balanceField
                label: i18n("Current Balance")
                text: "0.00"
                readOnly: true
                visible: isEditing
                // Add a small info icon and tooltip
                // trailing: Kirigami.Icon {
                //     source: "help-info"
                //     implicitWidth: Kirigami.Units.iconSizes.small
                //     implicitHeight: Kirigami.Units.iconSizes.small

                //     QQC2.ToolTip.visible: balanceMouseArea.containsMouse
                //     QQC2.ToolTip.text: qsTr("Balance can only be modified through transactions")

                //     MouseArea {
                //         id: balanceMouseArea
                //         anchors.fill: parent
                //         hoverEnabled: true
                //     }
                // }
            }

            // Bank-specific fields
            Kirigami.FormLayout {
                visible: typeField.currentValue === "bank"

                FormCard.FormTextFieldDelegate {
                    id: accountNumberField
                    label: i18n("Account Number")
                    placeholderText: i18n("Enter account number")
                    text: ""
                }

                FormCard.FormTextFieldDelegate {
                    id: bankNameField
                    label: i18n("Bank Name")
                    placeholderText: i18n("Enter bank name")
                    text: ""
                }
            }

            FormCard.FormTextAreaDelegate {
                id: descriptionField
                label: i18n("Description")
                placeholderText: i18n("Enter description (optional)")
                text: ""
            }

            FormCard.FormComboBoxDelegate {
                id: statusField
                //   label: qsTr("Status")
                text: i18n("Set the operational status")
                model: [
                    { text: i18n("Active"), value: "active" },
                    { text: i18n("Inactive"), value: "inactive" }
                ]
                textRole: "text"
                valueRole: "value"
                currentIndex : 0
            }

            FormCard.FormSwitchDelegate {
                id: isDefaultField
                text: i18n("Set as Default")
                description: i18n("Make this the default cash source")
                checked: false
                visible:false
            }
        }


    }

    TransactionDialog {
        id: depositDialog
        title: i18n("Deposit")
        onTransactionAccepted: function(amount, notes) {
            cashSourceModel.deposit(dialogSourceId, amount, notes)
        }
    }

    TransactionDialog {
        id: withdrawDialog
        title: i18n("Withdraw")
        onTransactionAccepted: function(amount, notes) {
            cashSourceModel.withdraw(dialogSourceId, amount, notes)
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: isEditing ? i18n("Save Changes") : i18n("Create Cash Source")
            icon.name: isEditing ? "document-save" : "list-add-symbolic"
            enabled: !cashSourceApi.isLoading && nameField.text.trim() !== "" // Basic validation
            onTriggered: {
                isCreateAnother = false
                let sourceData = getSourceData()

                console.log("Sending source data:", JSON.stringify(sourceData, null, 2))

                if (isEditing) {
                    cashSourceModel.updateCashSource(dialogSourceId, sourceData)
                } else {
                    cashSourceModel.createCashSource(sourceData)
                }
            }
        },
        Kirigami.Action {
            text: i18n("Create & Add Another")
            icon.name: "list-add-symbolic"
            visible: !isEditing
            enabled: !cashSourceApi.isLoading
            onTriggered: {
                isCreateAnother = true
                let sourceData = getSourceData()
                cashSourceModel.createCashSource(sourceData)
            }
        },
        Kirigami.Action {
            text: i18n("Delete")
            icon.name: "edit-delete"
            visible: isEditing
            enabled: !cashSourceApi.isLoading
            onTriggered: {
                deleteDialog.cashSourceToDelete = dialogSourceId
                deleteDialog.open()
            }
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: sourceDialog.close()
        }
    ]

    Connections {
        target: cashSourceApi

        function onCashSourceReceived(source) {
            loadData(source)
        }

        function onCashSourceCreated() {
            if (!isCreateAnother) {
                applicationWindow().gnotification.showNotification("",
                                                                   i18n("Cash source created successfully"),
                                                                   Kirigami.MessageType.Positive,
                                                                   "short",
                                                                   "dialog-close"
                                                                   )
                sourceDialog.close()
            } else {
                inlineMsg.text = "Cash source created successfully"
                inlineMsg.visible = true
                inlineMsg.type = Kirigami.MessageType.Positive
                clearFields()
            }
            cashSourceModel.refresh()
        }

        function onCashSourceUpdated() {
            if(!isTransaction){
                applicationWindow().gnotification.showNotification("",
                                                                   i18n("Cash source updated successfully"),
                                                                   Kirigami.MessageType.Positive,
                                                                   "short",
                                                                   "dialog-close"
                                                                   )
                sourceDialog.close()
            }
            cashSourceModel.refresh()
        }

        function onCashSourceDeleted() {
            applicationWindow().gnotification.showNotification("",
                                                               i18n("Cash source deleted successfully"),
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            sourceDialog.close()

        }

        function onDepositCompleted() {
            isTransaction=true
            inlineMsg.text= i18n("Deposit completed successfully")
            inlineMsg.visible=true
            inlineMsg.type= Kirigami.MessageType.Positive
            depositDialog.close()
            cashSourceApi.getCashSource(dialogSourceId)
            // let source = cashSourceModel.getCashSource(dialogSourceId)
            // if (source) {
            //     loadData(source)
            // }
            cashSourceModel.refresh()
        }

        function onWithdrawalCompleted() {
            isTransaction=true
            withdrawDialog.close()
            inlineMsg.text= i18n("Withdrawal completed successfully")
            inlineMsg.visible=true
            inlineMsg.type= Kirigami.MessageType.Positive
            cashSourceApi.getCashSource(dialogSourceId)
            // let source = cashSourceModel.getCashSource(dialogSourceId)
            // if (source) {
            //     loadData(source)
            // }
            cashSourceModel.refresh()
        }

        function onErrorCashSourceReceived(message, status, details){
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{

                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }

        }

        function onErrorCashSourceCreated(message, status, details){
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{

                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }

        }

        function onErrorCashSourceUpdated(message, status, details){
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{

                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }

        }

        function onErrorCashSourceDeleted(message, status, details){
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{
                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }

        }

    }

    function loadData(source) {
        if (!source) return;

        nameField.text = source.name || ""

        // Find the correct index for type
        let typeIndex = typeField.model.findIndex(item => item.value === source.type)
        typeField.currentIndex = typeIndex !== -1 ? typeIndex : 0

        initialBalanceField.text = source.initialBalance?.toFixed(2) || "0.00"
        balanceField.text = source.balance?.toFixed(2) || "0.00"
        accountNumberField.text = source.account_number || ""
        bankNameField.text = source.bank_name || ""
        descriptionField.text = source.description || ""

        // Find the correct index for status
        let statusIndex = statusField.model.findIndex(item => item.value === source.status)
        statusField.currentIndex = statusIndex !== -1 ? statusIndex : 0

        isDefaultField.checked = source.isDefault || false
    }

    function clearStatusMessages() {
        // Clear all status messages
        nameField.statusMessage = ""
        initialBalanceField.statusMessage = ""
        balanceField.statusMessage = ""
        accountNumberField.statusMessage = ""
        bankNameField.statusMessage = ""
        descriptionField.statusMessage = ""
        //inlineMsg.visible = false
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

        // Map of field names to their corresponding form components
        const fieldMap = {
            'name': nameField,
            'initial_balance': initialBalanceField,
            //'balance': balanceField,
            'account_number': accountNumberField,
            'bank_name': bankNameField,
            'description': descriptionField
        }

        // Set error messages for each field that has validation errors
        Object.keys(errorObj).forEach(fieldName => {
                                          const field = fieldMap[fieldName]
                                          if (field) {
                                              field.statusMessage = errorObj[fieldName][0]
                                              field.status = Kirigami.MessageType.Error
                                          }
                                      })
    }
    function clearFields() {
        // Clear all fields and reset to default values
        nameField.text = ""
        typeField.currentIndex = 0
        initialBalanceField.text = "0.00"
        balanceField.text = "0.00"
        accountNumberField.text = ""
        bankNameField.text = ""
        descriptionField.text = ""
        statusField.currentIndex = statusField.model.findIndex(item => item.value === "active")
        isDefaultField.checked = false
        clearStatusMessages()
    }
    function getSourceData() {
        let data = {
            name: nameField.text.trim(),
            type: typeField.currentValue || typeField.currentText,
            description: descriptionField.text.trim(),
            status: statusField.currentValue || statusField.currentText,
            is_default: isDefaultField.checked
        }

        // Only include bank-specific fields if type is bank
        if (typeField.currentValue === "bank" || typeField.currentText === "bank") {
            data.account_number = accountNumberField.text.trim()
            data.bank_name = bankNameField.text.trim()
        }

        // Only include initial_balance for new sources
        if (!isEditing) {
            data.initial_balance = parseFloat(initialBalanceField.text) || 0
        }

        return data
    }
    Kirigami.PromptDialog {
        id: deleteDialog
        property int cashSourceToDelete: -1
        title: i18n("Delete Cash Source")
        subtitle: i18n("Are you sure you'd like to delete this Cash Source?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            cashSourceApi.deleteCashSource(cashSourceToDelete)
        }
    }

    onDialogSourceIdChanged:{
        if (dialogSourceId > 0) {
            cashSourceApi.getCashSource(dialogSourceId)
        }
    }
    Component.onCompleted: {

    }
}
