import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import Qt.labs.platform as Platform
import "../../components"
import com.dervox.printing 1.0
import com.dervox.dim

Kirigami.Dialog {
    id: barcodeDialog
    title: i18n("Barcode Generator")
    width: Kirigami.Units.gridUnit * 43
    height: Kirigami.Units.gridUnit * 34
    standardButtons: Kirigami.Dialog.NoButton

    property string contentEditText: ""
    property string priceText: ""
    property string productNameText: ""
    property int productId: -1
    property bool isLoading: false
    property string generatedPdfUrl: ""
    property bool productDetailsLoaded: false
    property bool generateOnOpen: false  // Property to auto-generate barcode on open
    property bool requestInProgress: false
    property bool shouldRegenerateOnChange: true // Property to control auto regeneration
    property bool ignoreChanges: false // Used to prevent regeneration during dialog setup
    property bool pdfLoadFinished: false // Track PDF load completion
    property int paddingValue: 10 // Padding to subtract from size dimensions

    // Predefined label sizes
    property var labelSizes: [
        { name: i18n("Small Barcode (50 × 20 mm)"), width: 50, height: 20 },
        { name: i18n("Product Label (60 × 40 mm)"), width: 60, height: 40 },
        { name: i18n("Logistics Label (70 × 30 mm)"), width: 70, height: 30 },
        { name: i18n("Shipping Label (100 × 50 mm)"), width: 100, height: 50 },
        { name: i18n("Large Shipping (100 × 150 mm)"), width: 100, height: 150 },
        { name: i18n("Retail Barcode (40 × 20 mm)"), width: 40, height: 20 },
        { name: i18n("Inventory Label (80 × 50 mm)"), width: 80, height: 50 },
        { name: i18n("Large Square (100 × 100 mm)"), width: 100, height: 100 },
        { name: i18n("Custom Size"), width: -1, height: -1 }
    ]

    // Timer for debouncing multiple changes
    Timer {
        id: regenerateTimer
        interval: 300 // Wait 300ms before regenerating
        repeat: false
        onTriggered: {
            if (shouldRegenerateOnChange && !requestInProgress && !ignoreChanges) {
                generateBarcodePdf();
            }
        }
    }

    // PrinterHelper component for PDF printing
    PrinterHelper {
        id: printerHelper
    }

    customFooterActions: [
        // Kirigami.Action {
        //     text: generatedPdfUrl === "" ? i18n("Generate Barcode") : i18n("Regenerate")
        //     icon.name: "document-export"
        //     enabled: !isLoading
        //     onTriggered: {
        //         generateBarcodePdf()
        //     }
        // },
        Kirigami.Action {
            text: i18n("Print")
            icon.name: "document-print"
            enabled: !isLoading && generatedPdfUrl !== ""
            onTriggered: {
                if (generatedPdfUrl) {
                    // Apply printer settings
                    if (applyPrinterSettings()) {
                        let success = false;

                        if (directPrintSwitch.checked) {
                            // Direct print with configured settings
                            success = printerHelper.printReceiptWithConfig(generatedPdfUrl, "BarcodePrinting");
                        } else {
                            // Show print dialog with settings applied
                            success = printerHelper.printPdf(generatedPdfUrl);
                        }

                        if (success) {
                            applicationWindow().showPassiveNotification(
                                i18n("Barcode printed successfully"),
                                "short"
                                );

                            // Optionally save settings if they were changed
                            savePrinterSettings();
                        } else {
                            applicationWindow().showPassiveNotification(
                                i18n("Failed to print barcode"),
                                "short"
                                );
                        }
                    }
                }
            }
        },
        // Kirigami.Action {
        //     text: i18n("Save as PDF")
        //     icon.name: "document-save-as"
        //     enabled: !isLoading && generatedPdfUrl !== ""
        //     onTriggered: {
        //         // Show a file dialog to get save location
        //         const fileDialog = saveFileDialogComponent.createObject(barcodeDialog);
        //         fileDialog.open();
        //     }
        // },
        Kirigami.Action {
            text: i18n("Close")
            icon.name: "dialog-cancel"
            onTriggered: {
                barcodeDialog.close()
            }
        }
    ]

    // Save PDF component
    Component {
        id: saveFileDialogComponent

        Platform.FileDialog {
            title: i18n("Save Barcode as PDF")
            folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
            fileMode: Platform.FileDialog.SaveFile
            nameFilters: [i18n("PDF Files (*.pdf)")]
            defaultSuffix: "pdf"

            onAccepted: {
                // Get the selected file path and convert it to local path
                var saveUrl = file.toString();

                // Convert URL to local path for the PrinterHelper
                var localPath = saveUrl;

                // Save the barcode as PDF
                if (printerHelper.saveReceiptAsPdf(generatedPdfUrl, localPath)) {
                    applicationWindow().showPassiveNotification(
                                i18n("Barcode saved as PDF"),
                                "short"
                                );
                } else {
                    applicationWindow().showPassiveNotification(
                                i18n("Failed to save barcode as PDF"),
                                "short"
                                );
                }
            }

            onRejected: {
                // User canceled the file dialog
            }
        }
    }

    contentItem: GridLayout {
        columns: 3
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing
        // Row 1, Col 1: PDF Viewer
        FormCard.FormCard {
            Layout.row: 0
            Layout.column: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rowSpan: 1
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
                            visible: generatedPdfUrl !== ""
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

                        // Empty state (before generation)
                        ColumnLayout {
                            visible: !isLoading && generatedPdfUrl === ""
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Item { Layout.fillHeight: true }

                            Kirigami.Icon {
                                source: "view-barcode"
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: Kirigami.Units.iconSizes.huge
                                implicitHeight: Kirigami.Units.iconSizes.huge
                            }

                            QQC2.Label {
                                text: i18n("Click 'Generate Barcode' to create a barcode")
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
                            visible: generatedPdfUrl !== "" && (!isLoading || pdfView.count > 0) // Show PDF view if it has loaded pages even if still technically loading

                            path: {
                                if (generatedPdfUrl) {
                                    var url = new URL(generatedPdfUrl);
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

        // Row 1, Col 2: Display Options
        FormCard.FormCard {
            Layout.row: 0
            Layout.column: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rowSpan: 2
            Layout.margins: Kirigami.Units.smallSpacing

            FormCard.FormHeader {
                title: i18n("Content")
            }

            FormCard.FormTextFieldDelegate {
                id: customContentField
                label: i18n("Barcode")
                text: barcodeDialog.contentEditText
                onTextChanged: {
                    if (!ignoreChanges) {
                        barcodeDialog.contentEditText = text;
                        regenerateTimer.restart();
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormComboBoxDelegate {
                id: barcodeTypeCombo
                text: i18n("Type")
                model: ["CODE128", "QR", "EAN13", "CODE39", "DATAMATRIX", "PDF417"]
                currentIndex: 0
                onCurrentIndexChanged: {
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }

            FormCard.FormHeader {
                title: i18n("Display Options")
            }

            FormCard.FormSwitchDelegate {
                id: showTeamNameCheck
                text: i18n("Show Team Name")
                checked: true
                onCheckedChanged: {
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormSwitchDelegate {
                id: showProductNameCheck
                text: i18n("Show Product Name")
                checked: true
                onCheckedChanged: {
                    customNameField.enabled = checked;
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormSwitchDelegate {
                id: showPriceCheck
                text: i18n("Show Price")
                checked: true
                onCheckedChanged: {
                    customPriceField.enabled = checked;
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }

            // Show content switch is false and hidden
            FormCard.FormSwitchDelegate {
                id: showContentCheck
                text: i18n("Show Barcode Text")
                checked: false
                visible: false
                onCheckedChanged: {
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }
        }

        // Row 1, Col 3: Print Settings
        FormCard.FormCard {
            Layout.row: 0
            Layout.column: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rowSpan: 2
            Layout.margins: Kirigami.Units.smallSpacing

            FormCard.FormHeader {
                title: i18n("Print Settings")
            }

            // Label Size ComboBox
            FormCard.FormComboBoxDelegate {
                id: labelSizeCombo
                text: i18n("Label Size")
                model: {
                    let sizeLabels = [];
                    for (let i = 0; i < labelSizes.length; i++) {
                        sizeLabels.push(labelSizes[i].name);
                    }
                    return sizeLabels;
                }

                currentIndex: 0

                onCurrentIndexChanged: {
                    console.log("Size changed to index:", currentIndex, "name:", labelSizes[currentIndex].name);

                    if (!ignoreChanges) {
                        // Apply the selected size
                        applySelectedSize();

                        // Trigger regeneration, but with a slight delay to ensure values are set
                        Qt.callLater(function() {
                            regenerateTimer.restart();
                        });
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            // Custom width (only visible when "Custom Size" is selected)
            FormCard.FormSpinBoxDelegate {
                id: widthSpinBox
                label: i18n("Width (mm)")
                value: 80
                from: 20
                to: 500
                visible: labelSizeCombo.currentIndex === (labelSizes.length - 1) // Last item is "Custom Size"

                onValueChanged: {
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }

            FormCard.FormDelegateSeparator {
                visible: labelSizeCombo.currentIndex === (labelSizes.length - 1)
            }

            // Custom height (only visible when "Custom Size" is selected)
            FormCard.FormSpinBoxDelegate {
                id: heightSpinBox
                label: i18n("Height (mm)")
                value: 30
                from: 10
                to: 500
                visible: labelSizeCombo.currentIndex === (labelSizes.length - 1) // Last item is "Custom Size"

                onValueChanged: {
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormSpinBoxDelegate {
                id: copyCountSpinBox
                label: i18n("Copies")
                value: 1
                from: 1
                to: 100
                onValueChanged: {
                    if (!ignoreChanges) {
                        regenerateTimer.restart();
                    }
                }
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormSwitchDelegate {
                id: directPrintSwitch
                text: i18n("Direct Print")
                checked: false
            }

            FormCard.FormDelegateSeparator {}

            FormCard.FormComboBoxDelegate {
                id: printerCombo
                text: i18n("Printer")
                model: printerHelper.getPrinterNames()
            }
        }

        // Row 2, Col 1: Content and Product Info Cards
        ColumnLayout {
            Layout.row: 1
            Layout.column: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            Layout.margins: Kirigami.Units.smallSpacing

            // Product Info Card
            FormCard.FormCard {
                Layout.fillWidth: true
  visible:!productId > 0
                FormCard.FormHeader {
                    title: i18n("Product Info")
                }

                FormCard.FormTextFieldDelegate {
                    id: customNameField
                    label: i18n("Name")
                    text: barcodeDialog.productNameText
                    enabled: showProductNameCheck.checked
                    onTextChanged: {
                        if (!ignoreChanges) {
                            barcodeDialog.productNameText = text;
                            regenerateTimer.restart();
                        }
                    }
                }

                FormCard.FormDelegateSeparator {}

                FormCard.FormTextFieldDelegate {
                    id: customPriceField
                    label: i18n("Price")
                    text: barcodeDialog.priceText
                    enabled: showPriceCheck.checked
                    onTextChanged: {
                        if (!ignoreChanges) {
                            barcodeDialog.priceText = text;
                            regenerateTimer.restart();
                        }
                    }
                }
            }
        }
    }

    // Function to apply the selected size from the combo box
    function applySelectedSize() {
        // Only apply if not in ignore changes mode
        if (ignoreChanges) return;

        // Get the selected label size
        let selectedSize = labelSizes[labelSizeCombo.currentIndex];

        // For Custom Size, don't change the current values
        if (selectedSize.width === -1) {
            return;
        }

        console.log("Applying size:", selectedSize.name, "width:", selectedSize.width, "height:", selectedSize.height);

        // Set the width and height values - temporarily disable ignore changes
        let prevIgnore = ignoreChanges;
        ignoreChanges = true;
        widthSpinBox.value = selectedSize.width;
        heightSpinBox.value = selectedSize.height;
        ignoreChanges = prevIgnore;
    }


    function generateBarcodePdf() {
        // Make sure we have some content
        if (customContentField.text.trim() === "") {
            applicationWindow().showPassiveNotification(
                i18n("Please enter barcode content"),
                "short"
            );
            return;
        }

        // Reset PDF load state
        pdfLoadFinished = false;

        // Set loading state
        isLoading = true;
        requestInProgress = true;
        generatedPdfUrl = "";

        // Get the current width and height
        let actualWidth = widthSpinBox.value;
        let actualHeight = heightSpinBox.value;

        // Apply padding reduction for standard sizes (not for custom)
        if (labelSizeCombo.currentIndex !== (labelSizes.length - 1)) {
            // Make sure we don't subtract too much - only apply a small padding
            actualWidth = Math.max(actualWidth - paddingValue, actualWidth * 0.9);
            actualHeight = Math.max(actualHeight , actualHeight * 0.9);
        }

        console.log("Generating barcode with width:", actualWidth, "height:", actualHeight);

        // Gather all options
        var options = {
            "showTeamName": showTeamNameCheck.checked,
            "showPrice": showPriceCheck.checked,
            "showProductName": showProductNameCheck.checked,
            "showContent": showContentCheck.checked,
            "paperWidth": actualWidth,
            "paperHeight": actualHeight,
            "copies": copyCountSpinBox.value
        };

        // Log the complete options to debug
        console.log("Sending options to API:", JSON.stringify(options));

        // Save printer settings
        savePrinterSettings();

        // Choose whether to generate a product barcode or custom barcode
        try {
            if (productId > 0) {
                productApi.generateProductBarcode(
                    productId,
                    barcodeTypeCombo.currentText,
                    options
                );
            } else {
                productApi.generateCustomBarcode(
                    customContentField.text,
                    barcodeTypeCombo.currentText,
                    customNameField.text,
                    customPriceField.text,
                    options
                );
            }
        } catch (e) {
            console.error("Error requesting barcode:", e);
            isLoading = false;
            requestInProgress = false;
            applicationWindow().showPassiveNotification(
                i18n("Error generating barcode: %1", e.toString()),
                "long"
            );
        }
    }
    // Rest of the functions remain the same...
    function savePrinterSettings() {
        let config = {
            "printerName": printerCombo.currentText,
            "directPrint": directPrintSwitch.checked,
            "paperWidth": widthSpinBox.value,
            "paperHeight": heightSpinBox.value,
            "copies": copyCountSpinBox.value,
            "grayscale": true, // Default to grayscale for barcodes
            "zoom": 1.0,       // Default zoom
            "xOffset": 0,      // Default horizontal offset
            "yOffset": 0,      // Default vertical offset
            "labelSizeIndex": labelSizeCombo.currentIndex // Save the selected label size index
        };

        printerHelper.savePrinterConfig("BarcodePrinting", config);
    }

    function loadPrinterSettings() {
        let config = printerHelper.loadPrinterConfig("BarcodePrinting");
        if (Object.keys(config).length > 0) {
            // Temporarily disable regeneration while setting initial values
            ignoreChanges = true;

            // Set printer name if it's in the list
            let printerIndex = printerCombo.model.indexOf(config.printerName);
            if (printerIndex >= 0) {
                printerCombo.currentIndex = printerIndex;
            }

            // Apply other settings
            directPrintSwitch.checked = config.directPrint || false;

            // If label size index is saved, apply it first
            if (config.labelSizeIndex !== undefined &&
                config.labelSizeIndex >= 0 &&
                config.labelSizeIndex < labelSizes.length) {
                labelSizeCombo.currentIndex = config.labelSizeIndex;

                // If custom, then load the custom dimensions
                if (config.labelSizeIndex === labelSizes.length - 1) {
                    if (config.paperWidth) widthSpinBox.value = config.paperWidth;
                    if (config.paperHeight) heightSpinBox.value = config.paperHeight;
                } else {
                    // For standard sizes, make sure the correct dimensions are loaded
                    applySelectedSize();
                }
            } else {
                // For backward compatibility, just load width and height directly
                if (config.paperWidth) widthSpinBox.value = config.paperWidth;
                if (config.paperHeight) heightSpinBox.value = config.paperHeight;

                // Try to match to an existing size
                findMatchingSize();
            }

            if (config.copies) copyCountSpinBox.value = config.copies;

            // Re-enable regeneration
            ignoreChanges = false;
        }
    }

    // Function to find a matching size in the labelSizes array
    function findMatchingSize() {
        // Don't change the current size if it's already Custom
        if (labelSizeCombo.currentIndex === labelSizes.length - 1) {
            return;
        }

        let matchFound = false;
        for (let i = 0; i < labelSizes.length - 1; i++) { // Skip last item (Custom)
            if (Math.abs(labelSizes[i].width - widthSpinBox.value) <= 1 &&
                Math.abs(labelSizes[i].height - heightSpinBox.value) <= 1) {
                // Only update if different to avoid regeneration loop
                if (labelSizeCombo.currentIndex !== i) {
                    labelSizeCombo.currentIndex = i;
                }
                matchFound = true;
                break;
            }
        }

        // If no match found and not already on Custom, switch to Custom
        if (!matchFound && labelSizeCombo.currentIndex !== labelSizes.length - 1) {
            labelSizeCombo.currentIndex = labelSizes.length - 1;
        }
    }

    // Load product details when needed
    function loadProductDetails() {
        if (productId > 0 && !productDetailsLoaded) {
            isLoading = true;

            // Call the API method that will emit a signal when done
            productApi.getProduct(productId);
        }
    }

    // Helper to check if a field from parent page exists
    function getParentFieldValue(fieldName) {
        if (applicationWindow().activePage &&
                applicationWindow().activePage[fieldName]) {
            return applicationWindow().activePage[fieldName].text;
        }
        return "";
    }

    // Connections to API signals
    Connections {
        target: productApi

        function onBarcodeGenerated(pdfUrl) {
            requestInProgress = false;

            // Only update if URL is different to avoid loops
            if (pdfUrl !== generatedPdfUrl) {
                console.log("Barcode PDF generated:", pdfUrl);
                generatedPdfUrl = pdfUrl;

                // Start a timeout in case the PDF never loads
                pdfLoadTimeout.restart();

                // Extract dimension metadata from URL if present
                try {
                    let url = new URL(pdfUrl);
                    let params = new URLSearchParams(url.search);

                    console.log("PDF URL parameters:", url.search);

                    // Only update dimensions if they're actually present and valid
                    if (params.has("paperWidth") && params.has("paperHeight")) {
                        let width = parseInt(params.get("paperWidth"));
                        let height = parseInt(params.get("paperHeight"));

                        // Only process if we got actual values (not 0)
                        if (width > 0 && height > 0) {
                            // Temporarily disable regeneration
                            ignoreChanges = true;

                            // For custom size, update dimensions directly
                            if (labelSizeCombo.currentIndex === (labelSizes.length - 1)) {
                                console.log("Updating custom size from PDF:", width, "×", height);
                                // For custom size, no need to add padding back
                                widthSpinBox.value = width;
                                heightSpinBox.value = height;
                            }

                            // Re-enable regeneration
                            ignoreChanges = false;
                        }
                    }
                } catch (e) {
                    console.error("Error parsing PDF URL:", e);
                }

                applicationWindow().showPassiveNotification(
                    i18n("Barcode generated successfully"),
                    "short"
                );
            }
        }
        function onErrorBarcodeGenerated(title, message) {
            isLoading = false;
            requestInProgress = false;
            console.error("Error generating barcode:", title, message);
            applicationWindow().showPassiveNotification(
                i18n("Error generating barcode: %1", message),
                "long"
            );
        }


        function onProductReceived(product) {
            isLoading = false;

            if (product) {
                // Temporarily disable regeneration while setting initial values
                ignoreChanges = true;

                // Update fields with product details if they're not already set
                if (productNameText === "" && product.name) {
                    customNameField.text = product.name;
                    barcodeDialog.productNameText = product.name;
                }

                if (priceText === "" && product.price) {
                    customPriceField.text = product.price;
                    barcodeDialog.priceText = product.price;
                }

                // If content is not set, use product barcode or ID
                if (contentEditText === "") {
                    let barcode = product.barcode || productId.toString();
                    customContentField.text = barcode;
                    barcodeDialog.contentEditText = barcode;
                }

                // Re-enable regeneration
                ignoreChanges = false;

                productDetailsLoaded = true;

                // Use the timer to allow UI to update first
                if (generateOnOpen) {
                    console.log("Product received, scheduling barcode generation");
                    initialGenerationTimer.start();
                }
            }
        }
        function onErrorProductReceived(message, status, details) {
            isLoading = false;
            applicationWindow().showPassiveNotification(
                i18n("Error loading product details: %1", message),
                "long"
            );
            generateOnOpen = false;
        }
    }

    // Timer to handle PDF loading timeout
    Timer {
        id: pdfLoadTimeout
        interval: 5000 // 5 seconds timeout
        repeat: false
        onTriggered: {
            if (isLoading && generatedPdfUrl) {
                console.log("PDF load timeout - forcing loading state to complete");
                isLoading = false;
            }
        }
    }
    Timer {
        id: initialGenerationTimer
        interval: 500 // Half a second delay
        repeat: false
        onTriggered: {
            if (generateOnOpen || (productId > 0 && productDetailsLoaded && !requestInProgress)) {
                console.log("Triggering initial barcode generation");
                generateBarcodePdf();
                generateOnOpen = false;
            }
        }
    }

    onOpened: {
        console.log("Dialog opened, productId:", productId, "generateOnOpen:", generateOnOpen);

        // Reset state
        generatedPdfUrl = "";
        isLoading = false;
        requestInProgress = false;
        pdfLoadFinished = false;

        // Temporarily disable regeneration during setup
        ignoreChanges = true;

        // Update local controls with incoming content
        if (contentEditText !== "") {
            customContentField.text = contentEditText;
        }

        // Try to get product name from parent if not set and we have a product ID
        if (productNameText === "") {
            let name = getParentFieldValue("nameField");
            if (name !== "") {
                customNameField.text = name;
                productNameText = name;
            }
        } else {
            customNameField.text = productNameText;
        }

        // Try to get price from parent if not set and we have a product ID
        if (priceText === "") {
            let price = getParentFieldValue("priceField");
            if (price !== "") {
                customPriceField.text = price;
                priceText = price;
            }
        } else {
            customPriceField.text = priceText;
        }

        // Load printer settings
        loadPrinterSettings();

        // Re-enable regeneration
        ignoreChanges = false;

        // If we have product ID but no content yet, try to load product details
        if (productId > 0 && (contentEditText === "" || productNameText === "" || priceText === "")) {
            productDetailsLoaded = false; // Reset this flag
            loadProductDetails();
            // Generation will happen via onProductReceived
        } else {
            // We already have all needed data, schedule generation after a short delay
            productDetailsLoaded = true;
            initialGenerationTimer.start();
        }
    }
    function applyPrinterSettings() {
        // Get the actual width and height, applying padding if needed
        let actualWidth = widthSpinBox.value;
        let actualHeight = heightSpinBox.value;

        // Apply padding reduction for standard sizes (not for custom)
        if (labelSizeCombo.currentIndex !== (labelSizes.length - 1)) {
            actualWidth = Math.max(actualWidth - paddingValue, 1);
            actualHeight = Math.max(actualHeight, 1);
        }

        // Get the values from the UI
        let config = {
            paperWidth: actualWidth,
            paperHeight: actualHeight,
            copies: copyCountSpinBox.value,
            printerName: printerCombo.currentText,
            directPrint: directPrintSwitch.checked,
            grayscale: true  // Always grayscale for barcodes
        };

        // Apply to printer helper
        printerHelper.setColorMode(!config.grayscale);
        printerHelper.setCopyCount(config.copies);

        if (config.printerName) {
            printerHelper.setPrinterName(config.printerName);
        }

        // CRITICAL: Set the paper size with explicit height parameter
        // Pass 'false' as the 2nd parameter (autoHeight) and the actual height as 3rd parameter
        printerHelper.setCustomPaperSize(config.paperWidth, false, config.paperHeight);

        // Set position offset
        printerHelper.setPositionOffset(0, 0);

        return true;
    }

    onClosed: {
        // Optional: clean up PDF file if needed
        if (generatedPdfUrl) {
            console.log("Dialog closed, PDF URL:", generatedPdfUrl);
        }
    }
}
