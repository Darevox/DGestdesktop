import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../components"
Kirigami.Card {
    id: imageCard
    Layout.preferredHeight: Kirigami.Units.gridUnit * 7
    property string currentImagePath: ""
    property string imageUrl: ""
    property int idProduct: 0

    actions: []

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.alignment: Qt.AlignLeft
        Layout.margins: Kirigami.Units.smallSpacing

        QQC2.ToolButton {
            icon.name: imageUrl ? "edit-image" : "insert-image-symbolic"
            display: QQC2.AbstractButton.IconOnly
            text: imageUrl ? "Change Image" : "Add Image"
            onClicked: imageFileDialog.open()
        }

        QQC2.ToolButton {
            icon.name: "edit-delete"
            display: QQC2.AbstractButton.IconOnly
            text: i18n("Remove Image")
            enabled: imageUrl !== ""
            onClicked: confirmDeleteDialog.open()
        }
    }

    // Image Container
    Item {
        id: imageContainer
        anchors.fill: imageCard
        anchors.margins: 10

        // Main Image
        Image {
            id: imageBanner
            anchors.fill: parent
            source: imageUrl
            sourceSize {
                width: imageBanner.width
                height: imageBanner.height
            }
            fillMode: Image.PreserveAspectFit
            cache: true
            asynchronous: true

            // Loading Overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3)
                visible: imageBanner.status === Image.Loading

                DBusyIndicator {
                    anchors.centerIn: parent
                    running: imageBanner.status === Image.Loading
                }
            }

            // Error Overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.3)
                visible: imageBanner.status === Image.Error

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "dialog-error"
                        width: Kirigami.Units.iconSizes.medium
                        height: width
                    }

                    QQC2.Label {
                        text: i18n("Failed to load image")
                        color: "white"
                    }
                }
            }
        }

        // Placeholder when no image
        Item {
            visible: !imageUrl && imageBanner.status !== Image.Loading
            anchors.fill: parent

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.huge
                height: width
                source: "viewimage"
                opacity: 0.5
            }
        }

        // States for different image statuses
        states: [
            State {
                name: "loading"
                when: imageBanner.status === Image.Loading
                PropertyChanges {
                    target: imageContainer
                    opacity: 0.7
                }
            },
            State {
                name: "error"
                when: imageBanner.status === Image.Error
                PropertyChanges {
                    target: imageContainer
                    opacity: 0.7
                }
            },
            State {
                name: "ready"
                when: imageBanner.status === Image.Ready
                PropertyChanges {
                    target: imageContainer
                    opacity: 1
                }
            }
        ]

        // Transitions between states
        transitions: Transition {
            NumberAnimation {
                properties: "opacity"
                duration: 200
            }
        }
    }

    // Your existing dialogs
    ImageFileDialog {
        id: imageFileDialog
        onImageSelected: function(filePath) {
            imageEditorDialog.initialImagePath = filePath
            imageEditorDialog.open()
        }
    }

    ProductImageEditor {
        id: imageEditorDialog
        onImageEdited: function(path) {
            productApi.uploadProductImage(idProduct, path)
        }
    }

    Kirigami.Dialog {
        id: confirmDeleteDialog
        title: i18n("Remove Image")
        standardButtons: Kirigami.Dialog.Yes | Kirigami.Dialog.No

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: i18n("Are you sure you want to remove the product image?")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            productApi.removeProductImage(idProduct)
        }
    }

    // API Loading overlay
    QQC2.Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.5)
        visible: productApi.loading

        DBusyIndicator {
            anchors.centerIn: parent
            running: productApi.loading
        }
    }
}
