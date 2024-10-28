import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
Kirigami.PromptDialog {
    id: profileDialog
    property bool isLoading: false
    property string userFullName: ""
    property string userEmail: ""

    title: "Profile"
    preferredWidth: Kirigami.Units.gridUnit * 24
    standardButtons: Kirigami.Dialog.NoButton
    customFooterActions: [
        Kirigami.Action {
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                profileDialog.close();
            }
        }
    ]

    FormCard.FormHeader {
        title: i18n("Plan")
    }

    FormCard.FormCard {
        FormCard.FormTextDelegate {
            text: i18n("Current plan : ") + "sss"
            description: "Expired on : " + "2090"

        }
        FormCard.FormButtonDelegate {
            id: upgradeButton
            icon.name: "go-up-symbolic"
            text: i18n("Upgrade plan")
            onClicked: root.pageStack.layers.push(aboutkde)
        }
    }
    FormCard.FormHeader {
        title: i18n("User information")
    }
    FormCard.FormCard {
        visible:!isLoading
        FormCard.FormTextDelegate {
            text: i18n("Full name : ") + profileDialog.userFullName
        }
        FormCard.FormTextDelegate {
            text: i18n("Email : ") + profileDialog.userEmail
        }
        FormCard.FormButtonDelegate {
            id: editProfileButton
            icon.name: "user-info-symbolic"
            text: i18n("Edit profile")
            onClicked: root.pageStack.layers.push(aboutkde)
        }

    }
    FormCard.FormCard {
        visible:isLoading
        padding:10
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width
            }
        }
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width/2
            }
        }
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width
            }
        }
    }
    function getProfile(){
        api.getUserInfo();
    }

    Connections {
        target: api
        function onUserInfoReceived() {
            profileDialog.userFullName= api.getUserName()
            profileDialog.userEmail= api.getUserEmail()
            profileDialog.isLoading=false

        }
    }
    Component.onCompleted :{
        profileDialog.isLoading=true
        getProfile()
    }
}
