import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami
import Qt.labs.platform as Platform
// import com.dervox.PDFView 1.0
import com.dervox.printing 1.0
import com.dervox.dim
import "../../components"
Kirigami.Dialog {
    id: pdfDialog
    title: i18nc("@title:window", "Invoice PDF")
    width: Kirigami.Units.gridUnit * 60
    height: Kirigami.Units.gridUnit * 40

    property string pdfUrl: ""
    property string originalFileName: ""
    property string defaultFileName: "invoice.pdf"

    PrinterHelper {
        id: printerHelper
    }

    customFooterActions: [
        Kirigami.Action {
            text: i18n("Save PDF")
            icon.name: "document-save"
            onTriggered: {
                saveFileDialog.currentFile = "file:///" + StandardPaths.writableLocation(StandardPaths.DocumentsLocation) + "/" + originalFileName
                saveFileDialog.open()
            }
        },
        Kirigami.Action {
            text: i18n("Print")
            icon.name: "document-print"
            enabled: pdfView.count > 0
            onTriggered: {
                if (printerHelper.printPdfWithPreview(pdfUrl)) {
                    applicationWindow().showPassiveNotification(
                        i18n("Document printed successfully"),
                        "short"
                    )
                } else {
                    applicationWindow().showPassiveNotification(
                        i18n("Printing failed"),
                        "short"
                    )
                }
            }
        },
        Kirigami.Action {
            text: i18n("Close")
            icon.name: "dialog-close"
            onTriggered: {
                pdfDialog.close()
            }
        }
    ]

    ColumnLayout {
        spacing: 10
        width: Kirigami.Units.gridUnit * 60
        height: pdfDialog.height

        // Toolbar
        QQC2.ToolBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3

            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Item { Layout.fillWidth: true }

                QQC2.Label {
                    text: i18n("Page %1 of %2",
                        (pdfView.currentPage + 1),
                        Math.max(1, pdfView.count))
                    visible: pdfView.count > 0
                }

                QQC2.ToolButton {
                    icon.name: "zoom-fit-width"
                    onClicked: pdfView.zoom = 1.0
                    QQC2.ToolTip.text: i18n("Fit to width")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ToolButton {
                    icon.name: "zoom-in"
                    onClicked: pdfView.zoom *= 1.2
                    QQC2.ToolTip.text: i18n("Zoom in")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ToolButton {
                    icon.name: "zoom-out"
                    onClicked: pdfView.zoom *= 0.8
                    QQC2.ToolTip.text: i18n("Zoom out")
                    QQC2.ToolTip.visible: hovered
                }

                Item { Layout.fillWidth: true }
            }
        }

        // PDF View
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            PDFView {
                id: pdfView
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing * 5
                // path: pdfUrl.toString().substring(7) // Remove "file://" prefix
                path: {
                    var url = new URL(pdfUrl);
                    return url.pathname.replace(/^\/([A-Z]:)/i, "$1"); // Fix Windows paths
                }

                focus: true

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    minimumSize: 0.04
                }

                DBusyIndicator {
                    anchors.centerIn: parent
                    running: pdfView.count === 0 && pdfUrl !== ""
                    visible: running
                }
            }
        }
    }

    // File save dialog
    Platform.FileDialog {
        id: saveFileDialog
        title: i18n("Save PDF")
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: [ i18n("PDF files (*.pdf)") ]
        defaultSuffix: "pdf"
        currentFile: "file:///" + StandardPaths.writableLocation(StandardPaths.DocumentsLocation) + "/" + defaultFileName

        onAccepted: {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", pdfDialog.pdfUrl, true);
            xhr.responseType = "arraybuffer";

            xhr.onload = function() {
                if (xhr.status === 200) {
                    let saveXhr = new XMLHttpRequest();
                    saveXhr.open("PUT", saveFileDialog.file, true);
                    saveXhr.onload = function() {
                        if (saveXhr.status === 200) {
                            applicationWindow().showPassiveNotification(
                                i18n("PDF saved successfully"),
                                "short"
                            );
                        } else {
                            applicationWindow().showPassiveNotification(
                                i18n("Failed to save PDF"),
                                "short"
                            );
                        }
                    };
                    saveXhr.send(xhr.response);
                } else {
                    applicationWindow().showPassiveNotification(
                        i18n("Failed to read PDF"),
                        "short"
                    );
                }
            };
            xhr.send();
        }
    }

    onClosed: {
        if (pdfUrl) {
            const xhr = new XMLHttpRequest()
            xhr.open("DELETE", pdfUrl)
            xhr.send()
            pdfUrl = ""
        }
    }
}
