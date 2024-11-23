import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property int alignment: Qt.AlignRight

    // Add right margin for spacing from screen edge
    property int rightMargin: Kirigami.Units.largeSpacing * 2

    readonly property int maximumNotificationWidth: {
        if (Kirigami.Settings.isMobile) {
            return applicationWindow().width - Kirigami.Units.largeSpacing * 4
        } else {
            return Math.min(Kirigami.Units.gridUnit * 25, applicationWindow().width / 2)
        }
    }

    readonly property int maximumNotificationCount: 4

    // Previous functions remain the same...
    function showNotification(iconName, message, messageType, timeout, actionText, callBack) {
        if (!message) {
            return;
        }

        let interval = 7000;

        if (timeout === "short") {
            interval = 4000;
        } else if (timeout === "long") {
            interval = 12000;
        } else if (timeout > 0) {
            interval = timeout;
        }
        // Get default icon based on message type if no icon provided
        let finalIconName = iconName;
        if (!iconName || iconName === "") {
            switch (messageType) {
            case Kirigami.MessageType.Positive:
                finalIconName = "dialog-ok"
                break;
            case Kirigami.MessageType.Warning:
                finalIconName = "dialog-warning"
                break;
            case Kirigami.MessageType.Error:
                finalIconName = "dialog-error"
                break;
            default:
                finalIconName = "documentinfo"
                break;
            }
        }
        const callBackWrapperObj = callBackWrapper.createObject(listView, { callBack })

        notificationsModel.append({
                                      iconName: finalIconName,
                                      text: message,
                                      messageType: messageType || Kirigami.MessageType.Information,
                                      actionButtonText: actionText || "",
                                      closeInterval: interval,
                                      callBackWrapper: callBackWrapperObj
                                  })

        if (notificationsModel.count === maximumNotificationCount) {
            if (listView.itemAtIndex(0).hovered === true) {
                hideNotification(1)
            } else {
                hideNotification()
            }
        }
    }

    function hideNotification(index = 0) {
        if (index >= 0 && notificationsModel.count > index) {
            const callBackWrapperObj = notificationsModel.get(index).callBackWrapper
            if (callBackWrapperObj) {
                callBackWrapperObj.destroy()
            }
            notificationsModel.remove(index)
        }
    }

    anchors {
        right: parent.right
        bottom: parent.bottom
        left: parent.left
    }
    height: Math.min(applicationWindow().height, Kirigami.Units.gridUnit * 20)

    ListModel {
        id: notificationsModel
    }

    ListView {
        id: listView

        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: root.rightMargin
            bottomMargin: Kirigami.Units.largeSpacing *10
        }

        width: root.maximumNotificationWidth
        height: parent.height
        spacing: Kirigami.Units.largeSpacing
        model: notificationsModel
        verticalLayoutDirection: ListView.BottomToTop
        keyNavigationEnabled: false
        reuseItems: false
        focus: false
        interactive: false

        // Keep existing transitions...
        add: Transition {
            id: addAnimation
            ParallelAnimation {
                alwaysRunToEnd: true
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "y"
                    from: addAnimation.ViewTransition.destination.y - Kirigami.Units.gridUnit * 3
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
        displaced: Transition {
            ParallelAnimation {
                alwaysRunToEnd: true
                NumberAnimation {
                    property: "y"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    duration: 0
                    to: 1
                }
            }
        }
        remove: Transition {
            ParallelAnimation {
                alwaysRunToEnd: true
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "y"
                    to: Kirigami.Units.gridUnit * 3
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InCubic
                }
                PropertyAction {
                    property: "transformOrigin"
                    value: Item.Bottom
                }
                PropertyAnimation {
                    property: "scale"
                    from: 1
                    to: 0
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InCubic
                }
            }
        }

        delegate: QQC2.Control {
            id: delegate

            function getTextColor() {
                switch(model.messageType) {
                case Kirigami.MessageType.Positive: return Kirigami.Theme.positiveTextColor
                case Kirigami.MessageType.Warning: return Kirigami.Theme.neutralTextColor
                case Kirigami.MessageType.Error: return Kirigami.Theme.negativeTextColor
                default: return Kirigami.Theme.textColor
                }
            }

            hoverEnabled: true
            width: listView.width

            implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                     implicitContentHeight + topPadding + bottomPadding)

            z: delegate.hovered ? 2 : (delegate.index === 0 ? 1 : 0)

            leftPadding: Kirigami.Units.largeSpacing
            rightPadding: Kirigami.Units.largeSpacing
            topPadding: Kirigami.Units.largeSpacing
            bottomPadding: Kirigami.Units.largeSpacing

            contentItem: RowLayout {
                id: mainLayout
                spacing: Kirigami.Units.smallSpacing

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: eventPoint => hideNotification(index)
                }

                Timer {
                    id: timer
                    interval: model.closeInterval
                    running: !delegate.hovered
                    onTriggered: hideNotification(index)
                }

                Kirigami.Icon {
                    id: icon
                    source: model.iconName
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: model.iconName !== ""
                    Layout.alignment: Qt.AlignVCenter
                    color: delegate.getTextColor()
                }

                QQC2.Label {
                    id: label
                    text: model.text
                    color: delegate.getTextColor()
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                QQC2.ToolButton {
                    id: actionButton
                    //   text: model.actionButtonText
                    icon.name:model.actionButtonText
                    // visible: model.actionButtonText > 0
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        const callBack = model.callBackWrapper.callBack
                        hideNotification(index)
                        if (callBack && (typeof callBack === "function")) {
                            callBack();
                        }
                    }
                }
            }

            background: Kirigami.ShadowedRectangle {
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: model.messageType === Kirigami.MessageType.Information ?
                                             Kirigami.Theme.Complementary : Kirigami.Theme.Window
                shadow {
                    size: Kirigami.Units.gridUnit/2
                    color: Qt.rgba(0, 0, 0, 0.4)
                    yOffset: 2
                }
                radius: Kirigami.Units.cornerRadius
                color: Kirigami.Theme.backgroundColor
                opacity: 1
            }
        }
    }

    Component {
        id: callBackWrapper
        QtObject {
            property var callBack
        }
    }
}
