import QtQuick 2.15
import org.kde.kirigami as Kirigami

Rectangle {
    id: skeletonLoader
    //anchors.centerIn: parent
    height: 100
    width: 200
    radius: 4
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.backgroundColor

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: shimmerAnimation.position
            color: Kirigami.Theme.backgroundColor
        }
        GradientStop {
            position: Math.min(shimmerAnimation.position + 0.1, 1.0)
            color: Kirigami.Theme.alternateBackgroundColor
        }
        GradientStop {
            position: Math.min(shimmerAnimation.position + 0.2, 1.0)
            color: Kirigami.Theme.backgroundColor
        }
    }

    PropertyAnimation {
        id: shimmerAnimation
        target: shimmerAnimation
        property: "position"
        from: -0.2  // Start more to the left
        to: 1   // End exactly at the right edge
        duration: 1500
        running: true
        loops: Animation.Infinite
        property real position: 0

        // Add smooth easing
        easing.type: Easing.InSine
    }
}
