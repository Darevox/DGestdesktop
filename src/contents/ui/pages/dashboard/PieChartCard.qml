// PieChartCard.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls

Kirigami.AbstractCard {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 16
 Layout.minimumWidth: Kirigami.Units.gridUnit * 15
    // Card properties
    property string title: ""
    property string subtitle: ""
    property var names: []
    property var values: []
    property var colors: []

    // Adaptive layout properties
    property bool isNarrow: width < Kirigami.Units.gridUnit * 20

    contentItem: ColumnLayout {
        id: mainLayout
        spacing: Kirigami.Units.smallSpacing
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing

        // Header - Similar to LineChartCard
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                Kirigami.Heading {
                    level: 3
                    text: root.title
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text: root.subtitle
                    opacity: 0.7
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Add value if needed
            // Item {
            //     Layout.fillWidth: true
            // }
            // Kirigami.Heading {
            //     level: 1
            //     text: "100 DH" // Sample value if needed
            //     color: Kirigami.Theme.positiveTextColor
            //     elide: Text.ElideRight
            // }
        }

        // Main chart content
        Item {
            id: chartContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            visible: root.values.length > 0

            // Main pie chart - takes most of the space
            Item {
                id: chartArea
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: legendContainer.top
                    bottomMargin: Kirigami.Units.smallSpacing
                    // Only use part of the width on desktop
                    right: isNarrow ? parent.right : parent.right - Kirigami.Units.gridUnit * 10
                }

                Charts.PieChart {
                    id: chart
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing

                    colorSource: Charts.ArraySource {
                        array: root.colors
                    }

                    valueSources: [
                        Charts.ArraySource {
                            array: root.values
                        }
                    ]
                }
            }

            // Right-side desktop legend
            Rectangle {
                id: desktopLegend
                anchors {
                    left: chartArea.right
                    right: parent.right
                    top: parent.top
                    bottom: legendContainer.top
                    bottomMargin: Kirigami.Units.smallSpacing
                }
                visible: !isNarrow && root.values.length > 0
                color: "transparent"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing

                    Column {
                        spacing: Kirigami.Units.smallSpacing
                        width: parent.width

                        Repeater {
                            model: Math.min(root.names.length, root.values.length)
                            delegate: RowLayout {
                                width: parent.width
                                spacing: Kirigami.Units.smallSpacing

                                Rectangle {
                                    width: Kirigami.Units.iconSizes.small
                                    height: width
                                    radius: width / 2
                                    color: root.colors[index % root.colors.length]
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: root.names[index]
                                    font.pointSize: 8
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: root.values[index].toFixed(2) + " DH"
                                    font.pointSize: 8
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }
            }

            // Bottom legend container - for mobile view
            Rectangle {
                id: legendContainer
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: isNarrow ? Kirigami.Units.gridUnit * 3 : Kirigami.Units.gridUnit
                color: "transparent"
                visible: isNarrow && root.values.length > 0

                Flow {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    // Only show in mobile view
                    visible: isNarrow

                    Repeater {
                        model: Math.min(root.names.length, root.values.length)

                        RowLayout {
                            height: Kirigami.Units.gridUnit
                            spacing: 4
                            width: Math.min(parent.width / 2, Kirigami.Units.gridUnit * 8)

                            Rectangle {
                                width: Kirigami.Units.iconSizes.small / 1.5
                                height: width
                                radius: width / 2
                                color: root.colors[index % root.colors.length]
                            }

                            Label {
                                Layout.fillWidth: true
                                text: root.names[index]
                                font.pointSize: 7
                                elide: Text.ElideRight
                            }

                            Label {
                                text: Number(root.values[index]).toFixed(0)
                                font.pointSize: 7
                                elide: Text.ElideRight
                            }
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
