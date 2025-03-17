import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Kirigami.Dialog {
    id: updateDialog
    title: i18n("Application Update")
    width: Kirigami.Units.gridUnit * 25
    height: Kirigami.Units.gridUnit * 25

    closePolicy: {
        if (appUpdater && appUpdater.downloading) {
            // Prevent any closing while downloading
            return Kirigami.Dialog.NoClose
        } else {
            // Allow escape key when not downloading
            return Kirigami.Dialog.CloseOnEscape
        }
    }
    // Also add a handler to properly confirm before closing if a download is in progress


    // Set padding for the content area
    padding: Kirigami.Units.gridUnit

    // Hide standard buttons
    standardButtons: Kirigami.Dialog.NoButton

    property bool hasButtons: true
    property bool cancelButtonVisible: false
    property bool updateButtonVisible: hasButtons
    property bool updateButtonEnabled: true
    property string updateButtonText: i18n("Download & Install")

    function checkForUpdates() {
        statusText.text = i18n("Checking for updates...")
        progressIndicator.running = true
        progressIndicator.visible = true
        appUpdater.checkForUpdates()
    }

    Connections {
        target: appUpdater

        function onUpdateCheckFinished(hasUpdate) {
            progressIndicator.running = false
            progressIndicator.visible = false

            if (hasUpdate) {
                statusText.text = i18n("Update available: %1", appUpdater.latestVersion)
                updateAvailableView.visible = true
                noUpdateView.visible = false
                // Show the button since an update is available
                updateButtonVisible = true
            } else {
                statusText.text = i18n("You have the latest version: %1", appUpdater.currentVersion)
                updateAvailableView.visible = false
                noUpdateView.visible = true
                // Hide the button since no update is available
                updateButtonVisible = false
            }
        }


        function onDownloadProgressChanged() {
            downloadProgress.value = appUpdater.downloadProgress
        }

        function onDownloadFinished(filePath) {
            statusText.text = i18n("Update downloaded successfully!")
        }

        function onDownloadError(errorMessage) {
            progressIndicator.running = false
            progressIndicator.visible = false
            statusText.text = i18n("Error: %1", errorMessage)

            downloadProgress.visible = false
            cancelButtonVisible = false
            updateButtonEnabled = true
            updateButtonText = i18n("Retry")
        }

        function onDownloadingChanged() {
            if (appUpdater.downloading) {
                updateButtonText = i18n("Downloading...")
                updateButtonEnabled = false
                downloadProgress.visible = true
                cancelButtonVisible = true
            } else {
                updateButtonText = i18n("Download & Install")
                updateButtonEnabled = true
                downloadProgress.visible = false
                cancelButtonVisible = false
            }
        }

        function onUpdateInstallProgressChanged(percent) {
            installProgressDialog.progress = percent
            if (!installProgressDialog.visible) {
                installProgressDialog.open()
            }
        }

        function onUpdateInstallFinished() {
            installProgressDialog.close()
        }
    }

    // Main content item
    ColumnLayout {
        id: mainColumn
        // Don't use anchors here, use Layout properties
        spacing: Kirigami.Units.largeSpacing

        // These Layout properties ensure the column fills the available space
        Layout.fillWidth: true

        // Header section with status text
        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                id: statusText
                Layout.fillWidth: true
                text: i18n("Check for updates")
                level: 2
            }

            Controls.BusyIndicator {
                id: progressIndicator
                running: false
                visible: false
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
            }
        }

        // Content Stack - only one view visible at a time
        Item {
            // This container holds both views but only one is visible at a time
            Layout.fillWidth: true
            Layout.fillHeight: true

            // No update view
            ColumnLayout {
                id: noUpdateView
                anchors.fill: parent
                visible: false
                spacing: Kirigami.Units.largeSpacing

                Item { Layout.fillHeight: true }  // Push content to vertical center

                Kirigami.Icon {
                    source: "dialog-ok-apply"
                    width: Kirigami.Units.iconSizes.huge
                    height: width
                    Layout.alignment: Qt.AlignHCenter
                }

                Kirigami.Heading {
                    text: i18n("Your application is up to date!")
                    level: 2
                    Layout.alignment: Qt.AlignHCenter
                }

                Controls.Label {
                    text: i18n("Current version: %1", appUpdater.currentVersion)
                    Layout.alignment: Qt.AlignHCenter
                }

                Controls.Button {
                    text: i18n("Check Again")
                    icon.name: "view-refresh"
                    Layout.alignment: Qt.AlignHCenter

                    onClicked: {
                        checkForUpdates()
                    }
                }

                Item { Layout.fillHeight: true }  // Push content to vertical center
            }

            // Update available view
            ColumnLayout {
                id: updateAvailableView
                anchors.fill: parent
                visible: false
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: "get-hot-new-stuff"
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    Layout.alignment: Qt.AlignHCenter
                }

                Kirigami.Heading {
                    text: i18n("New version available: %1", appUpdater.latestVersion)
                    level: 2
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Controls.Label {
                    text: i18n("Current version: %1", appUpdater.currentVersion)
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                // Changelog section
                Kirigami.Heading {
                    text: i18n("What's New:")
                    level: 4
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    visible: appUpdater.changelog.length > 0
                }

                Controls.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Kirigami.Units.gridUnit * 6
                    clip: true

                    Controls.TextArea {
                        id: changelogText
                        text: appUpdater.changelog
                        readOnly: true
                        textFormat: TextEdit.MarkdownText

                        // This ensures the text area uses the full width of the ScrollView
                        width: parent.width

                        background: Rectangle {
                            color: Kirigami.Theme.backgroundColor
                            border.color: Kirigami.Theme.disabledTextColor
                            border.width: 1
                            radius: 4
                        }
                    }
                }
                Controls.ProgressBar {
                    id: downloadProgress
                    Layout.fillWidth: true
                    visible: false
                    from: 0
                    to: 1

                    // Extra spacing AFTER the progress bar
                    Layout.bottomMargin: Kirigami.Units.gridUnit

                    // Show percentage text
                    Controls.Label {
                        anchors.centerIn: parent
                        text: Math.round(downloadProgress.value * 100) + "%"
                        color: Kirigami.Theme.textColor
                        visible: downloadProgress.visible && downloadProgress.value > 0
                    }
                }

                // This is a key part - add a flexible spacer at the bottom of the content
                // to push everything up and make room for the progress bar
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    visible: !downloadProgress.visible // Only use spacer when no progress bar
                }
            }
        }
    }

    // Use customFooterActions for action buttons
    customFooterActions: [
        Kirigami.Action {
            id: cancelButtonInternal
            text: i18n("Cancel")
            visible: cancelButtonVisible
            icon.name: "dialog-cancel"
            onTriggered: {
                // Show confirmation dialog first
                confirmCancelDialog.open()
            }
        },

        Kirigami.Action {
            id: updateButtonInternal
            text: updateButtonText
            // Only show the button when an update is available
            visible: updateButtonVisible && appUpdater.updateAvailable
            enabled: updateButtonEnabled
            icon.name: "get-hot-new-stuff"
            onTriggered: {
                appUpdater.downloadAndInstall()
            }
        }
    ]

    // Installation progress dialog
    UpdateProgressDialog {
        id: installProgressDialog
        parent: updateDialog.parent
        closePolicy: Kirigami.Dialog.NoAutoClose
    }


        Kirigami.PromptDialog {
            id: confirmCancelDialog
            title: i18n("Cancel Download?")
            standardButtons: Kirigami.Dialog.Cancel | Kirigami.Dialog.Ok

            // Make the OK button red to indicate it's destructive
            // Adjust based on your Kirigami version
          //  buttonSectionLayout.okButton.text: i18n("Cancel Download")

            // Place in center of parent dialog
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            parent: updateDialog

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    level: 4
                    Layout.fillWidth: true
                    text: i18n("Are you sure you want to cancel the download?")
                    wrapMode: Text.WordWrap
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: i18n("The download will be aborted and you'll need to restart it later.")
                    wrapMode: Text.WordWrap
                }
            }

            onAccepted: {
                // User confirmed cancellation - safely cancel the download
                if (appUpdater && appUpdater.downloading) {
                    appUpdater.cancelDownload()
                }
            }
        }


    Component.onCompleted: {
        // CRITICAL NEW CODE: Set the skip prompt flag before checking for updates
        if (typeof appUpdater !== "undefined") {
            // Save original state
            var originalSkipPrompt = appUpdater.skipPrompt;

            // Set skip prompt to true for this check
            appUpdater.skipPrompt = true;

            // Check for updates
            checkForUpdates();

            // Restore original state after a delay
            var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {interval: 1000; repeat: false; running: true;}',
                                          updateDialog);
            timer.triggered.connect(function() {
                appUpdater.skipPrompt = originalSkipPrompt;
                timer.destroy();
            });
        } else {
            // Just check for updates if we can't access the appUpdater
            checkForUpdates();
        }
    }

    // Handle cleanup when the dialog closes
    onClosed: {
        // Make sure any lingering settings are reset
        if (typeof appUpdater !== "undefined") {
            appUpdater.skipPrompt = false;
        }
    }
}
