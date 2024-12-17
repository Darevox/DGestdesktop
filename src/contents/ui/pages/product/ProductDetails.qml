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


    function updateProduct() {
        let packages = [];
        for (let i = 0; i < packagesModel.count; i++) {

            let pkg = packagesModel.get(i);
            packages.push({
                              name: pkg.name,
                              pieces_per_package: pkg.pieces_per_package,
                              purchase_price: pkg.purchase_price,
                              selling_price: pkg.selling_price,
                              barcode: pkg.barcode
                          });
        }
        let updatedProduct = {
            name: nameField.text,
            description: descriptionField.text,
            reference: referenceField.text,
            price: priceField.text,
            purchase_price: purchase_priceField.text,
            quantity: quantityField.value,
            productUnitId: unitCombo.unitId,
            expiredDate: expiredDateField.value instanceof Date && !isNaN(expiredDateField.value.getTime())
                         ? expiredDateField.value.toISOString()
                         : null,
            sku: skuField.text,
            minStockLevel: minStockField.value,
            maxStockLevel: maxStockField.value,
            reorderPoint: reorderPointField.value,
            location: locationField.text,
            packages: packages
        };
            console.log("Final product data:", JSON.stringify(updatedProduct));
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
                productDialog.close()
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
            FormCard.FormSpinBoxDelegate {
                id: quantityField
                label: qsTr("Quantity")
                value: 0
                from: 0
                to: 999999
                stepSize: 1
            }
            DFormTextFieldDelegate {
                id: purchase_priceField
                label: qsTr("Purchase Price")
                text: "0"

                // Property to store clean value as integer
                // Only allow digits
                validator: RegularExpressionValidator {
                    regularExpression: /^\d+$/
                }

                // Input validation - only allow numbers
                inputMethodHints: Qt.ImhDigitsOnly
            }
            FormCard.FormTextDelegate {
                leading: purchase_priceField
                text: {
                    var price = Number(priceField.text) || 0           // Selling Price
                    var purchasePrice = Number(purchase_priceField.text) || 0  // Purchase Price
                    var profit = price - purchasePrice
                    return "Selling Price: " + price.toFixed(2)
                }
                description: {
                    var price = Number(priceField.text) || 0           // Selling Price
                    var purchasePrice = Number(purchase_priceField.text) || 0  // Purchase Price
                    var profit = price - purchasePrice
                    return "Profit: " + profit.toFixed(2)
                }
            }
            DFormTextFieldDelegate {
                id: priceField
                label: qsTr("Price")
                text: "0"
                // Only allow digits
                validator: RegularExpressionValidator {
                    regularExpression: /^\d+$/
                }
                inputMethodHints: Qt.ImhDigitsOnly
            }

            FormCard.FormTextDelegate {
                leading: priceField
                text: {
                    return "Profit Margin: "
                }
                description: {
                    var price = Number(priceField.text) || 0
                    var purchasePrice = Number(purchase_priceField.text) || 0

                    // Avoid division by zero
                    if (price === 0) return "0 %"

                    var profitMargin = ((price - purchasePrice) / price) * 100
                    return  profitMargin.toFixed(2) + " %"
                }
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
            FormCard.FormButtonDelegate{
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

        FormCard.FormCard {
            Layout.fillWidth: true

            Kirigami.Heading {
                text: i18n("Product Packages")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Button {
                    text: i18n("Add Package")
                    icon.name: "list-add"
                    onClicked: packageDialog.open()
                }

                ListView {
                    id: packagesList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight + 60, 200)
                    model: ListModel { id: packagesModel }
                    clip: true

                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                text: model.name
                                Layout.preferredWidth: 150
                            }
                            QQC2.Label {
                                text: i18n("%1 pieces", model.pieces_per_package)
                                Layout.preferredWidth: 100
                            }
                            QQC2.Label {
                                text: i18n("Purchase: %1", model.purchase_price)
                                Layout.preferredWidth: 100
                            }
                            QQC2.Label {
                                text: i18n("Selling: %1", model.selling_price)
                                Layout.preferredWidth: 100
                            }
                            Item { Layout.fillWidth: true }
                            QQC2.ToolButton {
                                icon.name: "edit-entry"
                                onClicked: editPackage(index)
                            }
                            QQC2.ToolButton {
                                icon.name: "list-remove"
                                onClicked: deletePackage(index)
                            }
                        }
                    }
                }
            }
        }
    }


    Kirigami.Dialog {
        id: packageDialog
        title: editingPackageIndex >= 0 ? i18n("Edit Package") : i18n("Add Package")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        property int editingPackageIndex: -1

        FormCard.FormCard {
            FormCard.FormTextFieldDelegate {
                id: packageNameField
                label: i18n("Package Name")
                placeholderText: i18n("e.g., Box, Pack")
            }

            FormCard.FormSpinBoxDelegate {
                id: packageQuantityField
                label: i18n("Pieces per Package")
                from: 1
                to: 999999
                value: 1
            }

            FormCard.FormSpinBoxDelegate {
                id: packagePurchasePriceField
                label: i18n("Purchase Price")
                from: 0
                to: 999999
                value: 0
            }

            FormCard.FormSpinBoxDelegate {
                id: packageSellingPriceField
                label: i18n("Selling Price")
                from: 0
                to: 999999
                value: 0
            }

            FormCard.FormTextFieldDelegate {
                id: packageBarcodeField
                label: i18n("Barcode (Optional)")
            }
        }

        onAccepted: {
            if (editingPackageIndex >= 0) {
                packagesModel.set(editingPackageIndex, {
                                      name: packageNameField.text,
                                      pieces_per_package: packageQuantityField.value,
                                      purchase_price: packagePurchasePriceField.value,
                                      selling_price: packageSellingPriceField.value,
                                      barcode: packageBarcodeField.text
                                  });
            } else {
                packagesModel.append({
                                         name: packageNameField.text,
                                         pieces_per_package: packageQuantityField.value,
                                         purchase_price: packagePurchasePriceField.value,
                                         selling_price: packageSellingPriceField.value,
                                         barcode: packageBarcodeField.text
                                     });
            }
            clearPackageDialog();
        }

        onRejected: {
            clearPackageDialog();
        }
    }

    function clearPackageDialog() {
        packageDialog.editingPackageIndex = -1;
        packageNameField.text = "";
        packageQuantityField.value = 1;
        packagePurchasePriceField.value = 0;
        packageSellingPriceField.value = 0;
        packageBarcodeField.text = "";
    }

    function editPackage(index) {
        let pkg = packagesModel.get(index);
        packageDialog.editingPackageIndex = index;
        packageNameField.text = pkg.name;
        packageQuantityField.value = pkg.pieces_per_package;
        packagePurchasePriceField.value = pkg.purchase_price;
        packageSellingPriceField.value = pkg.selling_price;
        packageBarcodeField.text = pkg.barcode || "";
        packageDialog.open();
    }

    function deletePackage(index) {
        packagesModel.remove(index);
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
        minStockField.value = product.minStockLevel || 0;
        maxStockField.value = product.maxStockLevel || 0;
        reorderPointField.value = product.reorderPoint || 0;
        locationField.text = product.location || "";
        packagesModel.clear();
        if (product.packages) {
            product.packages.forEach(pkg => {
                                         packagesModel.append({
                                                                  name: pkg.name,
                                                                  pieces_per_package: pkg.pieces_per_package,
                                                                  purchase_price: pkg.purchase_price,
                                                                  selling_price: pkg.selling_price,
                                                                  barcode: pkg.barcode || ""
                                                              });
                                     });
        }
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
