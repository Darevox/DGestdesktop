import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../updater"


FormCard.FormCardPage {
    id: aboutSettingsPage
    title: i18nc("@title", "About DIM")

    FormCard.FormHeader {
        title: i18nc("@title:group", "Updates")
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
                const component = Qt.createComponent(Qt.resolvedUrl("qrc:/qt/qml/com/dervox/dim/contents/ui/updater/UpdaterDialog.qml"));

                if (component.status === Component.Ready) {
                    const dialog = component.createObject(applicationWindow().overlay);
                    dialog.open();
                } else if (component.status === Component.Error) {
                    console.error("Error loading UpdaterDialog.qml:", component.errorString());
                }
            }
        }
    }

    FormCard.FormHeader {
        title: i18nc("@title:group", "About")
    }

    FormCard.FormCard {
        FormCard.FormCard {
            FormCard.FormTextDelegate {
                text: i18n("DIM")
                description: "inventory management and point of sale software"

            }
            FormCard.FormButtonDelegate {
                id: webSiteButton
                icon.name: "internet-services"
                text: i18n("Home page")
                onClicked: root.pageStack.layers.push(aboutkde)
            }



        }
        FormCard.FormHeader {
            title: i18n("Team")
        }
        FormCard.FormCard {
            FormCard.FormTextDelegate {
                text: i18n("Dervox ")
                description: "Dervox Team © 2025 "
            }
            FormCard.FormButtonDelegate {
                id: webSiteButton1
                icon.name: "internet-services"
                text: i18n("Home page")
                onClicked: root.pageStack.layers.push(aboutkde)
            }

        }

        // You can add more about-related information here
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
}
