import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as Kcomponents
import com.dervox.ColorSchemeManager 1.0
import com.dervox.ApiStatusHandler 1.0
import com.dervox.dim

import "components"
import "pages"
import "pages/user"

Kirigami.ApplicationWindow {
    id: rootWindow
    title: "DIM"
    //header: Kirigami.ApplicationHeaderStyle.None
    property alias gnotification: notification
    property alias  gaboutDialog: aboutDialog
    property alias  gprofileDialog: profileDialog
    property alias  gColorSchemeModel: colorSchemeModel
    // property alias  gProductModel: productModel

    property alias  gApiStatusHandler: apiStatusHandler

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
        Rectangle{
            Kirigami.Theme.colorSet: Kirigami.Theme.View
            Kirigami.Theme.inherit: false
            color: Kirigami.Theme.backgroundColor

            implicitWidth: toolBarGlobal.implicitWidth
            implicitHeight: toolBarGlobal.implicitHeight
            RowLayout{
                id:toolBarGlobal
                anchors.fill:parent
                Item{
                    Layout.fillWidth: true
                }
                QQC2.ToolButton {
                    id:notfi2
                    Layout.alignment: Qt.AlignRight
                    icon.name: "notifications"
                    onClicked: {
                        if(!rootWindow.globalDrawer.collapsed)
                            rootWindow.globalDrawer.collapsed=true

                        if(notificationDrawer.opened)
                            notificationDrawer.close()
                        else
                            notificationDrawer.open()
                    }
                    /*notification.showNotification("",
                                                                 "Operation completed successfully", // message
                                                                 Kirigami.MessageType.Positive, // message type
                                                                 "short", // timeout
                                                                 "Undo", // action text
                                                                 function() { console.log("Undo clicked") }
                                                                 )*/
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


            property int expandedWidth: Kirigami.Units.gridUnit * 15
            property int collapsedWidth: Kirigami.Units.gridUnit * 2.3

           width: collapsed ? collapsedWidth : expandedWidth

            Behavior on width {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
            header:
                ColumnLayout{
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    QQC2.ToolButton {
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
            content:ColumnLayout{

                VNavigationTabBar {
                    id: navTabBar
                    Layout.fillWidth: true
                    Layout.fillHeight: !globalDrawerMain.collapsed
                    implicitHeight: globalDrawerMain.collapsed? contentHeight : null

                    drawerCollapsed: globalDrawerMain.collapsed
                }
                Item{
                    visible:globalDrawerMain.collapsed

                }
            }
        }



    }
    footer:  Kirigami.ApplicationHeaderStyle.None
    pageStack.initialPage:Qt.createComponent("com.dervox.dim", "Login") // Qt.resolvedUrl("qrc:/dim/contents/ui/pages/user/Login.qml")

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
                onTriggered:{
                    profileDialog.active=true

                }
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
            applicationWindow().pageStack.push(Qt.createComponent("com.dervox.dim", "Login") )
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
    // DBusyIndicator{
    //     id:loadingBusyIndicator
    //     anchors.centerIn: parent
    //     running: false
    // }

    DNotification{
        id:notification
    }
    Loader {
        id: profileDialog
        active: false
        asynchronous: true
        sourceComponent: Profile {}

        onLoaded: {
            item.open()
        }

        Connections {
            target: profileDialog.item
            function onClosed() {
                profileDialog.active = false
            }
        }
    }
    Loader {
        id: aboutDialog
        active: false
        asynchronous: true
        sourceComponent: AboutApp{}

        onLoaded: {
            item.open()
        }

        Connections {
            target: aboutDialog.item
            function onClosed() {
                aboutDialog.active = false
            }
        }
    }
    Kirigami.OverlayDrawer {
        id: notificationDrawer
        edge: Qt.RightEdge
        modal: true
        handleVisible: false
        width: Kirigami.Units.gridUnit * 24

        property bool hasNotifications: false
        contentItem: ColumnLayout {
            spacing: 0
            anchors.fill:parent
            RowLayout {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                Item {
                    Layout.fillWidth: true
                }
                Kirigami.Heading {
                    Layout.alignment: Qt.AlignHCenter
                    text: i18n("Notifications")
                    level: 2
                }
                Item {
                    Layout.fillWidth: true
                }
                QQC2.ToolButton {
                    icon.name: "dialog-close"
                    onClicked: {
                        notificationDrawer.close()
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: notificationDrawer.hasNotifications
            }
            Item {
                Layout.fillHeight: true
                visible: !notificationDrawer.hasNotifications
            }
            Kirigami.PlaceholderMessage {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Kirigami.Units.largeSpacing
                visible: !notificationDrawer.hasNotifications
                Layout.preferredWidth:  Kirigami.Units.gridUnit * 22
                icon.name: "notifications"
                icon.width: Kirigami.Units.iconSizes.huge
                icon.height: Kirigami.Units.iconSizes.huge
                text: i18n("No Notifications")
            }

            Item {
                Layout.fillHeight: true
                visible: !notificationDrawer.hasNotifications
            }
        }
    }

    ColorSchemeModel {
        id: colorSchemeModel
    }


    // ProductModel {
    //     id: productModel
    // }
    ApiStatusHandler{
        id:apiStatusHandler
    }

}
