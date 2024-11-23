import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
Kirigami.PromptDialog {
    id: profileDialog
    property bool isLoading: false
    property bool isLoadingPlan: false
    property string userFullName: ""
    property string userEmail: ""
    property string planName: ""
    property string planStatus: ""
    property string planExpiredDate: ""

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
        visible:!isLoadingPlan
        FormCard.FormTextDelegate {
            text: i18n("Current plan : ") +  profileDialog.planName
            description: "Expired on : " + profileDialog.planExpiredDate
        }
        FormCard.FormTextDelegate {
            text: i18n("Plan Status : ") +  profileDialog.planStatus

        }
        FormCard.FormButtonDelegate {
            id: upgradeButton
            icon.name: "go-up-symbolic"
            text: i18n("Upgrade plan")
            onClicked: Qt.openUrlExternally("https://dim.dervox.com")
        }
    }
    FormCard.FormCard {
        visible:isLoadingPlan
        FormCard.FormSectionText {
            SkeletonLoaders{
                height:20
                width:parent.width
            }

        }
        FormCard.FormSectionText {
            SkeletonLoaders{
                height:20
                width:parent.width
            }

        }
        FormCard.FormSectionText {
            SkeletonLoaders{
                height:20
                width:parent.width
            }
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
            onClicked: Qt.openUrlExternally("https://dim.dervox.com")
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
        subscriptionApi.getStatus("");
    }

    Connections {
        target: api
        function onUserInfoReceived() {
            profileDialog.userFullName= api.getUserName()
            profileDialog.userEmail= api.getUserEmail()
            profileDialog.isLoading=false
        }

    }
    Connections {
        target: subscriptionApi
        function onStatusReceived() {
            profileDialog.planName= subscriptionApi.getType()
            profileDialog.planExpiredDate= subscriptionApi.getExpirationDate()
            profileDialog.planStatus= subscriptionApi.getStatusString()
            profileDialog.isLoadingPlan=false
        }
    }
    Component.onCompleted :{
        profileDialog.isLoading=true
        profileDialog.isLoadingPlan=true
        isLoadingPlan
        getProfile()
    }
}
