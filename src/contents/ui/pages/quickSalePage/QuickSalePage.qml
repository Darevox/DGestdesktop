// QuickSale.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
//import com.dervox.FavoriteManager
import com.dervox.ProductFetchApi

import "."

Kirigami.Page {
    id: root
    title: i18n("Quick Sale")

    // Shared state properties
    property var saleStates: []
    property var sharedLoadedProducts: ({})
    property var sharedCurrentProductIds: []
    property bool isLoadingProducts: false
    property int currentCategoryId: 1
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Kirigami.Theme.inherit: false
    background: Rectangle {
        color: Qt.darker(Kirigami.Theme.backgroundColor, 1.1)
        border.width: 0
        radius: Kirigami.Units.smallSpacing
    }
    Component.onCompleted: {
        addNewSaleTab()
        loadFavoriteProducts()
        saleModel.setApi(saleApi)
    }

    actions: [
        Kirigami.Action {
            text: i18n("Settings")
            icon.name: "settings-configure"
            onTriggered: favoriteSettingsDialog.open()
        },
        Kirigami.Action {
            text: i18n("New Sale")
            icon.name: "list-add"
            enabled: saleStates.length<=5
            onTriggered: addNewSaleTab()
        }
    ]

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // Sale tabs
        QQC2.TabBar {
            id: saleTabBar
            Layout.fillWidth: true

            Repeater {
                model: saleStates.length
                QQC2.TabButton {
                    id: saleTab

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            text: i18n("Sale %1", modelData + 1)
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        QQC2.ToolButton {
                            icon.name: "window-close"
                            display: QQC2.AbstractButton.IconOnly
                            visible: saleStates.length > 1
                            onClicked: closeTab(modelData)

                            QQC2.ToolTip {
                                text: i18n("Close sale")
                            }
                        }
                    }

                    width: Math.max(120, saleTabBar.width / saleStates.length)
                }
            }
        }

        // Sale content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: saleTabBar.currentIndex

            Repeater {
                model: saleStates.length
                QuickSaleTabContent {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    saleState: saleStates[modelData]
                    sharedLoadedProducts: root.sharedLoadedProducts
                    sharedCurrentProductIds: root.sharedCurrentProductIds
                    isLoadingProducts: root.isLoadingProducts
                    onCategoryChanged: function(categoryId) {
                        root.currentCategoryId = categoryId
                        root.loadFavoriteProducts()
                    }
                }
            }
        }
    }

    // Settings dialog
    FavoriteProductsSettings {
        id: favoriteSettingsDialog
    }
    function closeTab(index) {
        // Show confirmation if there are items in the sale
        if (saleStates[index].saleItems.count > 0) {
            confirmCloseDialog.saleIndex = index;
            confirmCloseDialog.open();
        } else {
            removeTab(index);
        }
    }
    function removeTab(index) {
        saleStates.splice(index, 1);
        saleStates = [...saleStates];
        if (saleTabBar.currentIndex >= saleStates.length) {
            saleTabBar.currentIndex = saleStates.length - 1;
        }
    }
    function addNewSaleTab() {
        saleStates.push({
                            saleItems: Qt.createQmlObject('import QtQuick; ListModel {}', root),
                            total: 0,
                            autoPayment: false,
                            discountAmount: 0,
                            hasClient: false,
                            clientId: -1,
                            clientName: "",  // Add clientName to store the display name
                            clientData: null // Store the whole client object if needed
                        })
        saleStates = [...saleStates]
        saleTabBar.currentIndex = saleStates.length - 1
    }

    function loadFavoriteProducts() {
        if (isLoadingProducts) return

        isLoadingProducts = true
        const productIds = favoriteManager.getCategoryProductIds(currentCategoryId)
        console.log("Loading products for category:", currentCategoryId, "Products:", productIds)

        let pendingLoads = 0
        let token = api.getToken()
        productFetchApi.saveToken(token)

        productIds.forEach(id => {
                               if (!sharedLoadedProducts[id]) {
                                   pendingLoads++
                                   console.log("Fetching product:", id)
                                   productFetchApi.getProduct(id)
                               }
                           })

        if (pendingLoads === 0) {
            isLoadingProducts = false
        }

        sharedCurrentProductIds = productIds
    }

    // API Connections
    Connections {
        target: productFetchApi
        function onProductReceived(product) {
            console.log("Product received:", product.id)
            let temp = sharedLoadedProducts
            temp[product.id] = product
            sharedLoadedProducts = null  // Break binding
            sharedLoadedProducts = temp  // Reassign to trigger update
            checkLoadingComplete()
        }
        function onErrorOccurred(error) {
            console.error("Error loading product:", error)
            checkLoadingComplete()
        }
    }

    function checkLoadingComplete() {
        if (!isLoadingProducts) return

        let allLoaded = true
        sharedCurrentProductIds.forEach(id => {
                                            if (!sharedLoadedProducts[id]) {
                                                allLoaded = false
                                            }
                                        })

        if (allLoaded) {
            isLoadingProducts = false
        }
    }

    // Favorite manager connections
    Connections {
        target: favoriteManager
        function onProductsChanged(categoryId) {
            if (categoryId === currentCategoryId) {
                loadFavoriteProducts()
            }
        }
    }

    // FavoriteManager {
    //     id: favoriteManager
    // }

    ProductFetchApi {
        id: productFetchApi
        Component.onCompleted: {
            let token = api.getToken()
            productFetchApi.saveToken(token)
        }
    }
    Kirigami.Dialog {
        id: confirmCloseDialog
        title: i18n("Close Sale")
        standardButtons: Kirigami.Dialog.Yes | Kirigami.Dialog.No

        property int saleIndex: -1

        QQC2.Label {
            text: i18n("This sale has items. Are you sure you want to close it?")
        }

        onAccepted: {
            if (saleIndex !== -1) {
                removeTab(saleIndex);
            }
        }
    }
}
