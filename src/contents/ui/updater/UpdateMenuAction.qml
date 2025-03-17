import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.19 as Kirigami

Kirigami.Action {
    id: updateAction
    text: i18n("Check for Updates")
    icon.name: checkInProgress ? "process-working" : "system-software-update"

    property bool checkInProgress: false
    property bool updateAvailable: appUpdater.updateAvailable

    // Add an indicator when updates are available
    Controls.ToolTip.text: updateAvailable ?
        i18n("Update to version %1 available", appUpdater.latestVersion) :
        i18n("Check for application updates")

    Controls.ToolTip.visible: hovered
    Controls.ToolTip.delay: 1000

    // Badge to show there's an update
    Controls.Label {
        id: badge
        visible: updateAvailable
        text: "!"
        color: "white"

        anchors {
            top: parent.top
            right: parent.right
        }

        background: Rectangle {
            color: Kirigami.Theme.positiveTextColor
            radius: width / 2
            width: Kirigami.Units.gridUnit * 0.8
            height: width
        }
    }

    onTriggered: {
        checkInProgress = true
        // Create the dialog
        const component = Qt.createComponent("updater/UpdaterDialog.qml")
        if (component.status === Component.Ready) {
            const dialog = component.createObject(applicationWindow().overlay)
            dialog.open()

            // Update status when dialog closes
            dialog.closed.connect(function() {
                checkInProgress = false
            })
        } else if (component.status === Component.Error) {
            console.error("Error loading UpdaterDialog.qml:", component.errorString())
            checkInProgress = false
        }
    }

    // Handle update status changes
    Connections {
        target: appUpdater

        function onUpdateAvailableChanged() {
            // Update the icon when update status changes
            if (appUpdater.updateAvailable) {
                // Optionally change icon to something that indicates updates are available
                updateAction.icon.name = "update-low"
            } else {
                updateAction.icon.name = "system-software-update"
            }
        }
    }
}
