// ProductSelectorDialog.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import com.dervox.ProductModel 1.0


import "../../components"

import "../product"
Kirigami.Dialog {
    id: dialogProductSelector
    title: i18n("Select Products")
    width: Kirigami.Units.gridUnit * 57
    height: Kirigami.Units.gridUnit * 40

    signal productsSelected(var selectedProducts)
    contentItem : ColumnLayout{
        // Header with search
        RowLayout {
            Layout.margins : Kirigami.Units.smallSpacing

            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            Layout.alignment : Qt.AlignTop
            Item{

                Layout.fillWidth: true

            }
            Kirigami.SearchField {
                id: searchField
                //   Layout.fillWidth: true
                onTextChanged: productModel.searchQuery = text
            }
            Item{

                Layout.fillWidth: true

            }

            QQC2.Button {
                icon.name: "list-add-symbolic"
                text:"Create Product"
                onClicked: {
                    productDialogLoader.productId=0
                    productDialogLoader.active=true
                }
            }

        }

        // // Product table
        Tables.KTableView {
            Layout.fillHeight:true
            Layout.fillWidth : true
           // Layout.bottomMargin: loadingIndicator.height
            Layout.margins : Kirigami.Units.smallSpacing
            id: view
            enabled: !productApi.isLoading
            model: productModel
            interactive: true
            clip: true
            alternatingRows: true
            sortOrder : productModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: ProductRoles.NameRole
            selectionBehavior:TableView.SelectRows
            //  contentHeight : parent.height
            // Prevent bounce/overscroll effect
            boundsMovement: Flickable.StopAtBounds
            boundsBehavior: Flickable.StopAtBounds
            contentWidth : parent.width -  Kirigami.Units.smallSpacing
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
                    minimumWidth: dialogProductSelector.width * 0.04
                    width: minimumWidth
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
                    minimumWidth: dialogProductSelector.width * 0.12
                    width: minimumWidth
                    itemDelegate: QQC2.Label {
                        text: modelData
                    }
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
                    minimumWidth: dialogProductSelector.width * 0.20
                    width: minimumWidth
                    itemDelegate: QQC2.Label {
                        text: modelData
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Description")
                    textRole: "description"
                    role: ProductRoles.DescriptionRole
                    minimumWidth: dialogProductSelector.width * 0.25
                    width: minimumWidth
                    itemDelegate: QQC2.Label {
                        text: modelData
                        wrapMode: Text.WordWrap
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Price")
                    textRole: "price"
                    role: ProductRoles.PriceRole
                    minimumWidth: dialogProductSelector.width * 0.10
                    width: minimumWidth
                    itemDelegate: QQC2.Label {
                        text: Number(modelData).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                        font.bold: true
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Quantity")
                    textRole: "quantity"
                    role: ProductRoles.QuantityRole
                    minimumWidth: dialogProductSelector.width * 0.10
                    width: minimumWidth
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
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "minStock")
                    textRole: "minStockLevel"
                    role: ProductRoles.MinStockLevelRole
                    minimumWidth: view.width * 0.10
                    width: minimumWidth
                    itemDelegate: QQC2.Label {
                        text: modelData
                        horizontalAlignment: Text.AlignRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Unit")
                    textRole: "productUnit"
                    role: ProductRoles.ProductUnitRole
                    minimumWidth: dialogProductSelector.width * 0.30
                    width: minimumWidth
                    itemDelegate: QQC2.Label {
                        text: modelData
                    }
                }
            ]


            // Add scroll detection
            // onContentYChanged: {
            //     if (!productModel.loading &&
            //             productModel.currentPage < productModel.totalPages) {

            //         // Check if we're near the bottom
            //         let bottomThreshold = 50 // pixels from bottom
            //         let atBottom = (contentY + height) >= (contentHeight - bottomThreshold)

            //         if (atBottom) {
            //             productModel.loadPage(productModel.currentPage + 1)
            //         }
            //     }
            // }

            // // Optional: Add a footer component to show loading state
            // footer: Item {
            //     width: parent.width
            //     height: visible ? 50 : 0
            //     visible: productModel.loading ||
            //             productModel.currentPage < productModel.totalPages

            //     RowLayout {
            //         anchors.centerIn: parent
            //         spacing: Kirigami.Units.smallSpacing

            //         QQC2.BusyIndicator {
            //             running: productModel.loading
            //             visible: running
            //         }

            //         QQC2.Label {
            //             text: productModel.loading ?
            //                 i18n("Loading...") :
            //                 i18n("Scroll for more...")
            //         }
            //     }
            // }
        }
        // ColumnLayout {
        //     id: loadingIndicator
        //     Layout.fillWidth: true
        //     Layout.alignment: Qt.AlignBottom
        //     spacing: Kirigami.Units.smallSpacing
        //     visible: !productModel.loading && productModel.currentPage < productModel.totalPages

        //     QQC2.ToolButton {
        //         Layout.alignment: Qt.AlignCenter
        //         text: i18n("Load More...")
        //         icon.name: "list-add"
        //         onClicked: {
        //             if (!productModel.loading) {
        //                 productModel.loadPage(productModel.currentPage + 1)
        //             }
        //         }
        //     }

        //     QQC2.BusyIndicator {
        //         Layout.alignment: Qt.AlignCenter
        //         running: productModel.loading
        //         visible: running
        //     }
        // }
        PaginationBar {
            Layout.margins : Kirigami.Units.smallSpacing

            id: paginationBar
            Layout.fillWidth : true
            Layout.alignment : Qt.AlignBottom
            currentPage: productModel.currentPage
            totalPages: productModel.totalPages
            totalItems: productModel.totalItems
            onPageChanged: {
                console.log("  currentPage :  ",productModel.currentPage)
                productModel.loadPage(page)

            }
        }

    }

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

    customFooterActions: [
        Kirigami.Action {
            id: addSelect
            text: i18n("Add Selected")
            icon.name: "list-add"
            enabled: productModel.hasCheckedItems
            property var selectedProducts: []
            property int pendingRequests: 0

            function addSelectedProducts() {
                console.log("Selected products before emitting:", JSON.stringify(selectedProducts))
                dialogProductSelector.productsSelected(selectedProducts)
                dialogProductSelector.close()
            }

            onTriggered: {
                selectedProducts = []
                pendingRequests = 0

                for (let i = 0; i < productModel.rowCount; i++) {
                    if (productModel.data(productModel.index(i, 0), ProductRoles.CheckedRole)) {
                        let productId = productModel.data(productModel.index(i, 0), ProductRoles.IdRole)
                        console.log("Fetching product ID:", productId)
                        pendingRequests++
                        productApi.getProduct(productId)
                    }
                }
                console.log("Initial pending requests:", pendingRequests)
            }


        },
        Kirigami.Action {
            text: i18n("Close")
            icon.name: "dialog-close"
            onTriggered:   dialogProductSelector.close()

        }
    ]
    Connections {
        target: productApi
        function onProductReceived(product) {
            console.log("Received product:", JSON.stringify(product))

            addSelect.selectedProducts.push({
                                                id: product.id,
                                                name: product.name,
                                                purchase_price : product.purchase_price,
                                                price: product.price,
                                                quantity: product.quantity,
                                                maxQuantity: product.quantity,
                                                packages: product.packages || [],
                                                product: product  // Include the full product object
                                            })

            addSelect.pendingRequests--
            console.log("Remaining requests:", addSelect.pendingRequests)

            if (addSelect.pendingRequests === 0) {
                console.log("All products loaded, final array:",
                            JSON.stringify(addSelect.selectedProducts))
                addSelect.addSelectedProducts()
            }
        }

        function onProductError(error) {
            console.error("Error fetching product:", error)
            addSelect.pendingRequests--
        }
    }
    Component.onCompleted:{

        productModel.setApi(productApi)
    }
}
