// TransferDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.delegates as Delegates
import "../../components"

Kirigami.PromptDialog {
    id: transferDialog

    property int sourceId: -1
    property string sourceName: ""
    property double sourceBalance: 0.0

    title: i18n("Transfer Funds")
    subtitle: i18n("Transfer money between cash sources")
    preferredWidth: Kirigami.Units.gridUnit * 40

    standardButtons: Kirigami.Dialog.NoButton

    signal transferAccepted(double amount, int destinationId, string notes)

    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: cashSourceApi.isLoading
        visible: running
        z: 999
    }

    Kirigami.InlineMessage {
        id: inlineMsgDialogDialog
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // Source Account Info (read-only)
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.AbstractFormDelegate {
                background: Item {}
                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: i18n("From Account")
                        font.bold: true
                    }

                    QQC2.Label {
                        text: sourceName
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                    }

                    QQC2.Label {
                        text: i18n("Available Balance: %1 DH",sourceBalance.toFixed(2))
                        opacity: 0.7
                    }
                }
            }
        }

        // Transfer Details
        FormCard.FormCard {
            Layout.fillWidth: true

            // Destination Account
            FormCard.FormComboBoxDelegate {
                id: destinationField
                description: i18n("To Account")

                property var destinationsModel: ListModel {
                    id: destinationsList
                }

                model: destinationsModel
                textRole: "text"
                valueRole: "value"

                function updateDestinations() {
                    destinationsModel.clear()
                    let names = cashSourceModel.getAvailableDestinations(sourceId)
                    let ids = cashSourceModel.getAvailableDestinationIds(sourceId)

                    for(let i = 0; i < names.length; i++) {
                        destinationsModel.append({
                            text: names[i],
                            value: ids[i]
                        })
                    }
                }

                Component.onCompleted: updateDestinations()

                Connections {
                    target: transferDialog
                    function onSourceIdChanged() {
                        destinationField.updateDestinations()
                    }
                }
            }

            // Amount
            FormCard.FormTextFieldDelegate {
                id: amountField
                label: i18n("Amount")
                placeholderText: i18n("Enter transfer amount")
                text: ""
                statusMessage: ""
                validator: DoubleValidator {
                    bottom: 0.01
                    top: sourceBalance
                    decimals: 2
                    notation: DoubleValidator.StandardNotation
                }

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

            // Notes
            FormCard.FormTextAreaDelegate {
                id: notesField
                label: i18n("Notes")
                placeholderText: i18n("Enter transfer notes (optional)")
                text: ""
            }
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: i18n("Transfer")
            icon.name: "selection-move-to-layer-above"
            enabled: !cashSourceApi.isLoading &&
                     destinationField.currentIndex !== -1 &&
                     amountField.text !== "" &&
                     parseFloat(amountField.text) > 0 &&
                     parseFloat(amountField.text) <= sourceBalance
            onTriggered: {
                if (!validateForm()) {
                    return
                }

                let transferData = {
                    sourceId: sourceId,
                    destinationId: destinationField.currentValue,
                    amount: parseFloat(amountField.text),
                    notes: notesField.text.trim()
                }

                cashSourceModel.transfer(transferData)
            }
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: transferDialog.close()
        }
    ]

    function validateForm() {
        let isValid = true
        let errors = []

        // Clear previous error messages
        inlineMsgDialogDialog.visible = false
        amountField.statusMessage = ""

        // Validate destination
        if (destinationField.currentValue === -1) {
            errors.push(i18n("Please select a destination account"))
            isValid = false
        }

        // Validate amount
        if (!amountField.text) {
            amountField.statusMessage = i18n("Amount is required")
            errors.push(i18n("Amount is required"))
            isValid = false
        } else {
            let amount = parseFloat(amountField.text)
            if (isNaN(amount) || amount <= 0) {
                amountField.statusMessage = i18n("Please enter a valid amount")
                errors.push(i18n("Please enter a valid amount"))
                isValid = false
            } else if (amount > sourceBalance) {
                amountField.statusMessage = i18n("Insufficient funds")
                errors.push(i18n("Insufficient funds"))
                isValid = false
            }
        }

        if (!isValid) {
            inlineMsgDialogDialog.type = Kirigami.MessageType.Error
            inlineMsgDialogDialog.text = errors.join("\n")
            inlineMsgDialogDialog.visible = true
        }

        return isValid
    }

    function clearFields() {
        destinationField.currentIndex = -1
        amountField.text = ""
        notesField.text = ""
        inlineMsgDialogDialog.visible = false
        amountField.statusMessage = ""
    }
    Connections {
        target: cashSourceApi
        function onErrorTransfer(message, status, details){
                inlineMsgDialogDialog.text= message
                inlineMsgDialogDialog.visible=true
                inlineMsgDialogDialog.type= Kirigami.MessageType.Error
        }
        function onTransferCompleted() {
            transferDialog.close()
            applicationWindow().gnotification.showNotification("",
                                                               i18n("Transfer completed successfully"), // message
                                                               Kirigami.MessageType.Positive, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )
            cashSourceModel.refresh()
        }

    }
    onOpened: {
        clearFields()
    }
}
