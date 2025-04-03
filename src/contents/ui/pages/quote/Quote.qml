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
                description: quoteModel.summary.total_sales || "0"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Amount")
                description: Number(quoteModel.summary.total_amount || 0).toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Paid")
                description: Number(quoteModel.summary.total_paid || 0).toLocaleString(Qt.locale(), 'f', 2)
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Status Breakdown")
            }

            Repeater {
                model: quoteModel.summary.sales_by_status || []
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
                model: quoteModel.summary.top_clients || []
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
                model: quoteModel.summary.top_products || []
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
                    id: typeField
                    text: i18n("Type")
                    model: [
                        { text: i18n("All"), value: "" },
                        { text: i18n("Sales"), value: "sale" },
                        { text: i18n("Quotes"), value: "quote" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    onCurrentValueChanged: quoteModel.setType(currentValue)
                }
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
                    onCurrentValueChanged: quoteModel.setStatus(currentValue)
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
                    onCurrentValueChanged: quoteModel.setPaymentStatus(currentValue)
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
                    onCurrentValueChanged: quoteModel.setClientId(currentValue)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing

                QQC2.Button {
                    text: i18n("Apply Filters")
                    icon.name: "view-filter"
                    onClicked: {
                        quoteModel.refresh()
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
                        quoteModel.refresh()
                    }
                }
            }
        }
    }

    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: i18n("New")
            onTriggered: {
                saleDialog.saleId = 0
                saleDialog.active = true
            }
        },
        Kirigami.Action {
            icon.name: "view-filter"
            text: i18n("Filter")
            onTriggered: filterSheet.open()
        },
        // Kirigami.Action {
        //     icon.name: "view-statistics"
        //     text: i18n("Summary")
        //     onTriggered: {
        //         quoteModel.getSummary()
        //         summarySheet.open()
        //     }
        // },
        Kirigami.Action {
            icon.name: "edit-delete"
            text: i18n("Delete")
            enabled: quoteModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        }
    ]

    header: RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        DBusyIndicator {
            running: quoteModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: quoteModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        visible: !quoteModel.loading && quoteModel.rowCount === 0
        text: searchField.text !== "" ?
                  i18n("No sales matching '%1'", searchField.text) :
                  i18n("No sales found")
        explanation: i18n("Create a new sale to get started")
        icon.name: "document-edit"
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !quoteModel.loading && quoteModel.rowCount > 0

        Tables.KTableView {
            id: view
            model: quoteModel
            clip: true
            alternatingRows: true
            sortOrder: quoteModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: SaleRoles.SaleDateRole
            selectionMode: TableView.SelectionMode.SingleSelection
            selectionBehavior: TableView.SelectRows

            property var nonSortableColumns: {
                return {
                    // [ ProductRoles.ProductUnitRole]: "productUnit",
                    // [ ProductRoles.MinStockLevelRole]: "minStock",

                }
            }

            onColumnClicked: function (index, headerComponent) {
                if (Object.keys(nonSortableColumns).includes(String(headerComponent.role)) ||
                        Object.values(nonSortableColumns).includes(headerComponent.textRole)) {
                    return; // Exit if column shouldn't be sortable
                }
                if (view.sortRole !== headerComponent.role) {

                    quoteModel.sortField=headerComponent.textRole
                    quoteModel.sortDirection="asc"

                    view.sortRole = headerComponent.role;

                    view.sortOrder = Qt.AscendingOrder;

                } else {
                    //view.sortOrder = view.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder
                    // view.sortOrder = view.sortOrder === "asc" ? "desc": "asc"
                    quoteModel.sortDirection=view.sortOrder === Qt.AscendingOrder ? "desc" : "asc"
                    view.sortOrder = quoteModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder



                }

                view.model.sort(view.sortRole, view.sortOrder);

                // After sorting we need update selection
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
                    role: quoteModel.CheckedRole
                    width: root.width * 0.03
                    headerDelegate: QQC2.CheckBox {
                        onClicked: quoteModel.toggleAllSalesChecked()
                    }
                    itemDelegate: QQC2.CheckBox {
                        checked: modelData
                        onClicked: quoteModel.setChecked(row, checked)
                    }
                },
                // Add this to the headerComponents array in Tables.KTableView
                // Tables.HeaderComponent {
                //     title: i18nc("@title:column", "Type")
                //     textRole: "type"
                //     role: SaleRoles.TypeRole
                //     width: root.width * 0.10

                //     itemDelegate: DStatusBadge {
                //         text: {
                //             switch(modelData) {
                //                 case "quote": return i18n("Quote")
                //                 case "sale": return i18n("Sale")
                //                 default: return i18n("Sale") // Default for backward compatibility
                //             }
                //         }
                //         textColor: {
                //             switch(modelData) {
                //                 case "quote": return  Kirigami.Theme.neutralTextColor// blue
                //                 case "sale": return  Kirigami.Theme.positiveTextColor  // green
                //                 default: return Kirigami.Theme.positiveTextColor    // green
                //             }
                //         }
                //     }
                //     headerDelegate: TableHeaderLabel {}
                // },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Reference")
                    textRole: "reference_number"
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
                    width: root.width * 0.15

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
                    textRole: "payment_status"
                    role: SaleRoles.PaymentStatusRole
                    width: root.width * 0.15

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
                    textRole: "total_amount"
                    role: SaleRoles.TotalAmountRole
                    width: root.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: Number(modelData || 0).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Paid")
                    textRole: "paid_amount"
                    role: SaleRoles.PaidAmountRole
                    width: root.width * 0.10
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
                    title: i18nc("@title:column", "Sale Date")
                    textRole: "sale_date"
                    role: SaleRoles.SaleDateRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: {
                            // Assuming createdAt is a valid date string or timestamp
                            let date = new Date(modelData);
                            return Qt.formatDateTime(date, "yyyy-MM-dd");
                        }
                        horizontalAlignment: Text.AlignRight
                        // font.family: "Monospace"
                    }
                    headerDelegate: TableHeaderLabel {}
                }
                // Tables.HeaderComponent {
                //     title: i18nc("@title:column", "Created At")
                //     textRole: "createdAt"
                //     role: SaleRoles.CreatedAtRole
                //     width: root.width * 0.15
                //     itemDelegate: QQC2.Label {
                //         text: {
                //             // Assuming createdAt is a valid date string or timestamp
                //             let date = new Date(modelData);
                //             return Qt.formatDateTime(date, "yyyy-MM-dd HH:mm:ss");
                //         }
                //         horizontalAlignment: Text.AlignRight
                //         font.family: "Monospace"
                //     }
                //     headerDelegate: TableHeaderLabel {}
                // }
            ]

            onCellDoubleClicked: function(row) {
                let sale = quoteModel.getSale(row)
                saleDialog.saleId = sale.id
                saleDialog.active = true
            }
        }
    }


    // Loading skeleton
    GridLayout {
        anchors.fill: parent
        visible: quoteModel.loading
        columns: 6
        rows: 8
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.largeSpacing

        Repeater {
            model: 6 * 8
            SkeletonLoaders {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            }
        }
    }

    footer: PaginationBar {
        id: paginationBar
        currentPage: quoteModel.currentPage
        totalPages: quoteModel.totalPages
        totalItems: quoteModel.totalItems
        onPageChanged: quoteModel.loadPage(page)
    }

    Loader {
        id: saleDialog
        active: false
        asynchronous: true
        sourceComponent: QuoteDetails {}
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
            let checkedIds = quoteModel.getCheckedSaleIds()
            checkedIds.forEach(id => {
                                   quoteModel.deleteSale(id)
                               })
        }
    }

    function updateDateFilter() {
        if (startDateField.value && endDateField.value) {
            quoteModel.setDateRange(startDateField.value, endDateField.value)
        }
    }

    Component.onCompleted: {
      //  quoteModel.setType("quote")
        quoteModel.setApi(saleApi)
        clientModel.setApi(clientApi)

    }
}
