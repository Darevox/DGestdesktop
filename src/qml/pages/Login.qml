import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
Kirigami.Page {
    title: "Login"
    header: Kirigami.ApplicationHeaderStyle.None
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
    footer:  Kirigami.ApplicationHeaderStyle.None
    Rectangle{
        id:loginContainer
        width: Math.min(parent.width * 2/3, 400)
        height: Math.min(parent.height * 3/4, 600)
        anchors.centerIn: parent
        color:Kirigami.Theme.alternateBackgroundColor
        radius: 4

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
                padding: 10
                placeholderText:  "Email"
            }
            Controls.TextField {
                padding: 10
                placeholderText:  "Password"
            }
            Controls.CheckBox {
                text: "Keep me signed in"
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
        ColumnLayout{
            anchors.top: loginLayout.bottom
            anchors.left: loginContainer.left
            anchors.right: loginContainer.right
            anchors.bottom: loginContainer.bottom
            anchors.margins: 20
            Controls.Button{
                text:"Continue"
                Layout.fillWidth: true
                anchors.horizontalCenter: loginContainer.horizontalCenter
                //     Layout.margins: 20
                // Kirigami.Theme.backgroundColor:   Kirigami.Theme.highlightColor
                //  Kirigami.Theme.textColor:  Kirigami.Theme.highlightedTextColor
            }
            Controls.Label {
                text: "Forgot your passowrd ?"
                elide: Text.elideLeft
            }


        }
    }
}
