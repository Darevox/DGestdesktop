// NumPad.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    // Properties
    property alias display: displayField.text
    property var target: null  // Target component for input
    property string mode: "normal"  // "normal", "quantity", "price", "payment"
    property real amountTendered: 0
    property real changeAmount: 0

    // Signals
    signal numberEntered(string number)
    signal enterPressed()
    signal clearPressed()
    signal quickAmountSelected(real amount)

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Display field with labels
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: {
                    switch(root.mode) {
                        case "quantity": return i18n("Enter Quantity")
                        case "price": return i18n("Enter Price")
                        case "payment": return i18n("Enter Payment Amount")
                        default: return i18n("Enter Value")
                    }
                }
                font.bold: true
            }

            TextField {
                id: displayField
                Layout.fillWidth: true
                readOnly: true
                horizontalAlignment: Text.AlignRight
                font.pointSize: 16
                background: Rectangle {
                    color: Kirigami.Theme.backgroundColor
                    border.color: Kirigami.Theme.textColor
                    border.width: 1
                    radius: 4
                }
            }

            // Show change amount when in payment mode
            Label {
                visible: root.mode === "payment"
                text: i18n("Change: %1", root.changeAmount.toFixed(2))
                color: root.changeAmount >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                font.bold: true
            }
        }

        // Quick amount buttons for payment mode
        Flow {
            visible: root.mode === "payment"
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: [5, 10, 20, 50, 100]
                Button {
                    text: modelData.toString()
                    onClicked: {
                        displayField.text = modelData.toString()
                        root.amountTendered = modelData
                        root.quickAmountSelected(modelData)
                    }
                }
            }
        }

        // Number pad grid
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 3
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", ".", "⌫"]

                Button {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: modelData
                    font.pointSize: 14
                    contentItem: Label {
                              text: parent.text
                              font: parent.font
                              color: Kirigami.Theme.textColor  // Add this
                              horizontalAlignment: Text.AlignHCenter
                              verticalAlignment: Text.AlignVCenter
                          }
                    background: Rectangle {
                        color: parent.pressed ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.textColor
                        border.width: 1
                        radius: 4
                    }

                    onClicked: {
                        if (modelData === "⌫") {
                            displayField.text = displayField.text.slice(0, -1)
                        } else {
                            // Prevent multiple decimal points
                            if (modelData === "." && displayField.text.includes(".")) {
                                return
                            }
                            displayField.text += modelData
                        }

                        let value = parseFloat(displayField.text) || 0
                        root.amountTendered = value

                        if (root.mode === "payment") {
                            root.changeAmount = value - root.target
                        }

                        numberEntered(displayField.text)
                    }
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Button {
                Layout.fillWidth: true
                text: i18n("Clear")
                icon.name: "edit-clear"
                onClicked: {
                    displayField.text = ""
                    root.amountTendered = 0
                    root.changeAmount = 0
                    clearPressed()
                }
            }

            Button {
                Layout.fillWidth: true
                text: i18n("Enter")
                icon.name: "dialog-ok"
                highlighted: true
                enabled: {
                    if (root.mode === "payment") {
                        return root.amountTendered >= root.target
                    }
                    return displayField.text !== ""
                }
                onClicked: enterPressed()
            }
        }
    }

    // Function to reset the numpad
    function reset() {
        displayField.text = ""
        root.amountTendered = 0
        root.changeAmount = 0
    }
}
