import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

Kirigami.PromptDialog {
    id: expiredDialog

    title: i18nc("@title", "Subscription Status")
    preferredWidth: Kirigami.Units.gridUnit * 24
    standardButtons: Kirigami.Dialog.NoButton

    // Main content
    FormCard.FormCard {
        Layout.fillWidth: true

        // FormCard.FormHeader {
        //     title: i18nc("@title", "Subscription Status")
        // }

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            source: "dialog-warning"
        }

        FormCard.FormTextDelegate {
            description: "<p>" + i18n("We regret to inform you that your subscription has expired.") + "</p>" +
                 "<p>" + i18n("To continue enjoying our services without interruption, please renew your subscription at your earliest convenience.") + "</p>" +
                 "<p>" + i18n("If you have any questions or need assistance, don't hesitate to contact our support team - we're here to help!") + "</p>"
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormButtonDelegate {
            icon.name: "internet-services"
            text: i18nc("@action:button", "Renew Subscription")
            onClicked: Qt.openUrlExternally("https://dim.dervox.com/")
        }

        FormCard.FormDelegateSeparator {}

        FormCard.FormButtonDelegate {
            icon.name: "help-contents"
            text: i18nc("@action:button", "Contact Support")
            onClicked: Qt.openUrlExternally("https://dim.dervox.com/")
        }
    }

    // Footer actions
    customFooterActions: [
        // Kirigami.Action {
        //     text: i18nc("@action:button", "Later")
        //     icon.name: "chronometer"
        //     onTriggered: expiredDialog.close()
        // },
        Kirigami.Action {
            text: i18nc("@action:button", "Logout")
            icon.name: "system-log-out"
            onTriggered: {
                // Add your logout logic here
                expiredDialog.close()
            }
        }
    ]

    // Optional: Add a property to track if the dialog should be shown again
    property bool dontShowAgain: false

    Component.onCompleted: {
        // Optional: Add any initialization logic here
    }

    // Optional: Add a method to show the dialog with animation
    function show() {
        open()
        // Optional: Add any animation or additional logic here
    }
}
