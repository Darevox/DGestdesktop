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
        visible: !cashSourceModel.loading && cashSourceModel.rowCount === 0
        text: searchField.text !== ""
              ? i18n("There are no cash sources matching '%1'", searchField.text)
              : i18n("There are no cash sources. Please add a new cash source.")
        icon.name: "money-management"

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
            running: cashSourceModel.loading
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
        visible: cashSourceModel.loading
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
        visible: !cashSourceModel.loading && cashSourceModel.rowCount > 0

        DKTableViewAbstract {
            id: view
            model: cashSourceModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder: cashSourceModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: CashSourceRoles.NameRole
            modelCheck : cashSourceModel
            onCellDoubleClicked: function(row) {
                let sourceId = view.model.data(view.model.index(row, 0), CashSourceRoles.IdRole)
                cashSourceDetailsDialog.sourceId = sourceId
                cashSourceDetailsDialog.active = true
            }

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Select")
                    textRole: "checked"
                    role: CashSourceRoles.CheckedRole
                    minimumWidth: root.width * 0.05
                    width: minimumWidth
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: cashSourceModel.toggleAllCashSourcesChecked()
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: CashSourceRoles.NameRole
                    minimumWidth: root.width * 0.20
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Type")
                    textRole: "type"
                    role: CashSourceRoles.TypeRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Balance")
                    textRole: "balance"
                    role: CashSourceRoles.BalanceRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: CashSourceRoles.StatusRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Description")
                    textRole: "description"
                    role: CashSourceRoles.DescriptionRole
                    minimumWidth: root.width * 0.30
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Initial Balance")
                    textRole: "initialBalance"
                    role: CashSourceRoles.InitialBalanceRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Current Balance")
                    textRole: "balance"
                    role: CashSourceRoles.BalanceRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
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
