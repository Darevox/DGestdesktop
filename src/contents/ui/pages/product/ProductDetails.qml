import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.dervox.ProductUnitModel 1.0
import "../../components"
import "."
Kirigami.PromptDialog {
    id: productDialog
    title: "Product Details"
    preferredWidth: Kirigami.Units.gridUnit * 50
    standardButtons: Kirigami.Dialog.NoButton
    property int dialogProductId: 0
    property var productData: ({})
    property bool isCreateAnother: false
    QQC2.BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: productApi.isLoading
        visible: running
        z: 999 // Ensure it's above other content
    }
    Kirigami.InlineMessage {
        id:inlineMsg
        Layout.fillWidth: true
        text: "Hey! Let me tell you something positive!"
        showCloseButton: true
        type: Kirigami.MessageType.Positive
        visible: false
    }

    function updateProduct(){
        let unitVlaue = unitCombo.unitId
        console.log("unitCombo.unitVlaue  ",unitVlaue )
        let updatedProduct = {
            name: nameField.text,
            description: descriptionField.text,
            reference: referenceField.text,
            price: priceField.text,
            purchase_price: purchase_priceField.text,
            quantity: quantityField.value,
            productUnitId: unitVlaue, // unitCombo.unitId ,//unitCombo.currentIndex,
            expiredDate: expiredDateField.value instanceof Date && !isNaN(expiredDateField.value.getTime()) ? expiredDateField.value.toISOString() : null,
            sku: skuField.text,
            barcode: barcodeField.text,
            minStockLevel: minStockField.value,
            maxStockLevel: maxStockField.value,
            reorderPoint: reorderPointField.value,
            location: locationField.text
        }
        return updatedProduct;
    }
    customFooterActions: [
        Kirigami.Action {
            text: dialogProductId>0? "Save": "Add"
            icon.name:  dialogProductId>0? "document-save" : "list-add-symbolic"
            enabled: !productApi.isLoading
            onTriggered: {
                inlineMsg.visible=false
                isCreateAnother=false
                clearStatusMessages() // Clear previous error messages
                let updatedProduct = updateProduct()
                if (dialogProductId>0) {
                    console.log("Update Product : ",dialogProductId)
                    productModel.updateProduct(dialogProductId, updatedProduct)
                } else {
                    productModel.createProduct(updatedProduct)
                }

                // productDialog.close()
            }
        },
        Kirigami.Action {
            text: qsTr("Add & Add another")
            icon.name: "list-add-symbolic"
            visible: dialogProductId<=0
            enabled: !productApi.isLoading
            onTriggered: {
                inlineMsg.visible=false
                clearStatusMessages() // Clear previous error messages
                isCreateAnother=true
                let updatedProduct = updateProduct()
                productModel.createProduct(updatedProduct)
            }
        },
        Kirigami.Action {
            text: qsTr("Delete")
            icon.name: "edit-delete"
            visible: dialogProductId>0
            enabled: !productApi.isLoading
            onTriggered: {
                inlineMsg.visible=false
                clearStatusMessages() // Clear previous error messages
                console.log("Product IDDDD : ",dialogProductId)
                productModel.deleteProduct(dialogProductId)
            }
        },
        Kirigami.Action {
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                applicationWindow().gnotification.showNotification("",
                                                                   "Product Added successfully", // message
                                                                   Kirigami.MessageType.Positive, // message type
                                                                   "short",
                                                                   "dialog-close"
                                                                   )
               // productDialog.close()
            }



        }
    ]
    GridLayout{
        columns:2
        rows:1
        // anchors.fill:parent
        enabled: !productApi.isLoading
        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: nameField
                label: qsTr("Name")
                text:  ""
                status: statusMessage ? Kirigami.MessageType.Error : Kirigami.MessageType.Information
            }

            FormCard.FormTextAreaDelegate {
                id: descriptionField
                label: qsTr("Description")
                text:  ""
            }

            DFormTextFieldDelegate {
                id: priceField
                label: qsTr("Price")
                text: "0"

                // Property to store clean value as integer
                property int cleanValue: 0

                // Only allow digits
                validator: RegularExpressionValidator {
                    regularExpression: /^\d+$/
                }

                // Input validation - only allow numbers
                inputMethodHints: Qt.ImhDigitsOnly

                // onTextChanged: {
                //     // Store cursor position
                //     let cursorPosition1 = priceField.cursorPosition

                //     // Remove .00 and any non-digits
                //     let newValue = text.replace(/\.00$/, '').replace(/\D/g, '')

                //     if (newValue === "") {
                //         text = "0.00"
                //         cleanValue = 0
                //         priceField.cursorPosition = 1
                //         return
                //     }

                //     // Update cleanValue as integer
                //     cleanValue = parseInt(newValue)

                //     // Don't trigger another text change if it already ends with .00
                //     if (!text.endsWith('.00')) {
                //         text = newValue + ".00"
                //         // Set cursor position before .00
                //         priceField.cursorPosition = newValue.length
                //     } else {
                //         // Ensure cursor doesn't go past the dot
                //         if (cursorPosition1 > newValue.length) {
                //             priceField.cursorPosition = newValue.length
                //         }
                //     }
                // }

                // // Handle cursor position changes
                // onCursorPositionChanged: {
                //     let valueLength = cleanValue.toString().length
                //     // If cursor is after the dot, move it before the dot
                //     if (cursorPosition > valueLength) {
                //         priceField.cursorPosition = valueLength
                //     }
                // }

                // // Handle focus changes
                // onFocusChanged: {
                //     priceField.cursorPosition = cleanValue.toString().length
                // }

                // onActiveFocusChanged: {
                //     if (activeFocus) {
                //         priceField.cursorPosition = cleanValue.toString().length
                //     }
                // }

                // // Function to get value as integer
                // function getValue() {
                //     return cleanValue
                // }
            }
            DFormTextFieldDelegate {
                id: purchase_priceField
                label: qsTr("Purchase Price")
                text: "0"

                // Property to store clean value as integer
                property int cleanValue: 0

                // Only allow digits
                validator: RegularExpressionValidator {
                    regularExpression: /^\d+$/
                }

                // Input validation - only allow numbers
                inputMethodHints: Qt.ImhDigitsOnly

                // onTextChanged: {
                //     // Store cursor position
                //     let cursorPosition1 = purchase_priceField.cursorPosition

                //     // Remove .00 and any non-digits
                //     let newValue = text.replace(/\.00$/, '').replace(/\D/g, '')

                //     if (newValue === "") {
                //         text = "0.00"
                //         cleanValue = 0
                //         priceField.cursorPosition = 1
                //         return
                //     }

                //     // Update cleanValue as integer
                //     cleanValue = parseInt(newValue)

                //     // Don't trigger another text change if it already ends with .00
                //     if (!text.endsWith('.00')) {
                //         text = newValue + ".00"
                //         // Set cursor position before .00
                //         purchase_priceField.cursorPosition = newValue.length
                //     } else {
                //         // Ensure cursor doesn't go past the dot
                //         if (cursorPosition1 > newValue.length) {
                //             purchase_priceField.cursorPosition = newValue.length
                //         }
                //     }
                // }

                // // Handle cursor position changes
                // onCursorPositionChanged: {
                //     let valueLength = cleanValue.toString().length
                //     // If cursor is after the dot, move it before the dot
                //     if (cursorPosition > valueLength) {
                //         purchase_priceField.cursorPosition = valueLength
                //     }
                // }

                // // Handle focus changes
                // onFocusChanged: {
                //     purchase_priceField.cursorPosition = cleanValue.toString().length
                // }

                // onActiveFocusChanged: {
                //     if (activeFocus) {
                //         purchase_priceField.cursorPosition = cleanValue.toString().length
                //     }
                // }

                // // Function to get value as integer
                // function getValue() {
                //     return cleanValue
                // }
            }
            FormCard.FormSpinBoxDelegate {
                id: quantityField
                label: qsTr("Quantity")
                value: 0
                from: 0
                to: 999999
                stepSize: 1
            }

            FormCard.FormComboBoxDelegate {
                id: unitCombo
                text: i18nc("@label:listbox", "Product Unit")
                displayMode: FormCard.FormComboBoxDelegate.ComboBox
                editable: false
                currentIndex:-1
                property int unitId: 0
                textRole: "name"
                // Function to find and set index by unit ID
                function setCurrentIndexById(id) {
                    if(id === 0 || id === -1) {
                        unitCombo.currentIndex = -1
                    }
                    else
                        for(let i = 0; i < unitCombo.model.rowCount(); i++) {
                            let itemId = unitCombo.model.data(unitCombo.model.index(i, 0), Qt.UserRole + 1)
                            if(itemId === id) {
                                unitCombo.currentIndex = i
                                break
                            }
                        }
                }

                onCurrentIndexChanged: {
                    console.log("unitCombo currentIndex", unitCombo.currentIndex)
                    var selectedIndex = unitCombo.currentIndex
                    var selectedId = unitCombo.model.data(unitCombo.model.index(selectedIndex, 0),  Qt.UserRole + 1)
                    var selectedName = unitCombo.model.data(unitCombo.model.index(selectedIndex, 0),  Qt.UserRole + 2)
                    unitCombo.unitId = selectedId
                    console.log("unitCombo name", selectedName)
                    console.log("unitCombo id", selectedId)
                }
            }
            FormCard.FormDateTimeDelegate {
                id: expiredDateField
                dateTimeDisplay:FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                text: i18nc("@label:listbox", "Expiration Date")
                value: undefined
                onValueChanged:{
                    console.log(value)
                }
            }

        }
        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: referenceField
                label: qsTr("Refernce")
                text:  ""
            }
            FormCard.FormTextFieldDelegate {
                id: skuField
                label: qsTr("SKU")
                text:  ""
            }
            FormCard.FormTextFieldDelegate {
                id: barcodeField
                label: qsTr("Barcode")
                text: ""
            }
            FormCard.FormButtonDelegate{
                leading:barcodeField
                text:"Setup Barcode"
                description:"View & print"
                icon.name:"view-barcode"
                onClicked :{

                    // barcodeDialogLoader.priceText = priceField.text
                    // barcodeDialogLoader.contentEditText = barcodeField.text
                    barcodeDialogLoader.productId =  productDialog.dialogProductId
                    barcodeDialogLoader.active=true
                }
            }
            FormCard.FormSpinBoxDelegate {
                id: minStockField
                label: qsTr("Min Stock")
                value:  0
                from: 0
                to: 999999
            }
            FormCard.FormSpinBoxDelegate {
                id: maxStockField
                label: qsTr("Max Stock")
                value:  0
                from: 0
                to: 999999
            }
            FormCard.FormSpinBoxDelegate {
                id: reorderPointField
                label: qsTr("Reorder Point")
                value:  0
                from: 0
                to: 999999
            }
            FormCard.FormTextFieldDelegate {
                id: locationField
                label: qsTr("Location")
                text:  ""
            }


        }
    }
    function loadData(product){
        nameField.text = product.name  || "";
        descriptionField.text=product.description  || "";
        referenceField.text = product.reference  || "";
        priceField.text = product.price || 0;
        purchase_priceField.text = product.purchase_price || 0;
        quantityField.value = product.quantity || 0;
        console.log("product.unit.id ",product.unit.id)
        unitCombo.setCurrentIndexById(product.unit.id ||-1);
        expiredDateField.value = new Date(product.expiredDate) || undefined;
        skuField.text = product.sku || "";
        barcodeField.text = product.barcode  || "";
        minStockField.value = product.minStockLevel || 0;
        maxStockField.value = product.maxStockLevel || 0;
        reorderPointField.value = product.reorderPoint || 0;
        locationField.text = product.location || "";
    }
    Connections {
        target: productApi
        function onProductReceived(product) {
            loadData(product)
        }
        function onProductUnitsReceived(){
            unitCombo.model=productUnitModel
        }

        function onProductError(message, status, details) {
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{

                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }
        }
        function onProductUpdated(){
            applicationWindow().gnotification.showNotification("",
                                                               "Product "+ nameField.text +" Updated successfully", // message
                                                               Kirigami.MessageType.Positive, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )
            productDialog.close()
        }
        function onProductDeleted(){
            applicationWindow().gnotification.showNotification("",
                                                               "Product "+ nameField.text +" Deleted successfully", // message
                                                               Kirigami.MessageType.Positive, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )
            productDialog.close()
        }
        function onProductCreated(){
            if(!isCreateAnother){

                applicationWindow().gnotification.showNotification("",
                                                                   "Product Added successfully", // message
                                                                   Kirigami.MessageType.Positive, // message type
                                                                   "short",
                                                                   "dialog-close"
                                                                   )
                productDialog.close()

            }
            else {
                inlineMsg.text="Product "+ nameField.text +" Added successfully"
                inlineMsg.visible=true
                cleanField()
            }
            isCreateAnother=false
        }

    }
    // Add function to clear all status messages
    function clearStatusMessages() {
        nameField.statusMessage = ""
        referenceField.statusMessage = ""
        descriptionField.statusMessage = ""
        priceField.statusMessage = ""
        purchase_priceField.statusMessage = ""
        skuField.statusMessage = ""
        barcodeField.statusMessage = ""
        locationField.statusMessage = ""
    }

    // Add function to handle validation errors
    function handleValidationErrors(errorDetails) {
        clearStatusMessages()

        let errorObj = {}
        try {
            errorObj = JSON.parse(errorDetails)
        } catch (e) {
            console.error("Error parsing validation details:", e)
            return
        }

        // Map of field names to their corresponding form components
        const fieldMap = {
            'name': nameField,
            'reference': referenceField,
            'description': descriptionField,
            'price': priceField,
            'purchase_price': purchase_priceField,
            'sku': skuField,
            'barcode': barcodeField,
            'location': locationField
        }

        // Set error messages for each field that has validation errors
        Object.keys(errorObj).forEach(fieldName => {
                                          const field = fieldMap[fieldName]
                                          if (field) {
                                              field.statusMessage = errorObj[fieldName][0]
                                              field.status = Kirigami.MessageType.Error
                                          }
                                      })
    }
    function cleanField(){
        nameField.text =  "";
        descriptionField.text="";
        referenceField.text = "";
        priceField.text =0;
        purchase_priceField.text = 0;
        quantityField.value = 0;
        unitCombo.setCurrentIndexById(-1);
        expiredDateField.value =  undefined;
        skuField.text = "";
        barcodeField.text = "";
        minStockField.value = 0;
        maxStockField.value = 0;
        reorderPointField.value = 0;
        locationField.text = "";


    }


    Loader {
        id: barcodeDialogLoader
        active: false
        asynchronous: true
        sourceComponent: Barcode{}
        property string contentEditText: ""
        property string priceText: ""
        property int productId: -1
        onLoaded: {
            // item.priceText = barcodeDialogLoader.priceText
            // item.contentEditText =  barcodeDialogLoader.contentEditText
            console.log("iDDDDDDDDDDDD : " ,barcodeDialogLoader.productId )
            item.productId = barcodeDialogLoader.productId
            item.open()
        }

        Connections {
            target: barcodeDialogLoader.item
            function onClosed() {
                barcodeDialogLoader.active = false
            }
        }
    }


    Component.onCompleted:{
        //  cleanField()
        productUnitModel.fetchUnits(productApi)
        if(productDetailsDialog.productId>0)
            productApi.getProduct(productDetailsDialog.productId)

    }
}
