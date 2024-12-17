// InvoiceSummaryCard.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormCard {
    id: root
    property var invoice: ({})

    FormCard.FormTextDelegate {
        text: i18n("Reference")
        description: invoice.reference_number || ""
    }

    FormCard.FormTextDelegate {
        text: i18n("Client")
        description: invoice.client?.name || ""
    }

    FormCard.FormTextDelegate {
        text: i18n("Date")
        description: Qt.formatDateTime(new Date(invoice.invoice_date), "dd/MM/yyyy")
    }

    FormCard.FormTextDelegate {
        text: i18n("Due Date")
        description: Qt.formatDateTime(new Date(invoice.due_date), "dd/MM/yyyy")
    }

    FormCard.FormTextDelegate {
        text: i18n("Status")
        description: invoice.status || ""
    }

    FormCard.FormTextDelegate {
        text: i18n("Payment Status")
        description: invoice.payment_status || ""
    }

    FormCard.FormTextDelegate {
        text: i18n("Total Amount")
        description: Number(invoice.total_amount || 0).toLocaleString(Qt.locale(), 'f', 2)
    }

    FormCard.FormTextDelegate {
        text: i18n("Amount Paid")
        description: Number(invoice.paid_amount || 0).toLocaleString(Qt.locale(), 'f', 2)
    }

    FormCard.FormTextDelegate {
        text: i18n("Remaining Amount")
        description: Number(invoice.remaining_amount || 0).toLocaleString(Qt.locale(), 'f', 2)
    }
}
