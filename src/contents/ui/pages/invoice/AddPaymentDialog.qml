// AddPaymentDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.Dialog {
    id: paymentDialog
    title: i18n("Add Payment")
    standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

    property int invoiceId: -1
    property real totalAmount: 0
    property real paidAmount: 0
    property real remainingAmount: totalAmount - paidAmount

    signal paymentAdded()

    FormCard.FormCard {
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30

        FormCard.FormTextDelegate {
            text: i18n("Total Amount")
            description: totalAmount.toLocaleString(Qt.locale(), 'f', 2)
        }

        FormCard.FormTextDelegate {
            text: i18n("Amount Paid")
            description: paidAmount.toLocaleString(Qt.locale(), 'f', 2)
        }

        FormCard.FormTextDelegate {
            text: i18n("Remaining Amount")
            description: remainingAmount.toLocaleString(Qt.locale(), 'f', 2)
        }

        FormCard.FormComboBoxDelegate {
            id: cashSourceCombo
            text: i18n("Payment Source")
            model: cashSourceModel // You'll need to create this model
            textRole: "name"
            valueRole: "id"

        }

        DFormTextFieldDelegate {
            id: amountField
            label: i18n("Payment Amount")
            text: String(remainingAmount)
            validator: DoubleValidator {
                bottom: 0
                top: remainingAmount
                decimals: 2
            }

        }

        FormCard.FormComboBoxDelegate {
            id: paymentMethodCombo
            text: i18n("Payment Method")
            model: [
                { text: i18n("Cash"), value: "cash" },
                { text: i18n("Bank Transfer"), value: "bank_transfer" },
                { text: i18n("Check"), value: "check" },
                { text: i18n("Credit Card"), value: "credit_card" }
            ]
            textRole: "text"
            valueRole: "value"
        }

        FormCard.FormTextFieldDelegate {
            id: referenceField
            label: i18n("Reference Number")
            placeholderText: i18n("Payment reference number")
        }

        FormCard.FormTextAreaDelegate {
            id: notesField
            label: i18n("Notes")
            placeholderText: i18n("Additional payment notes")
        }
    }

    onAccepted: {
        let paymentData = {
            cash_source_id: cashSourceCombo.currentValue,
            amount: Number(amountField.text),
            payment_method: paymentMethodCombo.currentValue,
            reference_number: referenceField.text,
            notes: notesField.text
        }

        invoiceModel.addPayment(invoiceId, paymentData)
    }

    Connections {
        target: invoiceModel
        function onPaymentAdded() {
            paymentDialog.paymentAdded()
            paymentDialog.close()
        }
    }
}
