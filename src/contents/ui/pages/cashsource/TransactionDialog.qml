// TransactionDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
Kirigami.Dialog {
    id: dialog

    title: i18n("Transaction")
    preferredWidth: Kirigami.Units.gridUnit * 30

    property alias amount: amountField.text
    property alias notes: notesField.text

    signal transactionAccepted(double amount, string notes)

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Kirigami.InlineMessage {
            id: inlineMsgDialog
            Layout.fillWidth: true
            showCloseButton: true
            visible: false
        }
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextFieldDelegate {
                id: amountField
                label: i18n("Amount")
                text: ""
                validator: DoubleValidator {
                    bottom: 0
                    decimals: 2
                }
            }

            FormCard.FormTextAreaDelegate {
                id: notesField
                label: i18n("Notes")
                text: ""
                Layout.preferredHeight: 80
            }
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: i18n("Submit")
            icon.name: "dialog-ok"
            onTriggered: {
                if (validateInput()) {
                    dialog.transactionAccepted(parseFloat(amountField.text), notesField.text)
                  //  dialog.close()
                }
            }
        },
        Kirigami.Action {
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: dialog.close()
        }
    ]

    function validateInput() {
        if (!amountField.text || parseFloat(amountField.text) <= 0) {
            // Show error message
            applicationWindow().showPassiveNotification(
                i18n("Please enter a valid amount greater than 0"),
                "short"
            )
            return false
        }
        return true
    }

    function clearFields() {
        amountField.text = ""
        notesField.text = ""
    }
    Connections {
        target: cashSourceApi
        function onErrorWithdrawal(message, status, details){
                inlineMsgDialog.text= message
                inlineMsgDialog.visible=true
                inlineMsgDialog.type= Kirigami.MessageType.Error
        }
        function onErrorDeposit(message, status, details){
                inlineMsgDialog.text= message
                inlineMsgDialog.visible=true
                inlineMsgDialog.type= Kirigami.MessageType.Error
        }

    }
    onOpened: {
        clearFields()
    }
}
