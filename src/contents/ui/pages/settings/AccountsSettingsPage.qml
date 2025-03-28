import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import Qt5Compat.GraphicalEffects
FormCard.FormCardPage {
    id: accountsSettingsPage
    title: i18nc("@title", "Account Settings")
    property bool isLoading: false
    property bool isLoadingPlan: false
    property string userFullName: ""
    property string userEmail: ""
    property string planName: ""
    property string planStatus: ""
    property string planExpiredDate: ""
    function getProfile(){
        api.getUserInfo();
        subscriptionApi.getStatus("");
    }

    Connections {
        target: api
        function onUserInfoReceived() {
            accountsSettingsPage.userFullName= api.getUserName()
            accountsSettingsPage.userEmail= api.getUserEmail()
            accountsSettingsPage.isLoading=false
        }

    }
    Connections {
        target: subscriptionApi
        function onStatusReceived() {
            accountsSettingsPage.planName= subscriptionApi.getType()
            accountsSettingsPage.planExpiredDate= subscriptionApi.getExpirationDate()
            accountsSettingsPage.planStatus= subscriptionApi.getStatusString()
            accountsSettingsPage.isLoadingPlan=false
        }
    }
    Component.onCompleted :{
        accountsSettingsPage.isLoading=true
        accountsSettingsPage.isLoadingPlan=true
        getProfile()
    }


    FormCard.FormHeader {
        title: i18nc("@title:group", "Account Settings")
    }



    FormCard.FormHeader {
        title: i18n("Plan")
    }

    FormCard.FormCard {
        visible:!accountsSettingsPage.isLoadingPlan
        FormCard.FormTextDelegate {
            text: i18n("Current plan: ")

            // Add a container for the badge
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                // The "Current plan:" text
                QQC2.Label {
                    text: i18n("Current plan: ")
                    Layout.alignment: Qt.AlignVCenter
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                }

                // The animated plan badge - completely rectangular with increased size
                Rectangle {
                    id: planBadge
                    Layout.preferredHeight: planText.height + Kirigami.Units.largeSpacing * 1.5
                    Layout.preferredWidth: planText.width + Kirigami.Units.largeSpacing * 3.5
                    radius: 0  // No radius for a true rectangle
                    color: {
                        // Choose color based on plan type
                        if (accountsSettingsPage.planName.toLowerCase().includes("premium")) {
                            return "#FFBF00" // Gold for premium
                        } else if (accountsSettingsPage.planName.toLowerCase().includes("pro")) {
                            return "#8A2BE2" // Purple for pro
                        } else if (accountsSettingsPage.planName.toLowerCase().includes("business")) {
                            return "#00A36C" // Green for business
                        } else {
                            return "#8A2BE2" // Gold for other plans
                        }
                    }

                    // Enhanced gradient with three stops for more depth
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(planBadge.color, 1.1) }
                        GradientStop { position: 0.5; color: planBadge.color }
                        GradientStop { position: 1.0; color: Qt.darker(planBadge.color, 1.3) }
                    }

                    // Border to enhance the rectangular appearance
                    border.width: 1
                    border.color: Qt.lighter(planBadge.color, 1.3)

                    // Property for animation
                    property real glowStrength: 0.3

                    // Improved glow effect
                    layer.enabled: true
                    layer.effect: Glow {
                        radius: 2
                        samples: 17
                        color: planBadge.color
                        spread: planBadge.glowStrength
                    }

                    QQC2.Label {
                        id: planText
                        anchors.centerIn: parent
                        text: accountsSettingsPage.planName
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                        color: "#ffffff"

                        // Text shadow for better readability
                        style: Text.Outline
                        styleColor: Qt.rgba(0, 0, 0, 0.2)
                    }

                    // Background grid pattern for premium look
                    Canvas {
                        anchors.fill: parent
                        z: -1
                        opacity: 0.1

                        onPaint: {
                            var ctx = getContext("2d");
                            var gridSize = 10;

                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 0.5;

                            // Create subtle grid pattern
                            for (var x = 0; x <= width; x += gridSize) {
                                ctx.beginPath();
                                ctx.moveTo(x, 0);
                                ctx.lineTo(x, height);
                                ctx.stroke();
                            }

                            for (var y = 0; y <= height; y += gridSize) {
                                ctx.beginPath();
                                ctx.moveTo(0, y);
                                ctx.lineTo(width, y);
                                ctx.stroke();
                            }
                        }
                    }

                    // Enhanced electric beam animation
                    Rectangle {
                        id: electricBeam
                        height: parent.height
                        width: parent.width / 2.5
                        radius: 0
                        y: 0

                        // More dynamic gradient
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.3) }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.7) }
                            GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.3) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }

                        // Improved electric zigzag lines
                        Canvas {
                            anchors.fill: parent
                            opacity: 0.8

                            property real phase: 0

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();

                                // Create more energetic zigzag lines
                                ctx.strokeStyle = Qt.lighter(planBadge.color, 2.0);
                                ctx.lineWidth = 1.5;

                                // Multiple zigzags with varying frequency
                                var centerX = width / 2;
                                var amplitude = width / 7;
                                var segments = 12;

                                for (var j = 0; j < 4; j++) {
                                    ctx.beginPath();
                                    var startX = centerX - amplitude + (j * amplitude/2);
                                    var frequency = 10 + (j * 3);

                                    for (var i = 0; i <= segments; i++) {
                                        var t = i / segments;
                                        var y = t * height;
                                        var offset = Math.sin((t * frequency) + phase + (j * 1.5)) * (amplitude / 4);
                                        var x = startX + offset;

                                        if (i === 0) {
                                            ctx.moveTo(x, y);
                                        } else {
                                            ctx.lineTo(x, y);
                                        }
                                    }
                                    ctx.stroke();
                                }
                            }

                            Timer {
                                interval: 40  // Faster update for smoother animation
                                running: true
                                repeat: true
                                onTriggered: {
                                    parent.phase += 0.25;
                                    parent.requestPaint();
                                }
                            }
                        }

                        // More dynamic animation for the beam
                        SequentialAnimation {
                            running: true
                            loops: Animation.Infinite

                            // Start from left outside the badge
                            PropertyAction {
                                target: electricBeam
                                property: "x"
                                value: -electricBeam.width
                            }

                            // Faster animation to right
                            NumberAnimation {
                                target: electricBeam
                                property: "x"
                                to: planBadge.width
                                duration: 1500
                                easing.type: Easing.OutCubic
                            }

                            // Shorter pause for more frequent animations
                            PauseAnimation {
                                duration: 2000
                            }
                        }
                    }

                    // Enhanced pulsing glow animation
                    SequentialAnimation {
                        id: pulseAnimation
                        running: true
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: planBadge
                            property: "glowStrength"
                            from: 0.3
                            to: 0.7  // Stronger glow
                            duration: 1200
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: planBadge
                            property: "glowStrength"
                            from: 0.7
                            to: 0.3
                            duration: 1200
                            easing.type: Easing.InQuad
                        }

                        PauseAnimation {
                            duration: 800
                        }
                    }

                    // Improved spark effect with multiple random areas
                    Repeater {
                        model: 3  // Create multiple spark areas

                        Rectangle {
                            id: sparkFlash
                            width: parent.width / 3
                            height: parent.height / 2
                            x: Math.random() * (parent.width - width)
                            y: Math.random() * (parent.height - height)
                            radius: 0
                            opacity: 0
                            color: "transparent"

                            Timer {
                                interval: 2000 + Math.random() * 4000
                                running: true
                                repeat: true
                                onTriggered: {
                                    sparkAnimation.start();
                                }
                            }

                            SequentialAnimation {
                                id: sparkAnimation

                                PropertyAction {
                                    target: sparkFlash
                                    property: "color"
                                    value: Qt.lighter(planBadge.color, 2.0)
                                }

                                // Quick flash
                                NumberAnimation {
                                    target: sparkFlash
                                    property: "opacity"
                                    from: 0
                                    to: 0.5
                                    duration: 40
                                }

                                NumberAnimation {
                                    target: sparkFlash
                                    property: "opacity"
                                    from: 0.5
                                    to: 0
                                    duration: 150
                                }
                            }
                        }
                    }

                    // Subtle shimmer effect across the whole badge
                    Rectangle {
                        id: shimmerEffect
                        width: parent.width * 1.5
                        height: parent.height * 1.5
                        rotation: -30
                        opacity: 0
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.2) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }

                        SequentialAnimation {
                            running: true
                            loops: Animation.Infinite

                            PauseAnimation { duration: 4000 }

                            ParallelAnimation {
                                NumberAnimation {
                                    target: shimmerEffect
                                    property: "x"
                                    from: -shimmerEffect.width
                                    to: planBadge.width
                                    duration: 1500
                                    easing.type: Easing.InOutSine
                                }

                                NumberAnimation {
                                    target: shimmerEffect
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 500
                                }

                                NumberAnimation {
                                    target: shimmerEffect
                                    property: "opacity"
                                    from: 1
                                    to: 0
                                    duration: 1000
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }
            }
        }

        FormCard.FormTextDelegate {
            description: i18n("Expired on : ") + accountsSettingsPage.planExpiredDate
        }
        FormCard.FormTextDelegate {
            text: i18n("Plan Status : ") +  accountsSettingsPage.planStatus

        }
        FormCard.FormButtonDelegate {
            id: upgradeButton
            icon.name: "go-up-symbolic"
            text: i18n("Upgrade plan")
            onClicked: Qt.openUrlExternally("https://dim.dervox.com")
        }
    }
    FormCard.FormCard {
        visible:accountsSettingsPage.isLoadingPlan
        FormCard.FormSectionText {
            SkeletonLoaders{
                height:20
                width:parent.width
            }

        }
        FormCard.FormSectionText {
            SkeletonLoaders{
                height:20
                width:parent.width
            }

        }
        FormCard.FormSectionText {
            SkeletonLoaders{
                height:20
                width:parent.width
            }
        }
    }
    FormCard.FormHeader {
        title: i18n("User information")
    }
    FormCard.FormCard {
        visible:!accountsSettingsPage.isLoading
        FormCard.FormTextDelegate {
            text: i18n("Full name : ") + accountsSettingsPage.userFullName
        }
        FormCard.FormTextDelegate {
            text: i18n("Email : ") + accountsSettingsPage.userEmail
        }
        FormCard.FormButtonDelegate {
            id: editProfileButton
            icon.name: "user-info-symbolic"
            text: i18n("Edit profile")
            onClicked: Qt.openUrlExternally("https://dim.dervox.com")
        }

    }


    FormCard.FormCard {
        visible:accountsSettingsPage.isLoading
        padding:10
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width
            }
        }
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width/2
            }
        }
        FormCard.FormTextDelegate {
            SkeletonLoaders{
                height:20
                width:parent.width
            }
        }
    }


}
