import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."
import com.dervox.InvoiceModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Invoices")

    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    // Filter drawer
    Kirigami.OverlayDrawer {
        id: filterSheet
        edge: Qt.RightEdge
        modal: true
        handleVisible: false
        width: Kirigami.Units.gridUnit * 30

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                text: i18n("Filter Invoices")
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

                FormCard.FormComboBoxDelegate {
                    id: statusCombo
                    text: i18n("Status")
                    model: [
                        { text: i18n("All"), value: "" },
                        { text: i18n("Draft"), value: "draft" },
                        { text: i18n("Sent"), value: "sent" },
                        { text: i18n("Paid"), value: "paid" },
                        { text: i18n("Overdue"), value: "overdue" },
                        { text: i18n("Cancelled"), value: "cancelled" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    onCurrentValueChanged: invoiceModel.setStatus(currentValue)
                }

                FormCard.FormDateTimeDelegate {
                    id: startDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18n("Start Date")
                    value: undefined
                }

                FormCard.FormDateTimeDelegate {
                    id: endDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18n("End Date")
                    value: undefined
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing

                QQC2.Button {
                    text: i18n("Apply Filters")
                    icon.name: "view-filter"
                    onClicked: {
                        invoiceModel.refresh()
                        filterSheet.close()
                    }
                }

                QQC2.Button {
                    text: i18n("Clear Filters")
                    icon.name: "edit-clear-all"
                    onClicked: {
                        statusCombo.currentIndex = 0
                        startDateField.value = undefined
                        endDateField.value = undefined
                        invoiceModel.refresh()
                    }
                }
            }
        }
    }

    // Summary overlay
    Kirigami.OverlaySheet {
        id: summarySheet
        header: Kirigami.Heading {
            text: i18n("Invoice Summary")
            level: 2
        }

        FormCard.FormCard {
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 30

            FormCard.FormTextDelegate {
                text: i18n("Total Invoices")
                description: invoiceModel.summary?.total_invoices || "0"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Amount")
                description: invoiceModel.summary?.total_amount || "0.00"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Paid")
                description: invoiceModel.summary?.total_paid || "0.00"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Outstanding")
                description: invoiceModel.summary?.total_outstanding || "0.00"
            }
        }
    }

    // Empty state message
    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        z: 99
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !invoiceModel.loading && invoiceModel.rowCount === 0
        text: {
            if (statusCombo.currentValue && searchField.text !== "") {
                icon.name = "document-edit"
                return i18n("There are no %1 invoices matching '%2'",
                            statusCombo.currentValue,
                            searchField.text)
            }
            if (statusCombo.currentValue) {
                icon.name = "document-edit"
                return i18n("There are no %1 invoices", statusCombo.currentValue)
            }
            if (searchField.text !== "") {
                icon.name = "search-symbolic"
                return i18n("There are no invoices matching '%1'", searchField.text)
            }
            return i18n("There are no invoices. Please create a new invoice.")
        }
        icon.name: "document-edit"

        helpfulAction: (statusCombo.currentValue || searchField.text !== "")
                       ? null
                       : Qt.createQmlObject(`
                                            import org.kde.kirigami as Kirigami
                                            Kirigami.Action {
                                            icon.name: "list-add"
                                            text: "Create Invoice"
                                            onTriggered: {
                                            invoiceDetailsDialog.invoiceId = 0
                                            invoiceDetailsDialog.active = true
                                            }
                                            }
                                            `, emptyStateMessage)
    }

    // Page actions
    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: i18n("Create")
            onTriggered: {
                invoiceDetailsDialog.invoiceId = 0
                invoiceDetailsDialog.active = true
            }
        },
        Kirigami.Action {
            icon.name: "delete"
            text: i18n("Delete")
            enabled: invoiceModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        },
        Kirigami.Action {
            icon.name: "filter"
            text: i18n("Filter")
            onTriggered: filterSheet.open()
        },
        Kirigami.Action {
            icon.name: "view-statistics"
            text: i18n("Summary")
            onTriggered: {
                invoiceModel.getSummary()
                summarySheet.open()
            }
        }
    ]

    // Header with search
    header: RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        QQC2.BusyIndicator {
            running: invoiceModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: invoiceModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    // Main content - Invoice table
    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !invoiceModel.loading && invoiceModel.rowCount > 0

        Tables.KTableView {
            id: view
            model: invoiceModel
            clip: true
            alternatingRows: true
            sortOrder: invoiceModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: InvoiceRoles.IssueDateRole  // Updated from InvoiceDateRole
            onCellDoubleClicked: function(row) {
                let invoiceId = view.model.data(view.model.index(row, 0), InvoiceRoles.IdRole)
                invoiceDetailsDialog.invoiceId = invoiceId
                invoiceDetailsDialog.active = true
            }
            property var nonSortableColumns: {
                return {
                    [ InvoiceRoles.ReferenceNumberRole]: "referenceNumber",
                    [InvoiceRoles.CheckedRole]: "checked",
                    [InvoiceRoles.InvoiceableTypeRole]: "invoiceableType",
                    [ InvoiceRoles.StatusRole]: "status",
                    [  InvoiceRoles.TotalAmountRole]: "totalAmount",
                }
            }

            // Modified onColumnClicked function
            onColumnClicked: function (index, headerComponent) {
                // Check if the column is sortable
                if (Object.keys(nonSortableColumns).includes(String(headerComponent.role)) ||
                        Object.values(nonSortableColumns).includes(headerComponent.textRole)) {
                    return; // Exit if column shouldn't be sortable
                }

                if (view.sortRole !== headerComponent.role) {
                    invoiceModel.sortField = headerComponent.textRole
                    invoiceModel.sortDirection = "asc"
                    view.sortRole = headerComponent.role;
                    view.sortOrder = Qt.AscendingOrder;
                } else {
                    invoiceModel.sortDirection = view.sortOrder === Qt.AscendingOrder ? "desc" : "asc"
                    view.sortOrder = invoiceModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
                }

                view.model.sort(view.sortRole, view.sortOrder);
                __resetSelection();
            }
            function __resetSelection() {
                // NOTE: Making a forced copy of the list
                let selectedIndexes = Array(...view.selectionModel.selectedIndexes)

                let currentRow = view.selectionModel.currentIndex.row;
                let currentColumn = view.selectionModel.currentIndex.column;

                view.selectionModel.clear();
                for (let i in selectedIndexes) {
                    view.selectionModel.select(selectedIndexes[i], ItemSelectionModel.Select);
                }

                view.selectionModel.setCurrentIndex(view.model.index(currentRow, currentColumn), ItemSelectionModel.Select);
            }
            headerComponents: [

                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Select")
                    textRole: "checked"
                    role: InvoiceRoles.CheckedRole
                    width: root.width * 0.03
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: invoiceModel.toggleAllInvoicesChecked()
                    }
                    itemDelegate: QQC2.CheckBox {
                        checked: modelData
                        onCheckedChanged: invoiceModel.setChecked(row, checked)
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Reference")
                    textRole: "referenceNumber"
                    role: InvoiceRoles.ReferenceNumberRole
                    width: root.width * 0.15
                },

                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Invoiceable")
                    textRole: "invoiceableType"
                    role: InvoiceRoles.InvoiceableTypeRole
                    width: root.width * 0.16
                    itemDelegate: QQC2.Label {
                        text: modelData + " #" + model.invoiceableId
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: InvoiceRoles.StatusRole
                    width: root.width * 0.10
                    itemDelegate: DStatusBadge {
                        text: {
                            switch(modelData) {
                                case "draft": return "Draft"
                                case "sent": return "Sent"
                                case "paid": return "Paid"
                                case "overdue": return "Overdue"
                                case "cancelled": return "Cancelled"
                                default: return Kirigami.Theme.textColor
                            }
                        }
                        textColor: {
                            switch(modelData) {
                                case "draft": return Kirigami.Theme.neutralTextColor
                                case "sent": return Kirigami.Theme.positiveTextColor
                                case "paid": return Kirigami.Theme.positiveTextColor
                                case "overdue": return Kirigami.Theme.neutralTextColor
                                case "cancelled": return Kirigami.Theme.negativeTextColor
                                default: return Kirigami.Theme.textColor
                            }
                        }
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Total")
                    textRole: "totalAmount"
                    role: InvoiceRoles.TotalAmountRole
                    width: root.width * 0.12
                    itemDelegate: QQC2.Label {
                        text: Number(modelData).toLocaleString(Qt.locale(), 'f', 2)
                        color: Number(modelData) >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        font.bold : true
                        horizontalAlignment: Text.AlignRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Date")
                    textRole: "issueDate"
                    role: InvoiceRoles.IssueDateRole
                    width: root.width * 0.40
                    itemDelegate: QQC2.Label {
                        text: Qt.formatDateTime(modelData, "dd/MM/yyyy")
                        horizontalAlignment: Text.AlignRight

                    }
                }
                // Tables.HeaderComponent {
                //     title: i18nc("@title:column", "Actions")
                //     width: root.width * 0.15
                //     itemDelegate: RowLayout {
                //         anchors.fill : parent
                //         QQC2.Button {
                //             icon.name: "document-view"
                //             text: i18n("View")
                //             enabled: !invoiceModel.loading
                //              Layout.alignment: Qt.AlignTop
                //             onClicked: {
                //                 let row = model.row
                //                 let invoiceId = view.model.data(view.model.index(row, 0), InvoiceRoles.IdRole)
                //                 invoiceModel.generatePdf(invoiceId)
                //             }
                //         }
                //         QQC2.ToolButton {
                //             icon.name: "mail-sent"
                //             text: i18n("Send")
                //             visible: modelData.status !== "sent"
                //              Layout.alignment: Qt.AlignTop
                //             onClicked: {
                //                 let row = model.row
                //                 let invoiceId = view.model.data(view.model.index(row, 0), InvoiceRoles.IdRole)
                //                 invoiceModel.sendToClient(invoiceId)
                //             }
                //         }
                //     }
                // }
            ]
        }
    }

    // Pagination
    footer: PaginationBar {
        id: paginationBar
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        currentPage: invoiceModel.currentPage
        totalPages: invoiceModel.totalPages
        totalItems: invoiceModel.totalItems
        onPageChanged: invoiceModel.loadPage(page)
    }

    // Delete confirmation dialog
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Invoice")
        subtitle: i18n("Are you sure you'd like to delete this invoice?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            let checkedIds = invoiceModel.getCheckedInvoiceIds();
            checkedIds.forEach(invoiceId => {
                                   invoiceModel.deleteInvoice(invoiceId);
                               });
        }
    }

    // Invoice details dialog loader
    Loader {
        id: invoiceDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: InvoiceDetails{}
        property int invoiceId: 0
        onLoaded: {
            item.dialogInvoiceId = invoiceDetailsDialog.invoiceId
            item.open()
        }

        Connections {
            target: invoiceDetailsDialog.item
            function onClosed() {
                invoiceDetailsDialog.active = false
            }
        }
    }
    Connections {
        target: invoiceApi
        function onInvoiceDeleted() {
            applicationWindow().gnotification.showNotification(
                        "",
                        "Invoice deleted successfully",
                        Kirigami.MessageType.Positive,
                        "short",
                        "dialog-close"
                        )
            invoiceModel.clearAllChecked();
        }

        function onErrorInvoicesReceived(message, status, details) {
            applicationWindow().gnotification.showNotification(
                        "",
                        message,
                        Kirigami.MessageType.Error,
                        "short",
                        "dialog-close"
                        )
        }
    }
    ViewPdfDialog {
        id: pdfViewer
    }
    Connections {
        target: invoiceApi
        function onPdfGenerated(url) {
            pdfViewer.pdfUrl = url
            console.log("url : ", url)
            pdfViewer.open()
        }

        function onErrorPdfGenerated(message, status, details) {
            applicationWindow().showPassiveNotification(
                        i18n("Error generating PDF: %1", message),
                        "long"
                        )
        }
    }
    Component.onCompleted: {
        invoiceModel.setApi(invoiceApi)
    }
}
