// StatsCard.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: root

    // Fixed height for consistency
    implicitHeight: Kirigami.Units.gridUnit * 8

    // Check if card is narrow
    property bool isNarrow: width < Kirigami.Units.gridUnit * 15

    property string title: ""
    property string value: ""
    property string subtitle: ""
    property string iconCard: ""
    property color valueColor: Kirigami.Theme.textColor

    contentItem: Item {
        anchors.fill: parent

        // Choose layout based on width
        Loader {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            sourceComponent: isNarrow ? narrowLayout : wideLayout
        }

        Component {
            id: wideLayout

            RowLayout {
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: root.iconCard
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Kirigami.Heading {
                        level: 3
                        text: root.title
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Kirigami.Heading {
                        level: 2
                        text: root.value
                        color: root.valueColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Fixed subtitle with constrained height
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: Kirigami.Units.gridUnit * 1.5
                        Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                        clip: true // Ensure text doesn't overflow

                        Label {
                            id: wideSubtitle
                            width: parent.width
                            anchors.top: parent.top
                            text: root.subtitle
                            opacity: 0.7
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9 // Slightly smaller text
                        }
                    }
                }
            }
        }

        Component {
            id: narrowLayout

            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: root.iconCard
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    Layout.alignment: Qt.AlignHCenter
                }

                Kirigami.Heading {
                    level: 3
                    text: root.title
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Kirigami.Heading {
                    level: 2
                    text: root.value
                    color: root.valueColor
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Fixed subtitle with constrained height
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                    Layout.maximumHeight: Kirigami.Units.gridUnit * 1.5
                    clip: true // Ensure text doesn't overflow
                     Label {
                        id: narrowSubtitle
                        width: parent.width
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin:  Kirigami.Units.smallSpacing
                         text: root.subtitle
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        maximumLineCount: 1 // Only one line in narrow view
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9 // Slightly smaller text
                    }
                }
            }
        }
    }
}
