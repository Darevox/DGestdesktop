// ReceiptPrintDialog.qml
import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import Qt.labs.platform as Platform
import com.dervox.printing 1.0
import com.dervox.dim

Kirigami.Dialog {
    id: receiptPrintDialog
    title: i18nc("@title:window", "Receipt")
    width: Kirigami.Units.gridUnit * 50
    height: Kirigami.Units.gridUnit * 40
    standardButtons: Kirigami.Dialog.NoButton

    property string pdfUrl: ""
    property bool configChanged: false
    property bool needNewPdf: false
    property int saleId: 0
    property bool requestInProgress: false
    property bool pdfLoadFinished: false // Track PDF load completion
    property int paddingValue: 4 // Padding to subtract from width for actual printing

    // Predefined paper sizes
    property var paperSizes: [
        { name: i18n("Standard POS (80mm)"), width: 80 },
        { name: i18n("Mobile Printer (58mm)"), width: 58 },
        { name: i18n("Legacy POS (76mm)"), width: 76 },
        { name: i18n("Handheld Device (57.5mm)"), width: 57.5 },
        { name: i18n("4 inch Receipt (101.6mm)"), width: 101.6 },
        { name: i18n("Custom Size"), width: -1 }
    ]

    // Load saved configuration from settings and request initial PDF
    onPdfUrlChanged: {
        // Only process valid URLs and avoid reloading if we're the ones who requested it
        if (pdfUrl && !isLoading) {
            console.log("PDF URL changed to:", pdfUrl);
        }
    }

    Component.onCompleted: {
        loadConfig();
    }

    // Add debounce timer to avoid too many requests when changing settings
    Timer {
        id: requestNewPdfTimer
        interval: 300  // Wait 300ms before requesting new PDF
        repeat: false
        onTriggered: {
            if (needNewPdf && !requestInProgress) {
                requestNewPdf();
                needNewPdf = false;
            }
        }
    }

    // Configuration objects
    QtObject {
        id: printerConfig
        property real paperWidth: 80 // Default value in mm
        property bool autoHeight: true
        property string printerName: ""
        property bool grayscale: true
        property int copies: 1
        property string paperSize: "Standard POS (80mm)" // Default value
        property real zoom: 1.0
        property bool directPrint: false
        property int xOffset: 0
        property int yOffset: 0
        property int customHeight: 800 // Default max height in points for fixed mode
        property int paperSizeIndex: 0 // Index of selected paper size
    }

    PrinterHelper {
        id: printerHelper
    }

    // Timer to handle PDF loading timeout
    Timer {
        id: pdfLoadTimeout
        interval: 5000 // 5 seconds timeout
        repeat: false
        onTriggered: {
            if (isLoading && pdfUrl) {
                console.log("PDF load timeout - forcing loading state to complete");
                isLoading = false;
            }
        }
    }

    // Properties for controlling loading state
    property bool isLoading: false

    // Function to request a new PDF with current settings
    function requestNewPdf() {
        if (saleId > 0 && !requestInProgress) {
            requestInProgress = true;
            isLoading = true;
            pdfLoadFinished = false;

            console.log("Requesting new PDF for sale ID:", saleId,
                        "width:", getPaperWidth(),
                        "height mode:", printerConfig.autoHeight ? "auto" : "fixed");

            try {
                saleApi.generateReceipt(
                    saleId,
                    getPaperWidth(),  // Paper width in mm with padding adjustment
                    printerConfig.autoHeight ? "auto" : "fixed",  // Height mode
                    printerConfig.customHeight // Max height in points (used for fixed mode)
                );
            } catch (e) {
                console.error("Error requesting PDF:", e);
                isLoading = false;
                requestInProgress = false;
                applicationWindow().showPassiveNotification(
                    i18n("Error requesting receipt: %1", e.toString()),
                    "long"
                );
            }
        }
    }

    // Get the actual paper width with padding adjustment
    function getPaperWidth() {
        // Start with the configured paper width
        let width = printerConfig.paperWidth;

        // Apply padding reduction for standard sizes (not for custom)
        if (printerConfig.paperSizeIndex !== (paperSizes.length - 1)) {
            width = Math.max(width - paddingValue, width * 0.9);
        }

        return width;
    }

    // Save the current configuration
    function saveConfig() {
        // Create config object
        var config = {
            "paperWidth": printerConfig.paperWidth,
            "autoHeight": printerConfig.autoHeight,
            "printerName": printerConfig.printerName,
            "grayscale": printerConfig.grayscale,
            "copies": printerConfig.copies,
            "paperSize": printerConfig.paperSize,
            "paperSizeIndex": printerConfig.paperSizeIndex,
            "zoom": printerConfig.zoom,
            "directPrint": printerConfig.directPrint,
            "xOffset": printerConfig.xOffset,
            "yOffset": printerConfig.yOffset,
            "customHeight": printerConfig.customHeight
        };

        // Save using PrinterHelper
        let success = printerHelper.savePrinterConfig("ReceiptPrinting", config);

        if (success) {
            configChanged = false;
            applicationWindow().showPassiveNotification(i18n("Printer settings saved"), "short");
        } else {
            applicationWindow().showPassiveNotification(i18n("Failed to save printer settings"), "short");
        }
    }

    function loadConfig() {
        // Load using PrinterHelper
        let config = printerHelper.loadPrinterConfig("ReceiptPrinting");

        if (Object.keys(config).length > 0) {
            // Apply loaded settings
            if ("paperWidth" in config) printerConfig.paperWidth = config["paperWidth"];
            if ("autoHeight" in config) printerConfig.autoHeight = config["autoHeight"];
            if ("printerName" in config) printerConfig.printerName = config["printerName"];
            if ("grayscale" in config) printerConfig.grayscale = config["grayscale"];
            if ("copies" in config) printerConfig.copies = config["copies"];
            if ("paperSize" in config) printerConfig.paperSize = config["paperSize"];
            if ("paperSizeIndex" in config && config["paperSizeIndex"] >= 0 && config["paperSizeIndex"] < paperSizes.length)
                printerConfig.paperSizeIndex = config["paperSizeIndex"];
            if ("zoom" in config) printerConfig.zoom = config["zoom"];
            if ("directPrint" in config) printerConfig.directPrint = config["directPrint"];
            if ("xOffset" in config) printerConfig.xOffset = config["xOffset"];
            if ("yOffset" in config) printerConfig.yOffset = config["yOffset"];
            if ("customHeight" in config) printerConfig.customHeight = config["customHeight"];

            // Update UI when components are available
            Qt.callLater(updateUIfromConfig);
        }
    }

    // Helper function to update UI elements from config
    function updateUIfromConfig() {
        // Set the paper size combo box index
        paperSizeCombo.currentIndex = printerConfig.paperSizeIndex;

        // Update custom width field
        customWidthField.value = printerConfig.paperWidth;
        customWidthField.enabled = (printerConfig.paperSizeIndex === paperSizes.length - 1);

        // Update other UI controls
        autoHeightCheck.checked = printerConfig.autoHeight;
        grayscaleCheck.checked = printerConfig.grayscale;
        copiesField.value = printerConfig.copies;
        directPrintSwitch.checked = printerConfig.directPrint;
        zoomSlider.value = printerConfig.zoom;
        customHeightField.value = printerConfig.customHeight;

        // Position sliders
        xOffsetSlider.value = printerConfig.xOffset;
        yOffsetSlider.value = printerConfig.yOffset;

        // Set printer combo
        for (let i = 0; i < printerCombo.count; i++) {
            if (printerCombo.model[i] === printerConfig.printerName) {
                printerCombo.currentIndex = i;
                break;
            }
        }
    }

    // Apply current settings to the printer helper
    function applyPrinterSettings() {
        printerHelper.setColorMode(!printerConfig.grayscale);
        printerHelper.setCopyCount(printerConfig.copies);

        if (printerConfig.printerName) {
            printerHelper.setPrinterName(printerConfig.printerName);
        }

        // Get the width with padding adjustment
        let actualWidth = getPaperWidth();

        // Apply all settings
        printerHelper.setCustomPaperSize(actualWidth, printerConfig.autoHeight,
                                         printerConfig.autoHeight ? 0 : printerConfig.customHeight);
        printerHelper.setZoom(printerConfig.zoom);
        printerHelper.setPositionOffset(printerConfig.xOffset, printerConfig.yOffset);

        return true;
    }

    // Reset settings to defaults
    function resetToDefaults() {
        printerConfig.paperWidth = 80;
        printerConfig.autoHeight = true;
        printerConfig.grayscale = true;
        printerConfig.copies = 1;
        printerConfig.paperSize = paperSizes[0].name;
        printerConfig.paperSizeIndex = 0;
        printerConfig.zoom = 1.0;
        printerConfig.directPrint = false;
        printerConfig.xOffset = 0;
        printerConfig.yOffset = 0;
        printerConfig.customHeight = 800;

        // Update UI from the new settings
        updateUIfromConfig();

        configChanged = true;
        needNewPdf = true;
        requestNewPdfTimer.start();
    }

    // Print with current settings
    function printReceipt() {
        if (!applyPrinterSettings()) return false;

        let success = false;
        if (printerConfig.directPrint) {
            success = printerHelper.printReceiptWithConfig(pdfUrl, "ReceiptPrinting");
        } else {
            success = printerHelper.printPdf(pdfUrl);
        }

        if (success) {
            // Save config if changed
            if (configChanged) {
                saveConfig();
            }
            return true;
        }
        return false;
    }

    contentItem: GridLayout {
        columns: 2
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        // Col 1: PDF Viewer
        FormCard.FormCard {
            Layout.row: 0
            Layout.column: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rowSpan: 2
            Layout.margins: Kirigami.Units.smallSpacing
            // Make the card header transparent
            FormCard.AbstractFormDelegate {
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: Item {} // Transparent background
                contentItem: Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        // Toolbar for PDF view - with transparent background and centered buttons
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            visible: pdfUrl !== ""
                            color: "transparent" // Transparent background

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Kirigami.Units.smallSpacing
                                width: parent.width * 0.8

                                QQC2.Label {
                                    text: i18n("Page %1 of %2",
                                        (pdfView.currentPage + 1),
                                        Math.max(1, pdfView.count))
                                    visible: pdfView.count > 0
                                }

                                Item { Layout.fillWidth: true }

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
                            }
                        }

                        // Empty state (before PDF is loaded)
                        ColumnLayout {
                            visible: !isLoading && pdfUrl === ""
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Item { Layout.fillHeight: true }

                            Kirigami.Icon {
                                source: "document-print-preview"
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: Kirigami.Units.iconSizes.huge
                                implicitHeight: Kirigami.Units.iconSizes.huge
                            }

                            QQC2.Label {
                                text: i18n("Receipt preview will appear here")
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // PDF View
                        PDFView {
                            id: pdfView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            visible: pdfUrl !== "" && (!isLoading || pdfView.count > 0) // Show PDF view if it has loaded pages even if still technically loading

                            path: {
                                if (pdfUrl) {
                                    var url = new URL(pdfUrl);
                                    return url.pathname.replace(/^\/([A-Z]:)/i, "$1"); // Fix Windows paths
                                }
                                return "";
                            }

                            focus: true

                            // Set pdfLoadFinished when the PDF is loaded
                            onCountChanged: {
                                console.log("PDF page count changed to:", count);
                                if (count > 0) {
                                    pdfLoadFinished = true;
                                    isLoading = false;
                                    pdfLoadTimeout.stop(); // Stop the timeout timer
                                }
                            }

                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                                minimumSize: 0.04
                            }
                            QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
                                minimumSize: 0.04
                            }
                        }

                        // Busy indicator
                        QQC2.BusyIndicator {
                            id: busyIndicator
                            Layout.alignment: Qt.AlignCenter
                            width: Kirigami.Units.gridUnit * 5
                            height: width
                            running: isLoading
                            visible: isLoading
                        }
                    }
                }
            }
        }

        // Col 2: Paper Settings
        FormCard.FormCard {
            Layout.row: 0
            Layout.column: 1
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 20
            Layout.margins: Kirigami.Units.smallSpacing

            FormCard.FormHeader {
                title: i18n("Paper Settings")
            }

            FormCard.FormComboBoxDelegate {
                id: paperSizeCombo
                text: i18n("Paper Size")
                model: {
                    let sizeLabels = [];
                    for (let i = 0; i < paperSizes.length; i++) {
                        sizeLabels.push(paperSizes[i].name);
                    }
                    return sizeLabels;
                }

                currentIndex: printerConfig.paperSizeIndex

                onCurrentIndexChanged: {
                    console.log("Paper size changed to index:", currentIndex, "name:", paperSizes[currentIndex].name);

                    if (!ignoreChanges) {
                        // Save the selection
                        printerConfig.paperSizeIndex = currentIndex;
                        printerConfig.paperSize = paperSizes[currentIndex].name;

                        // Apply the selected size
                        applySelectedSize();

                        // Trigger regeneration, but with a slight delay to ensure values are set
                        Qt.callLater(function() {
                            configChanged = true;
                            needNewPdf = true;
                            requestNewPdfTimer.start();
                        });
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            // Custom width (only visible when "Custom Size" is selected)
            FormCard.FormSpinBoxDelegate {
                id: customWidthField
                label: i18n("Width (mm)")
                value: printerConfig.paperWidth
                from: 30
                to: 150
                visible: paperSizeCombo.currentIndex === (paperSizes.length - 1) // Last item is "Custom Size"

                onValueChanged: {
                    if (enabled && !ignoreChanges) {
                        printerConfig.paperWidth = value;
                        configChanged = true;
                        needNewPdf = true;
                        requestNewPdfTimer.start();
                    }
                }
            }

            FormCard.FormDelegateSeparator {
                visible: paperSizeCombo.currentIndex === (paperSizes.length - 1)
            }

            FormCard.FormSwitchDelegate {
                id: autoHeightCheck
                text: i18n("Auto Height")
                checked: printerConfig.autoHeight
                onCheckedChanged: {
                    if (!ignoreChanges) {
                        printerConfig.autoHeight = checked;
                        configChanged = true;
                        needNewPdf = true;
                        requestNewPdfTimer.start();
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            // Custom height field for fixed mode
            FormCard.FormSpinBoxDelegate {
                id: customHeightField
                label: i18n("Max Height (pt)")
                value: printerConfig.customHeight
                from: 200
                to: 2000
                stepSize: 50
                visible: !printerConfig.autoHeight

                onValueChanged: {
                    if (!ignoreChanges) {
                        printerConfig.customHeight = value;
                        configChanged = true;
                        needNewPdf = true;
                        requestNewPdfTimer.start();
                    }
                }
            }

            FormCard.FormDelegateSeparator {
                visible: !printerConfig.autoHeight
            }

            FormCard.FormSwitchDelegate {
                id: grayscaleCheck
                text: i18n("Grayscale")
                checked: printerConfig.grayscale
                onCheckedChanged: {
                    if (!ignoreChanges) {
                        printerConfig.grayscale = checked;
                        configChanged = true;
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormSpinBoxDelegate {
                id: copiesField
                label: i18n("Copies")
                value: printerConfig.copies
                from: 1
                to: 10
                onValueChanged: {
                    if (!ignoreChanges) {
                        printerConfig.copies = value;
                        configChanged = true;
                    }
                }
            }
        }

        // Col 2, Row 2: Print Controls
        FormCard.FormCard {
                Layout.row: 0
                Layout.column: 2
                Layout.fillWidth: true
            //    Layout.fillHeight: true
                Layout.rowSpan: 2
                Layout.margins: Kirigami.Units.smallSpacing

            FormCard.FormHeader {
                title: i18n("Print Controls")
            }

            FormCard.FormSwitchDelegate {
                id: directPrintSwitch
                text: i18n("Direct Print")
                checked: printerConfig.directPrint
                onCheckedChanged: {
                    if (!ignoreChanges) {
                        printerConfig.directPrint = checked;
                        configChanged = true;
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormComboBoxDelegate {
                id: printerCombo
                text: i18n("Printer")
                model: printerHelper.getPrinterNames()
                displayText: printerConfig.printerName || i18n("Default Printer")

                onActivated: {
                    if (!ignoreChanges) {
                        printerConfig.printerName = model[currentIndex];
                        configChanged = true;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing

                QQC2.Button {
                    text: i18n("Save Settings")
                    icon.name: "document-save"
                    enabled: configChanged
                    Layout.fillWidth: true

                    onClicked: {
                        saveConfig();
                    }
                }

                QQC2.Button {
                    text: i18n("Reset")
                    icon.name: "edit-reset"
                    Layout.fillWidth: true

                    onClicked: {
                        resetToDefaults();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing

                QQC2.Button {
                    text: i18n("Save PDF")
                    icon.name: "document-save-as"
                    enabled: pdfView.count > 0
                    Layout.fillWidth: true

                    onClicked: {
                        // Show a file dialog to get save location
                        const fileDialog = saveFileDialogComponent.createObject(receiptPrintDialog);
                        fileDialog.open();
                    }
                }

                QQC2.Button {
                    text: i18n("Print")
                    icon.name: "document-print"
                    enabled: pdfView.count > 0
                    Layout.fillWidth: true

                    onClicked: {
                        if (printReceipt()) {
                            applicationWindow().showPassiveNotification(
                                i18n("Receipt printed successfully"),
                                "short"
                            );
                            receiptPrintDialog.close();
                        } else {
                            applicationWindow().showPassiveNotification(
                                i18n("Failed to print receipt"),
                                "short"
                            );
                        }
                    }
                }
            }
        }

        // Col 3: Advanced Settings
        // FormCard.FormCard {
        //     Layout.row: 0
        //     Layout.column: 2
        //     Layout.fillWidth: true
        //     Layout.fillHeight: true
        //     Layout.rowSpan: 2
        //     Layout.margins: Kirigami.Units.smallSpacing

        //     FormCard.FormHeader {
        //         title: i18n("Advanced Settings")
        //     }

        //     FormCard.FormDelegateSeparator {}

        //     // Scaling slider
        //     ColumnLayout {
        //         Layout.fillWidth: true
        //         spacing: 0

        //         QQC2.Label {
        //             text: i18n("Zoom: %1×", zoomSlider.value.toFixed(1))
        //             Layout.alignment: Qt.AlignHCenter
        //             Layout.topMargin: Kirigami.Units.smallSpacing
        //             Layout.bottomMargin: Kirigami.Units.smallSpacing
        //         }

        //         QQC2.Slider {
        //             id: zoomSlider
        //             Layout.fillWidth: true
        //             Layout.leftMargin: Kirigami.Units.largeSpacing
        //             Layout.rightMargin: Kirigami.Units.largeSpacing
        //             from: 0.5
        //             to: 2.0
        //             stepSize: 0.1
        //             value: printerConfig.zoom

        //             onMoved: {
        //                 if (!ignoreChanges) {
        //                     printerConfig.zoom = value;
        //                     configChanged = true;
        //                 }
        //             }
        //         }
        //     }

        //     FormCard.FormDelegateSeparator {}

        //     // FormCard.FormHeader {
        //     //     title: i18n("Position Adjustment")
        //     // }

        //     // // Horizontal offset
        //     // ColumnLayout {
        //     //     Layout.fillWidth: true
        //     //     spacing: 0

        //     //     QQC2.Label {
        //     //         text: i18n("Horizontal: %1", xOffsetSlider.value)
        //     //         Layout.alignment: Qt.AlignHCenter
        //     //         Layout.topMargin: Kirigami.Units.smallSpacing
        //     //         Layout.bottomMargin: Kirigami.Units.smallSpacing
        //     //     }

        //     //     QQC2.Slider {
        //     //         id: xOffsetSlider
        //     //         Layout.fillWidth: true
        //     //         Layout.leftMargin: Kirigami.Units.largeSpacing
        //     //         Layout.rightMargin: Kirigami.Units.largeSpacing
        //     //         from: -50
        //     //         to: 50
        //     //         stepSize: 1
        //     //         value: printerConfig.xOffset

        //     //         onMoved: {
        //     //             if (!ignoreChanges) {
        //     //                 printerConfig.xOffset = value;
        //     //                 configChanged = true;
        //     //             }
        //     //         }
        //     //     }
        //     // }

        //     // FormCard.FormDelegateSeparator {}

        //     // Vertical offset
        //     // ColumnLayout {
        //     //     Layout.fillWidth: true
        //     //     spacing: 0

        //     //     QQC2.Label {
        //     //         text: i18n("Vertical: %1", yOffsetSlider.value)
        //     //         Layout.alignment: Qt.AlignHCenter
        //     //         Layout.topMargin: Kirigami.Units.smallSpacing
        //     //         Layout.bottomMargin: Kirigami.Units.smallSpacing
        //     //     }

        //     //     QQC2.Slider {
        //     //         id: yOffsetSlider
        //     //         Layout.fillWidth: true
        //     //         Layout.leftMargin: Kirigami.Units.largeSpacing
        //     //         Layout.rightMargin: Kirigami.Units.largeSpacing
        //     //         from: -50
        //     //         to: 50
        //     //         stepSize: 1
        //     //         value: printerConfig.yOffset

        //     //         onMoved: {
        //     //             if (!ignoreChanges) {
        //     //                 printerConfig.yOffset = value;
        //     //                 configChanged = true;
        //     //             }
        //     //         }
        //     //     }
        //     // }

        //     Item {
        //         Layout.fillHeight: true
        //     }
        // }
    }

    // Function to apply the selected size from the combo box
    function applySelectedSize() {
        // Get the selected paper size
        let selectedSize = paperSizes[paperSizeCombo.currentIndex];

        // For Custom Size, don't change the current values
        if (selectedSize.width === -1) {
            customWidthField.enabled = true;
            return;
        }

        // Set the width value
        let prevIgnore = ignoreChanges;
        ignoreChanges = true;
        printerConfig.paperWidth = selectedSize.width;
        customWidthField.value = selectedSize.width;
        customWidthField.enabled = false;
        ignoreChanges = prevIgnore;
    }

    customFooterActions: [
        Kirigami.Action {
            text: i18n("Close")
            icon.name: "dialog-close"
            onTriggered: {
                receiptPrintDialog.close()
            }
        }
    ]

    Component {
        id: saveFileDialogComponent

        Platform.FileDialog {
            title: i18n("Save Receipt as PDF")
            folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
            fileMode: Platform.FileDialog.SaveFile
            nameFilters: [i18n("PDF Files (*.pdf)")]
            defaultSuffix: "pdf"

            onAccepted: {
                // Get the selected file path and convert it to local path
                var saveUrl = file.toString();

                // Convert URL to local path for the PrinterHelper
                var localPath = saveUrl;

                // Save the receipt as PDF
                if (printerHelper.saveReceiptAsPdf(pdfUrl, localPath)) {
                    applicationWindow().showPassiveNotification(
                        i18n("Receipt saved as PDF"),
                        "short"
                    );
                } else {
                    applicationWindow().showPassiveNotification(
                        i18n("Failed to save receipt as PDF"),
                        "short"
                    );
                }
            }

            onRejected: {
                // User canceled the file dialog
            }
        }
    }

    // Property to track UI initialization state
    property bool ignoreChanges: true

    onOpened: {
        // Reset state
        isLoading = false;
        requestInProgress = false;
        needNewPdf = false;
        pdfLoadFinished = false;

        // Enable ignoreChanges to prevent multiple regenerations during setup
        ignoreChanges = true;

        // Load settings
        loadConfig();

        // End ignoreChanges after a delay to ensure all UI is set up
        Qt.callLater(function() {
            ignoreChanges = false;

            // Request new PDF if we have a sale ID but no PDF yet
            if (saleId > 0 && pdfUrl === "") {
                requestNewPdf();
            }
        });
    }

    onClosed: {
        // Clean up PDF file if it was a temporary file
        if (pdfUrl) {
            console.log("Dialog closed, PDF URL:", pdfUrl);
        }
    }

    // Connection to handle PDF generation
    Connections {
        target: saleApi

        function onReceiptGenerated(url) {
            requestInProgress = false;

            // Only set URL if it's different to avoid loops
            if (url !== receiptPrintDialog.pdfUrl) {
                console.log("Receipt generated:", url);
                receiptPrintDialog.pdfUrl = url;

                // Keep isLoading true until PDF is actually loaded
                // The pdfView.onCountChanged will set isLoading to false

                // Start a timeout in case the PDF never loads
                pdfLoadTimeout.restart();
            }
        }

        function onErrorReceiptGenerated(title, message) {
            isLoading = false;
            requestInProgress = false;
            console.error("Error generating receipt:", title, message);
            applicationWindow().showPassiveNotification(
                i18n("Failed to generate receipt: %1", message),
                "long"
            );
        }
    }
}
