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

    // Kirigami.InlineMessage {
    //     id:statusMessage
    //     anchors.top: header.bottom
    //     width: parent.width
    //     text: "You are offline please check your connection"
    //      type: Kirigami.MessageType.Warning
    //     visible: true
    //     showCloseButton: true
    //     icon.source: "offline"
    //     actions: [
    //         Kirigami.Action {
    //             text: qsTr("Refresh")
    //             icon.name: "refreshstructure"
    //         }
    //     ]

    // }
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
                    onClicked: showPassiveNotification("BEEP!")
                }
                Kcomponents.AvatarButton {
                    Layout.margins: 5
                    Layout.alignment: Qt.AlignRight
                    name: "akram chaima"
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
                Layout.margins: Kirigami.Units.largeSpacing
                Layout.alignment: Qt.AlignHCenter
                name: "akram chaima"
            }
            Kirigami.Heading {
                text: "akram chaima"
                level: 3
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

        // Slot for handling login result
        function onLogoutResult(result) {
            handleApiResult(result, "Logout");
            if (result.success) {
                console.log("Logout successful:", result.data);
                if(!api.isLoggedIn()){
                    destroyHeader()
                    destroyGlobalDrawer()
                    applicationWindow().pageStack.pop()
                    applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Login.qml"))
                }
            }
        }

    }
    // Function to handle generic errors and validation errors
    function handleApiResult(result, actionName) {
        if (result.success) {
            console.log(actionName + " successful:", result.data);
            // Handle successful action (login, get user info, etc.)
        } else {
            console.error(actionName + " result.error failed:", result.error);
            console.error(actionName + " result.errorCode failed:", result.errorCode);
            if (result.validationErrors) {
                handleValidationErrors(result.validationErrors);
            } else {
                handleGenericError(result.errorCode, result.error);
            }
        }
        resetUIState();
    }

    // Function to handle validation errors
    function handleValidationErrors(validationErrors) {
        var jsonString = JSON.stringify(validationErrors); // Convert JSON object to string
        var messages = [];
        for (var key in validationErrors) {
            messages = messages.concat(validationErrors[key]);
        }
        var errorMessage = messages.join(", ");
        console.log("Validation errors:", jsonString);

        updateStatusMessage(errorMessage, Kirigami.MessageType.Warning);
    }

    // Function to handle generic errors
    function handleGenericError(errorCode, errorMessage) {
        console.log("Error: " + errorMessage);
        updateStatusMessage(errorMessage, Kirigami.MessageType.Warning);
    }

    // Function to update status message
    function updateStatusMessage(text, type) {
        statusMessage.type = type;
        statusMessage.visible = true;
        statusMessage.text = text;
    }

    // Function to reset UI state
    function resetUIState() {
        loadingBusyIndicator.running = false;
    }
    Controls.BusyIndicator{
        id:loadingBusyIndicator
        anchors.centerIn: parent
        running: false
    }
}
