import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import "../../components"
import "."
import com.dervox.ClientModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Clients")

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
        visible: !clientModel.loading && clientModel.rowCount === 0
        text: searchField.text !== ""
              ? i18n("No clients found matching '%1'", searchField.text)
              : i18n("There are no clients. Please add a new client.")
        icon.name: "user-group-new"

        helpfulAction: searchField.text !== ""
            ? null
            : Qt.createQmlObject(`
                import org.kde.kirigami as Kirigami
                Kirigami.Action {
                    icon.name: "list-add"
                    text: i18n("Add Client")
                    onTriggered: {
                        clientDetailsDialog.clientId = 0
                        clientDetailsDialog.active = true
                    }
                }
            `, emptyStateMessage)
    }

    // Actions
    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: i18n("Add")
            onTriggered: {
                clientDetailsDialog.clientId = 0
                clientDetailsDialog.active = true
            }
        },
        Kirigami.Action {
            icon.name: "delete"
            text: i18n("Delete")
            enabled: clientModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        },
        Kirigami.Action {
            icon.name: "overflow-menu"
            Kirigami.Action {
                text: i18n("Export")
                onTriggered: showPassiveNotification("Export triggered")
            }
            Kirigami.Action {
                text: i18n("Print")
                onTriggered: showPassiveNotification("Print triggered")
            }
        }
    ]

    // Header section with search
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

    // Loading skeleton
    GridLayout {
        anchors.fill: parent
        visible: clientModel.loading
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
        visible: !clientModel.loading && clientModel.rowCount > 0

        DKTableView {
            id: view
            enabled: !clientModel.loading
            model: clientModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder: clientModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: ClientRoles.NameRole

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
                    minimumWidth: root.width * 0.04
                    width: minimumWidth
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: clientModel.toggleAllClientsChecked()
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: ClientRoles.NameRole
                    minimumWidth: root.width * 0.20
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Email")
                    textRole: "email"
                    role: ClientRoles.EmailRole
                    minimumWidth: root.width * 0.20
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Phone")
                    textRole: "phone"
                    role: ClientRoles.PhoneRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Status")
                    textRole: "status"
                    role: ClientRoles.StatusRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Balance")
                    textRole: "balance"
                    role: ClientRoles.BalanceRole
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
        currentPage: clientModel.currentPage
        totalPages: clientModel.totalPages
        totalItems: clientModel.totalItems
        onPageChanged: clientModel.loadPage(page)
    }

    // Client Details Dialog
    Loader {
        id: clientDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: ClientDetails {}
        property int clientId: 0
        onLoaded: {
            item.dialogClientId = clientDetailsDialog.clientId
            item.open()
        }

        Connections {
            target: clientDetailsDialog.item
            function onClosed() {
                clientDetailsDialog.active = false
            }
        }
    }

    // API Connections for notifications
    Connections {
        target: clientApi
        function onClientDeleted() {
            applicationWindow().gnotification.showNotification("",
                i18n("Client deleted successfully"),
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
            clientModel.clearAllChecked();
        }

        function onErrorClientDeleted(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onErrorClientsReceived(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onErrorClientCreated(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onErrorClientUpdated(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                message,
                Kirigami.MessageType.Error,
                "short",
                "dialog-close"
            )
        }

        function onClientCreated() {
            applicationWindow().gnotification.showNotification("",
                i18n("Client created successfully"),
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
        }

        function onClientUpdated() {
            applicationWindow().gnotification.showNotification("",
                i18n("Client updated successfully"),
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
        }
    }

    // Delete Dialog
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Client")
        subtitle: i18n("Are you sure you'd like to delete this client?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = clientModel.getCheckedClientIds()
            checkedIds.forEach(clientId => {
                clientModel.deleteClient(clientId)
            })
        }
    }

    Component.onCompleted: {
        clientModel.setApi(clientApi)
    }
}
