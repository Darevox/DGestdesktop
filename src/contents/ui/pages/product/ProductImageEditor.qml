// ProductImageEditor.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickimageeditor as KQuickImageEditor
import Qt.labs.platform
import org.kde.kirigamiaddons.components as Kcomponents

Kirigami.Dialog {
    id: imageEditorDialog
    title: i18n("Edit Product Image")
    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 30

    property string initialImagePath: ""
    property var onImageEdited: null
    property bool hasChanges: imageDoc.edited
    property var allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']

    // Get file extension
    function getFileExtension(filePath) {
        return filePath.slice((filePath.lastIndexOf(".") - 1 >>> 0) + 2).toLowerCase();
    }

    // Validate and get proper extension
    function getValidExtension(filePath) {
        const ext = getFileExtension(filePath);
        return allowedExtensions.includes(ext) ? ext : 'jpg';
    }

    // Generate temp file path
    function generateTempPath() {
        const ext = getValidExtension(initialImagePath);
        const timestamp = Date.now();
        return StandardPaths.writableLocation(StandardPaths.TempLocation) +
                "/temp_product_image_" + timestamp + "." + ext;
    }

    // Dynamic temp file path
    property string tempFilePath: generateTempPath()

    // Optional: Add mime type handling
    function getMimeType(filePath) {
        const ext = getFileExtension(filePath);
        const mimeTypes = {
            'png': 'image/png',
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'gif': 'image/gif',
            'webp': 'image/webp'
        };
        return mimeTypes[ext] || 'image/jpeg';
    }

    // Use in save function
    function saveModifiedImage() {
        if (hasChanges) {
            const tempPath = generateTempPath();
            if (imageDoc.saveAs(tempPath)) {
                console.log("Saved with mime type:", getMimeType(tempPath));
                return tempPath;
            }
            return null;
        }
        return initialImagePath;
    }

    standardButtons: Kirigami.Dialog.NoButton
    // Editing tools
    Kirigami.InlineMessage {
        id: errorMessage
        type: Kirigami.MessageType.Error
        visible: false
        showCloseButton: true
    }
    // header:  RowLayout {
    //     Layout.fillWidth: true
    //     spacing: Kirigami.Units.smallSpacing

    //     QQC2.ToolButton {
    //         icon.name: "transform-crop"
    //         text: i18n("Crop")
    //         onClicked: toggleCropMode()
    //     }

    //     QQC2.ToolButton {
    //         icon.name: "object-rotate-left"
    //         text: i18n("Rotate Left")
    //         onClicked: imageDoc.rotate(-90)
    //     }

    //     QQC2.ToolButton {
    //         icon.name: "object-rotate-right"
    //         text: i18n("Rotate Right")
    //         onClicked: imageDoc.rotate(90)
    //     }

    //     QQC2.ToolButton {
    //         icon.name: "object-flip-vertical"
    //         text: i18n("Flip")
    //         onClicked: imageDoc.mirror(false, true)
    //     }

    //     QQC2.ToolButton {
    //         icon.name: "object-flip-horizontal"
    //         text: i18n("Mirror")
    //         onClicked: imageDoc.mirror(true, false)
    //     }

    //     QQC2.ToolButton {
    //         icon.name: "edit-undo"
    //         text: i18n("Undo")
    //         enabled: imageDoc.edited
    //         onClicked: imageDoc.undo()
    //     }
    // }
    // Main editor container
    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        // Image editor
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Kirigami.Units.smallSpacing * 2
            KQuickImageEditor.ImageItem {
                id: editImage
                anchors.fill: parent
                fillMode: KQuickImageEditor.ImageItem.PreserveAspectFit
                image: imageDoc.image

                readonly property real ratioX: paintedWidth / nativeWidth
                readonly property real ratioY: paintedHeight / nativeHeight

                KQuickImageEditor.ImageDocument {
                    id: imageDoc
                    path: imageEditorDialog.initialImagePath
                }

                // Selection tool for cropping
                KQuickImageEditor.SelectionTool {
                    id: selectionTool
                    visible: rootEditorView.resizing
                    width: editImage.paintedWidth
                    height: editImage.paintedHeight
                    x: editImage.horizontalPadding
                    y: editImage.verticalPadding
                    KQuickImageEditor.CropBackground {
                        anchors.fill: parent
                        z: -1
                        insideX: selectionTool.selectionX
                        insideY: selectionTool.selectionY
                        insideWidth: selectionTool.selectionWidth
                        insideHeight: selectionTool.selectionHeight
                    }
                }
            }
        }

        Kcomponents.FloatingToolBar {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.largeSpacing
            }
            Layout.preferredWidth :contentItem.implicitWidth
            contentItem: Kirigami.ActionToolBar {
                //alignment: Qt.AlignCenter
                display:Kirigami.DisplayHint.KeepVisible
                actions: [
                    Kirigami.Action {
                        icon.name: "transform-crop"
                        text: i18n("Crop")
                        onTriggered: toggleCropMode()
                        displayHint : Kirigami.DisplayHint.KeepVisible

                    },
                    // Kirigami.Action {
                    //     displayComponent: QQC2.ToolSeparator {
                    //         padding: Kirigami.Units.smallSpacing
                    //     }
                    // },

                    Kirigami.Action {
                        icon.name: "object-rotate-left"
                        text: i18n("Rotate Left")
                        onTriggered: imageDoc.rotate(-90)
                        displayHint : Kirigami.DisplayHint.KeepVisible

                    },
                    Kirigami.Action {
                        icon.name: "object-rotate-right"
                        text: i18n("Rotate Right")
                        onTriggered: imageDoc.rotate(90)
                        displayHint : Kirigami.DisplayHint.KeepVisible

                    },
                    Kirigami.Action {
                        icon.name: "object-flip-vertical"
                        text: i18n("Flip")
                        onTriggered: imageDoc.mirror(false, true)
                        displayHint : Kirigami.DisplayHint.KeepVisible

                    },
                    Kirigami.Action {
                        icon.name: "object-flip-horizontal"
                        text: i18n("Mirror")
                        onTriggered: imageDoc.mirror(true, false)
                        displayHint : Kirigami.DisplayHint.KeepVisible
                    },


                    // Kirigami.Action {
                    //     displayComponent: QQC2.ToolSeparator {
                    //         padding: Kirigami.Units.smallSpacing
                    //     }
                    // },
                    Kirigami.Action {
                        icon.name: "edit-undo"
                        text: i18n("Undo")
                        enabled: imageDoc.edited
                        onTriggered: imageDoc.undo()
                        displayHint : Kirigami.DisplayHint.KeepVisible

                    }

                ]
            }
        }

    }

    property bool isResizing: false

    function toggleCropMode() {
        isResizing = !isResizing
        selectionTool.visible = isResizing
        if (!isResizing && selectionTool.selectionWidth > 0) {
            cropImage()
        }
    }

    function cropImage() {
        imageDoc.crop(
                    selectionTool.selectionX / editImage.ratioX,
                    selectionTool.selectionY / editImage.ratioY,
                    selectionTool.selectionWidth / editImage.ratioX,
                    selectionTool.selectionHeight / editImage.ratioY
                    )
    }

    customFooterActions: [
        Kirigami.Action {
            text: i18n("Upload")
            icon.name: "document-save"
            enabled: !productApi.isLoading
            onTriggered: {
                const savePath = saveModifiedImage();
                if (savePath) {
                    if (imageEditorDialog.onImageEdited) {
                        imageEditorDialog.onImageEdited(savePath);
                    }
                    imageEditorDialog.close();
                } else {
                    errorMessage.text = i18n("Failed to save image");
                    errorMessage.visible = true;
                }
            }
        },
        Kirigami.Action {
            text: i18n("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                // Clean up temp file if it exists
                if (hasChanges) {
                    var file = Qt.createQmlObject('import Qt.labs.platform 1.1; File {}', imageEditorDialog)
                    if (file.exists(tempFilePath)) {
                        file.remove(tempFilePath)
                    }
                }
                imageEditorDialog.close()
            }
        }
    ]
    // Cleanup on close
    onClosed: {
        if (hasChanges) {
            var file = Qt.createQmlObject('import Qt.labs.platform 1.1; File {}', imageEditorDialog)
            if (file.exists(tempFilePath)) {
                file.remove(tempFilePath)
            }
        }
    }

    // Error message
    // footer: Kirigami.InlineMessage {
    //     id: errorMessage
    //     type: Kirigami.MessageType.Error
    //     visible: false
    //     showCloseButton: true
    // }
}
