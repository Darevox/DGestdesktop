import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
Kirigami.Page {
    title: "Signup"
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
        height: Math.min(parent.height * 3/4, 400)
        anchors.centerIn: parent
        color:Kirigami.Theme.alternateBackgroundColor
        radius: 4

        Kirigami.Heading {
            id:welcomeHeading
            anchors.top: loginContainer.top
            horizontalAlignment: Text.AlignHCenter
            text: "Create an account"
            level: 1
            anchors.margins: 20
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Kirigami.FormLayout {
            id:signUpLayout
            wideMode: false
            anchors.top: welcomeHeading.bottom
            anchors.left: loginContainer.left
            anchors.right: loginContainer.right
            anchors.margins: 20
            Controls.TextField {
                id:nameField
                padding: 10
                placeholderText:  "Name"
            }
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
            Kirigami.ActionTextField {
                id:c_passwordField
                padding: 10
                placeholderText:  "Confirm password"
                echoMode:TextInput.Password
                rightActions: Kirigami.Action {
                    icon.name: "password-show-on"
                    visible: true
                    onTriggered: {
                        if(icon.name=="password-show-on"){
                            c_passwordField.echoMode=TextInput.Normal
                            icon.name="password-show-off"
                        }
                        else{
                            c_passwordField.echoMode=TextInput.Password
                            icon.name="password-show-on"
                        }
                    }
                }
            }
            Controls.Button{
                id:signUpBtn
                text:"Continue"
                Layout.fillWidth: true
                anchors.horizontalCenter: loginContainer.horizontalCenter
                onClicked: {
                    api.registerUser(nameField.text,emailField.text,passwordField.text,c_passwordField.text)
                    loadingBusyIndicator.running=true
                    enabled=false
                    signUpLayout.enabled=false
                }
            }
        }
        RowLayout{
            anchors.top: signUpLayout.bottom
            anchors.margins: 20
            anchors.horizontalCenter: loginContainer.horizontalCenter
            Layout.fillWidth: true
            Controls.Label {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                text: "Already have an account ?"
            }
            Controls.Label {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                id: linkLabel
                text: "<a href='#'>Sign In</a>"
                textFormat: Text.RichText
                onLinkActivated: {
                    applicationWindow().pageStack.pop()
                    applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Login.qml"))
                }
            }
        }
    }
    Connections{
        target: api
        function onRegisterSuccess() {
            updateStatusMessage("SignUp successful, Redirecting ...", Kirigami.MessageType.Positive);
            api.login(emailField.text, passwordField.text, false);
        }
        function onUserInfoReceived() {
            updateStatusMessage("Login successful", Kirigami.MessageType.Positive);
            applicationWindow().pageStack.pop()
            applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Welcome.qml"))
        }
        function onUserInfoError() {
            console.log("GetUserInfo  failed:", arguments[0]);
            updateStatusMessage("Get UserInfo failed: " + arguments[0], Kirigami.MessageType.Warning);
            resetUIState();
        }
        function onRegisterError() {
            console.log("SignUp failed:", arguments[0]);
            updateStatusMessage("SignUp failed: " + arguments[0], Kirigami.MessageType.Warning);
            loadingBusyIndicator.running = false;
            resetUIState();
        }

    }
    function updateStatusMessage(message, type) {
        statusMessage.type = type;
        statusMessage.visible = true;
        statusMessage.text = message;
    }
    function resetUIState() {
        signUpLayout.enabled = true;
        signUpBtn.enabled = true;
        loadingBusyIndicator.running = false;
    }
    Controls.BusyIndicator{
        id:loadingBusyIndicator
        anchors.centerIn: parent
        running: false
    }


}

