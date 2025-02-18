import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."

Kirigami.PromptDialog {
    id: invoiceDialog
    title: i18n("Invoice Details")
    preferredWidth: Kirigami.Units.gridUnit * 50
    standardButtons: Kirigami.Dialog.NoButton

    property int dialogInvoiceId: 0
    property var invoiceData: ({})
    property bool isViewMode: dialogInvoiceId > 0
    property var statusMapping: {
        "Draft": "draft",
        "Cancelled": "cancelled",
        "Paid": "paid",
        "Sent": "sent",
        "draft": "Draft",
        "cancelled": "Cancelled",
        "paid": "Paid",
        "sent": "Sent"
    }

    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: invoiceApi.isLoading
        visible: running
        z: 999
    }

    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
    }

    // Main Content
    RowLayout {
        spacing: Kirigami.Units.largeSpacing

        // Header Section
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextDelegate {
                text: i18n("Reference Number")
                description: invoiceData.reference_number || ""
                visible: description !== ""
            }

            FormCard.FormComboBoxDelegate {
                id: statusCombo
                description: i18n("Change Status")
                model: ["Draft", "Cancelled"]
                visible: isViewMode && invoiceData.status !== "paid" && invoiceData.status !== "sent"
                currentIndex: model.indexOf(statusMapping[invoiceData.status]) || 0
            }
        }

        // Dates and Source Section
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextDelegate {
                text: i18n("Issue Date")
                description: formatDate(invoiceData.issue_date)
            }

            FormCard.FormTextDelegate {
                text: i18n("Due Date")
                description: formatDate(invoiceData.due_date)
            }

            FormCard.FormTextDelegate {
                id: sourceInfoText
                text: i18n("Source")
                description: invoiceData.meta_data?.source_type ?
                                 i18n("Generated from %1 %2",
                                      invoiceData.meta_data.source_type,
                                      invoiceData.meta_data.source_reference) : ""
                visible: description !== ""
            }

            FormCard.FormTextDelegate {
                id: contactInfoText
                text: i18n("Contact")
                description: invoiceData.meta_data?.contact ?
                                 i18n("%1: %2",
                                      invoiceData.meta_data.contact.type || "",
                                      (invoiceData.meta_data.contact.data?.name || "").trim() || i18n("Anonymous")) : ""
                visible: description !== ""
            }
        }

        // Amounts Section
        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextDelegate {
                text: i18n("Subtotal")
                description: formatCurrency(invoiceData.meta_data?.subtotal || 0)
            }

            FormCard.FormTextDelegate {
                text: i18n("Tax Amount")
                description: formatCurrency(invoiceData.tax_amount || 0)
            }

            FormCard.FormTextDelegate {
                text: i18n("Discount Amount")
                description: formatCurrency(invoiceData.discount_amount || 0)
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Amount")
                description: formatCurrency(invoiceData.total_amount || 0)
                Component.onCompleted: {
                    const divider = Qt.createQmlObject(
                                      'import QtQuick; Rectangle {
                            Layout.fillWidth: true;
                            height: 1;
                            color: Kirigami.Theme.textColor;
                            opacity: 0.2
                        }',
                                      parent,
                                      "divider"
                                      )
                    parent.Layout.topMargin = Kirigami.Units.largeSpacing
                }
            }
        }

        // Notes Section
        FormCard.FormCard {
            Layout.fillWidth: true
            visible: invoiceData.notes

            FormCard.FormTextDelegate {
                text: i18n("Notes")
                description: invoiceData.notes
            }
        }
    }

    // Footer Actions
    customFooterActions: [
        Kirigami.Action {
            text: i18n("Mark as Paid")
            icon.name: "checkbox-checked"
            enabled: isViewMode && invoiceData.status !== "paid" && invoiceData.status !== "cancelled" && invoiceData.status !== "sent"
            // enabled: !invoiceApi.loading
            onTriggered: {
                // let updatedInvoice = {
                //     status: "paid"
                // }
                invoiceModel.markAsPaid(dialogInvoiceId)
            }
        },
        Kirigami.Action {
            id:sendEmail
            text: i18n("Send Email")
            icon.name: "mail-send"
            enabled: isViewMode &&  invoiceData.status !== "sent"
            // enabled: !invoiceApi.loading
            onTriggered: {
                invoiceModel.sendToClient(dialogInvoiceId)
            }
        },
        Kirigami.Action {
            text: i18n("Generate PDF")
            icon.name: "document-export"
            visible: isViewMode
            enabled: !invoiceApi.loading
            onTriggered: {
                invoiceModel.generatePdf(dialogInvoiceId)
            }
        },
        Kirigami.Action {
            text: i18n("Update Status")
            icon.name: "document-edit"
            enabled: isViewMode && statusCombo.enabled && statusCombo.currentText !== statusMapping[invoiceData.status]
            // enabled: !invoiceApi.loading
            onTriggered: {
                let updatedInvoice = {
                    status: statusMapping[statusCombo.currentText]
                }
                invoiceModel.updateInvoice(dialogInvoiceId, updatedInvoice)
            }
        },
        Kirigami.Action {
            text: i18n("Close")
            icon.name: "dialog-close"
            onTriggered: invoiceDialog.close()
        }
    ]

    // Helper Functions
    function formatDate(dateString) {
        if (!dateString) return ""
        const date = new Date(dateString)
        return date.toLocaleDateString(Qt.locale(), "yyyy-MM-dd")
    }

    function formatCurrency(amount) {
        return Number(amount).toLocaleString(Qt.locale(), 'f', 2)
    }

    function getStatusColor(status) {
        switch(status?.toLowerCase()) {
        case "draft": return "#3498db"    // Blue
        case "sent": return "#f1c40f"     // Yellow
        case "paid": return "#2ecc71"     // Green
        case "cancelled": return "#95a5a6" // Grey
        default: return Kirigami.Theme.textColor
        }
    }

    // API Connections
    Connections {
        target: invoiceApi

        function onInvoiceReceived(invoice) {
            invoiceData = invoice
            if(invoiceData.status === "sent" || invoiceData.status === "paid") {
                statusCombo.enabled = false
            }
        }

        function onInvoiceMarkedAsPaid() {

            inlineMsg.text = i18n("Invoice paid successfully")
            inlineMsg.visible = true
            inlineMsg.type = Kirigami.MessageType.Positive
            invoiceApi.getInvoice(dialogInvoiceId) // Refresh invoice data
            invoiceModel.refresh();

        }
        function onInvoiceUpdated() {

            inlineMsg.text = i18n("Invoice updated successfully")
            inlineMsg.visible = true
            inlineMsg.type = Kirigami.MessageType.Positive
            invoiceApi.getInvoice(dialogInvoiceId) // Refresh invoice data
            invoiceModel.refresh();
        }
        function onInvoiceSent() {
            inlineMsg.text = i18n("Invoice sent successfully")
            inlineMsg.visible = true
            inlineMsg.type = Kirigami.MessageType.Positive
            invoiceApi.getInvoice(dialogInvoiceId)
            sendEmail.enable=false
            invoiceModel.refresh();

        }

        function onErrorPdfGenerated(message) {
            inlineMsg.text = message
            inlineMsg.type = Kirigami.MessageType.Error
            inlineMsg.visible = true
        }
        function onErrorInvoiceSent(message) {
            inlineMsg.text = message
            inlineMsg.type = Kirigami.MessageType.Error
            inlineMsg.visible = true
        }
        function onErrorInvoiceMarkedAsPaid(message) {
            inlineMsg.text = message
            inlineMsg.type = Kirigami.MessageType.Error
            inlineMsg.visible = true
        }
        function onErrorInvoiceUpdated(message) {
            inlineMsg.text = message
            inlineMsg.type = Kirigami.MessageType.Error
            inlineMsg.visible = true
        }
    }

    // Initialize
    onDialogInvoiceIdChanged: {
        if (dialogInvoiceId > 0) {
            invoiceApi.getInvoice(dialogInvoiceId)
        } else {
            invoiceData = {}
        }
    }
    onClosed:{


    }
}
