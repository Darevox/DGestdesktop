import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Kcomponents
import "components"
Kirigami.ApplicationWindow {
    id: rootWindow
    title: "DGest"
    //header: Kirigami.ApplicationHeaderStyle.None
    property alias gnotification: notification

    property var currentHeader: null
    function loadHeader() {
        if (currentHeader === null) {
            currentHeader = headerComponent.createObject(rootWindow)
            rootWindow.header = currentHeader
        }
        // currentGlobalDrawer.open()
    }
    function destroyHeader() {
        if (currentHeader !== null) {
            currentHeader.destroy()
            currentHeader = null
            rootWindow.header = null
        }
    }
    property var currentGlobalDrawer: null
    function loadGlobalDrawer() {
        if (currentGlobalDrawer === null) {
            currentGlobalDrawer = globalDrawerComponent.createObject(rootWindow)
            rootWindow.globalDrawer = currentGlobalDrawer
        }
        currentGlobalDrawer.open()
    }
    Component{
        id: headerComponent
        RowLayout{
            Layout.margins: 5
            Item{
                Layout.fillWidth: true
            }
            Controls.ToolButton {
                id:notfi2
                Layout.alignment: Qt.AlignRight
                icon.name: "notifications"
                onClicked: notification.showNotification("",
                                                         "Operation completed successfully", // message
                                                         Kirigami.MessageType.Positive, // message type
                                                         "short", // timeout
                                                         "Undo", // action text
                                                         function() { console.log("Undo clicked") }
                                                         )
            }
            Kcomponents.AvatarButton {
                Layout.margins: 5
                Layout.alignment: Qt.AlignRight
                name: api.getUserName()
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
                onClicked: menuDialog.open()
            }
        }
    }
    Component{
        id: globalDrawerComponent
        Kirigami.GlobalDrawer {
            id: globalDrawerMain
            showHeaderWhenCollapsed: true
            modal : false;
            collapsible : true;
            collapsed : true;
            collapseButtonVisible:false;
            showContentWhenCollapsed:true
            header:
                ColumnLayout{
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    Controls.ToolButton {
                        icon.name: "application-menu"
                        visible: globalDrawer.collapsible
                        checked: !globalDrawer.collapsed
                        onClicked: globalDrawer.collapsed = !globalDrawer.collapsed
                    }
                    Kirigami.SearchField {
                        visible: !globalDrawer.collapsed
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                }
            }
            content: VNavigationTabBar {
                id: navTabBar
                Layout.fillWidth: true
                Layout.fillHeight: true
                drawerCollapsed: globalDrawerMain.collapsed
            }
            footer:RowLayout {
                visible: !globalDrawer.collapsed
                spacing: Kirigami.Units.smallSpacing
                Item{
                    Layout.fillWidth: true
                }
                Kirigami.Icon {
                    Layout.margins: Kirigami.Units.largeSpacing
                    source: "shape-cuboid"
                }

                Kirigami.Heading {
                    //Layout.margins: Kirigami.Units.largeSpacing
                    text: "DGest"
                    level: 3
                    Layout.fillWidth: true
                }

                Controls.ToolButton {
                    spacing: Kirigami.Units.smallSpacing
                    icon.name: "documentinfo"
                    onClicked: {
                        rootWindow.pageStack.pop()
                        rootWindow.pageStack.push("qrc:/DGest/qml/pages/Settings.qml")
                    }
                }
            }
        }
    }
    footer:  Kirigami.ApplicationHeaderStyle.None
    pageStack.initialPage: Qt.resolvedUrl("qrc:/DGest/qml/pages/Login.qml")
    Kirigami.MenuDialog {
        id: menuDialog
        title: i18n("Profile")
        showCloseButton: false
        contentHeader:  RowLayout {
            Layout.fillWidth: true
            Kcomponents.Avatar {
                id:avatarUser
                Layout.margins: Kirigami.Units.largeSpacing
                Layout.alignment: Qt.AlignHCenter
                name:  "User"
            }
            Kirigami.Heading {
                id:userName
                text:  "User"
                level: 3
            }
            Connections {
                target: api
                function onUserInfoReceived() {
                    userName.text= api.getUserName()
                    avatarUser.name= api.getUserName()
                }
            }
        }
        actions: [
            Kirigami.Action {
                icon.name: "user-identity"
                text: i18n("Profile..")
                tooltip: i18n("View profile")
            },
            Kirigami.Action {
                icon.name: "draw-arrow-back"
                text: i18n("Logout")
                tooltip: i18n("Logout")
                onTriggered: {
                    loadingBusyIndicator.running=true
                    api.logout()
                }
            }

        ]
    }
    function destroyGlobalDrawer() {
        if (currentGlobalDrawer !== null) {
            currentGlobalDrawer.destroy()
            currentGlobalDrawer = null
            rootWindow.globalDrawer = null
        }
    }
    Connections {
        target: api
        function onLogoutSuccess() {
            resetUIState()
            destroyHeader()
            destroyGlobalDrawer()
            applicationWindow().pageStack.pop()
            applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Login.qml"))
        }
        function onLogoutError() {
            console.log("GetUserInfo  failed:", arguments[0]);
            //   updateStatusMessage("Get UserInfo failed: " + arguments[0], Kirigami.MessageType.Warning);
            resetUIState();
        }
    }
    function resetUIState() {
        loadingBusyIndicator.running = false;
    }
    Controls.BusyIndicator{
        id:loadingBusyIndicator
        anchors.centerIn: parent
        running: false
    }
    DNotification{
        id:notification
    }
}
