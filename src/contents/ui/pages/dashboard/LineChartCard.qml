import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.quickcharts as Charts
import org.kde.quickcharts.controls as ChartsControls

Kirigami.AbstractCard {
    id: card

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 15

    property string title: ""
    property string value: ""
    property string subtitle: ""
    property bool showChart: true
    property var chartData: []
    property color chartColor: Kirigami.Theme.highlightColor
    property string timeframe: "daily"
    property alias yRange: chart.yRange

    // Determine if chart should be visible based on timeframe and data
    property bool shouldShowChart: {
        // if (timeframe === "daily") {
        //     return false; // Only show trend number for today
        // }
        // return showChart && chartData.length > 0;
        return true;
    }

    // Calculate effective period for x-axis
    property int effectivePeriod: {
        switch(timeframe) {
        case "daily":
            return 24;  // Hours in a day
        case "24hours":
            return 24;  // 24 hours
        case "weekly":
            return 7;   // Days in a week
        case "monthly":
            return 31;  // Days in a month
        case "yearly":
            return 12;  // Months in a year
        case "all":
            return chartData.length || 12; // Use data length or default to 12
        default:
            return 24;
        }
    }

    // Get appropriate labels for the timeframe
    property var timeLabels: {
        switch(timeframe) {
        case "daily":
        case "24hours":
            return ["00:00", "06:00", "12:00", "18:00", "23:59"];
        case "weekly":
            return [i18n("Mon"), i18n("Tue"), i18n("Wed"), i18n("Thu"), i18n("Fri"), i18n("Sat"), i18n("Sun")];
        case "monthly":
            return [i18n("W 1"), i18n("W 2"), i18n("W 3"), i18n("W 4")];
        case "yearly":
            return [i18n("Jan"), i18n("Mar"), i18n("May"), i18n("Jul"), i18n("Sep"), i18n("Nov")];
        case "all":
            // Create labels based on data length
            let labels = [];
            let step = Math.max(1, Math.floor(chartData.length / 6));
            for (let i = 0; i < chartData.length; i += step) {
                labels.push((i + 1).toString());
            }
            return labels;
        default:
            return ["00:00", "06:00", "12:00", "18:00", "23:59"];
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.fillWidth: true
        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: card.icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }

            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                Layout.fillWidth: true

                Kirigami.Heading {
                    level: 3
                    text: card.title
                }

                Label {
                    text: card.subtitle
                    opacity: 0.7
                }
            }
            Item{
                Layout.fillWidth: true
            }
            Kirigami.Heading {
                level: 1
                text: card.value
                color: card.chartColor
            }
        }

        // Chart
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: card.shouldShowChart

            ChartsControls.GridLines {
                anchors.fill: chart
                direction: ChartsControls.GridLines.Vertical
                major.visible: false
                minor.count: timeframe === "daily" || timeframe === "24hours" ? 6 :
                                                                                timeframe === "weekly" ? 7 :
                                                                                                         timeframe === "monthly" ? 4 : 6
                minor.color: Kirigami.Theme.alternateBackgroundColor
            }
            Charts.LineChart {
                id: chart
                anchors.fill: parent
                property real animationSpeed: 0.07
                property real upSpeed: 0.03    // Speed when values are increasing
                  property real downSpeed: 0.2  // Speed when values are decreasing
                property bool animating: true
                property var currentValues: []
                property var targetValues: []

                xRange {
                    from: 0
                    to: card.effectivePeriod
                    automatic: false
                }

                yRange {
                    from: 0
                    to: 100
                    automatic: true
                }

                colorSource: Charts.SingleValueSource { value: card.chartColor }
                fillOpacity: 0.2
                smooth: true

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                }

                valueSources: [
                    Charts.ArraySource {
                        id: arraySource
                        array: chart.currentValues

                        Component.onCompleted: {
                            chart.currentValues = new Array(card.effectivePeriod).fill(0)
                        }
                    }
                ]

                Timer {
                    id: updateTimer
                    // Adjust interval for smoother/faster updates (lower = smoother but more CPU)
                    // Try values between 16 and 32
                    interval: 16
                    repeat: true
                    running: chart.animating

                    onTriggered: {
                        var done = true
                        var newValues = []

                        for (var i = 0; i < chart.targetValues.length; i++) {
                            var current = chart.currentValues[i] || 0
                            var target = chart.targetValues[i] || 0
                            var diff = target - current

                            if (Math.abs(diff) > 0.1) {
                                done = false
                                if (target > current) {  // Going up
                                    newValues[i] = current + Math.abs(diff * chart.upSpeed)
                                    if (newValues[i] > target) {
                                        newValues[i] = target
                                    }
                                } else {  // Going down
                                    newValues[i] = current - Math.abs(diff * chart.downSpeed)
                                    if (newValues[i] < target) {
                                        newValues[i] = target
                                    }
                                }
                            } else {
                                newValues[i] = target
                            }
                        }

                        chart.currentValues = newValues

                        if (done) {
                            chart.animating = false
                            updateTimer.stop()
                        }
                    }
                }
                function animateToNewData(newData) {
                    if (!newData || newData.length === 0) return

                    // Save current values as starting point
                    var startValues = []
                    for (var i = 0; i < newData.length; i++) {
                        startValues[i] = currentValues[i] || 0
                    }
                    currentValues = startValues

                    // Set target values
                    targetValues = newData

                    // Start animation
                    animating = true
                    opacity = 0.7
                    updateTimer.start()
                    opacity = 1.0
                }
            }

            // In the parent component:

            // Add timer for animation
            Timer {
                id: chartAnimationTimer
                interval: 150
                repeat: false
                onTriggered: {
                    chart.opacity = 1.0
                }
            }

            // Charts.LineChart {
            //     id: chart
            //     anchors.fill: parent
            //     property bool animating: false
            //     xRange {
            //         from: 0
            //         to: card.effectivePeriod
            //         automatic: false
            //     }

            //     yRange {
            //         from: 0
            //         to: 100
            //         automatic: true
            //     }

            //     colorSource: Charts.SingleValueSource { value: card.chartColor }
            //     fillOpacity: 0.2
            //     smooth: true

            //     // valueSources: [
            //     //     Charts.ArraySource {
            //     //         array: card.chartData
            //     //         onArrayChanged: {
            //     //             if (array && array.length > 0) {
            //     //                 chart.yRange.automatic = true
            //     //                 chart.yRange.from = 0
            //     //             }
            //     //         }
            //     //     }
            //     // ]
            //     valueSources: [
            //         Charts.ArraySource {
            //             id: arraySource
            //             property var targetArray: []
            //             property var currentArray: []

            //             array: currentArray

            //             function animateToNewData(newData) {
            //                 if (chart.animating) return;

            //                 targetArray = newData;
            //                 chart.animating = true;
            //                 animationTimer.restart();
            //             }

            //             Timer {
            //                 id: animationTimer
            //                 interval: 16 // ~60fps
            //                 repeat: true
            //                 running: false

            //                 onTriggered: {
            //                     var done = true;
            //                     var newArray = [];

            //                     for (var i = 0; i < targetArray.length; i++) {
            //                         var current = arraySource.currentArray[i] || 0;
            //                         var target = targetArray[i];
            //                         var diff = target - current;

            //                         if (Math.abs(diff) > 0.1) {
            //                             done = false;
            //                             newArray[i] = current + (diff * 0.2); // Smooth interpolation
            //                         } else {
            //                             newArray[i] = target;
            //                         }
            //                     }

            //                     arraySource.currentArray = newArray;

            //                     if (done) {
            //                         chart.animating = false;
            //                         animationTimer.stop();
            //                     }
            //                 }
            //             }
            //         }
            //     ]

            //     // Use this function to update the data with animation
            //     function updateDataWithAnimation(newData) {
            //         arraySource.animateToNewData(newData);
            //     }
            // }

            // Time labels
            Row {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: (parent.width - card.timeLabels.length * 30) /
                         (card.timeLabels.length - 1)

                Repeater {
                    model: card.timeLabels
                    Label {
                        text: modelData
                        font.pointSize: 8
                        opacity: 0.7
                    }
                }
            }
        }

        // Optional: Add legend or additional information
        Label {
            visible: timeframe === "all"
            text: i18n("Showing all-time data")
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // Debug output
    Component.onCompleted: {
        console.log("Chart initialized with timeframe:", timeframe)
        console.log("Effective period:", effectivePeriod)
        console.log("Initial chart data:", JSON.stringify(chartData))
    }

    // onChartDataChanged: {
    //     console.log("Chart data updated:", JSON.stringify(chartData))
    // }
    onChartDataChanged: {
        if (chartData && chartData.length > 0) {
            chart.animateToNewData(chartData)
        }
    }

}
