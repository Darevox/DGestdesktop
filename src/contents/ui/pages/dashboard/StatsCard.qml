import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 5

    property string title: ""
    property string value: ""
    property string subtitle: ""
    property string iconCard: ""
    property color valueColor: Kirigami.Theme.textColor

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: root.iconCard
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                level: 2
                text: root.title
            }

            Label {
                text: root.subtitle
                opacity: 0.7
            }

            Kirigami.Heading {
                level: 1
                text: root.value
                color: root.valueColor
            }
        }
    }
}
