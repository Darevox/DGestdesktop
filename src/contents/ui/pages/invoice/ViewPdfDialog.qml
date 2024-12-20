// ViewPdfDialog.qml
 import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Pdf
import Qt.labs.platform as Platform

Kirigami.Dialog {
    id: pdfDialog
    title: i18nc("@title:window", "Invoice PDF")
    // preferredWidth: Kirigami.Units.gridUnit * 60
    // preferredHeight: Kirigami.Units.gridUnit * 40
    width: Kirigami.Units.gridUnit * 60
    height: Kirigami.Units.gridUnit * 40

    property string pdfUrl: ""
    property string originalFileName: ""  // Add this to store original filename
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
            enabled: pdfDocument.status === PdfDocument.Ready
            onTriggered: {
                printDialog.open()
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
                anchors.margins :  Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                Item { Layout.fillWidth: true }

                QQC2.Label {
                    text: i18n("Page %1 of %2",
                               (pdfView.currentPage + 1),
                               Math.max(1, pdfDocument.pageCount))
                    visible: pdfDocument.status === PdfDocument.Ready
                }

                QQC2.ToolButton {
                    icon.name: "zoom-fit-width"
                    onClicked: pdfView.scaleToWidth(pdfView.width, pdfView.height)
                    QQC2.ToolTip.text: i18n("Fit to width")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ToolButton {
                    icon.name: "zoom-in"
                    onClicked: pdfView.renderScale *= 1.2
                    QQC2.ToolTip.text: i18n("Zoom in")
                    QQC2.ToolTip.visible: hovered
                }

                QQC2.ToolButton {
                    icon.name: "zoom-out"
                    onClicked: pdfView.renderScale *= 0.8
                    QQC2.ToolTip.text: i18n("Zoom out")
                    QQC2.ToolTip.visible: hovered
                }

                Item { Layout.fillWidth: true }


            }
        }

        // PDF View
        Item{
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip:true
            PdfDocument {
                id: pdfDocument
                source: pdfDialog.pdfUrl
                onStatusChanged: function() {
                    console.log("PDF status:", status, source)
                    if (status === PdfDocument.Ready) {
                        console.log("PDF loaded, page count:", pageCount)
                        Qt.callLater(function() {
                            pdfView.scaleToWidth(pdfView.width, pdfView.height)
                        })
                    }
                }
            }
            PdfMultiPageView {
                id: pdfView
                anchors.fill:parent
                anchors.margins : Kirigami.Units.smallSpacing * 5
                clip:true
                document: pdfDocument
                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: pdfDocument.status === PdfDocument.Loading
                    visible: running
                }
            }
        }
    }

    // File save dialog
    // File save dialog
    Platform.FileDialog {
        id: saveFileDialog
        title: i18n("Save PDF")
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: [ i18n("PDF files (*.pdf)") ]
        defaultSuffix: "pdf"

        onAccepted: {
            // Read source file
            let xhr = new XMLHttpRequest();
            xhr.open("GET", pdfDialog.pdfUrl, true);
            xhr.responseType = "arraybuffer";

            xhr.onload = function() {
                if (xhr.status === 200) {
                    // Write to destination file
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
        // pdfDocument.source = ""
        if (pdfUrl) {
            const xhr = new XMLHttpRequest()
            xhr.open("DELETE", pdfUrl)
            xhr.send()
            pdfUrl = ""
        }
    }
}
