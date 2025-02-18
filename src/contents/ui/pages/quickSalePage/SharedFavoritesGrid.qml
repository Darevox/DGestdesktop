// SharedFavoritesGrid.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../components"
Item {
    id: root

    property var loadedProducts: ({})
    property var currentProductIds: []
    property bool isLoading: false
    signal productClicked(var product)

    GridView {
        id: favoritesGrid
        anchors.fill: parent
        cellWidth: Kirigami.Units.gridUnit * 6
        cellHeight: Kirigami.Units.gridUnit * 8
        clip: true
        model: root.currentProductIds

        delegate: Kirigami.Card {
            id: productCard
            width: favoritesGrid.cellWidth - 10
            height: favoritesGrid.cellHeight - 10
            opacity: root.loadedProducts[modelData] ? 1 : 0.5
            states: [
                State {
                    name: "hovered"
                    when: productMouseArea.containsMouse
                    PropertyChanges {
                        target: productCard
                        scale: 1.05
                    }
                }
            ]

            transitions: Transition {
                NumberAnimation {
                    properties: "scale"
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                id: rippleEffect
                property real centerX
                property real centerY
                anchors.fill: parent
                color: Kirigami.Theme.highlightColor
                opacity: 0
                radius: width

                ParallelAnimation {
                    id: rippleAnimation
                    NumberAnimation {
                        target: rippleEffect
                        property: "opacity"
                        from: 0.3
                        to: 0
                        duration: 500
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: rippleEffect
                        property: "radius"
                        from: 0
                        to: rippleEffect.width * 1.5
                        duration: 500
                        easing.type: Easing.OutQuad
                    }
                }
            }

            MouseArea {
                id: productMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.loadedProducts[modelData]) {
                        rippleEffect.centerX = mouseX
                        rippleEffect.centerY = mouseY
                        rippleEffect.x = mouseX - rippleEffect.width/2
                        rippleEffect.y = mouseY - rippleEffect.height/2
                        rippleAnimation.restart()
                        root.productClicked(root.loadedProducts[modelData])
                    }
                }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width

                    Image {
                        id: productImage
                        anchors.fill: parent
                        source: root.loadedProducts[modelData]?.image_path ?
                            api.apiHost + root.loadedProducts[modelData].image_path :
                            "package"
                        fillMode: Image.PreserveAspectFit

                        DBusyIndicator {
                            anchors.centerIn: parent
                            running: productImage.status === Image.Loading
                            visible: running
                        }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: root.loadedProducts[modelData]?.name || i18n("Loading...")
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.bold: true
                    }

                    QQC2.Label {
                        text: {
                            const product = root.loadedProducts[modelData]
                            return product ? i18n("%1", product.price.toFixed(2)) : ""
                        }
                        visible: root.loadedProducts[modelData]
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        color: Kirigami.Theme.positiveTextColor
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: {
                            const product = root.loadedProducts[modelData]
                            if (!product) return Kirigami.Theme.neutralTextColor
                            if (product.quantity <= 0) return Kirigami.Theme.negativeTextColor
                            if (product.quantity < 10) return Kirigami.Theme.neutralTextColor
                            return Kirigami.Theme.positiveTextColor
                        }
                        visible: root.loadedProducts[modelData]
                    }
                }
            }

            QQC2.ToolTip {
                visible: productMouseArea.containsMouse && root.loadedProducts[modelData]
                text: {
                    const product = root.loadedProducts[modelData]
                    if (!product) return ""
                    return i18n("%1\nPrice: %2\nStock: %3",
                        product.name,
                        product.price.toFixed(2),
                        product.quantity)
                }
            }
        }

        // Empty state
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - (Kirigami.Units.largeSpacing * 4)
            visible: !root.isLoading && root.currentProductIds.length === 0
            text: i18n("No products in this category")
            explanation: i18n("Add products to this category in the settings")
        }
    }

    // Loading overlay
    Item {
        anchors.fill: parent
        visible: root.isLoading

        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            opacity: 0.7
        }

        DBusyIndicator {
            anchors.centerIn: parent
            running: parent.visible
        }

        QQC2.Label {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: Kirigami.Units.gridUnit
            text: i18n("Loading products...")
            visible: root.isLoading
        }
    }
}
