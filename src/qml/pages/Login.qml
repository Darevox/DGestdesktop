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
        // text: "Argh!!! Something went wrong!!"
        // type: Kirigami.MessageType.Error
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


            // Kirigami.Separator {
            //     Kirigami.FormData.isSection: true
            // }

            // Controls.Label {
            //     Layout.fillWidth: true
            //     horizontalAlignment: Text.AlignHCenter
            //     text: "Login using social media ."
            //     elide: Text.elideLeft
            // }

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
                    api.login(emailField.text,passwordField.text,keepSignedIn.checked)
                    loadingBusyIndicator.running=true
                    enabled=false
                    loginLayout.enabled=false
                }

                //     Layout.margins: 20
                // Kirigami.Theme.backgroundColor:   Kirigami.Theme.highlightColor
                //  Kirigami.Theme.textColor:  Kirigami.Theme.highlightedTextColor
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

        // Slot for handling login result
        function onLoginResult(result) {
            handleApiResult(result, "Login");

            if (result.success) {
                console.log("Login successful:", result.data);
                // Handle successful login
                // Example: Redirect to another page
                applicationWindow().pageStack.pop()
                applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Welcome.qml"));
            }
        }

        // Slot for handling get user info result
        function onGetUserInfoResult(result) {
            handleApiResult(result, "GetUserInfo");

            if (result.success) {
                console.log("GetUserInfo successful:", result.data);
                applicationWindow().pageStack.pop()
                applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Welcome.qml"));

            }
        }
    }

    // Function to handle generic errors and validation errors
    function handleApiResult(result, actionName) {
        if (result.success) {
            console.log(actionName + " successful2:", result.data);
            // Handle successful action (login, get user info, etc.)
        } else {
            console.error(actionName + " result.error failed:", result.error);
            console.error(actionName + " result.errorCode failed:", result.errorCode);
            if(result.errorCode===1){
                applicationWindow().pageStack.pop()
                applicationWindow().pageStack.push(Qt.resolvedUrl("qrc:/DGest/qml/pages/Welcome.qml"));
            }
            if (result.validationErrors) {
                handleValidationErrors(result.validationErrors);
            } else {
                // Handle other errors if needed
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
        loginLayout.enabled = true;
        loginBtn.enabled = true;
        loadingBusyIndicator.running = false;
        loginContainer.visible = true;
    }


    function checkLoginStatus(){
        if(api.getRemembeMe()&&api.isLoggedIn()){
            loadingBusyIndicator.running=true
            api.getUserInfo();
        }
        else{
            loadingBusyIndicator.running=false
            loginContainer.visible=true
        }
    }
    Controls.BusyIndicator{
        id:loadingBusyIndicator
        anchors.centerIn: parent
        running: false
    }
    Timer {
        id: loginCheckTimer
        interval: 300 // 2 seconds
        repeat: false
        onTriggered: checkLoginStatus()
    }
    Component.onCompleted: {
        loginCheckTimer.start()
    }

}
