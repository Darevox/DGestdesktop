import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
Kirigami.PromptDialog {
    id: expiredDialog

    title: "Profile"
    preferredWidth: Kirigami.Units.gridUnit * 24
    standardButtons: Kirigami.Dialog.NoButton
    customFooterActions: [
        Kirigami.Action {
            text: qsTr("Logout")
            icon.name: "dialog-cancel"
            onTriggered: {
                expiredDialog.close();
            }
        }
    ]
    FormCard.FormCard {

        FormCard.FormTextDelegate {
            text: i18nc("@info", "<p>We regret to inform you that your subscription has expired.<br>
                        To continue enjoying our services without interruption,<br>
                        please renew your subscription at your earliest convenience.<br>
                        If you have any questions or need assistance,<br>
                        don't hesitate to contact our support team we're here to help!</p>")
        }
    }


    Component.onCompleted :{
    }
}
