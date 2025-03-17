import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.19 as Kirigami

Item {
    id: root

    property bool checkOnStartup: true
    property int startupDelay: 1000 // milliseconds
    property bool checkInProgress: false

    Component.onCompleted: {
        if (checkOnStartup) {
            checkTimer.start()
        }

        // Add the skipPrompt property to appUpdater if it doesn't exist
        if (typeof appUpdater.skipPrompt === "undefined") {
            appUpdater.skipPrompt = false;
        }
    }

    Timer {
        id: checkTimer
        interval: startupDelay
        repeat: false
        onTriggered: {
            checkInProgress = true
            appUpdater.checkForUpdates()
        }
    }

    Connections {
        target: appUpdater

        function onUpdateCheckFinished(hasUpdate) {
            checkInProgress = false

            // Only show prompt if an update is found AND skipPrompt is false
            if (hasUpdate && !appUpdater.skipPrompt) {
                updaterPrompt.open()
            }
        }

        function onDownloadError(errorMessage) {
            checkInProgress = false
        }
    }

    Kirigami.PromptDialog {
        id: updaterPrompt
        title: i18n("Update Available")
        standardButtons: Kirigami.Dialog.Yes | Kirigami.Dialog.No
        onAccepted: {
            // Use absolute path with Qt.resolvedUrl
            const component = Qt.createComponent(Qt.resolvedUrl("UpdaterDialog.qml"))

            if (component.status === Component.Ready) {
                const dialog = component.createObject(applicationWindow().overlay)
                if (dialog) {
                    dialog.open()
                } else {
                    console.error("Failed to create UpdaterDialog instance")
                }
            } else if (component.status === Component.Error) {
                console.error("Error loading UpdaterDialog.qml:", component.errorString())
            }
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: "system-software-update"
                width: Kirigami.Units.iconSizes.large
                height: width
                Layout.alignment: Qt.AlignHCenter
            }

            Controls.Label {
                width: Math.min(Kirigami.Units.gridUnit * 20, parent.width)
                text: i18n("A new version (%1) of the application is available. Would you like to update now?",
                          appUpdater.latestVersion)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Controls.Label {
                visible: appUpdater.changelog.length > 0
                width: Math.min(Kirigami.Units.gridUnit * 20, parent.width)
                text: i18n("Key changes: %1", appUpdater.changelog.split("\n")[0]) // Just show first line
                wrapMode: Text.WordWrap
                font.italic: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
