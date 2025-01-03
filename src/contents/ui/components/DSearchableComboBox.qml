// SearchableComboBox.qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import com.dervox.ProductFetchApi
import com.dervox.ProductFetchModel
QQC2.ComboBox {
    id: root

    property bool searchOnType: true
    property int debounceInterval: 300
    property string currentSearchText: ""
    property bool preventAutoOpen: false

    signal itemSelected(var item)
    signal enterPressed(string text)

    editable: true
    ProductFetchApi{
        id:productFetchApi
    }
    ProductFetchModel{
        id:productFetchModel
    }

    // Direct access to the TextField
    property alias inputField: inputField

    // Custom contentItem to have better control over the TextField
    contentItem: QQC2.TextField {
        id: inputField
        text: root.editText
        width: root.width - root.indicator.width - root.spacing
        font: root.font
        verticalAlignment: Text.AlignVCenter
        placeholderText:"Enter Name , Barcode ..."
        // Keep focus when model updates
        background: Rectangle {
            color: "transparent"
            border.width: 0  // No border
        }
        onTextChanged: {
            if (activeFocus) {
                forceActiveFocus()
            }
        }

        // Update ComboBox editText
        onTextEdited: {
            root.editText = text
            if (searchOnType && !preventAutoOpen) {
                if (!popup.opened) {
                    loadInitialData()
                    popup.open()
                }
                searchDebounceTimer.restart()
            }
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: root.debounceInterval
        onTriggered: {
            currentSearchText = root.editText
            productFetchModel.setSearchQuery(currentSearchText)
        }
    }

    // Load initial data when dropdown is opened
    onPressedChanged: {
        if (pressed) {
            loadInitialData()
        }
    }

    function loadInitialData() {
        if (productFetchModel.rowCount === 0) {
            productFetchModel.setSearchQuery("")
            productFetchModel.refresh()
        }
    }

    // Connection to handle loading state changes
    Connections {
        target: productFetchModel

        function onLoadingChanged() {
            if (!productFetchModel.loading) {
                inputField.forceActiveFocus()
            }
        }

        function onRowsInserted() {
            inputField.forceActiveFocus()
        }
    }

    popup: QQC2.Popup {
        y: root.height
        width: root.width
        height: Math.min(contentHeight + Kirigami.Units.gridUnit, 300)
        padding: 1
        onOpened: {
            productFetchModel.setSortField("")
            productFetchModel.setSearchQuery("")
            productFetchModel.loadPage(1)
            inputField.forceActiveFocus()
        }

        onClosed: {
            preventAutoOpen = true
            Qt.callLater(() => {
                             preventAutoOpen = false
                             inputField.forceActiveFocus()
                         })
        }

        contentItem: ColumnLayout {
            spacing: 1

            Kirigami.ScrollablePage {

                supportsRefreshing: true
                refreshing: productFetchModel.loading
                Layout.fillWidth: true
                Layout.fillHeight: true


                onRefreshingChanged: {
                    if (refreshing) {
                        productFetchModel.refresh()
                    }
                }

                ListView {
                    id: listView
                    model: productFetchModel
                    interactive : true
                    delegate: QQC2.ItemDelegate {
                        width: listView.width
                        highlighted: ListView.isCurrentItem

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "package"
                                implicitWidth: Kirigami.Units.iconSizes.small
                                implicitHeight: Kirigami.Units.iconSizes.small
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: model.name || ""
                                    elide: Text.ElideRight
                                    font.bold: true
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: i18n("Ref: %1 - Stock: %2", model.reference || "", model.quantity || 0)
                                    elide: Text.ElideRight
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    opacity: 0.7
                                }
                            }

                            QQC2.Label {
                                text: Number(model.price || 0).toLocaleString(Qt.locale(), 'f', 2)
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Name: %1\nReference: %2\nQuantity: %3\nPrice: %4",
                                                model.name || "",
                                                model.reference || "",
                                                model.quantity || 0,
                                                Number(model.price || 0).toLocaleString(Qt.locale(), 'f', 2)
                                                )

                        onClicked: {
                            root.currentIndex = index
                            root.activated(index)
                            root.popup.close()

                            // Get the ID from the model and call API
                            const productId = model.id
                            productFetchApi.getProduct(productId)
                        }
                    }

                    // Empty state message
                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (Kirigami.Units.largeSpacing * 4)
                        visible: listView.count === 0 && !productFetchModel.loading
                        text: currentSearchText ?
                                  i18n("No products found matching '%1'", currentSearchText) :
                                  i18n("No products available")
                        // icon.name: "package"
                    }

                    // Load more button
                    footer: QQC2.ItemDelegate {
                        visible: productFetchModel.currentPage < productFetchModel.totalPages && !productFetchModel.loading
                        width: parent.width
                        height: visible ? implicitHeight : 0

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: i18n("Load More ...")
                            }
                        }

                        onClicked: {
                            console.log(" productFetchModel.currentPage :" , productFetchModel.currentPage)
                            productFetchModel.loadPage(productFetchModel.currentPage + 1)
                        }
                    }
                }
            }

            // Loading indicator
            QQC2.BusyIndicator {
                Layout.alignment: Qt.AlignCenter
                running: productFetchModel.loading
                visible: running
            }
        }
    }

    // Handle Enter key
    Keys.onReturnPressed: {
        root.enterPressed(editText)
    }

    Component.onCompleted: {
        let token = api.getToken();

        productFetchApi.saveToken(token);
        productFetchModel.setApi(productFetchApi)
        productFetchModel.setSearchQuery("")
        inputField.forceActiveFocus()
    }
    Connections {
        target: productFetchApi
        function onProductReceived(product) {
            if (product) {
                //  root.editText = product.name || ""
                root.editText = ""
                root.itemSelected(product)
                inputField.forceActiveFocus()
                inputField.selectAll()
                productFetchModel.setSortField("")
                productFetchModel.setSearchQuery("")
                productFetchModel.loadPage(1)
            }
        }
    }

    // Override default focus handling
    onActiveFocusChanged: {
        if (activeFocus) {
            inputField.forceActiveFocus()
        }
    }
}
