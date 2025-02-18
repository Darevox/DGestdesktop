import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "transparent"
    property string errorDetails: ""
    signal reconnectClicked()
    property bool isRequasting: false

    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        icon.name: "network-disconnect-symbolic"
        text: i18n("No Internet Connection")
        explanation: i18nc("@info:placeholder",
            "Please check your network connection and try again. " +
            "Check network cables, modem, and router, or try reconnecting to Wi-Fi.\n\n" +
            "Error: %1", errorDetails || i18n("Unknown error"))

        helpfulAction: Kirigami.Action {
            id: reconnectButton
            icon.name: "network-connect"
            text: i18nc("@action:button", "Try Again")
            onTriggered: {
                root.isRequasting = true
                root.reconnectClicked()
            }
            enabled: !root.isRequasting
        }
    }
}
