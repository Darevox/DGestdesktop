import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ComboBox {
    id: root

    property bool searchOnType: true
    property int debounceInterval: 300
    property string currentSearchText: ""
    property bool preventAutoOpen: false

    signal itemSelected(var item)
    signal enterPressed(string text)

    editable: true

    // Direct access to the TextField
    property alias inputField: inputField

    // Custom contentItem to have better control over the TextField
    contentItem: QQC2.TextField {
        id: inputField
        text: root.editText
        width: root.width - root.indicator.width - root.spacing
        font: root.font
        verticalAlignment: Text.AlignVCenter
        placeholderText:"Enter Name , Email ..."

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
            clientModel.setSearchQuery(currentSearchText)
        }
    }

    // Load initial data when dropdown is opened
    onPressedChanged: {
        if (pressed) {
            loadInitialData()
        }
    }

    function loadInitialData() {
        if (clientModel.rowCount === 0) {
            clientModel.setSearchQuery("")
            clientModel.refresh()
        }
    }

    // Connection to handle loading state changes
    Connections {
        target: clientModel

        function onLoadingChanged() {
            if (!clientModel.loading) {
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
                Layout.fillWidth: true
                Layout.fillHeight: true

                supportsRefreshing: true
                refreshing: clientModel.loading

                onRefreshingChanged: {
                    if (refreshing) {
                        clientModel.refresh()
                    }
                }

                ListView {
                    id: listView
                    model: clientModel

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
                                    text: i18n("Email: %1", model.email || "")
                                    elide: Text.ElideRight
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    opacity: 0.7
                                }
                            }

                        }

                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Name: %1 \n Email: %2",
                                                model.name || "",
                                                model.email || ""
                                                )

                        onClicked: {
                            root.currentIndex = index
                            root.activated(index)
                            root.popup.close()

                            // Get the ID from the model and call API
                            const clientId = model.id
                            clientApi.getClient(clientId)
                        }
                    }

                    // Empty state message
                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (Kirigami.Units.largeSpacing * 4)
                        visible: listView.count === 0 && !clientModel.loading
                        text: currentSearchText ?
                                  i18n("No client found matching '%1'", currentSearchText) :
                                  i18n("No client available")
                        // icon.name: "package"
                    }

                    // Load more button
                    footer: QQC2.ItemDelegate {
                        visible: clientModel.currentPage < clientModel.totalPages && !clientModel.loading
                        width: parent.width
                        height: visible ? implicitHeight : 0

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: i18n("Load More")
                            }
                        }

                        onClicked: {
                            clientModel.loadPage(clientModel.currentPage + 1)
                        }
                    }
                }
            }

            // Loading indicator
            QQC2.BusyIndicator {
                Layout.alignment: Qt.AlignCenter
                running: clientModel.loading
                visible: running
            }
        }
    }

    // Handle Enter key
    Keys.onReturnPressed: {
        root.enterPressed(editText)
    }

    Component.onCompleted: {
        clientModel.setApi(clientApi)
        clientModel.setSearchQuery("")
        inputField.forceActiveFocus()
    }
    Connections {
        target: clientApi
        function onClientReceived(client) {
            if (client) {
                root.editText = client.name || ""
                //  root.editText = ""
                root.itemSelected(client)
                inputField.forceActiveFocus()
                //  inputField.selectAll()
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
