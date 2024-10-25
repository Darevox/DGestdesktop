import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import QtQuick.Layouts

Kirigami.Page {
    id:loginPage
    title: "Login"
    header: Kirigami.ApplicationHeaderStyle.None
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
    footer:  Kirigami.ApplicationHeaderStyle.None
    Kirigami.InlineMessage {
        id:statusMessage
        anchors.top: parent.top
        width: parent.width
        visible: false
        showCloseButton: true
    }
    Rectangle{
        id:loginContainer
        width: Math.min(parent.width * 2/3, 400)
        height: Math.min(parent.height * 3/4, 600)
        anchors.centerIn: parent
        color:Kirigami.Theme.alternateBackgroundColor
        radius: 4
        visible: false

        Image {
            id: logoImageSmall
            width: loginContainer.width
            anchors.left: loginContainer.left
            anchors.right: loginContainer.right
            height: 120
            opacity: 1
            anchors.top: loginContainer.top
            anchors.topMargin: 30
            source: "qrc:/DGest/qml/resources/logo.svg"
            fillMode: Image.PreserveAspectFit
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

            Controls.TextField {
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
            Controls.CheckBox {
                id:keepSignedIn
                text: "Keep me signed in"
                onCheckStateChanged: {
                    console.log(keepSignedIn.checked)
                }
            }
        }
        Controls.BusyIndicator{
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

            Controls.Button{
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
            Controls.Label {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                text: "Dont't have an account ?"
            }
            Controls.Label {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                id: linkLabel
                text: "<a href='#'>Sign Up</a>"
                textFormat: Text.RichText
                onLinkActivated: {
                    applicationWindow().pageStack.pop()
                    applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Signup.qml"))
                }
            }
        }

    }
    Connections {
        target: api
        // function onLoginSuccess() {
        //     console.log("Login successful:", arguments[0]);
        //     updateStatusMessage("Login successful", Kirigami.MessageType.Positive);
        //     applicationWindow().pageStack.replace(Qt.resolvedUrl("qrc:/DGest/qml/pages/Welcome.qml"));
        //     resetUIState();
        // }
        function onLoginError() {
            console.log("Login failed:", arguments[0]);
            updateStatusMessage("Login failed: " + arguments[0], Kirigami.MessageType.Warning);
            resetUIState();
        }
        function onUserInfoReceived() {
            updateStatusMessage("Login successful", Kirigami.MessageType.Positive);
            applicationWindow().pageStack.replace(Qt.resolvedUrl("qrc:/DGest/qml/pages/Welcome.qml"));
            resetUIState();
        }
        function onUserInfoError() {
            console.log("GetUserInfo  failed:", arguments[0]);
            updateStatusMessage("Get UserInfo failed: " + arguments[0], Kirigami.MessageType.Warning);
            resetUIState();
        }
    }

    function updateStatusMessage(message, type) {
        statusMessage.type = type;
        statusMessage.visible = true;
        statusMessage.text = message;
    }

    function resetUIState() {
        loginLayout.enabled = true;
        loginBtn.enabled = true;
        loadingBusyIndicator.running = false;
    }
    Controls.BusyIndicator{
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

    Component.onCompleted: {
        loginCheckTimer.start();
    }
}
