import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import com.dervox.ProductUnitModel 1.0
//import com.dervox.FavoriteManager

import "../../components"
import "."
Kirigami.Dialog {
    id: productDialog
    title: "Product Details"
    padding: Kirigami.Units.largeSpacing
    width: Kirigami.Units.gridUnit * 30
    height : Kirigami.Units.gridUnit * 35

    standardButtons: Kirigami.Dialog.NoButton
    property int dialogProductId: 0
    property var productData: ({})
    property bool isCreateAnother: false
    property bool isBarcodeRequest: false

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
                productDialog.isCreateAnother=false
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

    contentItem :
        ColumnLayout{

        // anchors.fill : parent
        anchors.margins : 20
        enabled: !productApi.isLoading
        QQC2.TabBar {
            id: tabBar
            Layout.fillWidth: true

            QQC2.TabButton {
                text: i18n("Basic Info")
                Layout.fillWidth: true
            }
            QQC2.TabButton {
                text: i18n("Pricing & Stock")
                Layout.fillWidth: true
            }
            QQC2.TabButton {
                text: i18n("Other Info")
                Layout.fillWidth: true
            }
            QQC2.TabButton {
                text: i18n("Categories / Packages")
                Layout.fillWidth: true
            }
        }
        StackLayout {
            currentIndex: tabBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            FormCard.FormCard {
                Layout.fillHeight:true
                Layout.alignment: Qt.AlignTop
                ImageBannerCard {
                    id: productImageCard
                    idProduct : productDialog.dialogProductId

                    Layout.alignment: Qt.AlignTop

                }

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
                FormCard.FormTextFieldDelegate {
                    id: locationField
                    label: qsTr("Location")
                    text:  ""
                }

            }
            FormCard.FormCard {
                Layout.fillHeight:true
                Layout.alignment: Qt.AlignTop
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
            }
            FormCard.FormCard {
                Layout.fillHeight:true

                Layout.alignment: Qt.AlignTop
                FormCard.FormSpinBoxDelegate {
                    id: reorderPointField
                    label: qsTr("Reorder Point")
                    value:  0
                    from: 0
                    to: 999999
                }

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
                        if(productDialog.dialogProductId>0){
                            barcodeDialogLoader.productId =  productDialog.dialogProductId
                            barcodeDialogLoader.active=true
                        }
                        else {
                            productDialog.isBarcodeRequest=true
                            createBeforSetupDialog.open()

                        }
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
                // Categories Section
                id :categoriesSection
                Layout.margins:Kirigami.Units.smallSpacing
                FormCard.FormHeader {
                    title: i18n("Categories")
                    actions: [
                        Kirigami.Action {
                            icon.name: "settings-configure"
                            text: i18n("Manage Categories")
                            onTriggered: categorySettingsDialog.open()
                        }
                    ]
                }

                // Current Categories as Chips
                // Add to Category section
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Layout.margins:Kirigami.Units.smallSpacing
                    QQC2.ComboBox {
                        id: categoryCombo
                        Layout.fillWidth: true
                        textRole: "name"
                        valueRole: "id"
                        model: categoriesSection.getAvailableCategories()
                    }

                    QQC2.Button {
                        icon.name: "list-add"
                        text: i18n("Add to Category")
                        enabled: categoryCombo.currentValue !== undefined && productDialog.dialogProductId > 0
                        onClicked: {
                            if (categoryCombo.currentValue !== undefined) {
                                favoriteManager.addProductToCategory(categoryCombo.currentValue, productDialog.dialogProductId)
                                // Force update both models
                                categoryChipsRepeater.model = categoriesSection.getProductCategories()
                                categoryCombo.model = categoriesSection.getAvailableCategories()
                            }
                        }
                    }
                }
                FormCard.FormCard {
                    Layout.fillHeight: true
                    Layout.margins:Kirigami.Units.smallSpacing
                    Flow {
                        Layout.alignment:Qt.AlignTop
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        Layout.margins:Kirigami.Units.smallSpacing
                        Repeater {
                            id: categoryChipsRepeater
                            model: categoriesSection.getProductCategories()

                            delegate: Kirigami.Chip {
                                text: modelData.name
                                closable: true
                                onRemoved: {
                                    favoriteManager.removeProductFromCategory(modelData.id, productDialog.dialogProductId)
                                    // Force update both models
                                    categoryChipsRepeater.model = categoriesSection.getProductCategories()
                                    categoryCombo.model = categoriesSection.getAvailableCategories()
                                }
                            }
                        }
                    }

                }

                FormCard.FormButtonDelegate {
                    Layout.margins:Kirigami.Units.smallSpacing
                    text: i18n("Manage Packages")
                    description: packagesModel.count > 0 ?
                                     i18np("%1 package defined", "%1 packages defined", packagesModel.count) :
                                     i18n("No packages defined")
                    icon.name: "package"
                    onClicked: packagesListDialog.open()
                }

                // Helper functions to get categories
                function getProductCategories() {
                    if (productDialog.dialogProductId <= 0) return []
                    return favoriteManager.getCategories().filter(category => {
                                                                      let productIds = favoriteManager.getCategoryProductIds(category.id)
                                                                      return productIds.includes(productDialog.dialogProductId)
                                                                  })
                }

                function getAvailableCategories() {
                    if (productDialog.dialogProductId <= 0) return []
                    return favoriteManager.getCategories().filter(category => {
                                                                      let productIds = favoriteManager.getCategoryProductIds(category.id)
                                                                      return !productIds.includes(productDialog.dialogProductId)
                                                                  })
                }

                // Add connections to handle category changes
                Connections {
                    target: favoriteManager
                    function onCategoriesChanged() {
                        categoryChipsRepeater.model = categoriesSection.getProductCategories()
                        categoryCombo.model = categoriesSection.getAvailableCategories()
                    }
                    function onProductsChanged(categoryId) {
                        categoryChipsRepeater.model = categoriesSection.getProductCategories()
                        categoryCombo.model = categoriesSection.getAvailableCategories()
                    }
                }
            }


            // Add this dialog to use CategoriesSettings

        }

    }
    //    Kirigami.Dialog {
    //        id: newCategoryDialog
    //        title: i18n("New Category")
    //        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel

    //        FormCard.FormCard {
    //            FormCard.FormTextFieldDelegate {
    //                id: newCategoryField
    //                label: i18n("Category Name")
    //                placeholderText: i18n("Enter category name")
    //            }
    //        }

    //        onAccepted: {
    //            if (newCategoryField.text.length > 0) {
    //                favoriteManager.createCategory(newCategoryField.text)
    //                newCategoryField.text = ""
    //            }
    //        }
    //    }
    //    Kirigami.Dialog {
    //        id: categoryManagementDialog
    //        title: i18n("Manage Categories")
    //        preferredWidth: Kirigami.Units.gridUnit * 40

    //        ColumnLayout {
    //            spacing: Kirigami.Units.largeSpacing

    //            RowLayout {
    //                Layout.fillWidth: true
    //                QQC2.TextField {
    //                    id: newCategoryField1
    //                    Layout.fillWidth: true
    //                    placeholderText: i18n("New category name")
    //                }
    //                QQC2.Button {
    //                    text: i18n("Add")
    //                    icon.name: "list-add"
    //                    onClicked: {
    //                        if (newCategoryField1.text.length > 0) {
    //                            favoriteManager.createCategory(newCategoryField1.text)
    //                            newCategoryField1.text = ""
    //                        }
    //                    }
    //                }
    //            }

    //            ListView {
    //                Layout.fillWidth: true
    //                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
    //                model: favoriteManager.getCategories()
    //                delegate: Kirigami.SwipeListItem {
    //                    contentItem: RowLayout {
    //                        QQC2.Label {
    //                            text: modelData.name
    //                            Layout.fillWidth: true
    //                        }
    //                        QQC2.CheckBox {
    //                            checked: {
    //                                let productIds = favoriteManager.getCategoryProductIds(modelData.id)
    //                                return productIds.includes(productDialog.dialogProductId)
    //                            }
    //                            onToggled: {
    //                                if (checked) {
    //                                    favoriteManager.addProductToCategory(modelData.id, productDialog.dialogProductId)
    //                                } else {
    //                                    favoriteManager.removeProductFromCategory(modelData.id, productDialog.dialogProductId)
    //                                }
    //                            }
    //                        }
    //                    }
    //                    actions: [
    //                        Kirigami.Action {
    //                            icon.name: "edit-entry"
    //                            onTriggered: {
    //                                editCategoryDialog.categoryId = modelData.id
    //                                editCategoryDialog.categoryName = modelData.name
    //                                editCategoryDialog.open()
    //                            }
    //                        },
    //                        Kirigami.Action {
    //                            icon.name: "edit-delete"
    //                            onTriggered: favoriteManager.deleteCategory(modelData.id)
    //                        }
    //                    ]
    //                }
    //            }
    //        }
    //    }



    Kirigami.Dialog {
        id: categorySettingsDialog
        title: i18n("Categories Settings")
        preferredWidth: Kirigami.Units.gridUnit * 30
        preferredHeight: Kirigami.Units.gridUnit * 30

        CategoriesSettings {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins:Kirigami.Units.smallSpacing
            Layout.preferredHeight :  Kirigami.Units.gridUnit * 28
            onCategoriesChanged: {
                // Update the category chips and combo box
                categoryChipsRepeater.model = Qt.binding(() => {
                                                             if (productDialog.dialogProductId <= 0) return [];
                                                             return favoriteManager.getCategories().filter(category => {
                                                                                                               let productIds = favoriteManager.getCategoryProductIds(category.id)
                                                                                                               return productIds.includes(productDialog.dialogProductId)
                                                                                                           });
                                                         });

                categoryCombo.model = Qt.binding(() => {
                                                     if (productDialog.dialogProductId <= 0) return [];
                                                     return favoriteManager.getCategories().filter(category => {
                                                                                                       let productIds = favoriteManager.getCategoryProductIds(category.id)
                                                                                                       return !productIds.includes(productDialog.dialogProductId)
                                                                                                   });
                                                 });
            }
        }
    }


    Kirigami.Dialog {
        id: packagesListDialog
        title: i18n("Product Packages")
        preferredWidth: Kirigami.Units.gridUnit * 50

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.InlineMessage {
                id:inlineMsgPackagesListDialog
                Layout.fillWidth: true
                text: "Hey! Let me tell you something positive!"
                showCloseButton: true
                type: Kirigami.MessageType.Positive
                visible: false
            }
            QQC2.Button {
                text: i18n("Add Package")
                icon.name: "list-add"
                onClicked: packageDialog.open()
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
            }

            ListView {
                id: packagesList
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 20
                model: ListModel { id: packagesModel }
                clip: true
                spacing: 1
                Layout.rightMargin : Kirigami.Units.gridUnit * 2
                Layout.leftMargin : Kirigami.Units.gridUnit * 2

                delegate: Rectangle {
                    width: ListView.view.width
                    height: Kirigami.Units.gridUnit * 3
                    color: index % 2 === 0 ? Kirigami.Theme.backgroundColor : Kirigami.Theme.alternateBackgroundColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.largeSpacing

                        QQC2.Label {
                            text: model.name
                            Layout.preferredWidth: parent.width * 0.2
                            elide: Text.ElideRight
                            font.bold: true
                        }
                        QQC2.Label {
                            text: i18n("%1 pieces", model.pieces_per_package)
                            Layout.preferredWidth: parent.width * 0.15
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            text: i18n("Purchase: %1", model.purchase_price)
                            Layout.preferredWidth: parent.width * 0.2
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                        }
                        QQC2.Label {
                            text: i18n("Selling: %1", model.selling_price)
                            Layout.preferredWidth: parent.width * 0.2
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignRight
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.minimumWidth: Kirigami.Units.gridUnit
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            Layout.alignment: Qt.AlignRight

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

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    active: true
                    visible: packagesList.contentHeight > packagesList.height
                }
            }
        }

        customFooterActions: [
            Kirigami.Action {
                text: i18n("Close")
                icon.name: "dialog-close"
                onTriggered: packagesListDialog.close()
            }
        ]
    }



    Kirigami.Dialog {
        id: packageDialog
        title: editingPackageIndex >= 0 ? i18n("Edit Package") : i18n("Add Package")
        preferredWidth: Kirigami.Units.gridUnit * 30

        property int editingPackageIndex: -1

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            FormCard.FormCard {
                Layout.fillWidth: true

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
                    visible:false
                    label: i18n("Barcode (Optional)")
                }
            }
        }

        customFooterActions: [
            Kirigami.Action {
                text: packageDialog.editingPackageIndex >= 0 ? i18n("Update") : i18n("Add")
                icon.name: packageDialog.editingPackageIndex >= 0 ? "document-save" : "list-add"
                onTriggered: {
                    if (packageNameField.text.length === 0) {
                        return
                    }

                    if (packageDialog.editingPackageIndex >= 0) {
                        packagesModel.set(packageDialog.editingPackageIndex, {
                                              name: packageNameField.text,
                                              pieces_per_package: packageQuantityField.value,
                                              purchase_price: packagePurchasePriceField.value,
                                              selling_price: packageSellingPriceField.value,
                                              barcode: packageBarcodeField.text
                                          })

                        inlineMsgPackagesListDialog.text= "Package updated successfully"
                        inlineMsgPackagesListDialog.visible=true
                        inlineMsgPackagesListDialog.type= Kirigami.MessageType.Positive
                    } else {
                        packagesModel.append({
                                                 name: packageNameField.text,
                                                 pieces_per_package: packageQuantityField.value,
                                                 purchase_price: packagePurchasePriceField.value,
                                                 selling_price: packageSellingPriceField.value,
                                                 barcode: packageBarcodeField.text
                                             })

                        inlineMsgPackagesListDialog.text= "Package added successfully"
                        inlineMsgPackagesListDialog.visible=true
                        inlineMsgPackagesListDialog.type= Kirigami.MessageType.Positive
                    }
                    clearPackageDialog()
                    packageDialog.close()
                }
            },
            Kirigami.Action {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onTriggered: {
                    clearPackageDialog()
                    packageDialog.close()
                }
            }
        ]
    }
    Kirigami.PromptDialog {
        id: createBeforSetupDialog
        title: i18n("Create Product")
        subtitle: i18n("You need to create prodcut before setup barcode, Are you sure you'd like to create product?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            clearStatusMessages() // Clear previous error messages
            let updatedProduct = updateProduct()
            productModel.createProduct(updatedProduct)

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
        productImageCard.imageUrl = product.image_path ? "https://dim.dervox.com" + product.image_path : "";
       // productImageCard.imageUrl = product.image_path ? "http://localhost:8000" + product.image_path : "";
        console.log("productImageCard.imageUrl : ",productImageCard.imageUrl)
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
        if(productDialog.isBarcodeRequest){
            barcodeDialogLoader.productId =  productDialog.dialogProductId
            barcodeDialogLoader.active=true
            productDialog.isBarcodeRequest=false
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
        function onErrorProductCreated(message, status, details) {
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{

                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }
        }
        function onErrorProductUpdated(message, status, details) {
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{

                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }
        }
        function onErrorPoductDeleted(message, status, details) {
            if (status === 1) { // Validation error
                handleValidationErrors(details)
            }
            else{

                inlineMsg.text= message
                inlineMsg.visible=true
                inlineMsg.type= Kirigami.MessageType.Error

            }
        }
        function onErrorProductReceived(message, status, details) {
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
            productModel.refresh()

        }
        function onProductDeleted(){
            applicationWindow().gnotification.showNotification("",
                                                               "Product "+ nameField.text +" Deleted successfully", // message
                                                               Kirigami.MessageType.Positive, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )
            favoriteManager.removeProductFromAllCategories(dialogProductId);

            productDialog.close()
            productModel.refresh()

        }
        function  onProductReceivedForBarcode(product){
            if(productDialog.isBarcodeRequest){
                productDialog.dialogProductId=product.id
            }

        }
        function onProductCreated(){
            if(!productDialog.isBarcodeRequest){
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
            productModel.refresh()

        }
        // function onImageRemoved(productId) {
        //       if (product && product.id === productId) {
        //           product.image_url = ""
        //       }
        //   }

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

    Connections {
        target: favoriteManager
        function onCategoriesChanged() {
            categoryChipsRepeater.model = favoriteManager.getCategories()
        }
        function onProductsChanged(categoryId) {
            categoryChipsRepeater.model = favoriteManager.getCategories()
        }
    }

    // FavoriteManager {
    //     id: favoriteManager
    // }
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
    onDialogProductIdChanged:{

        productUnitModel.fetchUnits(productApi)
        if(productDialog.dialogProductId>0)
            productApi.getProduct(productDialog.dialogProductId)


    }
    Component.onCompleted:{
        //  cleanField()
        console.log("productDialog.productId : ",productDialog.dialogProductId)
    }
}
