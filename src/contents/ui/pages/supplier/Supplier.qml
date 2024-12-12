import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import "../../components"
import "."
import com.dervox.SupplierModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Suppliers")

    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10
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

        helpfulAction: searchField.text !== ""
            ? null
            : Qt.createQmlObject(`
                import org.kde.kirigami as Kirigami
                Kirigami.Action {
                    icon.name: "list-add"
                    text: "Add Supplier"
                    onTriggered: {
                        supplierDetailsDialog.supplierId = 0
                        supplierDetailsDialog.active = true
                    }
                }
            `, emptyStateMessage)
    }

    // Actions
    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: "Add"
            onTriggered: {
                supplierDetailsDialog.supplierId = 0
                supplierDetailsDialog.active = true
            }
        },
        Kirigami.Action {
            icon.name: "delete"
            text: "Delete"
            enabled: supplierModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        },
        Kirigami.Action {
            icon.name: "overflow-menu"
            Kirigami.Action {
                text: "Export"
                onTriggered: showPassiveNotification("Export triggered")
            }
            Kirigami.Action {
                text: "Print"
                onTriggered: showPassiveNotification("Print triggered")
            }
        }
    ]

    // Header section with search
    header: RowLayout {
        Layout.fillWidth: true
        Item { Layout.fillWidth: true }
        QQC2.BusyIndicator {
            running: supplierModel.loading
        }
        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
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

    // Loading skeleton
    GridLayout {
        anchors.fill: parent
        visible: supplierModel.loading
        columns: 6
        rows: 8
        columnSpacing: parent.width * 0.01
        rowSpacing: parent.height * 0.02

        Repeater {
            model: 6 * 8
            SkeletonLoaders {
                Layout.preferredWidth: view.width * 0.15
                Layout.preferredHeight: 20
            }
        }
    }

    // Main table view
    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !supplierModel.loading && supplierModel.rowCount > 0

        DKTableView {
            id: view
            enabled: !supplierModel.loading
            model: supplierModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder: supplierModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: SupplierRoles.NameRole

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
                    minimumWidth: root.width * 0.04
                    width: minimumWidth
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: supplierModel.toggleAllSuppliersChecked()
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: SupplierRoles.NameRole
                    minimumWidth: root.width * 0.20
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Email")
                    textRole: "email"
                    role: SupplierRoles.EmailRole
                    minimumWidth: root.width * 0.20
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Phone")
                    textRole: "phone"
                    role: SupplierRoles.PhoneRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: SupplierRoles.StatusRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Balance")
                    textRole: "balance"
                    role: SupplierRoles.BalanceRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                }
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
        currentPage: supplierModel.currentPage
        totalPages: supplierModel.totalPages
        totalItems: supplierModel.totalItems
        onPageChanged: supplierModel.loadPage(page)
    }

    // Supplier Details Dialog
    Loader {
        id: supplierDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: SupplierDetails {}
        property int supplierId: 0
        onLoaded: {
            item.dialogSupplierId = supplierDetailsDialog.supplierId
            item.open()
        }

        Connections {
            target: supplierDetailsDialog.item
            function onClosed() {
                supplierDetailsDialog.active = false
            }
        }
    }
    // API Connections for notifications
    Connections {
        target: supplierApi
        function onSupplierDeleted() {
            applicationWindow().gnotification.showNotification("",
                "Supplier deleted successfully",
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
            supplierModel.clearAllChecked();
        }

        function onErrorSupplierDeleted(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onErrorSuppliersReceived(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onErrorSupplierCreated(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onErrorSupplierUpdated(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onSupplierCreated() {
            applicationWindow().gnotification.showNotification("",
                "Supplier created successfully",
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
        }

        function onSupplierUpdated() {
            applicationWindow().gnotification.showNotification("",
                "Supplier updated successfully",
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
        }
    }

    // Delete Dialog
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Supplier")
        subtitle: i18n("Are you sure you'd like to delete this supplier?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = supplierModel.getCheckedSupplierIds()
            checkedIds.forEach(supplierId => {
                supplierModel.deleteSupplier(supplierId)
            })
        }
    }

    Component.onCompleted: {
        supplierModel.setApi(supplierApi)
    }
}
