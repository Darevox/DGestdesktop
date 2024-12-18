// StatusBadge.qml
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root

    // Public properties
    property string text: ""
    property color textColor: Kirigami.Theme.textColor
    property color backgroundColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.2)

    // Default size, can be overridden by setting width/height
    implicitWidth: badge.width
    implicitHeight: badge.height

    Rectangle {
        id: badge
        anchors.centerIn: parent
        width: label.width + Kirigami.Units.largeSpacing * 2
        height: label.height + Kirigami.Units.smallSpacing
        radius: 2
        color: root.backgroundColor

        QQC2.Label {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: root.textColor
            font.pointSize: Kirigami.Theme.smallFont.pointSize * 1.2
            font.weight: Font.Medium
        }
    }
}
