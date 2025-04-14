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
    property var activeInput: null  // Currently active input field
    property string mode: "normal"  // "normal", "payment"
    property real amountTendered: 0
    property real changeAmount: 0
    property real targetAmount: 0  // Total amount in payment mode

    property string activeName: ""
    property real activeFrom: 0
    property real activeTo: 999999

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
                    if (mode === "payment") {
                        return i18n("Payment Amount")
                    } else if (activeInput) {
                        return activeName || i18n("Enter Value")
                    } else {
                        return i18n("Select an input field")
                    }
                }
                font.bold: true
            }
            Label {
                visible: mode === "normal" && activeInput
                text: i18n("Range: %1 - %2", activeFrom, activeTo)
                font.pointSize: 10
                color: Kirigami.Theme.disabledTextColor
            }
            TextField {
                id: displayField
                Layout.fillWidth: true
                readOnly: true
                horizontalAlignment: Text.AlignRight
                font.pointSize: 16

                // Remove the binding and add a function to update text
                function updateDisplayText() {
                    if (mode === "payment") {
                        text = amountTendered.toFixed(2)
                    } else if (activeInput) {
                        text = activeInput.value ? activeInput.value.toString() : ""
                    } else {
                        text = ""
                    }
                }

                // Call updateDisplayText when these properties change
                Connections {
                    target: root
                    function onModeChanged() { displayField.updateDisplayText() }
                    function onAmountTenderedChanged() { displayField.updateDisplayText() }
                    function onActiveInputChanged() { displayField.updateDisplayText() }
                }

                Component.onCompleted: updateDisplayText()

                background: Rectangle {
                    color: Kirigami.Theme.backgroundColor
                    border.color: Kirigami.Theme.textColor
                    border.width: 1
                    radius: 4
                }
            }


            // TextField {
            //     id: displayField
            //     Layout.fillWidth: true
            //     readOnly: true
            //     horizontalAlignment: Text.AlignRight
            //     font.pointSize: 16
            //     text: {
            //            if (mode === "payment") {
            //                return amountTendered.toFixed(2)
            //            } else if (activeInput) {
            //                return activeInput.value ? activeInput.value.toString() : ""
            //            }
            //            return ""
            //        }                background: Rectangle {
            //         color: Kirigami.Theme.backgroundColor
            //         border.color: Kirigami.Theme.textColor
            //         border.width: 1
            //         radius: 4
            //     }
            // }

            // Target amount display (for payment mode)
            // Label {
            //     visible: mode === "payment"
            //     text: i18n("Total: %1", targetAmount.toFixed(2))
            //     font.bold: true
            //     color: Kirigami.Theme.textColor
            // }

            // Change amount (for payment mode)
            Label {
                visible: mode === "payment"
                text: i18n("Change: %1", changeAmount.toFixed(2))
                color: changeAmount >= 0 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                font.bold: true
            }
        }

        // Quick amount buttons for payment mode
        // Quick amount buttons in horizontal ListView
        ListView {
            visible: mode === "payment"
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.smallSpacing
            model: [5, 10, 20, 50, 100]
            clip: true // Clips content for smooth scrolling

            // Enable flicking/swiping
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            delegate: Button {
                width: 80  // Fixed width for each button
                height: ListView.view.height
                text: modelData.toString()

                contentItem: Label {
                    text: parent.text
                    font.pointSize: 12
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.pressed ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    border.color: Kirigami.Theme.highlightColor
                    border.width: 0
                    radius: 4

                    // Gradient effect
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: parent.parent.pressed ? Qt.darker(Kirigami.Theme.highlightColor, 1.2) : Kirigami.Theme.backgroundColor }
                        GradientStop { position: 1.0; color: parent.parent.pressed ? Kirigami.Theme.highlightColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.1) }
                    }

                    // Hover effect
                    Rectangle {
                        anchors.fill: parent
                        color: Kirigami.Theme.highlightColor
                        opacity: parent.parent.hovered ? 0.2 : 0
                        radius: 4

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }
                }

                // Scale animation on click
                scale: pressed ? 0.95 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                onClicked: {
                    amountTendered = modelData
                    changeAmount = amountTendered - targetAmount
                    quickAmountSelected(modelData)
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
                model: ["7", "8", "9", "4", "5", "6", "1", "2", "3", "⌫", "0","Confirm"]
                delegate: Button {
                    id: numButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 20
                    Layout.minimumWidth: parent.width / 3.5 - columnSpacing * 2
                    Layout.preferredWidth: Layout.minimumWidth
                    // text: modelData
                    text: modelData === "⌫" ||  modelData === "Confirm"  ? "" : modelData
                    // Properties for ripple effect
                    property real centerX
                    property real centerY
                    property bool isRippling: false
                    icon.name:{
                        if(modelData === "⌫")
                            return "edit-clear"
                        else if(modelData === "Confirm")
                            return "dialog-ok"
                        else
                            return ""

                    }

                    // Timer for long press clear
                    Timer {
                        id: longPressTimer
                        interval: 500
                        onTriggered: {
                            if (modelData === "⌫") {
                                reset()
                                clearPressed()
                            }
                        }
                    }

                    // Press and hold handling
                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            numButton.centerX = mouseX
                            numButton.centerY = mouseY
                            rippleAnimation.start()
                            if (modelData === "⌫") {
                                longPressTimer.start()
                            }
                        }
                        onReleased: {
                            //  numButton.isRippling = false
                            longPressTimer.stop()
                        }

                        onClicked: {
                            if (!activeInput && mode === "normal") return

                            if (modelData === "⌫") {
                                if (mode === "payment") {
                                    let currentValue = Math.floor(amountTendered * 100) / 100  // Ensure 2 decimal places
                                    if (currentValue < 10) {
                                        amountTendered = 0
                                        displayField.text = "0.00"
                                    } else {
                                        let newValue = Math.floor(currentValue / 10)
                                        amountTendered = newValue
                                        displayField.text = newValue.toFixed(2)
                                    }
                                    changeAmount = amountTendered - targetAmount
                                } else {
                                    let newText = displayField.text.slice(0, -1)
                                    displayField.text = newText
                                    if (activeInput && activeInput.setValue) {
                                        let value = parseFloat(newText) || 0
                                        value = validateValue(value)
                                        activeInput.setValue(value)
                                    }
                                }
                            }
                            else if (modelData === "Confirm"){
                                root.enterPressed()

                            }
                            else if (modelData !== "") {  // Skip empty button
                                if (mode === "payment") {
                                    let currentValue = Math.floor(amountTendered * 100) / 100  // Ensure 2 decimal places
                                    let newValue
                                    if (currentValue === 0) {
                                        newValue = parseInt(modelData)
                                    } else {
                                        newValue = currentValue * 10 + parseInt(modelData)
                                    }
                                    amountTendered = newValue
                                    displayField.text = newValue.toFixed(2)
                                    changeAmount = amountTendered - targetAmount
                                } else {
                                    let newText = displayField.text + modelData
                                    let newValue = parseFloat(newText) || 0
                                    if (newValue <= activeTo) {
                                        displayField.text = newText
                                        if (activeInput && activeInput.setValue) {
                                            newValue = validateValue(newValue)
                                            activeInput.setValue(newValue)
                                        }
                                    }
                                }
                            }
                            numberEntered(displayField.text)
                        }

                    }

                    // contentItem: Label {
                    //     text: numButton.text
                    //     font.pointSize: 14
                    //     font.bold: true
                    //     color: Kirigami.Theme.textColor
                    //     horizontalAlignment: Text.AlignHCenter
                    //     verticalAlignment: Text.AlignVCenter
                    //     scale: numButton.pressed ? 0.95 : 1.0
                    //     Behavior on scale {
                    //         NumberAnimation { duration: 50 }
                    //     }
                    // }
                    contentItem: Item {
                        implicitWidth: parent.width
                        implicitHeight: parent.height

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Kirigami.Units.smallSpacing

                            // Icon for backspace button
                            Kirigami.Icon {
                                visible: modelData === "⌫" || modelData === "Confirm"
                                source: numButton.icon.name
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                color:                      {
                                    if(modelData === "⌫")
                                        return Kirigami.Theme.negativeTextColor
                                    else if(modelData === "Confirm")
                                        return  Kirigami.Theme.positiveTextColor
                                    else
                                        return Kirigami.Theme.textColor

                                }
                            }

                            // Label for numbers
                            Label {
                                visible: modelData !== "⌫" || modelData !== "Confirm"
                                text: numButton.text
                                font.pointSize: 14
                                font.bold: true
                                color: Kirigami.Theme.textColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                scale: numButton.pressed ? 0.95 : 1.0
                                Behavior on scale {
                                    NumberAnimation { duration: 50 }
                                }
                            }
                        }
                    }

                    background: Rectangle {
                        id: buttonBackground
                        color: numButton.pressed ? Kirigami.Theme.highlightColor : Qt.darker(Kirigami.Theme.backgroundColor,1.05)
                        border.color:{
                            if(modelData === "⌫")
                                return Kirigami.Theme.negativeTextColor
                            else if(modelData === "Confirm")
                                return Kirigami.Theme.positiveTextColor
                            else
                                 Qt.lighter(Kirigami.Theme.backgroundColor,1.1)
                        }
                        border.width: {
                            if(modelData === "⌫")
                                return 1
                            else if(modelData === "Confirm")
                                return 1
                            else
                                1
                        }
                        radius: 4

                        // Gradient effect
                        // gradient: Gradient {
                        //     GradientStop { position: 0.0; color: numButton.pressed ? Qt.darker(Kirigami.Theme.highlightColor, 1.2) : Kirigami.Theme.backgroundColor }
                        //     GradientStop { position: 1.0; color: numButton.pressed ? Kirigami.Theme.highlightColor : Qt.lighter(Kirigami.Theme.backgroundColor, 1.1) }
                        // }

                        // Ripple effect
                        Rectangle {
                            id: ripple
                            property real size: 0
                            property real opacity_: 0

                            x: numButton.centerX - size/2
                            y: numButton.centerY - size/2
                            width: size
                            height: size
                            radius: size/2
                            color: Kirigami.Theme.highlightColor
                            opacity: opacity_

                            ParallelAnimation {
                                id: rippleAnimation
                                running: false

                                NumberAnimation {
                                    target: ripple
                                    property: "size"
                                    from: 0
                                    to: numButton.width * 2
                                    duration: 300
                                }

                                NumberAnimation {
                                    target: ripple
                                    property: "opacity_"
                                    from: 0.5
                                    to: 0
                                    duration: 300
                                }
                            }
                        }
                        // Hover effect
                        Rectangle {
                            anchors.fill: parent
                            color: Kirigami.Theme.highlightColor
                            opacity: numButton.hovered ? 0.2 : 0
                            radius: 4

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }
                    }
                }


            }
        }


    }

    // Function to reset the numpad
    function reset() {
        displayField.text = ""
        amountTendered = 0
        changeAmount = 0
    }

    // Function to set active input
    function setActiveInput(input) {
        activeInput = input
        activeName = input?.name || ""
        activeFrom = input?.from ?? 0
        activeTo = input?.to ?? 999999

        if (input && input.hasOwnProperty('value')) {
            displayField.text = input.value.toString()
        } else {
            displayField.text = ""
        }
    }
    function validateValue(value) {
        if (mode === "normal" && activeInput) {
            return Math.min(Math.max(value, activeFrom), activeTo)
        }
        return value
    }
    // Function to update payment mode

    function setPaymentMode(total) {
        reset()  // Reset first
        mode = "payment"
        targetAmount = total
        amountTendered = total  // Set initial amount to total
        changeAmount = 0
        displayField.text = total.toFixed(2)  // Show the total in display field
    }


    // Function to update normal mode
    function setNormalMode() {
        mode = "normal"
        targetAmount = 0
        reset()
    }
}
