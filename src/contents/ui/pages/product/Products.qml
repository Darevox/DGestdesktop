/*
 * Copyright 2024 Your Name <your.email@example.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import "../../components"
import "."
import com.dervox.ProductModel 1.0
Kirigami.Page {
    id: root

    title: i18nc("@title:group", "Product")

    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false
    property var checkedProductIds: []
    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        z:99
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !productApi.isLoading && productModel.rowCount === 0
        text: {
            if (lowStockCheckBox.checked && searchField.text !== "") {
                icon.name="package"
                return i18n("There are no low stock products matching '%1'", searchField.text)
            }
            if (lowStockCheckBox.checked) {
                icon.name="package"
                return i18n("There are no products with low stock")
            }
            if (searchField.text !== "") {
                icon.name= "search-symbolic"
                return i18n("There are no products matching '%1'", searchField.text)
            }
            return i18n("There are no products. Please add a new product.")
        }
        icon.name: "package"

        helpfulAction: (lowStockCheckBox.checked || searchField.text !== "")
                       ? null
                       : Qt.createQmlObject(`
                                            import org.kde.kirigami as Kirigami
                                            Kirigami.Action {
                                            icon.name: "list-add"
                                            text: "Add product"
                                            onTriggered: {
                                            productDialogLoader.productId = 0
                                            productDialogLoader.active = true
                                            }
                                            }
                                            `, emptyStateMessage)
    }
    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text:i18n("Add")
            onTriggered: {
                productDialogLoader.productId=0
                productDialogLoader.active=true
            }
        },
        Kirigami.Action {
            icon.name: "delete"
            text:i18n("Delete")
            enabled: productModel.hasCheckedItems
            onTriggered: {
                deleteDialog.open()
            }
        }
        // Kirigami.Action {
        //     icon.name: "overflow-menu"
        //     Kirigami.Action {
        //         text: "Product Untis"
        //         onTriggered:{
        //             //showPassiveNotification("View Action 1 clicked")
        //         }
        //     }
        //     Kirigami.Action {
        //         text: "Print"
        //         onTriggered: showPassiveNotification("View Action 2 clicked")
        //     }
        // }

    ]
    header:RowLayout {
        Layout.fillWidth: true

        Item{
            Layout.fillWidth: true

        }
        DBusyIndicator {
            running: productApi.isLoading
        }
        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth:parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700  // 200 ms delay
                repeat: false
                onTriggered: productModel.searchQuery = searchField.text
            }

            onTextChanged: {
                searchDelayTimer.restart()  // Restart the timer each time text changes
            }
        }
        QQC2.CheckBox {
            id : lowStockCheckBox
            text: i18n("Show Low Stock Only")
            onCheckedChanged: productModel.filterLowStock(checked)
        }
        Item{
            Layout.fillWidth: true

        }

    }
    GridLayout {
        anchors.fill: parent
        visible: productApi.isLoading
        columns: 8
        rows: 8
        columnSpacing: parent.width * 0.01
        rowSpacing: parent.height * 0.02

        Repeater {
            model: 8 * 8
            SkeletonLoaders {
                // Determine width based on row and column index
                property int rowIndex: Math.floor(index / 8)
                property int columnIndex: index % 8

                Layout.preferredWidth:
                    columnIndex === 1 ? view.width * 0.05 :  // Column 1 small
                                        columnIndex === 2 ? view.width * 0.09 :  // Column 2 normal
                                                            columnIndex === 4 ?
                                                                (rowIndex === 0 ? view.width * 0.11 :
                                                                                  rowIndex === 1 ? view.width * 0.11 :
                                                                                                   rowIndex === 2 ? view.width * 0.11 :
                                                                                                                    rowIndex === 3 ? view.width * 0.11 :
                                                                                                                                     rowIndex === 4 ? view.width * 0.11 :
                                                                                                                                                      rowIndex === 5 ? view.width * 0.11 :
                                                                                                                                                                       rowIndex === 6 ? view.width * 0.11 :
                                                                                                                                                                                        view.width * 0.11) :
                                                                (columnIndex === 6 || columnIndex === 7 || columnIndex === 8) ? view.width * 0.10 :
                                                                                                                                view.width * 0.09  // Default width for other columns

                Layout.preferredHeight: 20
            }
        }
    }
    QQC2.ScrollView {
        anchors.fill:parent
        contentWidth : view.width
        visible:!productApi.isLoading&& productModel.rowCount > 0
        contentItem:Tables.KTableView {

            id: view
            enabled: !productApi.isLoading
            model: productModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder : productModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: ProductRoles.NameRole
            //  contentHeight : parent.height
            selectionMode: TableView.SelectionMode.SingleSelection
            selectionBehavior: TableView.SelectRows
            contentWidth : parent.width
            onCellDoubleClicked:function (row){
                let idProduct = view.model.data(view.model.index(row, 0), ProductRoles.IdRole);
                console.log("Row Clicked:", row, "Name:", idProduct);
                productDialogLoader.productId=idProduct
                productDialogLoader.active=true

            }

            property var nonSortableColumns: {
                return {
                    [ ProductRoles.ProductUnitRole]: "productUnit",
                    [ ProductRoles.MinStockLevelRole]: "minStock",

                }
            }

            onColumnClicked: function (index, headerComponent) {
                if (Object.keys(nonSortableColumns).includes(String(headerComponent.role)) ||
                        Object.values(nonSortableColumns).includes(headerComponent.textRole)) {
                    return; // Exit if column shouldn't be sortable
                }
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
                    width:  root.width * 0.04
                    headerDelegate: QQC2.CheckBox {
                        onCheckedChanged: {
                            productModel.toggleAllProductsChecked()
                        }
                    }
                    itemDelegate: QQC2.CheckBox {
                        checked: modelData
                        onCheckedChanged: productModel.setChecked(row, checked)
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Reference")
                    textRole: "reference"
                    role: ProductRoles.ReferenceRole
                    width:  root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: modelData
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Name")
                    textRole: "name"
                    role: ProductRoles.NameRole
                    // leading: Kirigami.Icon {
                    //     source: "system-software-install"
                    //     implicitWidth: view.compact ? Kirigami.Units.iconSizes.small : Kirigami.Units.iconSizes.medium
                    //     implicitHeight: implicitWidth
                    // }
                    width:  view.width * 0.20
                    itemDelegate: QQC2.Label {
                        text: modelData
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Description")
                    textRole: "description"
                    role: ProductRoles.DescriptionRole
                    width: view.width * 0.20
                    itemDelegate: QQC2.Label {
                        text: modelData
                        wrapMode: Text.WordWrap
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Price")
                    textRole: "price"
                    role: ProductRoles.PriceRole
                    width: view.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: Number(modelData).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                        font.bold: true
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Quantity")
                    textRole: "quantity"
                    role: ProductRoles.QuantityRole
                    width: view.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: modelData
                        horizontalAlignment: Text.AlignRight
                        color: {
                            // Compare quantity with minStockLevel
                            if (model.quantity <= model.minStockLevel) {
                                return Kirigami.Theme.negativeTextColor
                            }
                            return Kirigami.Theme.textColor
                        }
                        font.bold: model.quantity <= model.minStockLevel
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "minStock")
                    textRole: "minStockLevel"
                    role: ProductRoles.MinStockLevelRole
                    width:  view.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: modelData
                        horizontalAlignment: Text.AlignRight
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Unit")
                    textRole: "productUnit"
                    role: ProductRoles.ProductUnitRole
                    // minimumWidth: view.width * 0.30
                    width: view.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: modelData
                    }
                    headerDelegate: TableHeaderLabel {}
                }
            ]

        }
    }
    footer: PaginationBar {
        id: paginationBar
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        currentPage: productModel.currentPage
        totalPages: productModel.totalPages
        totalItems: productModel.totalItems
        onPageChanged: {
            console.log("  currentPage :  ",productModel.currentPage)
            productModel.loadPage(page)

        }
    }

    // Connections {
    //     target: productModel
    //     // function onCurrentPageChanged() {
    //     //     view.positionViewAtBeginning()
    //     // }
    //     function onDataChanged(topLeft, bottomRight) {
    //         //  view.positionViewAtBeginning()
    //     }
    // }

    Loader {
        id: productDialogLoader
        active: false
        asynchronous: true
        sourceComponent: ProductDetails{}
        property int productId: 0
        onLoaded: {
            item.dialogProductId=productDialogLoader.productId
            item.open()
        }

        Connections {
            target: productDialogLoader.item
            function onClosed() {
                productDialogLoader.active = false
            }
        }
    }
    Connections {
        target: productApi
        // function onProductDeleted(){
        //     applicationWindow().gnotification.showNotification("",
        //                                                        "Product  Deleted successfully", // message
        //                                                        Kirigami.MessageType.Positive, // message type
        //                                                        "short",
        //                                                        "dialog-close"
        //                                                        )
        //     productModel.clearAllChecked();

        // }
        function onProductError(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                                                               message, // message
                                                               Kirigami.MessageType.Error, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )

        }
        function onProductDeleted() {
               // Get the first ID from our stored array
               if (checkedProductIds.length > 0) {
                   const productId = checkedProductIds[0];
                   console.log("Processing deletion for productId:", productId); // Debug log

                   // Remove from favorites
                   favoriteManager.removeProductFromAllCategories(productId);

                   // Show notification
                   applicationWindow().gnotification.showNotification("",
                        i18n("Product Deleted successfully"),
                       Kirigami.MessageType.Positive,
                       "short",
                       "dialog-close"
                   );

                   // Remove this ID from our array
                   checkedProductIds.shift(); // removes and returns the first element
                   console.log("Remaining products to process:", checkedProductIds); // Debug log

                   // If all deletions are complete
                   if (checkedProductIds.length === 0) {
                       productModel.clearAllChecked();
                   }
               }
           }

    }
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Prodcut")
        subtitle: i18n("Are you sure you'd like to delete this product?")

        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            checkedProductIds = productModel.getCheckedProductIds();
              console.log("Initial checkedProductIds:", checkedProductIds); // Debug log
              checkedProductIds.forEach(productId => {
                  productModel.deleteProduct(productId);
              });
        }
    }

    Component.onCompleted : {
        productModel.setApi(productApi)
    }
}
