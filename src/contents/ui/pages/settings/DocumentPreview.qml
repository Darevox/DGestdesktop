// DocumentPreview.qml - Modified version
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Rectangle {
    id: previewContainer
    // Document configuration
    property var config: ({
        showClientInfo: true,
        showAmountInWords: true,
        showPaymentMethods: true,
        showTaxNumbers: true,
        showNotes: true,
        showThanksMessage: true,
        showTermsConditions: true,
        primaryColor: "#2563eb",
        logoEnabled: true,
        defaultNotes: "Thank you for your business.",
        thanksMessage: "Thank you for your business!",
        defaultTerms: "Payment is due within 30 days of invoice date.",
        footerText: "%teamName% • %teamEmail% • %teamPhone%"
    })

    property bool isQuote: false
    property string teamName: "Sample Company"
    property string teamEmail: "info@example.com"
    property string teamPhone: "+212 555-1234"

    color: "white"
    border.width: 1
    border.color: "#e2e8f0"
    clip: true

    // Document title (without rectangle background)
    QQC2.Label {
        id: documentTitle
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.largeSpacing
        text: isQuote ? "QUOTATION PREVIEW" : "INVOICE PREVIEW"
        color: config.primaryColor
        font.bold: true
        font.pixelSize: Kirigami.Theme.defaultFont.pointSize + 3
    }

    // Document number
    QQC2.Label {
        id: documentNumber
      //  anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: documentTitle.bottom
        anchors.right : parent.right
        anchors.rightMargin:  Kirigami.Units.gridUnit
        anchors.topMargin: Kirigami.Units.smallSpacing / 2
        text: isQuote ? "#QUOTE-2023-000123" : "#INV-2023-000123"
        color: config.primaryColor
        font.pixelSize: Kirigami.Theme.defaultFont.pointSize
    }

    Flickable {
        anchors.top: documentNumber.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: Kirigami.Units.gridUnit
        anchors.leftMargin: Kirigami.Units.gridUnit
        anchors.rightMargin: Kirigami.Units.gridUnit
        contentHeight: previewContent.height + Kirigami.Units.gridUnit * 2
        clip: true

        ColumnLayout {
            id: previewContent
            width: parent.width
            spacing: Kirigami.Units.smallSpacing
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing

            // Company and Client Info
            Item {
                Layout.fillWidth: true
                height: Math.max(companyInfo.height, clientInfoRect.height)

                // Company Info - Left aligned
                ColumnLayout {
                    id: companyInfo
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: parent.width * 0.5 - Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    RowLayout {
                        visible: config.logoEnabled
                        Rectangle {
                            width: Kirigami.Units.iconSizes.medium
                            height: Kirigami.Units.iconSizes.medium
                            color: config.primaryColor
                            radius: 3

                            QQC2.Label {
                                anchors.centerIn: parent
                                text: "LOGO"
                                color: "white"
                                font.pixelSize: Kirigami.Theme.smallFont.pointSize - 1
                            }
                        }
                        Item { width: Kirigami.Units.smallSpacing }
                        QQC2.Label {
                            text: teamName
                            font.pixelSize: Kirigami.Theme.defaultFont.pointSize
                            font.bold: true
                            color: Qt.darker(config.primaryColor, 1.1)
                        }
                    }

                    QQC2.Label {
                        text: "123 Sample Street, Sample City"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color: "#6b7280"
                    }

                    RowLayout {
                        QQC2.Label {
                            text: teamPhone
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }
                        QQC2.Label {
                            text: "|"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }
                        QQC2.Label {
                            text: teamEmail
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }
                    }
                }

                // Client Info Card - Right aligned with more space
                Rectangle {
                    id: clientInfoRect
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: parent.width * 0.35
                    visible: config.showClientInfo
                    height: clientInfoColumn.height + Kirigami.Units.largeSpacing
                    color: "#f8fafc"
                    border.color: "#e2e8f0"
                    border.width: 1
                    radius: 4

                    ColumnLayout {
                        id: clientInfoColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing / 2

                        QQC2.Label {
                            text: "Bill To:"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                            color: config.primaryColor
                        }
                        Item {
                            Layout.fillWidth: true
                            height: 2  // Space for the line

                            Rectangle {
                                width: parent.width - Kirigami.Units.largeSpacing * 2
                                height: 1
                                color: "#e2e8f0"
                                anchors.centerIn: parent
                            }
                        }
                        QQC2.Label {
                            text: "Sample Client"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            font.bold: true
                            color: "#6b7280"
                        }

                        QQC2.Label {
                            text: "client@example.com | +212 555-5678"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }

                        QQC2.Label {
                            visible: config.showTaxNumbers
                            text: "Tax Number: MA123456789"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }
                    }
                }
            }

            // Invoice Info
            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 1.5
                color: "#f8fafc"
                border.color: "#e2e8f0"
                border.width: 1
                radius: 4
                Layout.topMargin: Kirigami.Units.smallSpacing

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        text: "Issue Date: 01/06/2023"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    QQC2.Label {
                        text: "Due Date: 01/07/2023"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                          Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Items Table Header
            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 1.3
                color: config.primaryColor
                Layout.topMargin: Kirigami.Units.smallSpacing

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                        text: "Description"
                        color: "white"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        text: "Qty"
                        color: "white"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "Price"
                        color: "white"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                        text: "Tax"
                        color: "white"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "Discount"
                        color: "white"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "Total"
                        horizontalAlignment: Text.AlignRight
                        color: "white"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }
                }
            }

            // Sample Item 1
            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 0.8
                color: "transparent"
                border.color: "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                        text: "Sample Product"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        text: "2"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "500.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                        text: "100.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "50.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "950.00"
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }
                }
            }

            // Sample Item 2
            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 0.8
                color: "transparent"
                border.color: "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                        text: "Consulting Services"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        text: "5"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "200.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                        text: "0.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "0.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "1,000.00"
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }
                }
            }

            // Sample Item 3
            Rectangle {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 0.8
                color: "transparent"
                border.color: "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                        text: "Hardware"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                        text: "1"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "750.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                        text: "150.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                        text: "25.00"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "875.00"
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color:"black"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                height: 1  // Space for the line

                Rectangle {
                    width: parent.width - Kirigami.Units.largeSpacing * 2
                    height: 1
                    color: "#e2e8f0"
                    anchors.centerIn: parent
                }
            }

            // Totals Section - Right column
            // Totals section - right aligned with controlled width
            Item {
                Layout.fillWidth: true
                height: totalsLayout.implicitHeight

                ColumnLayout {
                    id: totalsLayout
                    width: parent.width * 0.3
                    anchors.right: parent.right
                    anchors.rightMargin:  Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    RowLayout {
                        Layout.fillWidth: true

                        QQC2.Label {
                            text: "Subtotal:"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.Label {
                            text: "2,825.00"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "black"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        QQC2.Label {
                            text: "Discount:"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.Label {
                            text: "75.00"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "black"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        QQC2.Label {
                            text: "Tax:"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                            color: "#6b7280"
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.Label {
                            text: "250.00"
                            color: "black"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 8  // Space for the line

                        Rectangle {
                            width: parent.width - Kirigami.Units.largeSpacing * 2
                            height: 1
                            color: "#e2e8f0"
                            anchors.centerIn: parent
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        QQC2.Label {
                            text: "Total:"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize + 4
                            color: config.primaryColor
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.Label {
                            text: "2,825.00 DH"
                            font.pixelSize: Kirigami.Theme.smallFont.pointSize + 4
                            color: config.primaryColor
                            font.bold: true
                        }
                    }
                }
            }

             // Amount in Words and Payment Methods now after totals
            // Payment Methods - Simple text display
            ColumnLayout {
                visible: config.showPaymentMethods
                spacing: 0
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.fillWidth: true

                QQC2.Label {
                    text: "Payment Methods:"
                    font.pixelSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                    color: "black"
                }

                RowLayout {
                    QQC2.Label {
                        text: "• Cash"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        color: "black"
                    }

                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing

                // Amount in Words - Simple text display
                ColumnLayout {
                    visible: config.showAmountInWords
                    spacing: 0
                    Layout.fillWidth: true

                    QQC2.Label {
                        text: "Amount in Words:"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                        color: "black"
                    }

                    QQC2.Label {
                        text: "Two thousand eight hundred twenty-five dirhams"
                        color: "black"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }


            }

            // Notes Section - Box style (full width)
            Rectangle {
                visible: config.showNotes && !isQuote
                Layout.fillWidth: true
                height: notesColumn.height + Kirigami.Units.largeSpacing
                color: "#f8fafc"
                border.color: "#e2e8f0"
                border.width: 1
                radius: 4
                Layout.topMargin: Kirigami.Units.smallSpacing

                ColumnLayout {
                    id: notesColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    QQC2.Label {
                        text: "Notes:"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                        color: "black"
                    }

                    QQC2.Label {
                        text: config.defaultNotes || "Thank you for your business."
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        color: "black"
                    }
                }
            }

            // Terms Section - Box style (full width)
            Rectangle {
                visible: config.showTermsConditions && isQuote
                Layout.fillWidth: true
                height: termsColumn.height + Kirigami.Units.largeSpacing
                color: "#f8fafc"
                border.color: "#e2e8f0"
                border.width: 1
                radius: 4
                Layout.topMargin: Kirigami.Units.smallSpacing

                ColumnLayout {
                    id: termsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    QQC2.Label {
                        text: "Terms & Conditions:"
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                        color: "black"
                    }

                    QQC2.Label {
                        text: config.defaultTerms || "Payment is due within 30 days of invoice date."
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        color: "black"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                height: 2  // Space for the line

                Rectangle {
                    width: parent.width - Kirigami.Units.largeSpacing
                    height: 1
                    color: "#e2e8f0"
                    anchors.centerIn: parent
                }
            }
            // Footer
            Rectangle {
                Layout.fillWidth: true
                height: footerColumn.height + Kirigami.Units.largeSpacing
                color: "transparent"
                border.color: "transparent"
                radius: 4

                ColumnLayout {
                    id: footerColumn
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing / 2

                    QQC2.Label {
                        visible: config.showThanksMessage
                        Layout.alignment: Qt.AlignHCenter
                        text: config.thanksMessage || "Thank you for your business!"
                        color: config.primaryColor
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }

                    // Footer text with variables replaced
                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            let ft = config.footerText;
                            ft = ft.replace("%teamName%", teamName);
                            ft = ft.replace("%teamEmail%", teamEmail);
                            ft = ft.replace("%teamPhone%", teamPhone);
                            return ft || teamName + " © " + new Date().getFullYear();
                        }
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize - 1
                        color: "#94a3b8"
                    }

                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Generated on: " + new Date().toLocaleDateString()
                        font.pixelSize: Kirigami.Theme.smallFont.pointSize - 1
                        color: "#94a3b8"
                    }
                }
            }
        }
    }

    // // Preview watermark
    // Rectangle {
    //     anchors.right: parent.right
    //     anchors.bottom: parent.bottom
    //     color: config.primaryColor
    //     opacity: 0.7
    //     width: previewLabel.width + Kirigami.Units.smallSpacing
    //     height: previewLabel.height + Kirigami.Units.smallSpacing / 2
    //     radius: 4

    //     QQC2.Label {
    //         id: previewLabel
    //         anchors.centerIn: parent
    //         text: "Preview Only"
    //         color: "white"
    //         font.pixelSize: Kirigami.Theme.smallFont.pointSize - 2
    //     }
    // }
}
