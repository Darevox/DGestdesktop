import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"

import "."
import com.dervox.SupplierModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Suppliers")

    padding: Kirigami.Units.largeSpacing
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    // Empty state message
    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        z: 99
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !supplierModel.loading && supplierModel.rowCount === 0
        text: searchField.text !== ""
              ? i18n("No suppliers found matching '%1'", searchField.text)
              : i18n("There are no suppliers. Please add a new supplier.")
        icon.name: "user-group-new"
        helpfulAction: searchField.text !== "" ? null : addSupplierAction
    }

    // Actions
    actions: [
        Kirigami.Action {
            id: addSupplierAction
            icon.name: "list-add-symbolic"
            text: i18n("New Supplier")
            onTriggered: {
                supplierDetailsDialog.supplierId = 0
                supplierDetailsDialog.active = true
            }
        },
        Kirigami.Action {
            icon.name: "view-filter"
            text: i18n("Filter")
            onTriggered: filterSheet.open()
        },
        Kirigami.Action {
            icon.name: "edit-delete"
            text: i18n("Delete")
            enabled: supplierModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        }
    ]

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
                text: i18n("Filtering")
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

                FormCard.FormComboBoxDelegate {
                    id: statusField
                    text: i18n("Status")
                    model: [
                        { text: i18n("All"), value: "" },
                        { text: i18n("Active"), value: "active" },
                        { text: i18n("Inactive"), value: "inactive" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    currentIndex: 0
                    onCurrentValueChanged: supplierModel.setStatus(currentValue)
                }

                FormCard.FormComboBoxDelegate {
                    id: balanceField
                    text: i18n("Balance")
                    model: [
                        { text: i18n("All"), value: "" },
                        { text: i18n("With Balance"), value: "with_balance" },
                        { text: i18n("Without Balance"), value: "without_balance" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    currentIndex: 0
                    onCurrentValueChanged: supplierModel.setBalanceFilter(currentValue)
                }
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

                FormCard.FormButtonDelegate {
                    text: i18n("Apply Filters")
                    icon.name: "view-filter"
                    onClicked: {
                        supplierModel.refresh()
                        filterSheet.close()
                    }
                }

                FormCard.FormButtonDelegate {
                    text: i18n("Clear Filters")
                    icon.name: "edit-clear-all"
                    onClicked: {
                        statusField.currentIndex = 0
                        balanceField.currentIndex = 0
                        supplierModel.refresh()
                    }
                }
            }
        }
    }

    // Top toolbar with search and filters
    header: RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        DBusyIndicator {
            running: supplierModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            placeholderText: i18n("Search suppliers...")
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: supplierModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    // Main content
    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !supplierModel.loading && supplierModel.rowCount > 0

        // Table view
        Tables.KTableView {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: supplierModel
            alternatingRows: true
            clip: true

            selectionMode: TableView.SelectionMode.SingleSelection
            selectionBehavior: TableView.SelectRows

            onCellDoubleClicked: function(row) {
                let supplierId = view.model.data(view.model.index(row, 0), SupplierRoles.IdRole)
                supplierDetailsDialog.supplierId = supplierId
                supplierDetailsDialog.active = true
            }

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Select")
                    textRole: "checked"
                    role: SupplierRoles.CheckedRole
                    width: root.width * 0.05
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: supplierModel.toggleAllSuppliersChecked()
                    }
                    itemDelegate: QQC2.CheckBox {
                        checked: modelData
                        onCheckedChanged: supplierModel.setChecked(row, checked)
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: SupplierRoles.NameRole
                    width: view.width * 0.2
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Contact Info")
                    textRole: "contact"
                    role: SupplierRoles.ContactRole
                    width: view.width * 0.40
                    itemDelegate: RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        QQC2.Label {
                            text: model.email || "-"
                            elide: Text.ElideRight
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                        }
                        QQC2.Label {
                            text: model.phone || ""
                            elide: Text.ElideRight
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                            opacity: 0.7
                        }
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: SupplierRoles.StatusRole
                    width: view.width * 0.15
                    itemDelegate: DStatusBadge {
                        text: model.status === "active" ? i18n("Active") : i18n("Inactive")
                        textColor: model.status === "active" ?
                                   Kirigami.Theme.positiveTextColor :
                                   Kirigami.Theme.neutralTextColor
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Balance")
                    textRole: "balance"
                    role: SupplierRoles.BalanceRole
                    width: root.width * 0.18
                    itemDelegate: RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: width / 2
                            color: model.balance > 1000 ? Kirigami.Theme.negativeTextColor :
                                   model.balance > 0 ? Kirigami.Theme.neutralTextColor :
                                   Kirigami.Theme.positiveTextColor

                            QQC2.ToolTip {
                                text: model.balance > 1000 ? i18n("High Balance") :
                                     model.balance > 0 ? i18n("Outstanding Balance") :
                                     i18n("Paid")
                            }
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            text: Number(model.balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                            color: model.balance > 0 ? Kirigami.Theme.negativeTextColor :
                                   model.balance < 0 ? Kirigami.Theme.positiveTextColor :
                                   Kirigami.Theme.textColor
                        }
                    }
                    headerDelegate: TableHeaderLabel {}
                }
            ]
        }
    }

    // Pagination
    footer: PaginationBar {
        id: paginationBar
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter
        currentPage: supplierModel.currentPage
        totalPages: supplierModel.totalPages
        totalItems: supplierModel.totalItems
        onPageChanged: supplierModel.loadPage(page)
    }

    // Loading skeleton
    GridLayout {
        anchors.fill: parent
        visible: supplierModel.loading
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

    // Supplier Details Dialog
    Loader {
        id: supplierDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: SupplierDetails {}
        property int supplierId: 0
        onLoaded: {
            item.dialogSupplierId = supplierId
            item.open()
        }
        Connections {
            target: supplierDetailsDialog.item
            function onClosed() {
                supplierDetailsDialog.active = false
            }
        }
    }

    // Statistics Dialog
    Loader {
        id: statisticsDialog
        active: false
        asynchronous: true
       // sourceComponent: SupplierStatisticsDialog {}
        property int dialogSupplierId: 0
        property string dialogSupplierName: ""
        onLoaded: {
            item.dialogSupplierId = dialogSupplierId
            item.dialogSupplierName = dialogSupplierName
            item.open()
        }
        Connections {
            target: statisticsDialog.item
            function onClosed() {
                statisticsDialog.active = false
            }
        }
    }

    // Delete Dialog
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Supplier")
        subtitle: i18n("Are you sure you want to delete the selected supplier(s)?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = supplierModel.getCheckedSupplierIds()
            checkedIds.forEach(supplierId => {
                supplierModel.deleteSupplier(supplierId)
            })
        }
    }

    // Notifications
    Connections {
        target: supplierApi
        function onSupplierDeleted() {
            showPassiveNotification(i18n("Supplier deleted successfully"))
            supplierModel.clearAllChecked()
        }
        function onSupplierCreated() {
            showPassiveNotification(i18n("Supplier created successfully"))
        }
        function onSupplierUpdated() {
            showPassiveNotification(i18n("Supplier updated successfully"))
        }
        function onErrorOccurred(message) {
            showPassiveNotification(message, "long", "error")
        }
    }

    Component.onCompleted: {
        supplierModel.setApi(supplierApi)
    }
}
