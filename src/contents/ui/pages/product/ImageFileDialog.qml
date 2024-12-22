// ImageFileDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import Qt.labs.platform as Platform

Platform.FileDialog {
    id: fileDialog
    title: i18n("Choose Image")
    nameFilters: [ i18n("Image files (*.jpg *.jpeg *.png)") ]
    fileMode: Platform.FileDialog.OpenFile

    signal imageSelected(string filePath)

    onAccepted: {
        imageSelected(currentFile)
    }
}
