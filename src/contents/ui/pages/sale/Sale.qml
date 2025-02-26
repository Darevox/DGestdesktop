// SalePage.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."
import com.dervox.SaleModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Sales")

    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    // Summary Drawer
    Kirigami.OverlaySheet {
        id: summarySheet
        header: Kirigami.Heading {
            text: i18n("Sales Summary")
            level: 2
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextDelegate {
                text: i18n("Total Sales")
                description: saleModel.summary.total_sales || "0"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Amount")
                description: Number(saleModel.summary.total_amount || 0).toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Paid")
                description: Number(saleModel.summary.total_paid || 0).toLocaleString(Qt.locale(), 'f', 2)
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Status Breakdown")
            }

            Repeater {
                model: saleModel.summary.sales_by_status || []
                delegate: FormCard.FormTextDelegate {
                    text: modelData.status
                    description: i18n("%1 sales", modelData.count)
                }
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Top Clients")
            }

            Repeater {
                model: saleModel.summary.top_clients || []
                delegate: FormCard.FormTextDelegate {
                    text: modelData.name || i18n("Anonymous")
                    description: i18n("%1 sales, Total: %2",
                                      modelData.count,
                                      Number(modelData.total_amount).toLocaleString(Qt.locale(), 'f', 2))
                }
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Top Products")
            }

            Repeater {
                model: saleModel.summary.top_products || []
                delegate: FormCard.FormTextDelegate {
                    text: modelData.name
                    description: i18n("Sold: %1, Total: %2",
                                      modelData.total_quantity,
                                      Number(modelData.total_amount).toLocaleString(Qt.locale(), 'f', 2))
                }
            }
        }
    }

    // Filter Drawer
    Kirigami.OverlayDrawer {
        id: filterSheet
        edge: Qt.RightEdge
        modal: true
        handleVisible: false
        width: Kirigami.Units.gridUnit * 30

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                text: i18n("Filter Sales")
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

                FormCard.FormComboBoxDelegate {
                    id: statusField
                    text: i18n("Status")
                    model: [
                        { text: i18n("All"), value: "" },
                        { text: i18n("Pending"), value: "pending" },
                        { text: i18n("Completed"), value: "completed" },
                        { text: i18n("Cancelled"), value: "cancelled" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    onCurrentValueChanged: saleModel.setStatus(currentValue)
                }

                FormCard.FormComboBoxDelegate {
                    id: paymentStatusField
                    text: i18n("Payment Status")
                    model: [
                        { text: i18n("All"), value: "" },
                        { text: i18n("Paid"), value: "paid" },
                        { text: i18n("Unpaid"), value: "unpaid" },
                        { text: i18n("Partial"), value: "partial" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    onCurrentValueChanged: saleModel.setPaymentStatus(currentValue)
                }

                FormCard.FormDateTimeDelegate {
                    id: startDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18n("Start Date")
                    onValueChanged: updateDateFilter()
                }

                FormCard.FormDateTimeDelegate {
                    id: endDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18n("End Date")
                    onValueChanged: updateDateFilter()
                }

                FormCard.FormComboBoxDelegate {
                    id: clientField
                    text: i18n("Client")
                    model: clientModel
                    textRole: "name"
                    valueRole: "id"
                    onCurrentValueChanged: saleModel.setClientId(currentValue)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing

                QQC2.Button {
                    text: i18n("Apply Filters")
                    icon.name: "view-filter"
                    onClicked: {
                        saleModel.refresh()
                        filterSheet.close()
                    }
                }

                QQC2.Button {
                    text: i18n("Clear Filters")
                    icon.name: "edit-clear-all"
                    onClicked: {
                        statusField.currentIndex = 0
                        paymentStatusField.currentIndex = 0
                        startDateField.value = undefined
                        endDateField.value = undefined
                        clientField.currentIndex = 0
                        saleModel.refresh()
                    }
                }
            }
        }
    }

    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: i18n("New Sale")
            onTriggered: {
                saleDialog.saleId = 0
                saleDialog.active = true
            }
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
                saleModel.getSummary()
                summarySheet.open()
            }
        },
        Kirigami.Action {
            icon.name: "edit-delete"
            text: i18n("Delete")
            enabled: saleModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        }
    ]

    header: RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

       DBusyIndicator {
            running: saleModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: saleModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        visible: !saleModel.loading && saleModel.rowCount === 0
        text: searchField.text !== "" ?
                  i18n("No sales matching '%1'", searchField.text) :
                  i18n("No sales found")
        explanation: i18n("Create a new sale to get started")
        icon.name: "document-edit"
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !saleModel.loading && saleModel.rowCount > 0

        Tables.KTableView {
            id: view
            model: saleModel
            clip: true
            alternatingRows: true
            sortOrder: saleModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: SaleRoles.SaleDateRole
            selectionMode: TableView.SelectionMode.SingleSelection
            selectionBehavior: TableView.SelectRows
            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Reference")
                    textRole: "referenceNumber"
                    role: SaleRoles.ReferenceNumberRole
                    width: root.width * 0.15
                    headerDelegate: TableHeaderLabel {}
                },

                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Client")
                    textRole: "client"
                    role: SaleRoles.ClientRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: modelData?.name || i18n("Anonymous")
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: SaleRoles.StatusRole
                    width: root.width * 0.10

                    itemDelegate: DStatusBadge {
                        text: {
                            switch(modelData) {
                                case "completed": return i18n("Completed")
                                case "cancelled": return i18n("Cancelled")
                                case "pending": return i18n("Pending")
                                default: return modelData || ""
                            }
                        }
                        textColor: {
                            switch(modelData) {
                                case "completed": return Kirigami.Theme.positiveTextColor
                                case "cancelled": return Kirigami.Theme.negativeTextColor
                                case "pending": return Kirigami.Theme.neutralTextColor
                                default: return Kirigami.Theme.textColor
                            }
                        }
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Payment")
                    textRole: "paymentStatus"
                    role: SaleRoles.PaymentStatusRole
                    width: root.width * 0.10

                    itemDelegate: DStatusBadge {
                        text: {
                            switch(modelData) {
                                case "partial": return "Partial"
                                case "unpaid": return "Unpaid"
                                case "paid": return "Paid"
                                default: return modelData || ""
                            }
                        }
                        textColor: {
                            switch(modelData) {
                                case "partial": return Kirigami.Theme.neutralTextColor
                                case "paid": return Kirigami.Theme.positiveTextColor
                                case "unpaid": return Kirigami.Theme.negativeTextColor
                                default: return Kirigami.Theme.textColor
                            }
                        }
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Total")
                    textRole: "totalAmount"
                    role: SaleRoles.TotalAmountRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: Number(modelData || 0).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Paid")
                    textRole: "paidAmount"
                    role: SaleRoles.PaidAmountRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: Number(modelData || 0).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                        color: {
                            if (model.paidAmount === 0) {
                                return Kirigami.Theme.negativeTextColor;  // Not paid
                            } else if (model.paidAmount === model.totalAmount) {
                                return Kirigami.Theme.positiveTextColor;  // Fully paid
                            } else if (model.paidAmount < model.totalAmount) {
                                return Kirigami.Theme.neutralTextColor;   // Partially paid
                            }
                            return Kirigami.Theme.textColor;  // Default color
                        }
                        font.bold: model.paidAmount > 0  // Optional: make non-zero amounts bold
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Date")
                    textRole: "saleDate"
                    role: SaleRoles.SaleDateRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: Qt.formatDateTime(modelData, "dd/MM/yyyy")
                         horizontalAlignment: Text.AlignRight
                    }
                    headerDelegate: TableHeaderLabel {}
                }

            ]

            onCellDoubleClicked: function(row) {
                let sale = saleModel.getSale(row)
                saleDialog.saleId = sale.id
                saleDialog.active = true
            }
        }
    }

    footer: PaginationBar {
        id: paginationBar
        currentPage: saleModel.currentPage
        totalPages: saleModel.totalPages
        totalItems: saleModel.totalItems
        onPageChanged: saleModel.loadPage(page)
    }

    Loader {
        id: saleDialog
        active: false
        asynchronous: true
        sourceComponent: SaleDetails {}
        property int saleId: 0
        onLoaded: {
            item.dialogSaleId = saleDialog.saleId
            item.open()
        }

        Connections {
            target: saleDialog.item
            function onClosed() {
                saleDialog.active = false
            }
        }
    }

    // Delete confirmation dialog
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Sale")
        subtitle: i18n("Are you sure you want to delete the selected sale(s)?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = saleModel.getCheckedSaleIds()
            checkedIds.forEach(id => {
                                   saleModel.deleteSale(id)
                               })
        }
    }

    function updateDateFilter() {
        if (startDateField.value && endDateField.value) {
            saleModel.setDateRange(startDateField.value, endDateField.value)
        }
    }

    Component.onCompleted: {
        saleModel.setApi(saleApi)
        clientModel.setApi(clientApi)
    }
}
