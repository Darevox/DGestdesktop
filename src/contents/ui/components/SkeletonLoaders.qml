import QtQuick 2.15
import org.kde.kirigami as Kirigami

Rectangle {
    id: skeletonLoader
    height: 100
    width: 200
    radius: 4

    // Use a mix of background and text color for base
    color: Qt.rgba(
        (Kirigami.Theme.backgroundColor.r + Kirigami.Theme.textColor.r) / 2,
        (Kirigami.Theme.backgroundColor.g + Kirigami.Theme.textColor.g) / 2,
        (Kirigami.Theme.backgroundColor.b + Kirigami.Theme.textColor.b) / 2,
        0.3
    )

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: shimmerAnimation.position
            color: Qt.rgba(
                Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b,
                0.05
            )
        }
        GradientStop {
            position: Math.min(shimmerAnimation.position + 0.1, 1.0)
            color: Qt.rgba(
                Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b,
                0.15
            )
        }
        GradientStop {
            position: Math.min(shimmerAnimation.position + 0.2, 1.0)
            color: Qt.rgba(
                Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b,
                0.05
            )
        }
    }

    PropertyAnimation {
        id: shimmerAnimation
        target: shimmerAnimation
        property: "position"
        from: -0.2
        to: 1
        duration: 1500
        running: true
        loops: Animation.Infinite
        property real position: 0
        easing.type: Easing.InOutQuad
    }
}
