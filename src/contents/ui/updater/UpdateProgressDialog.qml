import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Kirigami.Dialog {
    id: progressDialog
    title: i18n("Installing Update")
    standardButtons: Kirigami.Dialog.NoButton
    closePolicy: Controls.Popup.NoAutoClose
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 10
    padding:  Kirigami.Units.gridUnit * 2
    property int progress: 0

    // Add progress change monitoring
    onProgressChanged: {
        // Reset timer when progress changes
        progressTimer.restart()
    }

    // Timer to detect stalled updates
    Timer {
        id: progressTimer
        interval: 30000 // 30 seconds
        running: false
    }

  ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: "system-software-update"
            width: Kirigami.Units.iconSizes.large
            height: width
            Layout.alignment: Qt.AlignHCenter
        }

        Controls.Label {
            text: i18n("Installing update, please wait...")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Controls.ProgressBar {
            id: installProgress
            from: 0
            to: 100
            value: progress
            Layout.fillWidth: true

            // Show percentage text
            Controls.Label {
                anchors.centerIn: parent
                text: Math.round(progress) + "%"
                color: Kirigami.Theme.textColor
            }
        }

        Controls.Label {
            text: i18n("Please do not close the application during the update process.")
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            opacity: 0.7
        }
    }

    // Provide a way to close the app if update gets stuck
    footer: RowLayout {
        Controls.Button {
            text: i18n("Force Quit Application")
            icon.name: "application-exit"
            visible: progress > 0 && progress < 100 && progressTimer.running

            onClicked: {
                Qt.quit()
            }
        }

        // Start the timer when dialog opens
        Component.onCompleted: {
            progressTimer.start()
        }
    }
}
