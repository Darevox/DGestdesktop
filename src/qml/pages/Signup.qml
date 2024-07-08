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
        // text: "Argh!!! Something went wrong!!"
        // type: Kirigami.MessageType.Error
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
            id:loginLayout
            wideMode: false
            anchors.top: welcomeHeading.bottom
            anchors.left: loginContainer.left
            anchors.right: loginContainer.right
          //  anchors.bottom: loginContainer.bottom
            anchors.margins: 20
            // anchors.horizontalCenter: loginContainer.horizontalCenter

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



            // Kirigami.Separator {
            //     Kirigami.FormData.isSection: true
            // }

            // Controls.Label {
            //     Layout.fillWidth: true
            //     horizontalAlignment: Text.AlignHCenter
            //     text: "Login using social media ."
            //     elide: Text.elideLeft
            // }
            Controls.Button{
                id:loginBtn
                text:"Continue"
                Layout.fillWidth: true
                anchors.horizontalCenter: loginContainer.horizontalCenter
                onClicked: {
                    api.registerUser(nameField.text,emailField.text,passwordField.text,c_passwordField.text)
                    loadingLoginBusyIndicator.running=true
                    enabled=false
                    loginLayout.enabled=false
                }

                //     Layout.margins: 20
                // Kirigami.Theme.backgroundColor:   Kirigami.Theme.highlightColor
                //  Kirigami.Theme.textColor:  Kirigami.Theme.highlightedTextColor
            }
        }
        RowLayout{
            anchors.top: loginLayout.bottom
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
        Controls.BusyIndicator{
            id:loadingLoginBusyIndicator
            anchors.centerIn: parent
            running: false
        }
    }
    Connections {
        target: api
        function onRegisterResult(result) {
            if (result.success) {
                console.log("Register successful:", result.data.accessToken);
                statusMessage.type= Kirigami.MessageType.Information
                statusMessage.visible=true
                statusMessage.text="Register successful"
            } else {
                console.log("Register failed. Error:", result.error);
                try {
                    var errorObject = JSON.parse(result.error);
                    if (errorObject.errors) {
                        var messages = [];
                        for (var key in errorObject.errors) {
                            messages = messages.concat(errorObject.errors[key]);
                        }
                        var errorMessage = messages.join(", ");
                        console.log("Error messages:", errorMessage);
                        statusMessage.type = Kirigami.MessageType.Warning;
                        statusMessage.visible = true;
                        statusMessage.text = errorMessage;
                    } else {
                        console.log("Unknown error:", result.error);
                    }
                } catch (e) {
                    // If parsing fails, check if the error is from NetworkError
                    if (result.errorCode !== undefined) {
                        var networkErrorMessages = {
                            0: "Connection refused",
                            1: "Remote host closed",
                            2: "Host not found",
                            3: "Timeout",
                            4: "Operation canceled",
                            5: "SSL handshake failed",
                            6: "Temporary network failure",
                            7: "Network session failed",
                            8: "Background request not allowed",
                            9: "Too many redirects",
                            10: "Insecure redirect",
                        };
                        var networkErrorMessage = networkErrorMessages[result.errorCode] || "Unknown network error";
                        console.log("Network error:", networkErrorMessage);
                        statusMessage.type = Kirigami.MessageType.Warning;
                        statusMessage.visible = true;
                        statusMessage.text = "Network error: "+networkErrorMessage;
                    } else {
                        console.log("Failed to parse error JSON, using raw error:", result.error);
                        statusMessage.type = Kirigami.MessageType.Warning;
                        statusMessage.visible = true;
                        statusMessage.text = result.error;
                    }
                }
            }
        }
    }

}

