import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import "../../components"
import "."
import com.dervox.CashSourceModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Cash Sources")

    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        z: 99
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !cashSourceApi.isLoading && cashSourceModel.rowCount === 0
        text: searchField.text !== ""
              ? i18n("There are no cash sources matching '%1'", searchField.text)
              : i18n("There are no cash sources. Please add a new cash source.")
        icon.name: searchField.text !== "" ?  "search-symbolic" : "view-financial-account-cash"

        helpfulAction: searchField.text !== ""
                       ? null
                       : Qt.createQmlObject(`
                                            import org.kde.kirigami as Kirigami
                                            Kirigami.Action {
                                            icon.name: "list-add"
                                            text: "Add Cash Source"
                                            onTriggered: {
                                            cashSourceDetailsDialog.sourceId = 0
                                            cashSourceDetailsDialog.active = true
                                            }
                                            }
                                            `, emptyStateMessage)
    }

    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: "Add"
            onTriggered: {
                cashSourceDetailsDialog.sourceId = 0
                cashSourceDetailsDialog.active = true
            }
        },
        Kirigami.Action {
            icon.name: "delete"
            text: "Delete"
            enabled: cashSourceModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        },
        Kirigami.Action {
            icon.name: "overflow-menu"
            Kirigami.Action {
                text: "Transfer Money"
                icon.name: "transfer"
                enabled: cashSourceModel.hasCheckedItems
                onTriggered: {
                    let sourceData = cashSourceModel.getFirstCheckedSource()
                    if (sourceData.id) {
                        transferDialog.sourceId = sourceData.id
                        transferDialog.sourceName = sourceData.name
                        transferDialog.sourceBalance = sourceData.balance
                        transferDialog.open()
                    }
                }
            }

            Kirigami.Action {
                text: "Print Report"
                icon.name: "document-print"
                onTriggered: showPassiveNotification("Print functionality not implemented")
            }
        }
    ]

    header: RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        QQC2.BusyIndicator {
            running: cashSourceApi.isLoading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: cashSourceModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    GridLayout {
        anchors.fill: parent
        visible: cashSourceApi.isLoading
        columns: 6
        rows: 8
        columnSpacing: parent.width * 0.01
        rowSpacing: parent.height * 0.02

        Repeater {
            model: 6 * 8
            SkeletonLoaders {
                property int rowIndex: Math.floor(index / 6)
                property int columnIndex: index % 6

                Layout.preferredWidth: view.width * (columnIndex === 0 ? 0.05 :
                                                                         columnIndex === 1 ? 0.20 :
                                                                                             columnIndex === 2 ? 0.15 :
                                                                                                                 columnIndex === 3 ? 0.15 :
                                                                                                                                     columnIndex === 4 ? 0.15 : 0.30)
                Layout.preferredHeight: 20
            }
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !cashSourceApi.isLoading && cashSourceModel.rowCount > 0

                Tables.KTableView {
            id: view
            model: cashSourceModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder: cashSourceModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: CashSourceRoles.NameRole
           // modelCheck : cashSourceModel
            property var nonSortableColumns: {
                return {
                    [CashSourceRoles.InitialBalanceRole]: "initialBalance",
                    [CashSourceRoles.CheckedRole]: "checked",
                    // Add more as needed
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
                    cashSourceModel.sortField = headerComponent.textRole
                    cashSourceModel.sortDirection = "asc"
                    view.sortRole = headerComponent.role;
                    view.sortOrder = Qt.AscendingOrder;
                } else {
                    cashSourceModel.sortDirection = view.sortOrder === Qt.AscendingOrder ? "desc" : "asc"
                    view.sortOrder = cashSourceModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
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

            onCellDoubleClicked: function(row) {
                let sourceId = view.model.data(view.model.index(row, 0), CashSourceRoles.IdRole)
                cashSourceDetailsDialog.sourceId = sourceId
                cashSourceDetailsDialog.active = true
            }
            property  int  columnWidth :( root.width -  (root.width * 0.05) )/ 6.2
            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Select")
                    textRole: "checked"
                    role: CashSourceRoles.CheckedRole
                    width: root.width * 0.05
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: cashSourceModel.toggleAllCashSourcesChecked()
                    }
                    itemDelegate: QQC2.CheckBox {
                        checked: modelData
                        onCheckedChanged: modelCheck.setChecked(row, checked)
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: CashSourceRoles.NameRole
                    width: view.columnWidth
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        width: view.columnWidth - 20
                        elide: Text.ElideRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Type")
                    textRole: "type"
                    role: CashSourceRoles.TypeRole
                    width: view.columnWidth
                    itemDelegate: QQC2.Label {
                        text: {
                            switch(modelData) {
                                case "bank": return i18n("Bank")
                                case "cash": return i18n("Cash")
                                default: return modelData || ""
                            }
                        }
                        width: view.columnWidth - 20
                        elide: Text.ElideRight
                        color: Kirigami.Theme.textColor
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Balance")
                    textRole: "balance"
                    role: CashSourceRoles.BalanceRole
                    width: view.columnWidth
                    itemDelegate: QQC2.Label {
                        text: Number(modelData).toLocaleString(Qt.locale(), 'f', 2)
                        //  horizontalAlignment: Text.AlignRight
                        font.bold : true
                        color: Number(modelData) >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                        width: view.columnWidth - 20
                        elide: Text.ElideRight
                          horizontalAlignment: Text.AlignRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: CashSourceRoles.StatusRole
                    width: view.columnWidth
                    itemDelegate: DStatusBadge {
                        width: view.columnWidth
                        height: parent.height
                        text: {
                            switch(modelData) {
                                case "active":
                                return i18n("Active")
                                case "inactive":
                                return i18n("Inactive")
                                case "pending":
                                return i18n("Pending")
                                default:
                                return modelData || ""
                            }
                        }
                        textColor: {
                            switch(modelData) {
                                case "active":
                                return Kirigami.Theme.positiveTextColor
                                case "inactive":
                                return Kirigami.Theme.negativeTextColor
                                case "pending":
                                return Kirigami.Theme.neutralTextColor
                                default:
                                return Kirigami.Theme.textColor
                            }
                        }
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Description")
                    textRole: "description"
                    role: CashSourceRoles.DescriptionRole
                    width: view.columnWidth
                    itemDelegate: QQC2.Label {
                        width: view.columnWidth - 20
                        text: modelData || ""
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        maximumLineCount: 1
                        clip: true
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Initial Balance")
                    textRole: "initialBalance"
                    role: CashSourceRoles.InitialBalanceRole
                    width: view.columnWidth
                    itemDelegate: QQC2.Label {
                        text: Number(modelData).toLocaleString(Qt.locale(), 'f', 2)
                        //   horizontalAlignment: Text.AlignRight
                        font.bold : true
                        width: view.columnWidth - 20
                        elide: Text.ElideRight
                        color: Number(modelData) >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                          horizontalAlignment: Text.AlignRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Current Balance")
                    textRole: "balance"
                    role: CashSourceRoles.BalanceRole
                    width: view.columnWidth
                    itemDelegate: QQC2.Label {
                        text: Number(modelData).toLocaleString(Qt.locale(), 'f', 2)
                        //  horizontalAlignment: Text.AlignRight
                        font.bold : true
                        width: view.columnWidth - 20
                        elide: Text.ElideRight
                        color: Number(modelData) >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                    }
                }
            ]
        }
    }

    footer: PaginationBar {
        id: paginationBar
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        currentPage: cashSourceModel.currentPage
        totalPages: cashSourceModel.totalPages
        totalItems: cashSourceModel.totalItems
        onPageChanged: cashSourceModel.loadPage(page)
    }

    Loader {
        id: cashSourceDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: CashSourceDetails {}
        property int sourceId: 0
        onLoaded: {
            item.dialogSourceId = cashSourceDetailsDialog.sourceId
            item.open()
        }

        Connections {
            target: cashSourceDetailsDialog.item
            function onClosed() {
                cashSourceDetailsDialog.active = false
            }
        }
    }

    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Cash Source")
        subtitle: i18n("Are you sure you'd like to delete the selected cash source(s)?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = cashSourceModel.getCheckedCashSourceIds()
            checkedIds.forEach(sourceId => {
                                   cashSourceModel.deleteCashSource(sourceId)
                               })
        }
    }
    Connections {
        target: cashSourceApi
        // function cashSourceDeleted(){
        //     applicationWindow().gnotification.showNotification("",
        //                                                        "Product  Deleted successfully", // message
        //                                                        Kirigami.MessageType.Positive, // message type
        //                                                        "short",
        //                                                        "dialog-close"
        //                                                        )
        //     cashSourceModel.clearAllChecked();

        // }
        function onErrorCashSourcesReceived(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                                                               message, // message
                                                               Kirigami.MessageType.Error, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )

        }
    }
    TransferDialog {
        id: transferDialog
        onTransferAccepted: function(sourceId, destinationId, amount, notes) {
            let transferData = {
                sourceId: sourceId,
                destinationId: destinationId,
                amount: amount,
                notes: notes
            }
            cashSourceModel.transfer(transferData)
        }
    }

    Component.onCompleted: {
        cashSourceModel.setApi(cashSourceApi)
    }
}
