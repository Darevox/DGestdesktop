// ReceiptSettingsPage.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import "../../components"
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import Qt.labs.platform 1.1 as Platform
import com.dervox.printing 1.0
import com.dervox.dim

Kirigami.ScrollablePage {
    id: receiptSettingsPage
    title: i18nc("@title", "Receipt Printer Settings")

    property bool isLoading: false
    property bool initialLoadComplete: false
    property bool preventAutoGenerate: false
    property bool requestPending: false
    property bool busyIndicatorRunning: false  // Renamed from busyIndicator.running
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

    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.ToolBar

    PrinterHelper {
        id: printerHelper
    }

    // Add debounce timer for auto-generation
    Timer {
        id: regenerateTimer
        interval: 800 // Increase to 800ms for more stable debouncing
        running: false
        repeat: false
        onTriggered: {
            if (!preventAutoGenerate && initialLoadComplete && !requestPending) {
                generateTestReceipt();
            }
        }
    }

    // Get the configuration from storage
    Component.onCompleted: {
        preventAutoGenerate = true;
        let config = printerHelper.loadPrinterConfig("ReceiptPrinting");

        // Apply loaded settings
        if (Object.keys(config).length > 0) {
            // Apply loaded settings
            if ("paperWidth" in config) printerConfig.paperWidth = config["paperWidth"];
            if ("autoHeight" in config) printerConfig.autoHeight = config["autoHeight"];
            if ("printerName" in config) printerConfig.printerName = config["printerName"];
            if ("grayscale" in config) printerConfig.grayscale = config["grayscale"];
            if ("copies" in config) printerConfig.copies = config["copies"];
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

        // Wait a moment then generate initial receipt
        initialGenerateTimer.start();
    }

    // Timer to generate initial receipt after component is fully loaded
    Timer {
        id: initialGenerateTimer
        interval: 500 // Increase to 500ms to ensure UI is fully initialized
        running: false
        repeat: false
        onTriggered: {
            preventAutoGenerate = false;
            initialLoadComplete = true;
            generateTestReceipt();
        }
    }

    // Helper function to update UI from config
    function updateUIfromConfig() {
        // Prevent auto-generation during UI updates
        preventAutoGenerate = true;

        // Set the paper size combo index
        paperSizeCombo.currentIndex = printerConfig.paperSizeIndex;

        // Update width field
        widthField.value = printerConfig.paperWidth;
        widthField.enabled = (printerConfig.paperSizeIndex === paperSizes.length - 1);

        // Update other controls
        autoHeightSwitch.checked = printerConfig.autoHeight;
        heightField.value = printerConfig.customHeight;
        xOffsetSlider.value = printerConfig.xOffset;
        yOffsetSlider.value = printerConfig.yOffset;

        // Re-enable auto-generation after UI updates
        preventAutoGenerate = false;
    }

    // Watch for config changes to auto-regenerate preview
    Connections {
        target: printerConfig

        // Use onPropertyChanged handlers to trigger the debounce timer
        function onPaperWidthChanged() { regenerateTimer.restart(); }
        function onAutoHeightChanged() { regenerateTimer.restart(); }
        function onPrinterNameChanged() { regenerateTimer.restart(); }
        function onGrayscaleChanged() { regenerateTimer.restart(); }
        function onCopiesChanged() { regenerateTimer.restart(); }
        function onPaperSizeIndexChanged() { regenerateTimer.restart(); }
        function onZoomChanged() { regenerateTimer.restart(); }
        function onDirectPrintChanged() { regenerateTimer.restart(); }
        function onXOffsetChanged() { regenerateTimer.restart(); }
        function onYOffsetChanged() { regenerateTimer.restart(); }
        function onCustomHeightChanged() { regenerateTimer.restart(); }
    }

    // Configuration object
    QtObject {
        id: printerConfig

        // Properties with automatic change notifications
        property real paperWidth: 80 // Default value in mm
        property bool autoHeight: true
        property string printerName: ""
        property bool grayscale: true
        property int copies: 1
        property int paperSizeIndex: 0 // Index of selected paper size
        property real zoom: 1.0
        property bool directPrint: false
        property int xOffset: 0
        property int yOffset: 0
        property int customHeight: 800 // Default max height in points for fixed mode
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
            applicationWindow().showPassiveNotification(i18n("Printer settings saved"), "short");
        } else {
            applicationWindow().showPassiveNotification(i18n("Failed to save printer settings"), "short");
        }
    }

    // Function to apply the selected size from the combo box
    function applySelectedSize() {
        // Get the selected paper size
        let selectedSize = paperSizes[paperSizeCombo.currentIndex];

        // For Custom Size, don't change the current values
        if (selectedSize.width === -1) {
            widthField.enabled = true;
            return;
        }

        // Set the width value
        let prevPreventAutoGenerate = preventAutoGenerate;
        preventAutoGenerate = true;
        printerConfig.paperWidth = selectedSize.width;
        widthField.value = selectedSize.width;
        widthField.enabled = false;
        preventAutoGenerate = prevPreventAutoGenerate;
    }

    // Reset to defaults
    function resetToDefaults() {
        // Prevent auto generation during reset
        preventAutoGenerate = true;

        printerConfig.paperWidth = 80;
        printerConfig.autoHeight = true;
        printerConfig.grayscale = true;
        printerConfig.copies = 1;
        printerConfig.paperSizeIndex = 0; // First item - Standard POS (80mm)
        printerConfig.zoom = 1.0;
        printerConfig.directPrint = false;
        printerConfig.xOffset = 0;
        printerConfig.yOffset = 0;
        printerConfig.customHeight = 800;

        // Update UI
        updateUIfromConfig();

        // Save configuration
        saveConfig();

        // Re-enable auto generation and generate new preview
        preventAutoGenerate = false;
        generateTestReceipt();
    }

    header: QQC2.ToolBar {
        contentItem: RowLayout {
            Item { Layout.fillWidth: true }

            QQC2.Button {
                text: i18n("Reset to Defaults")
                icon.name: "edit-reset"
                onClicked: {
                    resetDialog.open()
                }
            }

            QQC2.Button {
                text: i18n("Save Settings")
                icon.name: "document-save"
                highlighted: true
                onClicked: {
                    saveConfig()
                }
            }
        }
    }

    // Reset confirmation dialog
    Kirigami.PromptDialog {
        id: resetDialog
        title: i18n("Reset Settings")
        subtitle: i18n("Are you sure you want to reset all receipt printer settings to defaults? The defaults will be saved immediately.")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            resetToDefaults()
        }
    }

    function generateTestReceipt() {
        // Check if we should skip generation
        if (preventAutoGenerate) {
            console.log("Skipping test generation (prevented)");
            return;
        }

        // Check if there's already a request in progress
        if (requestPending) {
            console.log("Skipping test generation (request already pending)");
            return;
        }

        // Get the width with padding adjustment
        let actualWidth = getPaperWidth();

        console.log("Generating test receipt with width:", actualWidth,
                  "autoHeight:", printerConfig.autoHeight,
                  "customHeight:", printerConfig.customHeight);

        busyIndicatorRunning = true;
        requestPending = true;

        // Generate a test receipt with the current settings
        try {
            saleApi.generateTestReceipt(
                actualWidth, // Apply padding reduction
                printerConfig.autoHeight ? "auto" : "fixed",
                printerConfig.customHeight
            );
        } catch (e) {
            console.error("Error calling generateTestReceipt:", e);
            busyIndicatorRunning = false;
            requestPending = false;

            // Show error notification
            applicationWindow().showPassiveNotification(
                i18n("Failed to generate preview: %1", e.toString()),
                "long"
            );
        }
    }

    // Main content
    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Kirigami.Units.largeSpacing

        // Two-column layout
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            // Left column - Settings
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1.5
                spacing: Kirigami.Units.largeSpacing

                // Paper Size Section
                FormCard.FormHeader {
                    title: i18nc("@title:group", "Receipt Size Settings")
                    Layout.fillWidth: true
                }

                FormCard.FormCard {
                    Layout.fillWidth: true

                    FormCard.FormComboBoxDelegate {
                        id: paperSizeCombo
                        text: i18n("Paper Size:")
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

                            if (!preventAutoGenerate) {
                                // Save the selection
                                printerConfig.paperSizeIndex = currentIndex;

                                // Apply the selected size
                                applySelectedSize();

                                // Trigger regeneration, but with a slight delay to ensure values are set
                                Qt.callLater(function() {
                                    regenerateTimer.restart();
                                });
                            }
                        }
                    }

                    FormCard.FormSpinBoxDelegate {
                        id: widthField
                        label: i18n("Width (mm):")
                        from: 30
                        to: 120
                        value: printerConfig.paperWidth
                        enabled: paperSizeCombo.currentIndex === (paperSizes.length - 1)

                        onValueChanged: {
                            if (enabled && value !== printerConfig.paperWidth && !preventAutoGenerate) {
                                printerConfig.paperWidth = value;
                            }
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        id: autoHeightSwitch
                        text: i18n("Auto Height")
                        checked: printerConfig.autoHeight
                        description: i18n("Adjust receipt height automatically based on content")

                        onCheckedChanged: {
                            if (!preventAutoGenerate) {
                                printerConfig.autoHeight = checked;
                            }
                        }
                    }

                    FormCard.FormSpinBoxDelegate {
                        id: heightField
                        label: i18n("Max Height (pt):")
                        from: 200
                        to: 2000
                        value: printerConfig.customHeight
                        stepSize: 50
                        enabled: !autoHeightSwitch.checked
                        visible: !autoHeightSwitch.checked

                        onValueChanged: {
                            if (enabled && value !== printerConfig.customHeight && !preventAutoGenerate) {
                                printerConfig.customHeight = value;
                            }
                        }
                    }
                }

                // Print Settings Section
                FormCard.FormHeader {
                    title: i18nc("@title:group", "Print Settings")
                    Layout.fillWidth: true
                }

                FormCard.FormCard {
                    Layout.fillWidth: true

                    FormCard.FormSwitchDelegate {
                        text: i18n("Print in Grayscale")
                        checked: printerConfig.grayscale
                        description: i18n("Print receipts in black and white")

                        onCheckedChanged: {
                            if (!preventAutoGenerate) {
                                printerConfig.grayscale = checked;
                            }
                        }
                    }

                    FormCard.FormSpinBoxDelegate {
                        label: i18n("Copies:")
                        from: 1
                        to: 10
                        value: printerConfig.copies

                        onValueChanged: {
                            if (value !== printerConfig.copies && !preventAutoGenerate) {
                                printerConfig.copies = value;
                            }
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        text: i18n("Direct Print")
                        checked: printerConfig.directPrint
                        description: i18n("Skip print dialog and print directly to selected printer")

                        onCheckedChanged: {
                            if (!preventAutoGenerate) {
                                printerConfig.directPrint = checked;
                            }
                        }
                    }

                    FormCard.FormComboBoxDelegate {
                        text: i18n("Default Printer:")
                        model: printerHelper.getPrinterNames()
                        displayText: printerConfig.printerName || i18n("Default Printer")

                        Component.onCompleted: {
                            // Find the index of saved printer
                            if (printerConfig.printerName) {
                                for (let i = 0; i < count; i++) {
                                    if (model[i] === printerConfig.printerName) {
                                        currentIndex = i;
                                        break;
                                    }
                                }
                            }
                        }

                        onCurrentValueChanged: {
                            if (currentValue !== printerConfig.printerName && !preventAutoGenerate) {
                                printerConfig.printerName = currentValue;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            text: i18n("Zoom Level:")
                        }

                        QQC2.Slider {
                            id: zoomSlider
                            Layout.fillWidth: true
                            from: 0.5
                            to: 2.0
                            stepSize: 0.1
                            value: printerConfig.zoom

                            onMoved: {
                                if (value !== printerConfig.zoom && !preventAutoGenerate) {
                                    printerConfig.zoom = value;
                                }
                            }
                        }

                        QQC2.Label {
                            text: printerConfig.zoom.toFixed(1) + "×"
                            Layout.minimumWidth: Kirigami.Units.gridUnit * 2
                        }
                    }
                }

                // Position Adjustment Section
                FormCard.FormHeader {
                    title: i18nc("@title:group", "Position Adjustment")
                    Layout.fillWidth: true
                    visible: false
                }

                FormCard.FormCard {
                    Layout.fillWidth: true
                    visible: false

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true

                            QQC2.Label {
                                text: i18n("Horizontal:")
                            }

                            QQC2.Slider {
                                id: xOffsetSlider
                                Layout.fillWidth: true
                                from: -50
                                to: 50
                                value: printerConfig.xOffset
                                stepSize: 1

                                onMoved: {
                                    if (value !== printerConfig.xOffset && !preventAutoGenerate) {
                                        printerConfig.xOffset = value;
                                    }
                                }
                            }

                            QQC2.Label {
                                text: printerConfig.xOffset
                                Layout.minimumWidth: Kirigami.Units.gridUnit * 2
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            QQC2.Label {
                                text: i18n("Vertical:")
                            }

                            QQC2.Slider {
                                id: yOffsetSlider
                                Layout.fillWidth: true
                                from: -50
                                to: 50
                                value: printerConfig.yOffset
                                stepSize: 1

                                onMoved: {
                                    if (value !== printerConfig.yOffset && !preventAutoGenerate) {
                                        printerConfig.yOffset = value;
                                    }
                                }
                            }

                            QQC2.Label {
                                text: printerConfig.yOffset
                                Layout.minimumWidth: Kirigami.Units.gridUnit * 2
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            // Right column - Preview
            Kirigami.Card {
                // Adjust width to take approximately half of the available width
                Layout.fillHeight: true
                Layout.fillWidth: false  // Don't fill the full width
                Layout.preferredWidth: parent.width * 0.45  // Take about 45% of parent width

                // Center it in the available space
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                // Ensure consistent margins
                Layout.margins: Kirigami.Units.largeSpacing

                // Compact header with minimal height
                header: ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    clip: true
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: Kirigami.Units.smallSpacing

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Kirigami.Heading {
                                text: i18n("Receipt Preview")
                                level: 2
                                Layout.fillWidth: true
                            }

                            QQC2.Label {
                                text: i18n("Preview updates automatically when settings change")
                                Layout.fillWidth: true
                                wrapMode: Qt.TextWordWrap
                                opacity: 0.7
                            }
                        }

                        QQC2.Button {
                            text: i18n("Refresh Preview")
                            icon.name: "view-refresh"
                            enabled: !requestPending
                            visible: false
                            onClicked: {
                                // Force a new generation even if auto-generation is disabled
                                let wasPreventAutoGenerate = preventAutoGenerate;
                                preventAutoGenerate = false;
                                generateTestReceipt();
                                preventAutoGenerate = wasPreventAutoGenerate;
                            }
                        }
                    }
                }

                // Content container that fills the card
                contentItem: Item {
                    implicitHeight: parent.height - headerItem.height
                    anchors.top: headerItem.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    // Center the content vertically if needed
                    Item {
                        id: previewContainer
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing

                        // Busy indicator centered in parent
                        DBusyIndicator {
                            id: pdfBusyIndicator
                            anchors.centerIn: parent
                            width: Kirigami.Units.gridUnit * 5
                            height: width
                            running: busyIndicatorRunning || (pdfView.count === 0 && pdfView.path !== "")
                            visible: running
                            z: 10 // Make sure it's above other content
                        }

                        // PDFView centered in the container
                        PDFView {
                            id: pdfView
                            anchors.fill: parent
                            clip:true
                            visible: path !== "" && !pdfBusyIndicator.running
                            path: ""
                            zoom: 1.0

                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                                minimumSize: 0.04
                            }
                        }

                        // Placeholder when no PDF is loaded - centered in parent
                        Kirigami.PlaceholderMessage {
                            anchors.centerIn: parent
                            width: parent.width - (Kirigami.Units.largeSpacing * 4)
                            visible: pdfView.path === "" && !pdfBusyIndicator.running
                            text: i18n("No preview available")
                            explanation: i18n("Please wait, preview is being generated...")
                            icon.name: "document-print-preview"
                        }
                    }
                }
            }
        }
    }

    // Connection to handle test receipt generation
    Connections {
        target: saleApi

        function onReceiptGenerated(pdfUrl) {
            busyIndicatorRunning = false;
            requestPending = false;

            try {
                // Update the PDF viewer with the new receipt
                let url = new URL(pdfUrl);
                pdfView.path = url.pathname.replace(/^\/([A-Z]:)/i, "$1"); // Fix Windows paths

                // Extract dimension metadata from URL if present
                let params = new URLSearchParams(url.search);

                if (params.has("paperWidth")) {
                    // Only update if we're in custom mode
                    if (paperSizeCombo.currentIndex === (paperSizes.length - 1)) {
                        let width = parseInt(params.get("paperWidth"));
                        if (width > 0) {
                            preventAutoGenerate = true;
                            printerConfig.paperWidth = width;
                            widthField.value = width;
                            preventAutoGenerate = false;
                        }
                    }
                }
            } catch (e) {
                console.error("Error processing PDF URL:", e);
                applicationWindow().showPassiveNotification(
                    i18n("Error displaying PDF preview"),
                    "short"
                );
            }
        }

        function onErrorReceiptGenerated(title, message) {
            console.log("Receipt generation error:", title, message);
            busyIndicatorRunning = false;
            requestPending = false;

            applicationWindow().showPassiveNotification(
                i18n("Failed to generate receipt preview: %1", message),
                "long"
            );
        }
    }

    // Handle page visibility changes to pause/resume auto-generation
    Connections {
        target: receiptSettingsPage
        function onVisibleChanged() {
            preventAutoGenerate = !visible;
        }
    }

    // Cleanup when page is destroyed
    Component.onDestruction: {
        // Ensure any pending timers are stopped
        if (regenerateTimer.running) {
            regenerateTimer.stop();
        }
        if (initialGenerateTimer.running) {
            initialGenerateTimer.stop();
        }
    }
}
