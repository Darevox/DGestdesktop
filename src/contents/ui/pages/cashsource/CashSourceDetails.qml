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
    header: ColumnLayout {
        Kirigami.Heading {
            text: sourceDialog.title
            level: 1
        }

        QQC2.Label {
            text: isEditing ?
                      qsTr("Editing cash source details") :
                      qsTr("Create a new cash source to manage your finances")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            opacity: 0.7
        }
    }
    QQC2.BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: cashSourceModel.loading
        visible: running
        z: 999
    }

    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
    }

    GridLayout {
        columns: 1
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextFieldDelegate {
                id: nameField
                label: qsTr("Name")
                placeholderText: qsTr("Enter cash source name")
                text: ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
                //    required: true
            }

            FormCard.FormComboBoxDelegate {
                id: typeField
                //  label: qsTr("Type")
                description: qsTr("Select the type of cash source")
                model: [
                    { text: qsTr("Cash"), value: "cash" },
                    { text: qsTr("Bank Account"), value: "bank" },
                    { text: qsTr("Other"), value: "other" }
                ]
                textRole: "text"
                valueRole: "value"
                enabled: !isEditing // Can't change type after creation
            }

            // Initial Balance (only shown when creating)
            FormCard.FormTextFieldDelegate {
                id: initialBalanceField
                label: qsTr("Initial Balance")
                placeholderText: qsTr("Enter initial balance")
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
                label: qsTr("Current Balance")
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
                    label: qsTr("Account Number")
                    placeholderText: qsTr("Enter account number")
                    text: ""
                }

                FormCard.FormTextFieldDelegate {
                    id: bankNameField
                    label: qsTr("Bank Name")
                    placeholderText: qsTr("Enter bank name")
                    text: ""
                }
            }

            FormCard.FormTextAreaDelegate {
                id: descriptionField
                label: qsTr("Description")
                placeholderText: qsTr("Enter description (optional)")
                text: ""
            }

            FormCard.FormComboBoxDelegate {
                id: statusField
                //   label: qsTr("Status")
                description: qsTr("Set the operational status")
                model: [
                    { text: qsTr("Active"), value: "active" },
                    { text: qsTr("Inactive"), value: "inactive" }
                ]
                textRole: "text"
                valueRole: "value"
            }

            FormCard.FormSwitchDelegate {
                id: isDefaultField
                text: qsTr("Set as Default")
                description: qsTr("Make this the default cash source")
                checked: false
            }
        }

        // Transaction buttons with better visual hierarchy
        ColumnLayout {
            visible: isEditing
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                text: qsTr("Transactions")
                level: 3
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing

                QQC2.Button {
                    text: qsTr("Deposit")
                    icon.name: "list-add-money"
                    highlighted: true
                    onClicked: depositDialog.open()
                }

                QQC2.Button {
                    text: qsTr("Withdraw")
                    icon.name: "list-remove-money"
                    onClicked: withdrawDialog.open()
                }

                QQC2.Button {
                    text: qsTr("Transfer")
                    icon.name: "transfer"
                    visible: false // TODO: Implement transfer functionality
                    onClicked: transferDialog.open()
                }
            }
        }
    }

    TransactionDialog {
        id: depositDialog
        title: qsTr("Deposit")
        onTransactionAccepted: function(amount, notes) {
            cashSourceModel.deposit(dialogSourceId, amount, notes)
        }
    }

    TransactionDialog {
        id: withdrawDialog
        title: qsTr("Withdraw")
        onTransactionAccepted: function(amount, notes) {
            cashSourceModel.withdraw(dialogSourceId, amount, notes)
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: isEditing ? qsTr("Save Changes") : qsTr("Create Cash Source")
            icon.name: isEditing ? "document-save" : "list-add-symbolic"
            enabled: !cashSourceModel.loading && nameField.text.trim() !== "" // Basic validation
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
            text: qsTr("Create & Add Another")
            icon.name: "list-add-symbolic"
            visible: !isEditing
            enabled: !cashSourceModel.loading
            onTriggered: {
                isCreateAnother = true
                let sourceData = getSourceData()
                cashSourceModel.createCashSource(sourceData)
            }
        },
        Kirigami.Action {
            text: qsTr("Delete")
            icon.name: "edit-delete"
            visible: isEditing
            enabled: !cashSourceModel.loading
            onTriggered: {
                // Add confirmation dialog
                // showDeleteConfirmation()
            }
        },
        Kirigami.Action {
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: sourceDialog.close()
        }
    ]

    Connections {
        target: cashSourceApi

        function onCashSourceReceived(source) {
            console.log("APPIIIIIIIIII")
            loadData(source)
        }


        function onCashSourceCreated() {
            if (!isCreateAnother) {
                applicationWindow().gnotification.showNotification("",
                                                                   "Cash source created successfully",
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
        }

        function onCashSourceUpdated() {
            applicationWindow().gnotification.showNotification("",
                                                               "Cash source updated successfully",
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            sourceDialog.close()
        }

        function onCashSourceDeleted() {
            applicationWindow().gnotification.showNotification("",
                                                               "Cash source deleted successfully",
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            sourceDialog.close()
        }

        function onDepositCompleted() {
            applicationWindow().gnotification.showNotification("",
                                                               "Deposit completed successfully",
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            depositDialog.close()
            let source = cashSourceModel.getCashSource(dialogSourceId)
            if (source) {
                loadData(source)
            }
        }

        function onWithdrawalCompleted() {
            applicationWindow().gnotification.showNotification("",
                                                               "Withdrawal completed successfully",
                                                               Kirigami.MessageType.Positive,
                                                               "short",
                                                               "dialog-close"
                                                               )
            withdrawDialog.close()
            let source = cashSourceModel.getCashSource(dialogSourceId)
            if (source) {
                loadData(source)
            }
        }

        function onErrorMessageChanged() {
            if (cashSourceModel.errorMessage) {
                inlineMsg.text = cashSourceModel.errorMessage
                inlineMsg.visible = true
                inlineMsg.type = Kirigami.MessageType.Error
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
        accountNumberField.text = source.accountNumber || ""
        bankNameField.text = source.bankName || ""
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
        inlineMsg.visible = false
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

    onDialogSourceIdChanged:{
        if (dialogSourceId > 0) {
            cashSourceApi.getCashSource(dialogSourceId)
        }
    }
    Component.onCompleted: {

    }
}
