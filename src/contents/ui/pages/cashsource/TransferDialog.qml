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

    title: qsTr("Transfer Funds")
    subtitle: qsTr("Transfer money between cash sources")
    preferredWidth: Kirigami.Units.gridUnit * 40

    standardButtons: Kirigami.Dialog.NoButton

    signal transferAccepted(double amount, int destinationId, string notes)

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
                        text: qsTr("From Account")
                        font.bold: true
                    }

                    QQC2.Label {
                        text: sourceName
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                    }

                    QQC2.Label {
                        text: qsTr("Available Balance: %1").arg(sourceBalance.toFixed(2))
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
                description: qsTr("To Account")

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
                label: qsTr("Amount")
                placeholderText: qsTr("Enter transfer amount")
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
                label: qsTr("Notes")
                placeholderText: qsTr("Enter transfer notes (optional)")
                text: ""
            }
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: qsTr("Transfer")
            icon.name: "transfer"
            enabled: !cashSourceModel.loading &&
                     destinationField.currentValue !== -1 &&
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
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: transferDialog.close()
        }
    ]

    function validateForm() {
        let isValid = true
        let errors = []

        // Clear previous error messages
        inlineMsg.visible = false
        amountField.statusMessage = ""

        // Validate destination
        if (destinationField.currentValue === -1) {
            errors.push(qsTr("Please select a destination account"))
            isValid = false
        }

        // Validate amount
        if (!amountField.text) {
            amountField.statusMessage = qsTr("Amount is required")
            errors.push(qsTr("Amount is required"))
            isValid = false
        } else {
            let amount = parseFloat(amountField.text)
            if (isNaN(amount) || amount <= 0) {
                amountField.statusMessage = qsTr("Please enter a valid amount")
                errors.push(qsTr("Please enter a valid amount"))
                isValid = false
            } else if (amount > sourceBalance) {
                amountField.statusMessage = qsTr("Insufficient funds")
                errors.push(qsTr("Insufficient funds"))
                isValid = false
            }
        }

        if (!isValid) {
            inlineMsg.type = Kirigami.MessageType.Error
            inlineMsg.text = errors.join("\n")
            inlineMsg.visible = true
        }

        return isValid
    }

    function clearFields() {
        destinationField.currentIndex = -1
        amountField.text = ""
        notesField.text = ""
        inlineMsg.visible = false
        amountField.statusMessage = ""
    }

    onOpened: {
        clearFields()
    }
}
