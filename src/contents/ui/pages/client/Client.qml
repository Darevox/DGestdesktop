import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"

import "."
import com.dervox.ClientModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Clients")

    padding: Kirigami.Units.largeSpacing
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    // Empty state message
    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        z: 99
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !clientModel.loading && clientModel.rowCount === 0
        text: searchField.text !== ""
              ? i18n("No clients found matching '%1'", searchField.text)
              : i18n("There are no clients. Please add a new client.")
        icon.name: "user-group-new"
        helpfulAction: searchField.text !== "" ? null : addClientAction
    }

    // Actions
    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: i18n("New Client")
            onTriggered: {
                clientDetailsDialog.clientId = 0
                clientDetailsDialog.active = true
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
            enabled: clientModel.hasCheckedItems
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
                    onCurrentValueChanged: clientModel.setStatus(currentValue)
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
                    onCurrentValueChanged: clientModel.setBalanceFilter(currentValue)
                }
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

                FormCard.FormButtonDelegate {
                    text: i18n("Apply Filters")
                   icon.name: "view-filter"
                    onClicked: {
                        clientModel.refresh()
                        filterSheet.close()
                    }
                }

                FormCard.FormButtonDelegate {
                    text: i18n("Clear Filters")
                    icon.name: "edit-clear-all"
                    onClicked: {
                        statusField.currentIndex = 0
                        balanceField.currentIndex = 0
                        clientModel.refresh()
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
            running: clientModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            placeholderText: i18n("Search clients...")
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: clientModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    // Main content
    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !clientModel.loading && clientModel.rowCount > 0

        // Table view
        Tables.KTableView  {
            id: view
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: clientModel
            alternatingRows: true
            clip: true

            selectionMode: TableView.SelectionMode.SingleSelection
            selectionBehavior: TableView.SelectRows


            onCellDoubleClicked: function(row) {
                let clientId = view.model.data(view.model.index(row, 0), ClientRoles.IdRole)
                clientDetailsDialog.clientId = clientId
                clientDetailsDialog.active = true
            }

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Select")
                    textRole: "checked"
                    role: ClientRoles.CheckedRole
                    width: root.width * 0.05
                    headerDelegate: QQC2.CheckBox {
                        onClicked: clientModel.toggleAllClientsChecked()
                    }
                    itemDelegate: QQC2.CheckBox {
                        checked: modelData
                        onClicked: clientModel.setChecked(row, checked)
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: ClientRoles.NameRole
                    width: view.width * 0.2
                   headerDelegate: TableHeaderLabel {}

                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Contact Info")
                    textRole: "contact"
                    role: ClientRoles.ContactRole
                    width: view.width * 0.40
                    itemDelegate: RowLayout {
                        spacing:  Kirigami.Units.smallSpacing
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
                    role: ClientRoles.StatusRole
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
                    role: ClientRoles.BalanceRole
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
                // ,
                //  Tables.HeaderComponent {
                //      title: i18nc("@title:column", "Actions")
                //      textRole: "actions"
                //      role: ClientRoles.ActionsRole
                //      width: view.width * 0.15
                //      itemDelegate: RowLayout {
                //          spacing: Kirigami.Units.smallSpacing

                //          QQC2.Button {
                //              icon.name: "document-edit"
                //              text: i18n("Edit")
                //              display: QQC2.AbstractButton.IconOnly
                //              QQC2.ToolTip.text: text
                //              QQC2.ToolTip.visible: hovered

                //              onClicked: {
                //                  clientDetailsDialog.clientId = model.id
                //                  clientDetailsDialog.active = true
                //              }
                //          }

                //          QQC2.Button {
                //              icon.name: "view-statistics"
                //              text: i18n("Statistics")
                //              display: QQC2.AbstractButton.IconOnly
                //              QQC2.ToolTip.text: text
                //              QQC2.ToolTip.visible: hovered
                //              onClicked: {
                //                  statisticsDialog.dialogClientId = model.id
                //                  statisticsDialog.dialogClientName = model.name
                //                  statisticsDialog.active = true
                //              }
                //          }
                //      }
                //  }
            ]
        }


    }
    // Pagination
    footer: PaginationBar {
        id: paginationBar
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignCenter
        currentPage: clientModel.currentPage
        totalPages: clientModel.totalPages
        totalItems: clientModel.totalItems
        onPageChanged: clientModel.loadPage(page)
    }
    // Loading skeleton
    GridLayout {
        anchors.fill: parent
        visible: clientModel.loading
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

    // Client Details Dialog
    Loader {
        id: clientDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: ClientDetails {}
        property int clientId: 0
        onLoaded: {
            item.dialogClientId = clientId
            item.open()
        }
        Connections {
            target: clientDetailsDialog.item
            function onClosed() {
                clientDetailsDialog.active = false
            }
        }
    }

    // Statistics Dialog
    Loader {
        id: statisticsDialog
        active: false
        asynchronous: true
        sourceComponent: ClientStatisticsDialog {}
        property int dialogClientId: 0
        property string dialogClientName: ""
        onLoaded: {
            item.dialogClientId = dialogClientId
            item.dialogClientName = dialogClientName
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
        title: i18n("Delete Client")
        subtitle: i18n("Are you sure you want to delete the selected client(s)?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = clientModel.getCheckedClientIds()
            checkedIds.forEach(clientId => {
                                   clientModel.deleteClient(clientId)
                               })
        }
    }

    // Notifications
    Connections {
        target: clientApi
        function onClientDeleted() {
            showPassiveNotification(i18n("Client deleted successfully"))
            clientModel.clearAllChecked()
        }
        function onClientCreated() {
            showPassiveNotification(i18n("Client created successfully"))
        }
        function onClientUpdated() {
            showPassiveNotification(i18n("Client updated successfully"))
        }
        function onErrorOccurred(message) {
            showPassiveNotification(message, "long", "error")
        }
    }

    Component.onCompleted: {
        clientModel.setApi(clientApi)
    }
}
