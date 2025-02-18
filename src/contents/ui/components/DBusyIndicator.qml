import QtQuick 2.15
import org.kde.kirigami 2.20 as Kirigami

/**
 * Design by Enes Özgör: ens.ninja
 * Adapted for KDE/Kirigami
 **/
Item {
    id: root

    // ----- Public Properties ----- //
    property alias color: rect.color
    property bool running: true

    // Animation Speed Properties
    property int mainDuration: Kirigami.Units.longDuration * 2
    property int bounceDuration: Kirigami.Units.shortDuration * 2
    property real bounceScale: 1

    // Size Properties
    property int size: Kirigami.Units.gridUnit * 2
    property int padding: Kirigami.Units.largeSpacing

    // Set the full size including padding
    implicitWidth: size + (padding * 2)
    implicitHeight: size + (padding * 2)
    visible: running

    // Container for centered content
    Item {
        id: container
        anchors.fill: parent

        Rectangle {
            id: rect
            width: root.size / 2
            height: root.size / 2
            radius: Kirigami.Units.smallSpacing / 2
            color: Kirigami.Theme.textColor
            transformOrigin: Item.BottomRight

            // Center the rectangle in the container accounting for padding
            x: (parent.width - root.size) / 2
            y: (parent.height - root.size) / 2

            // Optional shadow effect
            layer.enabled: false
            layer.effect: Kirigami.ShadowedRectangle {
                shadow.xOffset: 0
                shadow.yOffset: Kirigami.Units.smallSpacing / 2
                shadow.size: Kirigami.Units.smallSpacing
                shadow.color: Qt.rgba(0, 0, 0, 0.2)
            }

            transform: Scale {
                id: transformScale
                origin {
                    x: rect.width
                    y: rect.height
                }
            }

            SequentialAnimation {
                id: mainAnimation
                loops: Animation.Infinite
                running: false  // We'll control this via running property

                // Top right
                ParallelAnimation {
                    NumberAnimation {
                        target: transformScale
                        property: "xScale"
                        from: 1
                        to: -1
                        duration: root.mainDuration
                        easing.type: Easing.OutQuint
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: transformScale
                            property: "yScale"
                            from: 1
                            to: root.bounceScale
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }

                        NumberAnimation {
                            target: transformScale
                            property: "yScale"
                            from: root.bounceScale
                            to: 1
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                // Bottom right
                ParallelAnimation {
                    NumberAnimation {
                        target: transformScale
                        property: "yScale"
                        from: 1
                        to: -1
                        duration: root.mainDuration
                        easing.type: Easing.OutQuint
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: transformScale
                            property: "xScale"
                            from: -1
                            to: -root.bounceScale
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }

                        NumberAnimation {
                            target: transformScale
                            property: "xScale"
                            from: -root.bounceScale
                            to: -1
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                // Bottom left
                ParallelAnimation {
                    NumberAnimation {
                        target: transformScale
                        property: "xScale"
                        from: -1
                        to: 1
                        duration: root.mainDuration
                        easing.type: Easing.OutQuint
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: transformScale
                            property: "yScale"
                            from: -1
                            to: -root.bounceScale
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }

                        NumberAnimation {
                            target: transformScale
                            property: "yScale"
                            from: -root.bounceScale
                            to: -1
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                // Top left
                ParallelAnimation {
                    NumberAnimation {
                        target: transformScale
                        property: "yScale"
                        from: -1
                        to: 1
                        duration: root.mainDuration
                        easing.type: Easing.OutQuint
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: transformScale
                            property: "xScale"
                            from: 1
                            to: root.bounceScale
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }

                        NumberAnimation {
                            target: transformScale
                            property: "xScale"
                            from: root.bounceScale
                            to: 1
                            duration: root.bounceDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }
            }
        }
    }

    // Reset function
    function reset() {
        mainAnimation.stop()
        transformScale.xScale = 1
        transformScale.yScale = 1
    }

    // Handle running changes
    onRunningChanged: {
        if (running) {
            reset()
            mainAnimation.start()
        } else {
            reset()
        }
    }

    // Initial setup
    Component.onCompleted: {
        if (running) {
            mainAnimation.start()
        }
    }
}



// // BlockLoader.qml
// import QtQuick 2.15
// import org.kde.kirigami 2.20 as Kirigami
// import QtQuick.Controls 2.15 as QQC2

// Item {
//     id: root

//     // ----- Public Properties ----- //
//     property int spacing: Kirigami.Units.smallSpacing
//     property int horizontalBlockCount: 3
//     property int verticalBlockCount: 3
//     property bool running: false
//     property bool showBackground: false
//     property string text: ""
//     property color color:Kirigami.Theme.textColor// Kirigami.Theme.highlightColor
//     property real size: Kirigami.Units.gridUnit * 2
//     property int padding: Kirigami.Units.largeSpacing * 2
//     property real containerScale: 0.6  // Adjust this to change the margin around blocks

//     property int rotationDuration: 700        // Duration of each rotation (ms)
//     property int columnDelay: 200              // Delay between column animations (ms)
//     property int pauseDuration: 200            // Pause duration between rotations (ms)
//     property int sequenceInterval: 200         // Interval between starting each column (ms)


//     // Default size
//     implicitWidth: content.width + (showBackground ? Kirigami.Units.largeSpacing * 2 : 0)
//     implicitHeight: content.height + (showBackground ? Kirigami.Units.largeSpacing * 2 : 0)
//     width: size + (padding * 2)
//     height: size + (padding * 2)

//     // Background
//     Rectangle {
//         id: background
//         anchors.fill: parent
//         visible: root.showBackground
//         color: Kirigami.Theme.backgroundColor
//         opacity: 0.9
//         radius: Kirigami.Units.smallSpacing
//         border.color: Qt.rgba(Kirigami.Theme.textColor.r,
//                               Kirigami.Theme.textColor.g,
//                               Kirigami.Theme.textColor.b, 0.1)
//         border.width: 1

//         layer.enabled: true
//         layer.effect: Kirigami.ShadowedRectangle {
//             shadow.xOffset: 0
//             shadow.yOffset: 2
//             shadow.size: 8
//             shadow.color: Qt.rgba(0, 0, 0, 0.15)
//         }
//     }

//     Item {
//         id: content
//         anchors.centerIn: parent
//         width: root.size
//         height: width

//         Item {
//             id: blockContainer
//             anchors.centerIn: parent
//             width: parent.width * containerScale
//             height: parent.height * containerScale

//             Repeater {
//                 id: repeater
//                 model: root.running ? root.horizontalBlockCount : 0  // Only create blocks when running

//                 delegate: Column {
//                     property int _columnIndex: index

//                     id: column
//                     spacing: root.spacing
//                     x: blockContainer._getRectSize().width * index + ((index - 1) * root.spacing)

//                     Repeater {
//                         property alias _columnIndex: column._columnIndex

//                         id: blockRepeater
//                         model: root.running ? root.verticalBlockCount : 0  // Only create blocks when running


//                         delegate: Rectangle {
//                             id: rect
//                             width: blockContainer._getRectSize().width
//                             height: blockContainer._getRectSize().height
//                            // radius: 2
//                             color: root.color
//                             smooth: true
//                             transformOrigin: Item.BottomRight
//                             visible: root.running
//                             rotation: 0

//                             SequentialAnimation {
//                                 id: rotationAnimation
//                                 loops: Animation.Infinite
//                                 running: false

//                                 RotationAnimation {
//                                     target: rect
//                                     duration: root.rotationDuration
//                                     from: 0
//                                     to: 90
//                                     easing.type: Easing.InOutQuint
//                                 }

//                                 PauseAnimation {
//                                     duration: blockRepeater._columnIndex * 300 + 300 * blockRepeater._columnIndex
//                                 }

//                                 RotationAnimation {
//                                     target: rect
//                                     duration: root.rotationDuration
//                                     from: 90
//                                     to: 0
//                                     easing.type: Easing.InOutQuint
//                                 }

//                                 PauseAnimation {
//                                     duration: (blockRepeater.model - blockRepeater._columnIndex) * root.columnDelay + root.pauseDuration * (blockRepeater.model - blockRepeater._columnIndex)
//                                 }
//                             }

//                             function startAnimation() {
//                                 if (!rotationAnimation.running && root.running) {
//                                     rotationAnimation.start()
//                                 }
//                             }

//                             function stopAnimation() {
//                                 rotationAnimation.stop()
//                                 rotation = 0
//                             }

//                             function resetState() {
//                                 stopAnimation()
//                                 rotation = 0
//                             }
//                         }


//                     }

//                     function startAnimation() {
//                         var count = blockRepeater.model
//                         for (var index = 0; index < count; index++) {
//                             blockRepeater.itemAt(index).startAnimation()
//                         }
//                     }

//                     function resetState() {
//                         var count = blockRepeater.model
//                         for (var index = 0; index < count; index++) {
//                             if (blockRepeater.itemAt(index)) {
//                                 blockRepeater.itemAt(index).resetState()
//                             }
//                         }
//                     }
//                 }
//             }

//             function _getRectSize() {
//                 var w = width / root.horizontalBlockCount
//                 return Qt.size(w, w)
//             }

//             function resetAllStates() {
//                 for (var i = 0; i < repeater.count; i++) {
//                     if (repeater.itemAt(i)) {
//                         repeater.itemAt(i).resetState()
//                     }
//                 }
//             }
//         }

//         // Optional text label
//         Kirigami.Heading {
//             id: label
//             visible: root.text.length > 0
//             text: root.text
//             level: 3
//             color: Kirigami.Theme.textColor
//             anchors.horizontalCenter: parent.horizontalCenter
//             anchors.top: parent.bottom
//             anchors.topMargin: Kirigami.Units.largeSpacing
//             opacity: root.running ? 1 : 0
//             Behavior on opacity {
//                 NumberAnimation { duration: 200 }
//             }
//         }
//     }

//     Timer {
//         property int _blockIndex: root.horizontalBlockCount - 1

//         id: animationTimer
//         interval: root.sequenceInterval
//         repeat: true
//         running: false

//         onTriggered: {
//             if (_blockIndex === -1) {
//                 _blockIndex = root.horizontalBlockCount - 1
//             } else {
//                 if (repeater.itemAt(_blockIndex)) {
//                     repeater.itemAt(_blockIndex).startAnimation()
//                 }
//                 _blockIndex--
//             }
//         }
//     }
//     function resetAll() {
//         animationTimer.stop()
//         animationTimer._blockIndex = root.horizontalBlockCount - 1
//         blockContainer.resetAllStates()
//     }

//     onRunningChanged: {
//         if (running) {
//             // Start timer after a short delay to ensure blocks are created
//             Qt.callLater(function() {
//                 animationTimer.start()
//             })
//         } else {
//             resetAll()
//         }
//     }


//     Component.onCompleted: {
//         if (running) {
//                    Qt.callLater(function() {
//                        animationTimer.start()
//                    })
//                }
//     }
// }
