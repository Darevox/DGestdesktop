import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls

Kirigami.AbstractCard {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 13

    // Card properties
    property string title: ""
    property string subtitle: ""
    property var names: []
    property var values: []
    property var colors: []

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing

            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                Layout.fillWidth: true

                Kirigami.Heading {
                    level: 3
                    text: root.title
                }

                Label {
                    text: root.subtitle
                    opacity: 0.7
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.values.length > 0

            Charts.PieChart {
                id: chart
                anchors.fill: parent

                colorSource: Charts.ArraySource {
                    array: root.colors
                }

                valueSources: [
                    Charts.ArraySource {
                        array: root.values
                    }
                ]
            }

            // Legend
            Column {
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.largeSpacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: Math.min(root.names.length, root.values.length)

                    delegate: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Rectangle {
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            radius: width / 2
                            color: root.colors[index % root.colors.length]
                        }

                        Label {
                            text: root.names[index]
                            font.pointSize: 8
                        }

                        Label {
                            text: "€" + root.values[index].toFixed(2)
                            font.pointSize: 8
                            opacity: 0.7
                        }
                    }
                }
            }
        }

        // Show message when no data
        Label {
            visible: root.values.length === 0
            text: i18n("No data available")
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
