// InvoiceItemDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.Dialog {
    id: itemDialog
    title: editMode ? i18n("Edit Item") : i18n("Add Item")
    standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

    property bool editMode: false
    property var initialData: ({})

    FormCard.FormCard {
        Layout.fillWidth: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30

        FormCard.FormTextFieldDelegate {
            id: descriptionField
            label: i18n("Description")

            placeholderText: i18n("Enter item description")
            onAccepted: quantityField.forceActiveFocus()
        }

        FormCard.FormSpinBoxDelegate {
            id: quantityField
            label: i18n("Quantity")
            from: 1
            to: 9999
            value: 1
            onValueChanged: updateTotal()
        }

        DFormTextFieldDelegate {
            id: unitPriceField
            label: i18n("Unit Price")
            text: "0"
            validator: DoubleValidator {
                bottom: 0
                decimals: 2
            }
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            onTextChanged: updateTotal()
        }

        FormCard.FormTextDelegate {
            text: i18n("Total")
            description: Number(totalPrice).toLocaleString(Qt.locale(), 'f', 2)
        }

        FormCard.FormTextAreaDelegate {
            id: notesField
            label: i18n("Notes")
            placeholderText: i18n("Optional notes about this item")
        }
    }

    property real totalPrice: 0

    function updateTotal() {
        totalPrice = quantityField.value * Number(unitPriceField.text)
    }

    function getItemData() {
        return {
            description: descriptionField.text,
            quantity: quantityField.value,
            unit_price: Number(unitPriceField.text),
            total_price: totalPrice,
            notes: notesField.text
        }
    }

    function setItemData(data) {
        descriptionField.text = data.description || ""
        quantityField.value = data.quantity || 1
        unitPriceField.text = String(data.unit_price || 0)
        notesField.text = data.notes || ""
        updateTotal()
    }

    onOpened: {
        if (editMode && initialData) {
            setItemData(initialData)
        } else {
            descriptionField.text = ""
            quantityField.value = 1
            unitPriceField.text = "0"
            notesField.text = ""
            updateTotal()
        }
        descriptionField.forceActiveFocus()
    }
}
