// TeamSettingsPage.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import "../../components"
import "../team/"

FormCard.FormCardPage {
    id: teamSettingsPage
    title: i18nc("@title", "Team Settings")

    property int teamId: 0
    property var teamData: ({})
    property bool isLoading: teamApi.isLoading
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.ToolBar
    // Loading indicator
    header: QQC2.ToolBar {
        contentItem: RowLayout {
            Item { Layout.fillWidth: true }

            QQC2.Button {
                text: i18n("Save Changes")
                icon.name: "document-save"
                highlighted: true
                id: saveButton
                enabled: hasChanges() && !isLoading
                onClicked: {
                    inlineMsg.visible = false
                    clearStatusMessages()
                    let updatedTeam = updateTeam()
                    teamApi.updateTeam(teamData.id, updatedTeam)
                }
            }
        }
    }
    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: isLoading
        visible: running
        z: 999
    }

    function hasChanges() {
        return nameField.text !== (teamData.name || "") ||
               emailField.text !== (teamData.email || "") ||
               phoneField.text !== (teamData.phone || "") ||
               addressField.text !== (teamData.address || "")
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

    // Error message display
    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Kirigami.Units.largeSpacing
        }
    }

    // Main content
    ColumnLayout {
        anchors {
            fill: parent
            topMargin: inlineMsg.visible ? inlineMsg.height + Kirigami.Units.largeSpacing : 0
            leftMargin: Kirigami.Units.largeSpacing
            rightMargin: Kirigami.Units.largeSpacing
        }
        spacing: Kirigami.Units.largeSpacing
        enabled: !isLoading

        FormCard.FormHeader {
            title: i18nc("@title:group", "Team Profile")
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            TeamImageBannerCard {
                id: teamImageCard
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 7
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
        // FormCard.FormCard {
        //             Layout.fillWidth: true

        //             FormCard.FormButtonDelegate {
        //                 id: saveButton
        //                 text: i18n("Save Changes")
        //                 icon.name: "document-save"
        //                 enabled: hasChanges() && !isLoading

        //                 onClicked: {
        //                     inlineMsg.visible = false
        //                     clearStatusMessages()
        //                     let updatedTeam = updateTeam()
        //                     teamApi.updateTeam(teamData.id, updatedTeam)
        //                 }
        //             }
        //         }

        // Add spacer to push content up
        Item {
            Layout.fillHeight: true
        }
    }

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
            teamSettingsPage.teamData = team
            teamImageCard.imageUrl = team.image_path ? api.apiHost + team.image_path : "";
        }

        function onTeamUpdated(team) {
            applicationWindow().gnotification.showNotification(
                "",
                i18n("Team details updated successfully"),
                Kirigami.MessageType.Positive,
                "short",
                "dialog-close"
            )
            // Refresh the data to ensure we have the latest values
            teamApi.getTeam(teamSettingsPage.teamId)
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

    Component.onCompleted: {
        // Initialize with current team ID
        teamSettingsPage.teamId = api.getTeamId();

        // Fetch team data
        if (teamSettingsPage.teamId > 0) {
            teamApi.getTeam(teamSettingsPage.teamId);
        }
    }
}
