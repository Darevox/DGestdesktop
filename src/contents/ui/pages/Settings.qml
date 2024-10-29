import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.components as Kcomponents
import "../components"

FormCard.FormCardPage {
    id: root
    property bool isLoading: false
    property string userFullName: ""

    title: i18nc("@title", "Settings")

    FormCard.FormHeader {
        title: i18nc("@title:group", "General")
    }

    FormCard.FormCard {
        // FormCard.FormTextDelegate {
        //     text: i18nc("@info", "Current Color Scheme")
        //     description: "Breeze"
        // }

        FormCard.FormComboBoxDelegate {
            id: combobox
            text: i18nc("@label:listbox", "Current Color Scheme")
            displayMode: FormCard.FormComboBoxDelegate.ComboBox
            editable: false
            model: isEmpty ? [{"display": i18nc("@label:listbox", "No color schemes available")}] : applicationWindow().gColorSchemeModel
            textRole: "display"
            valueRole: "index"
            currentIndex: applicationWindow().gColorSchemeModel.activeSchemeIndex
            property bool isEmpty: applicationWindow().gColorSchemeModel.count === 0

            Component.onCompleted: {
            }

            onCurrentIndexChanged: {
                console.log("DDDD")
                applicationWindow().gColorSchemeModel.activateScheme(currentIndex);
            }
        }

        FormCard.FormDelegateSeparator {
            above: combobox
            below: checkbox
        }

        FormCard.FormCheckDelegate {
            id: checkbox
            text: i18nc("@option:check", "Show Tray Icon")
            checked: trayManager.showInTray
            onCheckedChanged: trayManager.showInTray = checked
            onToggled: {
                if (checkState) {
                    console.info("A tray icon appears on your system!")
                } else {
                    console.info("The tray icon disappears!")
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18nc("@title:group", "Accounts")
    }

    FormCard.FormCard {
        visible:!isLoading
        FormCard.FormSectionText {
            text: i18nc("@info:whatsthis", "Online Account Settings")
        }
        FormCard.FormTextDelegate {
            id: lastaccount
            leading: Kirigami.Icon {source: "user"}
            text: root.userFullName
            description: i18nc("@info:credit", "Admin")
        }
        FormCard.FormDelegateSeparator {
            above: lastaccount
            below: addaccount
        }
        FormCard.FormButtonDelegate {
            id: addaccount
            icon.name: "documentinfo"
            text: i18nc("@action:button", "Profile information")
            onClicked: applicationWindow().gprofileDialog.active=true
        }
    }
    FormCard.FormCard {
        visible:isLoading
        padding:10
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
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width /1.5
            }
        }
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width /1.2
            }
        }
    }
    FormCard.FormHeader {
        title: i18nc("@title:group", "DGest")
    }
    FormCard.FormCard {
        FormCard.FormTextDelegate {
            text: i18nc("@info", "Version")
            description: "1.0 Mona"
        }
        FormCard.FormButtonDelegate {
            id: abooutUs
            icon.name: "documentinfo"
            text: i18nc("@action:button", "About")
            onClicked: {
                applicationWindow().gaboutDialog.active=true
            }
        }
    }
    function getProfile(){
        api.getUserInfo();
    }

    Connections {
        target: api
        function onUserInfoReceived() {
            root.userFullName= api.getUserName()
            root.isLoading=false

        }
    }
    Component.onCompleted:{
        getProfile();
        root.isLoading=true
    }

}
