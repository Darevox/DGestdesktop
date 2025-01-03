import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../."
Kirigami.Page {
    id:loginPage
    title: "Login"
    header: Kirigami.ApplicationHeaderStyle.None
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
    footer:  Kirigami.ApplicationHeaderStyle.None
    property  bool showNoPage: false

    Rectangle {
        id:loginContainer
        width: Math.min(parent.width * 2/3, 400)
        height: Math.min(parent.height * 3/4, 600)
        anchors.centerIn: parent
        color:Kirigami.Theme.alternateBackgroundColor
        radius: 4
        visible: false
        Kirigami.InlineMessage {
            id:statusMessage
            anchors.top: parent.top
            width: parent.width
            visible: false
            showCloseButton: true
        }
        Image {
            id: logoImageSmall
            width: loginContainer.width
            anchors.left: loginContainer.left
            anchors.right: loginContainer.right
            height: 120
            opacity: 1
            anchors.top: statusMessage.bottom
            anchors.topMargin: 30
            source: "qrc:/DGest/contents/ui/resources/logo.svg"
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: ColorOverlay {
                color:   Kirigami.Theme.activeTextColor
            }
        }
        Kirigami.Heading {
            id:welcomeHeading
            anchors.top: logoImageSmall.bottom
            horizontalAlignment: Text.AlignHCenter
            text: "Welcome back !"
            level: 1
            anchors.margins: 20
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Kirigami.FormLayout {
            id:loginLayout
            wideMode: false
            anchors.top: welcomeHeading.bottom
            anchors.left: loginContainer.left
            anchors.right: loginContainer.right
            anchors.margins: 20
            anchors.horizontalCenter: loginContainer.horizontalCenter

            QQC2.TextField {
                id:emailField
                padding: 10
                placeholderText:  "Email"
            }
            Kirigami.ActionTextField {
                id:passwordField
                padding: 10
                placeholderText:  "Password"
                echoMode:TextInput.Password
                rightActions: Kirigami.Action {
                    icon.name: "password-show-on"
                    visible: true
                    onTriggered: {
                        if(icon.name=="password-show-on"){
                            passwordField.echoMode=TextInput.Normal
                            icon.name="password-show-off"
                        }
                        else{
                            passwordField.echoMode=TextInput.Password
                            icon.name="password-show-on"
                        }
                    }
                }
            }
            QQC2.CheckBox {
                id:keepSignedIn
                text: "Keep me signed in"
                onCheckStateChanged: {
                    console.log(keepSignedIn.checked)
                }
            }
        }
        QQC2.BusyIndicator{
            id:loadingLoginBusyIndicator
            anchors.centerIn: parent
            running: false
        }
        ColumnLayout{
            id:controlLoginLayout
            anchors.top: loginLayout.bottom
            anchors.left: loginContainer.left
            anchors.right: loginContainer.right
            //  anchors.bottom: loginContainer.bottom
            anchors.margins: 20

            QQC2.Button{
                id:loginBtn
                text:"Continue"
                Layout.fillWidth: true
                anchors.horizontalCenter: loginContainer.horizontalCenter
                onClicked: {
                    loginLayout.enabled = false;
                    loginBtn.enabled = false;
                    loadingBusyIndicator.running = true;
                    api.login(emailField.text, passwordField.text, keepSignedIn.checked);
                }
            }

        }
        RowLayout{
            anchors.top: controlLoginLayout.bottom
            anchors.margins: 20
            anchors.horizontalCenter: loginContainer.horizontalCenter
            Layout.fillWidth: true
            QQC2.Label {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                id: linkLabel
                text: "Dont't have an account  ? <a href=\"https://dim.dervox.com\">Sign Up!<a/>"
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }

    }

    NoPage {
        id:noPage
        anchors.fill:parent
        visible: loginPage.showNoPage
        onReconnectClicked: {
            loginPage.showNoPage = false
            loginPage.checkLoginStatus()
        }
    }
    Connections {
        target: api

        function onLoginError(message, status, errorMessageDetails) {
            updateStatusMessage(message + " " + errorMessageDetails,status)
            resetUIState()
        }

        function onUserInfoReceived() {
            let token = api.getToken();
            subscriptionApi.getStatus(token);
            productApi.saveToken(token);
            productApiFetch.saveToken(token);
            activityLogApi.saveToken(token);
            supplierApi.saveToken(token);
            cashSourceApi.saveToken(token);
            cashSourceApiFetch.saveToken(token);
            cashTransactionApi.saveToken(token);
            purchaseApi.saveToken(token);
            clientApi.saveToken(token);
            clientApiFetch.saveToken(token);
            saleApi.saveToken(token);
            invoiceApi.saveToken(token);
            dashboardAnalyticsApi.saveToken(token);
            // applicationWindow().pageStack.replace(Qt.resolvedUrl("qrc:/DGest/contents/ui/pages/Welcome.qml"))
        }

        function onUserInfoError(message, status, errorMessageDetails) {
            resetUIState()
            let  messagetype = gApiStatusHandler.getMessageType(status)
            if(messagetype==Kirigami.MessageType.Error){
                loginPage.showNoPage=true
                noPage.isRequasting=false
            }
            else if(messagetype = Kirigami.MessageType.Warning ){
                api.saveToken("");
                applicationWindow().pageStack.replace(Qt.resolvedUrl("qrc:/DGest/contents/ui/pages/user/Login.qml"))
            }
            else {
                updateStatusMessage( message + " " + errorMessageDetails,status)
            }
        }
    }

    function updateStatusMessage(message, status) {
        statusMessage.type = gApiStatusHandler.getMessageType(status)
        statusMessage.visible = true
        statusMessage.text = message
    }
    function resetUIState() {
        loginLayout.enabled = true
        loginBtn.enabled = true
        loadingBusyIndicator.running = false
    }
    QQC2.BusyIndicator{
        id:loadingBusyIndicator
        anchors.centerIn: parent
        running: false
    }
    Timer {
        id: loginCheckTimer
        interval: 300
        repeat: false
        onTriggered: checkLoginStatus()
    }
    Connections {
        target: subscriptionApi
        function onStatusReceived() {
            console.log("WWWWWWWWWWW")
            let statusPlan = subscriptionApi.getStatusString()
            if(statusPlan !="active"){
                expiredDialog.active = true
            }
            else {
                applicationWindow().pageStack.replace(Qt.resolvedUrl("qrc:/DGest/contents/ui/pages/Welcome.qml"))
            }
        }
    }
    function checkLoginStatus() {
        if (api.getRememberMe() && api.isLoggedIn()) {
            console.log("checkLoginStatus 1 ")
            loadingBusyIndicator.running = true;
            api.getUserInfo();
        } else {
            console.log("checkLoginStatus 2 ")
            loadingBusyIndicator.running = false;
            loginContainer.visible = true;
        }
    }
    Loader {
        id: expiredDialog
        active: false
        asynchronous: true
        sourceComponent: ExpiredSubscription {}

        onLoaded: {
            item.open()
        }

        Connections {
            target: expiredDialog.item
            function onClosed() {
                api.logout();
                resetUIState();
                expiredDialog.active = false
            }
        }
    }
    Component.onCompleted: {
        loginCheckTimer.start();
    }

}
