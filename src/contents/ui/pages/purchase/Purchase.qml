import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."
import com.dervox.PurchaseModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Purchases")

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
            text: i18n("Purchase Summary")
            level: 2
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextDelegate {
                text: i18n("Total Purchases")
                description: purchaseModel.summary.total_purchases || "0"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Amount")
                description: Number(purchaseModel.summary.total_amount || 0).toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Paid")
                description: Number(purchaseModel.summary.total_paid || 0).toLocaleString(Qt.locale(), 'f', 2)
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true

           Kirigami.Heading {
                text: i18n("Status Breakdown")
            }

            Repeater {
                model: purchaseModel.summary.purchases_by_status || []
                delegate: FormCard.FormTextDelegate {
                    text: modelData.status
                    description: i18n("%1 purchases", modelData.count)
                }
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true

           Kirigami.Heading {
                text: i18n("Top Suppliers")
            }

            Repeater {
                model: purchaseModel.summary.top_suppliers || []
                delegate: FormCard.FormTextDelegate {
                    text: modelData.name
                    description: i18n("%1 purchases, Total: %2",
                        modelData.count,
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
                text: i18n("Filter Purchases")
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
                    onCurrentValueChanged: purchaseModel.setStatus(currentValue)
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
                    onCurrentValueChanged: purchaseModel.setPaymentStatus(currentValue)
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
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing

                QQC2.Button {
                    text: i18n("Apply Filters")
                    icon.name: "view-filter"
                    onClicked: {
                        purchaseModel.refresh()
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
                        purchaseModel.refresh()
                    }
                }
            }
        }
    }

    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: i18n("New Purchase")
            onTriggered: {
                purchaseDialog.purchaseId = 0
                purchaseDialog.active = true
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
                purchaseModel.getSummary()
                summarySheet.open()
            }
        },
        Kirigami.Action {
            icon.name: "edit-delete"
            text: i18n("Delete")
            enabled: purchaseModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        }
    ]

    header: RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        QQC2.BusyIndicator {
            running: purchaseModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: purchaseModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        visible: !purchaseModel.loading && purchaseModel.rowCount === 0
        text: searchField.text !== "" ?
                  i18n("No purchases matching '%1'", searchField.text) :
                  i18n("No purchases found")
        explanation: i18n("Create a new purchase to get started")
        icon.name: "document-edit"
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !purchaseModel.loading && purchaseModel.rowCount > 0

        Tables.KTableView {
            id: view
            model: purchaseModel
            clip: true
            alternatingRows: true
            sortOrder: purchaseModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: PurchaseRoles.PurchaseDateRole

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Reference")
                    textRole: "referenceNumber"
                    role: PurchaseRoles.ReferenceNumberRole
                    width: root.width * 0.15
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Date")
                    textRole: "purchaseDate"
                    role: PurchaseRoles.PurchaseDateRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: Qt.formatDateTime(modelData, "dd/MM/yyyy")
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Supplier")
                    textRole: "supplier"
                    role: PurchaseRoles.SupplierRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: modelData?.name || ""
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: PurchaseRoles.StatusRole
                    width: root.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        color: {
                            switch(modelData) {
                                case "completed": return Kirigami.Theme.positiveTextColor
                                case "cancelled": return Kirigami.Theme.negativeTextColor
                                default: return Kirigami.Theme.textColor
                            }
                        }
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Payment")
                    textRole: "paymentStatus"
                    role: PurchaseRoles.PaymentStatusRole
                    width: root.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        color: {
                            switch(modelData) {
                                case "paid": return Kirigami.Theme.positiveTextColor
                                case "unpaid": return Kirigami.Theme.negativeTextColor
                                case "partial": return Kirigami.Theme.neutralTextColor
                                default: return Kirigami.Theme.textColor
                            }
                        }
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Total")
                    textRole: "totalAmount"
                    role: PurchaseRoles.TotalAmountRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: Number(modelData || 0).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Paid")
                    textRole: "paidAmount"
                    role: PurchaseRoles.PaidAmountRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: Number(modelData || 0).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                    }
                }
            ]

            onCellDoubleClicked: function(row) {
                let purchase = purchaseModel.getPurchase(row)
                purchaseDialog.purchaseId = purchase.id
                purchaseDialog.active = true
            }
        }
    }

    footer: PaginationBar {
        id: paginationBar
        currentPage: purchaseModel.currentPage
        totalPages: purchaseModel.totalPages
        totalItems: purchaseModel.totalItems
        onPageChanged: purchaseModel.loadPage(page)
    }

    Loader {
        id: purchaseDialog
        active: false
        asynchronous: true
        sourceComponent: PurchaseDetails {}
        property int purchaseId: 0
        onLoaded: {
            item.dialogPurchaseId = purchaseDialog.purchaseId
            item.open()
        }

        Connections {
            target: purchaseDialog.item
            function onClosed() {
                purchaseDialog.active = false
            }
        }
    }

    // Delete confirmation dialog
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Purchase")
        subtitle: i18n("Are you sure you want to delete the selected purchase(s)?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = purchaseModel.getCheckedPurchaseIds()
            checkedIds.forEach(id => {
                purchaseModel.deletePurchase(id)
            })
        }
    }

    Component.onCompleted: {
        purchaseModel.setApi(purchaseApi)
    }
}
