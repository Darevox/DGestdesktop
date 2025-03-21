import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import org.kde.kirigamiaddons.components as Kcomponents
import "../components"
import "team/"
import "../updater"
FormCard.FormCardPage {
    id: root
    property bool isLoading: false
    property string userFullName: ""
    property int teamId: 0
    title: i18nc("@title", "Settings")
    actions: [
        Kirigami.Action {
            icon.name: "gnumeric-group"
            text:  i18n("Team Settings")
            onTriggered: {
                teamDetailsDialog.active = true
            }
        }
    ]
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

        // FormCard.FormDelegateSeparator {
        //     above: combobox
        //     below: checkbox
        // }

        // FormCard.FormCheckDelegate {
        //     id: checkbox
        //     text: i18nc("@option:check", "Show Tray Icon")
        //     checked: trayManager.showInTray
        //     onCheckedChanged: trayManager.showInTray = checked
        //     onToggled: {
        //         if (checkState) {
        //             console.info("A tray icon appears on your system!")
        //         } else {
        //             console.info("The tray icon disappears!")
        //         }
        //     }
        // }
        FormCard.FormSectionText{
            text: i18n("Scale UI")
        }
        FormCard.FormSectionText {
            RowLayout {
                anchors.fill: parent
                QQC2.Slider {
                    id: scaleSlider
                    Layout.fillWidth: true
                    from: 50
                    to: 200
                    stepSize: 5
                    snapMode: QQC2.Slider.SnapOnRelease
                    value: appSettings.scaleValue

                    property bool wasPressed: false

                    onPressedChanged: {
                        if (pressed) {
                            wasPressed = true;
                        } else if (wasPressed) {
                            wasPressed = false;
                            if (value !== appSettings.scaleValue) {
                                restartPromptDialog.open();
                            }
                        }
                    }
                }
                QQC2.Label {
                    text: scaleSlider.value + "%"
                }
            }
        }
        FormCard.FormSectionText{
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
        title: i18nc("@title:group", "DIM")
    }
    FormCard.FormCard {


        // Update check delegate
        FormCard.FormButtonDelegate {
            id: updateCheckButton
            icon.name: appUpdater.updateAvailable ? "update-low" : "system-software-update"
            text: appUpdater.updateAvailable ?
                  i18nc("@action:button", "Update Available: %1", appUpdater.latestVersion) :
                  i18nc("@action:button", "Check for Updates")

            description: appUpdater.updateAvailable ?
                         i18n("A new version is available to install") :
                         i18n("Your current version: %1", appUpdater.currentVersion || "1.0")

            // Badge to show there's an update
            leading: appUpdater.updateAvailable ? updateBadge : null

            onClicked: {
                // Set the skip prompt flag before opening the dialog
                if (typeof appUpdater !== "undefined") {
                    appUpdater.skipPrompt = true;
                }

                // Create and open the dialog
                const component = Qt.createComponent(Qt.resolvedUrl("../updater/UpdaterDialog.qml"));

                if (component.status === Component.Ready) {
                    const dialog = component.createObject(applicationWindow().overlay);
                    dialog.open();
                } else if (component.status === Component.Error) {
                    console.error("Error loading UpdaterDialog.qml:", component.errorString());
                }
            }
        }


            // Badge component shown when updates are available
            Component {
                id: updateBadge

                Rectangle {
                    width: Kirigami.Units.gridUnit
                    height: width
                    radius: width / 2
                    color: Kirigami.Theme.positiveTextColor

                    QQC2.Label {
                        anchors.centerIn: parent
                        text: "!"
                        color: "white"
                        font.bold: true
                        font.pixelSize: parent.width * 0.7
                    }
                }
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
            root.teamId =  api.getTeamId()
            root.isLoading=false

        }
    }
    Kirigami.PromptDialog {
        id: restartPromptDialog
        title: i18n("Scale Change")
        subtitle: i18n("The application needs to restart to apply the new scale. Do you want to restart now?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            appSettings.applyScale(scaleSlider.value)
            appSettings.makeRestart()
        }
        onRejected: {
            scaleSlider.value = appSettings.scaleValue
        }
    }
    Loader {
        id: teamDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: TeamDialog{}
        onLoaded: {
            item.dialogTeamId = root.teamId
            item.open()
        }

        Connections {
            target: teamDetailsDialog.item
            function onClosed() {
                teamDetailsDialog.active = false
            }
        }
    }
    Component.onCompleted:{
        getProfile();
        root.isLoading=true
    }

}
