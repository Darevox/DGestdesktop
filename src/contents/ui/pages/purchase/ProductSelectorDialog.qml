// ProductSelectorDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import com.dervox.ProductModel 1.0

import "../../components"

Kirigami.Dialog {
    id: dialog
    title: i18n("Select Products")
    preferredWidth: Kirigami.Units.gridUnit * 60
    preferredHeight: Kirigami.Units.gridUnit * 40

    signal productsSelected(var selectedProducts)

    // Header with search
    header: RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Kirigami.SearchField {
            id: searchField
            Layout.fillWidth: true
            onTextChanged: productModel.searchQuery = text
        }

        QQC2.Button {
            text: i18n("Add Selected")
            icon.name: "list-add"
            enabled: productModel.hasCheckedItems
            onClicked: {
                let selectedProducts = []
                for (let i = 0; i < productModel.rowCount; i++) {
                    if (productModel.data(productModel.index(i, 0), ProductRoles.CheckedRole)) {
                        selectedProducts.push({
                                                  id: productModel.data(productModel.index(i, 0), ProductRoles.IdRole),
                                                  name: productModel.data(productModel.index(i, 0), ProductRoles.NameRole),
                                                  price: productModel.data(productModel.index(i, 0), ProductRoles.PriceRole),
                                                  quantity: 1 // Default quantity
                                              })
                    }
                }
                dialog.productsSelected(selectedProducts)
                dialog.close()
            }
        }
    }

    // Product table
    QQC2.ScrollView {
        anchors.fill:parent
        contentWidth : view.width
        visible:!productModel.loading&& productModel.rowCount > 0
        contentItem:DKTableView {

            id: view
            enabled: !productModel.loading
            model: productModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder : productModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: ProductRoles.NameRole
            //  contentHeight : parent.height

            contentWidth : parent.width
            onCellDoubleClicked:function (row){
                let idProduct = view.model.data(view.model.index(row, 0), ProductRoles.IdRole);
                console.log("Row Clicked:", row, "Name:", idProduct);
                productDetailsDialog.productId=idProduct
                productDetailsDialog.active=true

            }


            onColumnClicked: function (index, headerComponent) {

                if (view.sortRole !== headerComponent.role) {

                    productModel.sortField=headerComponent.textRole
                    productModel.sortDirection="asc"

                    view.sortRole = headerComponent.role;

                    view.sortOrder = Qt.AscendingOrder;

                } else {
                    //view.sortOrder = view.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder
                    // view.sortOrder = view.sortOrder === "asc" ? "desc": "asc"
                    productModel.sortDirection=view.sortOrder === Qt.AscendingOrder ? "desc" : "asc"
                    view.sortOrder = productModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder



                }

                view.model.sort(view.sortRole, view.sortOrder);

                // After sorting we need update selection
                __resetSelection();
            }

            function __resetSelection() {
                // NOTE: Making a forced copy of the list
                let selectedIndexes = Array(...view.selectionModel.selectedIndexes)

                let currentRow = view.selectionModel.currentIndex.row;
                let currentColumn = view.selectionModel.currentIndex.column;

                view.selectionModel.clear();
                for (let i in selectedIndexes) {
                    view.selectionModel.select(selectedIndexes[i], ItemSelectionModel.Select);
                }

                view.selectionModel.setCurrentIndex(view.model.index(currentRow, currentColumn), ItemSelectionModel.Select);
            }


            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Select")
                    textRole: "checked"
                    role: ProductRoles.CheckedRole
                    minimumWidth: root.width * 0.04
                    width: minimumWidth
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: {
                            productModel.toggleAllProductsChecked()
                        }
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Reference")
                    textRole: "reference"
                    role: ProductRoles.ReferenceRole
                    minimumWidth: root.width * 0.15 // Set directly here
                    width:minimumWidth

                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: ProductRoles.NameRole
                    leading: Kirigami.Icon {
                        source: "system-software-install"
                        implicitWidth: view.compact ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.medium
                        implicitHeight: implicitWidth
                    }
                    minimumWidth: view.width * 0.20
                    width:minimumWidth

                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Description")
                    textRole: "description"
                    role: ProductRoles.DescriptionRole
                    minimumWidth: view.width * 0.25
                    width:minimumWidth

                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Price")
                    textRole: "price"
                    role: ProductRoles.PriceRole
                    minimumWidth: view.width * 0.10
                    width:minimumWidth

                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Quantity")
                    textRole: "quantity"
                    role: ProductRoles.QuantityRole
                    minimumWidth: view.width * 0.10
                    width:minimumWidth

                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "minStock")
                    textRole: "minStockLevel"
                    role: ProductRoles.MinStockLevelRole
                    minimumWidth: view.width * 0.10
                    width:minimumWidth

                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Unit")
                    textRole: "productUnit"
                    role: ProductRoles.ProductUnitRole
                    minimumWidth: view.width * 0.30
                    width:minimumWidth
                }
            ]

        }
    }
    Component.onCompleted:{

        productModel.setApi(productApi)
    }
}