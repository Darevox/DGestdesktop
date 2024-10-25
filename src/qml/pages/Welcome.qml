import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import org.kde.kirigamiaddons.components as Kcomponents

Kirigami.ScrollablePage {
    title: "Welecome"
    Layout.fillWidth: true
    header: Kirigami.ApplicationHeaderStyle.None
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.ToolBar
    footer:  Kirigami.ApplicationHeaderStyle.None

    actions:[
        Kirigami.Action{
            icon.name: "notifications"
            onTriggered:{
                applicationWindow().gnotification.showNotification("",
                                                                         "Operation completed successfully", // message
                                                                         Kirigami.MessageType.Positive, // message type
                                                                         "short", // timeout
                                                                         "Undo", // action text
                                                                         function() { console.log("Undo clicked") }
                                                                         )

            }
        },
        Kirigami.Action{
            icon.name: "notifications"
        }
    ]

    Controls.Label {
        anchors.centerIn: parent
        text: i18n("Hello World!")
    }
    Component.onCompleted: {
        applicationWindow().loadGlobalDrawer()
        applicationWindow().loadHeader()

    }
}
