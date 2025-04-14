// PieChartCard.qml (Fixed Version with Visible Circle)
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

    // Avoid creating empty chart
    property bool hasValidData: root.values.length > 0 && root.values.some(function(val) { return val > 0; })

    // Add a property to track data changes
    property int dataUpdateCounter: 0

    // Function to handle data changes
    function handleDataChange() {
        // Forcing update by changing counter
        dataUpdateCounter++;

        // Clear and reset chart data with a slight delay to ensure UI updates
        chartResetTimer.restart();
    }

    // Connect data change signals to handler
    onNamesChanged: handleDataChange()
    onValuesChanged: handleDataChange()
    onColorsChanged: handleDataChange()

    // Timer to delay the chart reset
    Timer {
        id: chartResetTimer
        interval: 50
        onTriggered: {
            // This is a simpler approach that uses the existing components
            // but resets their data bindings
            if (chart) {
                // Force recalculation of chart by briefly clearing data then restoring
                chart.valueSources[0].array = []
                chart.colorSource.array = []

                // Then restore with original data
                chart.valueSources[0].array = root.values
                chart.colorSource.array = root.colors
            }
        }
    }

    // Adaptive layout properties
    property bool isNarrow: width < Kirigami.Units.gridUnit * 20

    background: Rectangle {
        color: Qt.lighter(Kirigami.Theme.backgroundColor, 1.2)
        border.width: 0
        radius: Kirigami.Units.smallSpacing
    }

    contentItem: ColumnLayout {
        id: mainLayout
        spacing: Kirigami.Units.smallSpacing
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing

        // Header
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
        }

        // Main chart content
        Item {
            id: chartContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: hasValidData

            // Main pie chart
            Item {
                id: chartArea
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: isNarrow ? legendContainer.top : parent.bottom
                    bottomMargin: isNarrow ? Kirigami.Units.smallSpacing : 0
                    right: isNarrow ? parent.horizontalCenter : parent.right - Kirigami.Units.gridUnit * 8
                }

                // Use direct referencing for the chart
                Charts.PieChart {
                    id: chart
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.8
                    height: width

                    // Ensure chart is created only when we have valid data
                    visible: hasValidData

                    // Using direct bindings
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
                    bottom: parent.bottom
                }
                visible: !isNarrow && hasValidData
                color: "transparent"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    clip: true

                    Column {
                        id: desktopLegendColumn
                        spacing: Kirigami.Units.smallSpacing
                        width: parent.width

                        // Use direct binding for model
                        Repeater {
                            id: desktopLegendRepeater
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

            // Bottom legend container for mobile view
            Rectangle {
                id: legendContainer
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: isNarrow ? Math.min(Kirigami.Units.gridUnit * 5, parent.height * 0.4) : 0
                color: "transparent"
                visible: isNarrow && hasValidData

                // Use ListView instead of GridLayout for more reliable item placement
                ListView {
                    id: mobileLegendList
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    orientation: ListView.Vertical
                    clip: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    // Create a simple model from the data
                    model: {
                        if (!root.names || !root.values) return 0;
                        return Math.min(root.names.length, root.values.length);
                    }

                    // Use cacheBuffer to keep items loaded
                    cacheBuffer: 1000

                    // Reliable row height calculation
                    property real delegateHeight: Kirigami.Units.gridUnit * 0.8

                    // Calculate how many columns will fit
                    property int columnCount: Math.max(2, Math.floor(width / (Kirigami.Units.gridUnit * 8)))

                    // Calculate grid cell width
                    property real cellWidth: width / columnCount

                    // Distribute items in a grid pattern
                    delegate: Item {
                        width: mobileLegendList.cellWidth
                        height: mobileLegendList.delegateHeight

                        // Calculate grid position (row, column)
                        property int row: Math.floor(index / mobileLegendList.columnCount)
                        property int column: index % mobileLegendList.columnCount

                        // Position element in grid cell
                        x: column * mobileLegendList.cellWidth
                        y: row * mobileLegendList.delegateHeight

                        // Actual content
                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: Kirigami.Units.smallSpacing
                                rightMargin: Kirigami.Units.smallSpacing
                            }
                            spacing: 2

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

                    // Adjust contentHeight to fit all rows
                    contentHeight: Math.ceil(count / columnCount) * delegateHeight
                }
            }

        }

        // Show message when no data
        Label {
            visible: !hasValidData
            text: i18n("No data available")
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // Public function to force a refresh
    function forceRefresh() {
        handleDataChange()
    }

    // Ensure chart is properly initialized when component is completed
    Component.onCompleted: {
        if (hasValidData) {
            // Initial layout might need a nudge
            Qt.callLater(function() {
                handleDataChange()
            })
        }
    }
}
