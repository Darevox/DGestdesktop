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

    // Status mapping with correct values
    property var statusMapping: {
        "Draft": "draft",
        "Completed": "completed",
        "Cancelled": "cancelled"
    }

    // Payment status mapping
    property var paymentStatusMapping: {
        "Unpaid": "unpaid",
        "Partial": "partial",
        "Paid": "paid"
    }

    // Email sent options
    property bool isEmailSent: invoiceData.is_email_sent || false

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
    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        visible: !invoiceApi.isLoading

        // Status badges row
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing

            DStatusBadge {
                text: invoiceData.type === "quote" ? i18n("Quote") : i18n("Invoice")
                textColor: invoiceData.type === "quote" ?
                    Kirigami.Theme.neutralTextColor :
                    Kirigami.Theme.positiveTextColor
            }

            DStatusBadge {
                text: {
                    switch(invoiceData.status) {
                        case "draft": return i18n("Draft")
                        case "completed": return i18n("Completed")
                        case "cancelled": return i18n("Cancelled")
                        default: return invoiceData.status || ""
                    }
                }
                textColor: {
                    switch(invoiceData.status) {
                        case "draft": return Kirigami.Theme.neutralTextColor
                        case "completed": return Kirigami.Theme.positiveTextColor
                        case "cancelled": return Kirigami.Theme.negativeTextColor
                        default: return Kirigami.Theme.textColor
                    }
                }
            }

            DStatusBadge {
                text: {
                    switch(invoiceData.payment_status) {
                        case "paid": return i18n("Paid")
                        case "partial": return i18n("Partial")
                        case "unpaid": return i18n("Unpaid")
                        default: return invoiceData.payment_status || ""
                    }
                }
                textColor: {
                    switch(invoiceData.payment_status) {
                        case "paid": return Kirigami.Theme.positiveTextColor
                        case "partial": return Kirigami.Theme.neutralTextColor
                        case "unpaid": return Kirigami.Theme.negativeTextColor
                        default: return Kirigami.Theme.textColor
                    }
                }
            }

            DStatusBadge {
                text: isEmailSent ? i18n("Email Sent") : i18n("Not Sent")
                textColor: isEmailSent ?
                    Kirigami.Theme.positiveTextColor :
                    Kirigami.Theme.neutralTextColor
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // Main details section
        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Layout.fillWidth: true

            // Header Section
            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15

                FormCard.FormTextDelegate {
                    text: i18n("Reference Number")
                    description: invoiceData.reference_number || ""
                    visible: description !== ""
                }

                FormCard.FormTextDelegate {
                    text: i18n("Type")
                    description: invoiceData.type === "quote" ? i18n("Quote") : i18n("Invoice")
                }

                FormCard.FormComboBoxDelegate {
                    id: statusCombo
                    text: i18n("Document Status")
                    model: ["Draft", "Completed", "Cancelled"]

                    // Only enable if document isn't cancelled and isn't a finalized document
                    enabled: isViewMode &&
                             invoiceData.status !== "cancelled" &&
                             invoiceData.payment_status !== "paid"

                    // Find the current status in our model or default to first item
                    currentIndex: {
                        let idx = -1
                        for (let i = 0; i < model.length; i++) {
                            if (statusMapping[model[i]] === invoiceData.status) {
                                idx = i
                                break
                            }
                        }
                        return idx !== -1 ? idx : 0
                    }
                }

                FormCard.FormComboBoxDelegate {
                    id: paymentStatusCombo
                    text: i18n("Payment Status")
                    model: ["Unpaid", "Partial", "Paid"]

                    // Only allow changing payment status if the document isn't cancelled
                    enabled: isViewMode && invoiceData.status !== "cancelled"

                    // Find the current payment status in our model or default to first item
                    currentIndex: {
                        let idx = -1
                        for (let i = 0; i < model.length; i++) {
                            if (paymentStatusMapping[model[i]] === invoiceData.payment_status) {
                                idx = i
                                break
                            }
                        }
                        return idx !== -1 ? idx : 0
                    }
                }
            }

            // Dates and Source Section
            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15

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
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15

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
        }

        // Payment info section (if payments exist)
        FormCard.FormCard {
            Layout.fillWidth: true
            visible: invoiceData.meta_data?.payment_methods &&
                     invoiceData.meta_data.payment_methods.length > 0

            Kirigami.Heading {
                text: i18n("Payment Information")
                level: 3
            }

            Repeater {
                model: invoiceData.meta_data?.payment_methods || []

                FormCard.FormTextDelegate {
                    text: modelData.method_name || i18n("Payment")
                    description: formatCurrency(modelData.amount || 0)
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
            id: markAsPaidAction
            text: i18n("Mark as Paid")
            icon.name: "checkbox-checked"
            // Only enable if document is not cancelled and not already paid
            enabled: isViewMode &&
                     invoiceData.status !== "cancelled" &&
                     invoiceData.payment_status !== "paid"
            onTriggered: {
                let updatedInvoice = {
                    payment_status: "paid"
                }
                invoiceModel.updateInvoice(dialogInvoiceId, updatedInvoice)
            }
        },
        Kirigami.Action {
            id: markAsEmailSentAction
            text: i18n("Mark Email as Sent")
            icon.name: "mail-mark-sent"
            // Only enable if email is not already marked as sent
            enabled: isViewMode && !isEmailSent
            onTriggered: {
                let updatedInvoice = {
                    is_email_sent: true
                }
                invoiceModel.updateInvoice(dialogInvoiceId, updatedInvoice)
            }
        },
        Kirigami.Action {
            id: sendEmailAction
            text: i18n("Send Email")
            icon.name: "mail-send"
            // Only enable if document isn't cancelled
            enabled: isViewMode &&
                     invoiceData.status !== "cancelled"
            onTriggered: {
                invoiceModel.sendToClient(dialogInvoiceId)
            }
        },
        Kirigami.Action {
            text: i18n("Generate PDF")
            icon.name: "document-export"
            visible: isViewMode
            enabled: !invoiceApi.isLoading
            onTriggered: {
                invoiceModel.generatePdf(dialogInvoiceId)
            }
        },
        Kirigami.Action {
            text: i18n("Update Status")
            icon.name: "document-edit"
            // Only enable if the combo boxes have changed from their original values
            enabled: isViewMode && (
                (statusCombo.enabled &&
                 statusMapping[statusCombo.currentText] !== invoiceData.status) ||
                (paymentStatusCombo.enabled &&
                 paymentStatusMapping[paymentStatusCombo.currentText] !== invoiceData.payment_status)
            )
            onTriggered: {
                let updatedInvoice = {}

                // Only include status in update if it's changed
                if (statusMapping[statusCombo.currentText] !== invoiceData.status) {
                    updatedInvoice.status = statusMapping[statusCombo.currentText]
                }

                // Only include payment_status in update if it's changed
                if (paymentStatusMapping[paymentStatusCombo.currentText] !== invoiceData.payment_status) {
                    updatedInvoice.payment_status = paymentStatusMapping[paymentStatusCombo.currentText]
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

    // API Connections
    Connections {
        target: invoiceApi

        function onInvoiceReceived(invoice) {
            invoiceData = invoice
            isEmailSent = invoice.is_email_sent || false
        }

        function onInvoiceMarkedAsPaid() {
            inlineMsg.text = i18n("Invoice payment status updated successfully")
            inlineMsg.visible = true
            inlineMsg.type = Kirigami.MessageType.Positive
            invoiceApi.getInvoice(dialogInvoiceId) // Refresh invoice data
            invoiceModel.refresh();
        }

        function onInvoiceMarkedAsEmailSent() {
            inlineMsg.text = i18n("Invoice marked as email sent")
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
            sendEmailAction.enabled = false
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

        function onErrorInvoiceMarkedAsEmailSent(message) {
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
}
