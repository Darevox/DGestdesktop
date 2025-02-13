import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import org.kde.prison as Prison
import com.dervox.Printer

Kirigami.Dialog {
    id: barcodeDialog
    title: "Barcode"
    height: Kirigami.Units.gridUnit * 25
    width: Kirigami.Units.gridUnit * 35
    standardButtons: Kirigami.Dialog.NoButton
    property string contentEditText: ""
    property string priceText: ""

    // Add Printer component
    Printer {
        id: printer
        antialias: true
        item: captureArea
        //resolution: 300
        onPrintComplete: {
            console.log("Barcode printed successfully")
        }

        onPrintError: {
            console.log("Error printing barcode")
        }

        Component.onCompleted: {
            printer.setPageSize(120, 80, printer.Millimeter)
            // Set margins to minimum
            printer.setMargins(0, 0, 0, 0)  // 5mm margins

        }
    }

    customFooterActions: [
        Kirigami.Action {
            text: qsTr("Print")
            icon.name: "document-print"
            onTriggered: {
                printer.setMargins(0, 0, 0, 0);
                if (!printer.setup()) {
                    console.log("Print setup cancelled")
                    return
                }
                let pageSize;
                switch (pageSizeCombobox.currentIndex) {
                    case 0: // "120mm x 80mm"
                    pageSize = { width: 120, height: 80 };
                    break;
                    case 1: // "80mm x 80mm"
                    pageSize = { width: 80, height: 80 };
                    break;
                    case 2: // "57mm x 30mm"
                    pageSize = { width: 57, height: 30 };
                    break;
                    default:
                    console.log("Invalid selection");
                    return;
                }

                console.log("getPageRect: " ,printer.getPageRect(Printer.Millimeter))
                printer.setMargins(0, 0, 0, 0);

                printer.setPageSize(pageSize.width, pageSize.height, Printer.Millimeter);

                if (!printer.open()) {
                    console.log("Failed to open printer")
                    return
                }
                printer.print(function(success) {
                    if (success) {
                        console.log("Print job submitted successfully")
                    }
                    printer.close()
                })
            }
        },
        Kirigami.Action {
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                barcodeDialog.close()
            }
        }
    ]


    RowLayout {
        id:layoutControls
        // Layout.fillHeight: true
        // Layout.fillWidth: true
        width:barcodeDialog.width
        spacing: Kirigami.Units.smallSpacing
        QQC2.TextField {
            id: contentEdit
            Layout.fillWidth: true
            Layout.preferredHeight: typeCombobox.height
            text: barcodeDialog.contentEditText
        }
        QQC2.ComboBox {
            id: typeCombobox
            // Layout.preferredWidth: Kirigami.Units.gridUnit * 15
            model: ["QRCode", "DataMatrix", "Aztec", "Code39", "Code93", "Code128", "PDF417", "EAN13"]
            currentIndex: 5
        }
        QQC2.ComboBox {
            id: pageSizeCombobox
            //  Layout.preferredWidth: Kirigami.Units.gridUnit * 15
            model: ["120mm x 80mm", "80mm x 80mm", "57mm x 30mm"]
            currentIndex: 0
            onCurrentIndexChanged: {
                let pageSize;
                switch (pageSizeCombobox.currentIndex) {
                case 0: // "120mm x 80mm"
                    pageSize = { width: 120, height: 80 };
                    break;
                case 1: // "80mm x 80mm"
                    pageSize = { width: 80, height: 80 };
                    break;
                case 2: // "57mm x 30mm"
                    pageSize = { width: 57, height: 30 };
                    break;
                default:
                    console.log("Invalid selection");
                    return;
                }
                printer.setMargins(0, 0, 0, 0);
                printer.setPageSize(pageSize.width, pageSize.height, Printer.Millimeter);

                // Reset margins after changing page size
            }
        }
    }
    Rectangle{
        id:pageContainer
        anchors.top:layoutControls.bottom
        width:barcodeDialog.width
        //  height:barcodeDialog.height
        height: (120 * 3.78) + priceLabel.height
        // You might want to add some padding
        // anchors.bottom:barcodeDialog.dialogData.
        // anchors.left:barcodeDialog.left
        // anchors.right:barcodeDialog.right
        // anchors.bottom:barcodeDialog.bottom
        // Layout.fillHeight: true
        // Layout.fillWidth: true
        // height:barcodeDialog.height / 2
        color: "white"
        Rectangle {
            // anchors.top:layoutControls.bottom
            id: captureArea

            width: printer.paperRect.width // When one sets a size using the 'setPageSize' method, this changes.
            height: printer.paperRect.height // When one sets a size using the 'setPageSize' method, this changes.


            anchors {
                top: pageContainer.top
                 topMargin: Kirigami.Units.largeSpacing * 2  // Adjust this value for desired top margin
                 horizontalCenter: parent.horizontalCenter
            }
            //  border.color:"black"
            color: "white"

            Prison.Barcode {
                id: barcode
                anchors.top: captureArea.top
                anchors.topMargin: 2
                width: printer.pageRect.width
                height:parent.height - priceLabel.height * 2
                content: contentEdit.text
                barcodeType: typeCombobox.currentIndex
            }
            QQC2.Label {
                id:priceLabel
                width:printer.pageRect.width
                text: "Prix : " + barcodeDialog.priceText + " DH"
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
                font.bold: true
                color: "black"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.top: barcode.bottom
                visible: false
            }
        }


    }
}
