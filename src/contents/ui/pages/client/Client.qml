import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import "../../components"
import Qt5Compat.GraphicalEffects
import "."
import com.dervox.ClientModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Clients")

    padding: Kirigami.Units.largeSpacing
    Kirigami.Theme.colorSet: Kirigami.Theme.View
   // globalToolBarStyle : Kirigami.ApplicationHeaderStyle.None

    Kirigami.Theme.inherit: false
    // Properties for sorting and responsive layout
    property string sortRole: ClientRoles.NameRole
    property int sortOrder: Qt.AscendingOrder
    property bool isWideScreen: width > Kirigami.Units.gridUnit * 50
    property bool isNarrowScreen: width < Kirigami.Units.gridUnit * 35
    // Property to track if we're in multi-select mode
    property bool multiSelectMode: false
    // background: Rectangle {
    //     color: Qt.darker(Kirigami.Theme.backgroundColor, 1.2)
    //     border.width: 0
    //     radius: Kirigami.Units.smallSpacing
    // }
    // header : Item {
    //     height: headerLayout.implicitHeight

    //     // Background rectangle that uses Kirigami theme colors
    //     Rectangle {
    //             id: headerBackground
    //             anchors.fill: parent
    //             // Use the Header color set for the proper header styling
    //             Kirigami.Theme.inherit: false  // Important! Prevents inheriting color set
    //             Kirigami.Theme.colorSet: Kirigami.Theme.View
    //             color: Kirigami.Theme.backgroundColor
    //         }

    //     RowLayout{
    //         id:headerLayout
    //         height:  Kirigami.Units.smallSpacing * 6
    //         width:parent.width
    //         Layout.alignment: Qt.AlignHCenter || Qt.AlignVCenter

    //         Kirigami.Heading{
    //             Layout.alignment: Qt.AlignVCenter
    //             text:root.title
    //             Layout.leftMargin: Kirigami.Units.smallSpacing * 2

    //         }
    //         Kirigami.ActionToolBar {

    //             alignment: Qt.AlignRight || Qt.AlignVCenter



    //             actions: [
    //                 Kirigami.Action {
    //                     text: "Search"
    //                     icon.name: "search"
    //                     visible: !clientModel.hasCheckedItems
    //                     displayComponent:
    //                     Kirigami.SearchField {
    //                         id: searchField
    //                         Layout.topMargin: Kirigami.Units.smallSpacing
    //                         Layout.bottomMargin: Kirigami.Units.smallSpacing
    //                         //  Layout.fillHeight: true
    //                         Layout.fillWidth: true

    //                         placeholderText: i18n("Search clients...")
    //                         Timer {
    //                             id: searchDelayTimer
    //                             interval: 700
    //                             repeat: false
    //                             onTriggered: clientModel.searchQuery = searchField.text
    //                         }
    //                         onTextChanged: searchDelayTimer.restart()
    //                     }


    //                     //    displayHint: Kirigami.DisplayHints.KeepVisible
    //                 },
    //                 Kirigami.Action {
    //                     icon.name: "list-add-symbolic"
    //                     text: i18n("New Client")
    //                     displayHint: Kirigami.DisplayHint.IconOnly

    //                     onTriggered: {
    //                         clientDetailsDialog.clientId = 0
    //                         clientDetailsDialog.active = true
    //                     }

    //                 },
    //                 Kirigami.Action {
    //                     icon.name: "edit-delete"
    //                     displayHint: Kirigami.DisplayHint.IconOnly

    //                     text: i18n("Delete")
    //                     visible: clientModel.hasCheckedItems
    //                     onTriggered: deleteDialog.open()
    //                 },
    //                 Kirigami.Action {
    //                     id: sortMenu
    //                     icon.name: "view-sort"
    //                     displayHint: Kirigami.DisplayHint.IconOnly
    //                     text: i18n("Sort")
    //                     visible : !isWideScreen
    //                     Kirigami.Action {
    //                         id: sortNameAsc
    //                         text: i18n("Name (A-Z)")
    //                         checkable: true
    //                         checked:true // root.sortRole === ClientRoles.NameRole && root.sortOrder === Qt.AscendingOrder
    //                         onTriggered: {
    //                             // Save current view state
    //                             let currentScreenMode = isWideScreen

    //                             // Uncheck all other sorting options manually
    //                             sortNameDesc.checked = false
    //                             sortBalanceAsc.checked = false
    //                             sortBalanceDesc.checked = false
    //                             sortStatus.checked = false

    //                             // Check this option
    //                             sortNameAsc.checked = true

    //                             // Apply sorting
    //                             root.sortRole = ClientRoles.NameRole
    //                             root.sortOrder = Qt.AscendingOrder
    //                             clientModel.sortField = "name"
    //                             clientModel.sortDirection = "asc"
    //                             clientModel.sort(ClientRoles.NameRole, Qt.AscendingOrder)

    //                             // Restore view state if changed
    //                             if (isWideScreen !== currentScreenMode) {
    //                                 isWideScreen = currentScreenMode
    //                             }
    //                         }
    //                     }

    //                     Kirigami.Action {
    //                         id: sortNameDesc
    //                         text: i18n("Name (Z-A)")
    //                         checkable: true
    //                         checked: sortRole === ClientRoles.NameRole && sortOrder === Qt.DescendingOrder
    //                         onTriggered: {
    //                             // Save current view state
    //                             let currentScreenMode = isWideScreen

    //                             // Uncheck all other sorting options manually
    //                             sortNameAsc.checked = false
    //                             sortBalanceAsc.checked = false
    //                             sortBalanceDesc.checked = false
    //                             sortStatus.checked = false

    //                             // Check this option
    //                             sortNameDesc.checked = true

    //                             // Apply sorting
    //                             root.sortRole = ClientRoles.NameRole
    //                             root.sortOrder = Qt.DescendingOrder
    //                             clientModel.sortField = "name"
    //                             clientModel.sortDirection = "desc"
    //                             clientModel.sort(ClientRoles.NameRole, Qt.DescendingOrder)

    //                             // Restore view state if changed
    //                             if (isWideScreen !== currentScreenMode) {
    //                                 isWideScreen = currentScreenMode
    //                             }
    //                         }
    //                     }

    //                     Kirigami.Action {
    //                         id: sortBalanceAsc
    //                         text: i18n("Balance (Low to High)")
    //                         checkable: true
    //                         checked: sortRole === ClientRoles.BalanceRole && sortOrder === Qt.AscendingOrder
    //                         onTriggered: {
    //                             // Save current view state
    //                             let currentScreenMode = isWideScreen

    //                             // Uncheck all other sorting options manually
    //                             sortNameAsc.checked = false
    //                             sortNameDesc.checked = false
    //                             sortBalanceDesc.checked = false
    //                             sortStatus.checked = false

    //                             // Check this option
    //                             sortBalanceAsc.checked = true

    //                             // Apply sorting
    //                             root.sortRole = ClientRoles.BalanceRole
    //                             root.sortOrder = Qt.AscendingOrder
    //                             clientModel.sortField = "balance"
    //                             clientModel.sortDirection = "asc"
    //                             clientModel.sort(ClientRoles.BalanceRole, Qt.AscendingOrder)

    //                             // Restore view state if changed
    //                             if (isWideScreen !== currentScreenMode) {
    //                                 isWideScreen = currentScreenMode
    //                             }
    //                         }
    //                     }

    //                     Kirigami.Action {
    //                         id: sortBalanceDesc
    //                         text: i18n("Balance (High to Low)")
    //                         checkable: true
    //                         checked: sortRole === ClientRoles.BalanceRole && sortOrder === Qt.DescendingOrder
    //                         onTriggered: {
    //                             // Save current view state
    //                             let currentScreenMode = isWideScreen

    //                             // Uncheck all other sorting options manually
    //                             sortNameAsc.checked = false
    //                             sortNameDesc.checked = false
    //                             sortBalanceAsc.checked = false
    //                             sortStatus.checked = false

    //                             // Check this option
    //                             sortBalanceDesc.checked = true

    //                             // Apply sorting
    //                             root.sortRole = ClientRoles.BalanceRole
    //                             root.sortOrder = Qt.DescendingOrder
    //                             clientModel.sortField = "balance"
    //                             clientModel.sortDirection = "desc"
    //                             clientModel.sort(ClientRoles.BalanceRole, Qt.DescendingOrder)

    //                             // Restore view state if changed
    //                             if (isWideScreen !== currentScreenMode) {
    //                                 isWideScreen = currentScreenMode
    //                             }
    //                         }
    //                     }

    //                     Kirigami.Action {
    //                         id: sortStatus
    //                         text: i18n("Status")
    //                         checkable: true
    //                         checked: sortRole === ClientRoles.StatusRole
    //                         onTriggered: {
    //                             // Save current view state
    //                             let currentScreenMode = isWideScreen

    //                             // Uncheck all other sorting options manually
    //                             sortNameAsc.checked = false
    //                             sortNameDesc.checked = false
    //                             sortBalanceAsc.checked = false
    //                             sortBalanceDesc.checked = false

    //                             // Check this option
    //                             sortStatus.checked = true

    //                             // Apply sorting
    //                             root.sortRole = ClientRoles.StatusRole
    //                             root.sortOrder = Qt.AscendingOrder
    //                             clientModel.sortField = "status"
    //                             clientModel.sortDirection = "asc"
    //                             clientModel.sort(ClientRoles.StatusRole, Qt.AscendingOrder)

    //                             // Restore view state if changed
    //                             if (isWideScreen !== currentScreenMode) {
    //                                 isWideScreen = currentScreenMode
    //                             }
    //                         }
    //                     }
    //                 },



    //                 Kirigami.Action {
    //                     icon.name: isWideScreen ? "view-list-details" : "table"
    //                     displayHint: Kirigami.DisplayHint.IconOnly
    //                     text: isWideScreen ? i18n("List View") : i18n("Table View")
    //                     onTriggered: isWideScreen = !isWideScreen
    //                 }
    //             ]

    //         }
    //     }
    // }
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

    actions: [
        // Kirigami.Action {
        //     text: "Search"
        //     icon.name: "search"
        //     displayComponent:
        //     Kirigami.SearchField {
        //         id: searchField
        //         Layout.topMargin: Kirigami.Units.smallSpacing
        //         Layout.bottomMargin: Kirigami.Units.smallSpacing
        //         //  Layout.fillHeight: true
        //         Layout.fillWidth: true
        //         placeholderText: i18n("Search clients...")
        //         Timer {
        //             id: searchDelayTimer
        //             interval: 700
        //             repeat: false
        //             onTriggered: clientModel.searchQuery = searchField.text
        //         }
        //         onTextChanged: searchDelayTimer.restart()
        //     }
        // },

        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text: i18n("New Client")
           // displayHint: Kirigami.DisplayHint.IconOnly
            onTriggered: {
                clientDetailsDialog.clientId = 0
                clientDetailsDialog.active = true
            }
        },
        Kirigami.Action {
            icon.name: "edit-delete"
            //displayHint: Kirigami.DisplayHint.IconOnly
            text: i18n("Delete")
            enabled: clientModel.hasCheckedItems
            onTriggered: deleteDialog.open()
        },
        Kirigami.Action {
            id: sortMenu
            icon.name: "view-sort"
            displayHint: Kirigami.DisplayHint.IconOnly
            text: i18n("Sort")
            visible : !isWideScreen
            Kirigami.Action {
                id: sortNameAsc
                text: i18n("Name (A-Z)")
                checkable: true
                checked:true // root.sortRole === ClientRoles.NameRole && root.sortOrder === Qt.AscendingOrder
                onTriggered: {
                    // Save current view state
                    let currentScreenMode = isWideScreen

                    // Uncheck all other sorting options manually
                    sortNameDesc.checked = false
                    sortBalanceAsc.checked = false
                    sortBalanceDesc.checked = false
                    sortStatus.checked = false

                    // Check this option
                    sortNameAsc.checked = true

                    // Apply sorting
                    root.sortRole = ClientRoles.NameRole
                    root.sortOrder = Qt.AscendingOrder
                    clientModel.sortField = "name"
                    clientModel.sortDirection = "asc"
                    clientModel.sort(ClientRoles.NameRole, Qt.AscendingOrder)

                    // Restore view state if changed
                    if (isWideScreen !== currentScreenMode) {
                        isWideScreen = currentScreenMode
                    }
                }
            }

            Kirigami.Action {
                id: sortNameDesc
                text: i18n("Name (Z-A)")
                checkable: true
                checked: sortRole === ClientRoles.NameRole && sortOrder === Qt.DescendingOrder
                onTriggered: {
                    // Save current view state
                    let currentScreenMode = isWideScreen

                    // Uncheck all other sorting options manually
                    sortNameAsc.checked = false
                    sortBalanceAsc.checked = false
                    sortBalanceDesc.checked = false
                    sortStatus.checked = false

                    // Check this option
                    sortNameDesc.checked = true

                    // Apply sorting
                    root.sortRole = ClientRoles.NameRole
                    root.sortOrder = Qt.DescendingOrder
                    clientModel.sortField = "name"
                    clientModel.sortDirection = "desc"
                    clientModel.sort(ClientRoles.NameRole, Qt.DescendingOrder)

                    // Restore view state if changed
                    if (isWideScreen !== currentScreenMode) {
                        isWideScreen = currentScreenMode
                    }
                }
            }

            Kirigami.Action {
                id: sortBalanceAsc
                text: i18n("Balance (Low to High)")
                checkable: true
                checked: sortRole === ClientRoles.BalanceRole && sortOrder === Qt.AscendingOrder
                onTriggered: {
                    // Save current view state
                    let currentScreenMode = isWideScreen

                    // Uncheck all other sorting options manually
                    sortNameAsc.checked = false
                    sortNameDesc.checked = false
                    sortBalanceDesc.checked = false
                    sortStatus.checked = false

                    // Check this option
                    sortBalanceAsc.checked = true

                    // Apply sorting
                    root.sortRole = ClientRoles.BalanceRole
                    root.sortOrder = Qt.AscendingOrder
                    clientModel.sortField = "balance"
                    clientModel.sortDirection = "asc"
                    clientModel.sort(ClientRoles.BalanceRole, Qt.AscendingOrder)

                    // Restore view state if changed
                    if (isWideScreen !== currentScreenMode) {
                        isWideScreen = currentScreenMode
                    }
                }
            }

            Kirigami.Action {
                id: sortBalanceDesc
                text: i18n("Balance (High to Low)")
                checkable: true
                checked: sortRole === ClientRoles.BalanceRole && sortOrder === Qt.DescendingOrder
                onTriggered: {
                    // Save current view state
                    let currentScreenMode = isWideScreen

                    // Uncheck all other sorting options manually
                    sortNameAsc.checked = false
                    sortNameDesc.checked = false
                    sortBalanceAsc.checked = false
                    sortStatus.checked = false

                    // Check this option
                    sortBalanceDesc.checked = true

                    // Apply sorting
                    root.sortRole = ClientRoles.BalanceRole
                    root.sortOrder = Qt.DescendingOrder
                    clientModel.sortField = "balance"
                    clientModel.sortDirection = "desc"
                    clientModel.sort(ClientRoles.BalanceRole, Qt.DescendingOrder)

                    // Restore view state if changed
                    if (isWideScreen !== currentScreenMode) {
                        isWideScreen = currentScreenMode
                    }
                }
            }

            Kirigami.Action {
                id: sortStatus
                text: i18n("Status")
                checkable: true
                checked: sortRole === ClientRoles.StatusRole
                onTriggered: {
                    // Save current view state
                    let currentScreenMode = isWideScreen

                    // Uncheck all other sorting options manually
                    sortNameAsc.checked = false
                    sortNameDesc.checked = false
                    sortBalanceAsc.checked = false
                    sortBalanceDesc.checked = false

                    // Check this option
                    sortStatus.checked = true

                    // Apply sorting
                    root.sortRole = ClientRoles.StatusRole
                    root.sortOrder = Qt.AscendingOrder
                    clientModel.sortField = "status"
                    clientModel.sortDirection = "asc"
                    clientModel.sort(ClientRoles.StatusRole, Qt.AscendingOrder)

                    // Restore view state if changed
                    if (isWideScreen !== currentScreenMode) {
                        isWideScreen = currentScreenMode
                    }
                }
            }
        },



        Kirigami.Action {
            icon.name: isWideScreen ? "view-list-details" : "table"
            displayHint: Kirigami.DisplayHint.IconOnly
            text: isWideScreen ? i18n("List View") : i18n("Table View")
            onTriggered: isWideScreen = !isWideScreen
            visible : false
        }
    ]

    // Sort menu


    // Filter Drawer

    // Top toolbar with search and filters
    // header: RowLayout {
    //     Layout.fillWidth: true

    //     Item { Layout.fillWidth: true }

    //     DBusyIndicator {
    //         running: clientModel.loading
    //     }

    //     Kirigami.SearchField {
    //         id: searchField
    //         Layout.margins: Kirigami.Units.smallSpacing
    //         Layout.preferredWidth: parent.width/2.5
    //         placeholderText: i18n("Search clients...")
    //         Timer {
    //             id: searchDelayTimer
    //             interval: 700
    //             repeat: false
    //             onTriggered: clientModel.searchQuery = searchField.text
    //         }
    //         onTextChanged: searchDelayTimer.restart()
    //     }

    //     Item { Layout.fillWidth: true }
    // }

    // Main content area with Stack to switch between views
    StackLayout {
        anchors.fill: parent
        currentIndex: isWideScreen ? 1 : 0
        anchors.margins: 5
        //anchors.bottomMargin: paginationBar.height + 20
        clip: true

        // Card List View (for mobile or narrow screens)
        Item {
            // Loading skeleton
            GridLayout {
                anchors.fill: parent
                visible: clientModel.loading
                columns: 1
                rows: 8
                rowSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: 8
                    SkeletonLoaders {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                        Layout.margins: Kirigami.Units.largeSpacing
                    }
                }
            }

            // Card list
            Flickable {
                id: clientFlickable
                anchors.fill: parent
                visible: !clientModel.loading && clientModel.rowCount > 0

                contentWidth: width
                contentHeight: clientColumn.height

                flickableDirection: Flickable.VerticalFlick
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 1500
                maximumFlickVelocity: 4000

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    policy: QQC2.ScrollBar.AlwaysOff
                }

                ColumnLayout {
                    id: clientColumn
                    width: clientFlickable.width
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: clientModel

                        // Modern, elegant single-row client card
                        Item {
                            id: clientCardContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                            // Layout.margins: Kirigami.Units.smallSpacing

                            // Modern card with subtle elevation
                            Rectangle {
                                id: clientCard
                                anchors.fill: parent
                                radius: 6

                                // Modern color palette with proper highlighting
                                color: model.checked ?
                                           Qt.rgba(Kirigami.Theme.highlightColor.r,
                                                   Kirigami.Theme.highlightColor.g,
                                                   Kirigami.Theme.highlightColor.b, 0.5):
                                           Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                                         Kirigami.Theme.backgroundColor.g,
                                                         Kirigami.Theme.backgroundColor.b,
                                                         0.95) // Almost opaque


                                // Elegant shadow effect
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    transparentBorder: true
                                    horizontalOffset: 0
                                    verticalOffset: 1
                                    radius: 6.0
                                    samples: 17
                                    color: Qt.rgba(0, 0, 0, 0.15)
                                }

                                // Status indicator as a vertical bar
                                Rectangle {
                                    width: 4
                                    height: parent.height
                                    color: model.status === "active" ?
                                               Kirigami.Theme.positiveTextColor :
                                               Kirigami.Theme.neutralTextColor
                                    radius: 2
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                }
                            }

                            // Horizontal layout with all elements
                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 8
                                    topMargin: 4
                                    bottomMargin: 4
                                }
                                spacing: 4

                                // FIXED: Checkbox with working click handling
                                Rectangle {
                                    id: checkbox
                                    width: 20
                                    height: 20
                                    radius: 3
                                    color: model.checked ? Kirigami.Theme.highlightColor : "transparent"
                                    border.width: 2
                                    border.color: model.checked ?
                                                      Kirigami.Theme.highlightColor :
                                                      Kirigami.Theme.disabledTextColor

                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: "dialog-ok"
                                        visible: model.checked
                                        color: Kirigami.Theme.backgroundColor
                                    }
                                }

                                // Client name
                                QQC2.Label {
                                    id: nameLabel
                                    text: model.name || ""
                                    elide: Text.ElideRight
                                    font.weight: Font.DemiBold
                                    color: model.checked ?
                                               Kirigami.Theme.backgroundColor :
                                               Kirigami.Theme.textColor
                                    Layout.minimumWidth: isNarrowScreen ? Kirigami.Units.gridUnit * 4 : Kirigami.Units.gridUnit * 4
                                    Layout.preferredWidth: isNarrowScreen ? Kirigami.Units.gridUnit * 6 : Kirigami.Units.gridUnit * 6
                                }

                                // Contact info
                                Item {
                                    Layout.fillWidth: true
                                    visible: !isNarrowScreen
                                    implicitHeight: parent.height

                                    Row {
                                        spacing: 8
                                        height: parent.height

                                        Rectangle {
                                            visible: !!model.email
                                            height: 22
                                            width: Math.min(emailLayout.implicitWidth + 8, 200)
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: model.checked ?
                                                       Qt.rgba(1, 1, 1, 0.2) :
                                                       Qt.rgba(Kirigami.Theme.textColor.r,
                                                               Kirigami.Theme.textColor.g,
                                                               Kirigami.Theme.textColor.b, 0.08)
                                            radius: 3

                                            Row {
                                                id: emailLayout
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Kirigami.Icon {
                                                    source: "mail-message"
                                                    implicitWidth: 12
                                                    implicitHeight: 12
                                                    color: model.checked ?
                                                               Kirigami.Theme.backgroundColor :
                                                               Kirigami.Theme.textColor
                                                }

                                                Text {
                                                    text: model.email || ""
                                                    elide: Text.ElideRight
                                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                                                    color: model.checked ?
                                                               Kirigami.Theme.backgroundColor :
                                                               Kirigami.Theme.textColor
                                                    width: Math.min(implicitWidth, 200)
                                                }
                                            }
                                        }

                                        Rectangle {
                                            visible: !!model.phone
                                            height: 22
                                            width: Math.min(phoneLayout.implicitWidth + 8, 150)
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: model.checked ?
                                                       Qt.rgba(1, 1, 1, 0.2) :
                                                       Qt.rgba(Kirigami.Theme.textColor.r,
                                                               Kirigami.Theme.textColor.g,
                                                               Kirigami.Theme.textColor.b, 0.08)
                                            radius: 3

                                            Row {
                                                id: phoneLayout
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Kirigami.Icon {
                                                    source: "call-start"
                                                    implicitWidth: 12
                                                    implicitHeight: 12
                                                    color: model.checked ?
                                                               Kirigami.Theme.backgroundColor :
                                                               Kirigami.Theme.textColor
                                                }

                                                Text {
                                                    text: model.phone || ""
                                                    elide: Text.ElideRight
                                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                                                    color: model.checked ?
                                                               Kirigami.Theme.backgroundColor :
                                                               Kirigami.Theme.textColor
                                                    width: Math.min(implicitWidth, 150)
                                                }
                                            }
                                        }
                                    }
                                }
                                Item{
                                    Layout.fillWidth: true
                                    visible: isNarrowScreen
                                }
                                // Status badge
                                Rectangle {
                                    implicitWidth: statusLabel.width + 12
                                    implicitHeight: 22
                                    radius: 3
                                    color: model.status === "active" ?
                                               (model.checked ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.15)) :
                                               (model.checked ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(Kirigami.Theme.neutralTextColor.r, Kirigami.Theme.neutralTextColor.g, Kirigami.Theme.neutralTextColor.b, 0.15))

                                    QQC2.Label {
                                        id: statusLabel
                                        anchors.centerIn: parent
                                        text: model.status === "active" ? i18n("Active") : i18n("Inactive")
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                                        font.bold: true
                                        color: model.checked ?
                                                   Kirigami.Theme.backgroundColor :
                                                   (model.status === "active" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.neutralTextColor)
                                    }
                                }

                                // Balance display
                                Rectangle {
                                    implicitWidth: balanceLayout.width + 12
                                    implicitHeight: 22
                                    visible:!model.checked
                                    radius: 3
                                    color: model.checked ?
                                               Qt.rgba(1, 1, 1, 0.2) :
                                               (model.balance > 0 ?
                                                    Qt.rgba(Kirigami.Theme.negativeTextColor.r, Kirigami.Theme.negativeTextColor.g, Kirigami.Theme.negativeTextColor.b, 0.15) :
                                                    Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.15))

                                    RowLayout {
                                        id: balanceLayout
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Rectangle {
                                            Layout.preferredWidth: 6
                                            Layout.preferredHeight: 6
                                            radius: width / 2
                                            color: model.checked ?
                                                       Kirigami.Theme.backgroundColor :
                                                       (model.balance > 1000 ? Kirigami.Theme.negativeTextColor :
                                                                               model.balance > 0 ? Kirigami.Theme.neutralTextColor :
                                                                                                   Kirigami.Theme.positiveTextColor)
                                        }

                                        QQC2.Label {
                                            text: Number(model.balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                                            font.bold: true
                                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                                            color: model.checked ?
                                                       Kirigami.Theme.backgroundColor :
                                                       (model.balance > 0 ? Kirigami.Theme.negativeTextColor :
                                                                            model.balance < 0 ? Kirigami.Theme.positiveTextColor :
                                                                                                Kirigami.Theme.textColor)
                                        }
                                    }
                                }

                                // Action buttons
                                // Action buttons with fixed click handling
                                RowLayout {
                                    id: actionButtons
                                    spacing: 2
                                    visible: model.checked
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    QQC2.ToolButton {
                                        icon.name: "document-edit"
                                        icon.width: Kirigami.Units.iconSizes.small
                                        icon.height: Kirigami.Units.iconSizes.small
                                        icon.color: Kirigami.Theme.backgroundColor
                                        display: QQC2.AbstractButton.IconOnly
                                        flat: true
                                        padding: 0

                                        QQC2.ToolTip.visible: hovered
                                        QQC2.ToolTip.text: i18n("Edit Client")

                                        onClicked: {
                                            clientDetailsDialog.clientId = model.id
                                            clientDetailsDialog.active = true
                                        }
                                    }

                                    QQC2.ToolButton {
                                        icon.name: "view-statistics"
                                        icon.width: Kirigami.Units.iconSizes.small
                                        icon.height: Kirigami.Units.iconSizes.small
                                        icon.color: Kirigami.Theme.backgroundColor
                                        display: QQC2.AbstractButton.IconOnly
                                        flat: true
                                        padding: 0

                                        QQC2.ToolTip.visible: hovered
                                        QQC2.ToolTip.text: i18n("View Statistics")

                                        onClicked: {
                                            statisticsDialog.dialogClientId = model.id
                                            statisticsDialog.dialogClientName = model.name
                                            statisticsDialog.active = true
                                        }
                                    }
                                }

                            }

                            // Card click area - completely rewritten for better handling
                            MouseArea {
                                id: cardMouseArea
                                // anchors{
                                //     top:parent.top
                                //    left : parent.left
                                //     bottom:parent.bottom
                                //     right:!model.checked ? parent.right : actionButtons.left
                                // }
                                anchors.fill: parent
                                anchors.rightMargin: !model.checked ? 0 : actionButtons.width
                                // Handle direct clicks on the card
                                onClicked: {
                                    // Check if clicking on the checkbox area
                                    let checkboxLocalPt = mapToItem(checkbox, mouse.x, mouse.y)
                                    if (checkboxLocalPt.x >= 0 && checkboxLocalPt.y >= 0 &&
                                            checkboxLocalPt.x <= checkbox.width && checkboxLocalPt.y <= checkbox.height) {

                                        // Toggle the clicked checkbox
                                        clientModel.setChecked(index, !model.checked)
                                        return;
                                    }

                                    // If item is already selected, unselect it on click
                                    if (model.checked) {
                                        clientModel.setChecked(index, false)
                                        return;
                                    }

                                    // Check if any item is already selected
                                    let anySelected = false;
                                    for (let i = 0; i < clientModel.rowCount; i++) {
                                        if (clientModel.data(clientModel.index(i, 0), ClientRoles.CheckedRole)) {
                                            anySelected = true;
                                            break;
                                        }
                                    }

                                    // If another item is already selected, also select this one
                                    if (anySelected) {
                                        clientModel.setChecked(index, true)
                                    } else {
                                        // Otherwise open details
                                        clientDetailsDialog.clientId = model.id
                                        clientDetailsDialog.active = true
                                    }
                                }

                                onPressAndHold: {
                                    // Long press to toggle selection
                                    clientModel.setChecked(index, !model.checked)
                                }
                            }

                        }
                    }

                    // Bottom space for pagination
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                    }
                }
            }

            // Pull to refresh
            Connections {
                target: clientFlickable
                function onContentYChanged() {
                    if (clientFlickable.contentY < -Kirigami.Units.gridUnit * 2 &&
                            !clientFlickable.dragging && !clientModel.loading) {
                        clientModel.refresh();
                    }
                }
            }
        }

        // Table View (for desktop or wide screens)
        QQC2.ScrollView {
            contentWidth: view.width
            visible: !clientModel.loading && clientModel.rowCount > 0 && isWideScreen

            Tables.KTableView {
                id: view
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: clientModel
                alternatingRows: true
                clip: true
                visible: !clientModel.loading && clientModel.rowCount > 0 && isWideScreen

                selectionMode: TableView.SelectionMode.SingleSelection
                selectionBehavior: TableView.SelectRows

                onCellDoubleClicked: function(row) {
                    let clientId = view.model.data(view.model.index(row, 0), ClientRoles.IdRole)
                    clientDetailsDialog.clientId = clientId
                    clientDetailsDialog.active = true
                }
                property var nonSortableColumns: {
                    return {
                        [ ClientRoles.ContactRole]: "contact",
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
                        clientModel.sortField = headerComponent.textRole
                        clientModel.sortDirection = "asc"
                        view.sortRole = headerComponent.role;
                        view.sortOrder = Qt.AscendingOrder;
                    } else {
                        clientModel.sortDirection = view.sortOrder === Qt.AscendingOrder ? "desc" : "asc"
                        view.sortOrder = clientModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
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
                ]
            }
        }
    }

    // Loading skeleton for table view
    GridLayout {
        anchors.fill: parent
        visible: clientModel.loading && isWideScreen
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

    // Pagination
    footer: PaginationBar {
        id: paginationBar
        Layout.fillWidth: true
        height: 30
        Layout.alignment: Qt.AlignCenter
        currentPage: clientModel.currentPage
        totalPages: clientModel.totalPages
        totalItems: clientModel.totalItems
        onPageChanged: clientModel.loadPage(page)
    }

    // Client Details Dialog - Use Component.onCompleted to initialize early
    Component {
        id: clientDetailsComponent
        ClientDetails {}
    }

    Loader {
        id: clientDetailsDialog
        active: false
        asynchronous: false // Changed to false for faster loading
        sourceComponent: clientDetailsComponent
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

    // Statistics Dialog - Use Component.onCompleted to initialize early
    Component {
        id: clientStatisticsComponent
        ClientStatisticsDialog {}
    }

    Loader {
        id: statisticsDialog
        active: false
        asynchronous: false // Changed to false for faster loading
        sourceComponent: clientStatisticsComponent
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

        // Preload dialogs to avoid delay on first use
        // This avoids the slow loading on mobile
        let preloadClient = Qt.createComponent("ClientDetails.qml")
        let preloadStats = Qt.createComponent("ClientStatisticsDialog.qml")
    }

    // Function to manage checkbox selection behavior
    function handleCheckboxClicked(index) {
        // Toggle the clicked item
        const currentState = clientModel.data(clientModel.index(index, 0), ClientRoles.CheckedRole)
        clientModel.setChecked(index, !currentState)

        // If Ctrl key is pressed, we're in multi-select mode
        if (multiSelectMode) {
            // We keep the multi-select mode when Ctrl is pressed initially
            // Items will be selected when clicked
        } else {
            // Regular toggle behavior - just toggle the current item
        }
    }
    // KirigamiComponents.FloatingButton {
    //     anchors {
    //         right: parent.right
    //         bottom: parent.bottom
    //     }
    //     margins: Kirigami.Units.largeSpacing

    //     action: Kirigami.Action {
    //         text: "Add new client"
    //         icon.name: "list-add"
    //     }
    // }
    // Detect when Ctrl key is pressed/released for multi-select mode
    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Control) {
                multiSelectMode = true
            }
        }
        Keys.onReleased: function(event) {
            if (event.key === Qt.Key_Control) {
                multiSelectMode = false
            }
        }
    }
}
