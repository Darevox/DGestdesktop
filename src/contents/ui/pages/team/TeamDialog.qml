// TeamDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "."
Kirigami.Dialog {
    id: teamDialog
    title: i18n("Team Details")
    padding: Kirigami.Units.largeSpacing
    width: Kirigami.Units.gridUnit * 30
    height: Kirigami.Units.gridUnit * 35
    property  int  dialogTeamId: 0
    property var teamData: ({})
    property bool isLoading: teamApi.isLoading

    QQC2.BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: isLoading
        visible: running
        z: 999
    }

    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
    }

    function updateTeam() {
        let updatedTeam = {
            name: nameField.text,
            email: emailField.text,
            phone: phoneField.text,
            address: addressField.text
        };
        return updatedTeam;
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        enabled: !isLoading

        FormCard.FormCard {
            Layout.fillWidth: true

            TeamImageBannerCard {
                id: teamImageCard
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 7
                // imageUrl: teamData.image_path ? "http://localhost:8000" + teamData.image_path : "";
                teamId: teamData.id || -1
            }

            FormCard.FormTextFieldDelegate {
                id: nameField
                label: i18n("Team Name")
                text: teamData.name || ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormTextFieldDelegate {
                id: emailField
                label: i18n("Email")
                text: teamData.email || ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormTextFieldDelegate {
                id: phoneField
                label: i18n("Phone")
                text: teamData.phone || ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormTextAreaDelegate {
                id: addressField
                label: i18n("Address")
                text: teamData.address || ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }
        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: i18n("Save")
            icon.name: "document-save"
            enabled: !isLoading
            onTriggered: {
                inlineMsg.visible = false
                clearStatusMessages()
                let updatedTeam = updateTeam()
                teamApi.updateTeam(teamData.id, updatedTeam)
            }
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: teamDialog.close()
        }
    ]

    function clearStatusMessages() {
        nameField.statusMessage = ""
        emailField.statusMessage = ""
        phoneField.statusMessage = ""
        addressField.statusMessage = ""
    }

    function handleValidationErrors(errorDetails) {
        clearStatusMessages()
        let errorObj = {}
        try {
            errorObj = JSON.parse(errorDetails)
        } catch (e) {
            console.error("Error parsing validation details:", e)
            return
        }

        const fieldMap = {
            'name': nameField,
            'email': emailField,
            'phone': phoneField,
            'address': addressField
        }

        Object.keys(errorObj).forEach(fieldName => {
                                          const field = fieldMap[fieldName]
                                          if (field) {
                                              field.statusMessage = errorObj[fieldName][0]
                                              field.status = Kirigami.MessageType.Error
                                          }
                                      })
    }

    Connections {
        target: teamApi

        function onTeamReceived(team) {
            teamDialog.teamData = team
            teamImageCard.imageUrl = team.image_path ? "https://dim.dervox.com" + team.image_path : "";
            console.log("image_path ",team.image_path)
        }

        function onTeamUpdated(team) {
            applicationWindow().gnotification.showNotification(
                        "",
                        i18n("Team details updated successfully"),
                        Kirigami.MessageType.Positive,
                        "short",
                        "dialog-ok"
                        )
            teamDialog.close()
        }

        function onTeamError(message, status, details) {
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            } else {
                inlineMsg.text = message
                inlineMsg.visible = true
                inlineMsg.type = Kirigami.MessageType.Error
            }
        }
    }
    onDialogTeamIdChanged:{
        teamApi.getTeam(teamDialog.dialogTeamId)

    }

}
