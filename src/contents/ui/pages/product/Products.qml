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
    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        z:99
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !productModel.loading && productModel.rowCount === 0
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
                        productDetailsDialog.productId = 0
                        productDetailsDialog.active = true
                    }
                }
            `, emptyStateMessage)
    }
    actions: [
        Kirigami.Action {
            icon.name: "list-add-symbolic"
            text:"Add"
            onTriggered: {
                productDetailsDialog.productId=0
                productDetailsDialog.active=true
            }
        },
        Kirigami.Action {
            icon.name: "delete"
            text:"Delete"
            enabled: productModel.hasCheckedItems
            onTriggered: {
                deleteDialog.open()
            }
        },
        Kirigami.Action {
            icon.name: "overflow-menu"
            Kirigami.Action {
                text: "Product Untis"
                onTriggered:{
                    //showPassiveNotification("View Action 1 clicked")
                }
            }
            Kirigami.Action {
                text: "Print"
                onTriggered: showPassiveNotification("View Action 2 clicked")
            }
        }

    ]
    header:RowLayout {
        Layout.fillWidth: true

        Item{
            Layout.fillWidth: true

        }
        QQC2.BusyIndicator {
            running: productModel.loading
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
            text: "Show Low Stock Only"
            onCheckedChanged: productModel.filterLowStock(checked)
        }
        Item{
            Layout.fillWidth: true

        }

    }

    QQC2.ScrollView {
        anchors.fill:parent
        contentWidth : view.width
        contentItem:DKTableView {
            visible: productModel.rowCount > 0
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
        id: productDetailsDialog
        active: false
        asynchronous: true
        sourceComponent: ProductDetails{}
        property int productId: 0
        onLoaded: {
            item.dialogProductId=productDetailsDialog.productId
            item.open()
        }

        Connections {
            target: productDetailsDialog.item
            function onClosed() {
                productDetailsDialog.active = false
            }
        }
    }
    Connections {
        target: productApi
        function onProductDeleted(){
            applicationWindow().gnotification.showNotification("",
                                                               "Product  Deleted successfully", // message
                                                               Kirigami.MessageType.Positive, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )
            productModel.clearAllChecked();

        }
        function onProductError(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                                                               message, // message
                                                               Kirigami.MessageType.Error, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )


        }
    }
    Kirigami.PromptDialog {
        id: deleteDialog
        title: i18n("Delete Prodcut")
        subtitle: i18n("Are you sure you'd like to delete this product?")

        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: {
            let checkedIds = productModel.getCheckedProductIds();
            checkedIds.forEach(productId => {
                                   productModel.deleteProduct(productId);
                               });

        }
    }

    Component.onCompleted : {
        productModel.setApi(productApi)
    }
}
