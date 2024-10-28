import QtQuick 2.15
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Rectangle {
    id:root
    color:"transparent"
    property string errorDetails: ""
    signal reconnectClicked()
    property bool isRequasting: false
    ColumnLayout{
        spacing:Kirigami.Units.largeSpacing * 2
        anchors.centerIn:parent
        Kirigami.Icon {
            source:"network-disconnect-symbolic"
            implicitWidth:Kirigami.Units.iconSizes.enormous
            implicitHeight: Kirigami.Units.iconSizes.enormous

        }
        Item{}
        Kirigami.Heading{
            text:"Not internet connection "
            level : 1
        }
        Item{        Layout.fillHeight:true
        }
        QQC2.Label {
            Layout.fillHeight:true

            text: "<p><strong>Try : </strong></p>
                       <ul>
                       <li>Checking the network cables, modem, and router </li>
                       <li>Reconnecting to Wi-Fi </li>
                       </ul>
                       <p>ERROR : "+errorDetails+" </p>"
        }

            Kirigami.Action {
                text: "action 1"
                icon.name: "view-list-icons"
            }
            QQC2.Button {
                id: reconnectButton
                icon.name: "network-connect"
                Layout.alignment: Qt.AlignRight
                text: "Try Again"
                onClicked: {
                    root.isRequasting=true
                    root.reconnectClicked()
                }
                enabled:!root.isRequasting
            }
        }
    }
