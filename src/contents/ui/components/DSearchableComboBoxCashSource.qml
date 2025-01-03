// CashSourceComboBox.qml
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
    property int selectedId: -1  // -1 indicates no selection
    signal itemSelected(var item)
    signal enterPressed(string text)
    property int defaultSourceId: -1

    editable: true
    property alias inputField: inputField

    contentItem: QQC2.TextField {
        id: inputField
        text: root.editText
        width: root.width - root.indicator.width - root.spacing
        font: root.font
        verticalAlignment: Text.AlignVCenter
        placeholderText: "Enter Cash Source Name..."

        background: Rectangle {
            color: "transparent"
            border.width: 0
        }

        onTextChanged: {
            if (activeFocus) {
                forceActiveFocus()
            }
        }

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
            cashSourceModelFetch.setSearchQuery(currentSearchText)
        }
    }

    onPressedChanged: {
        if (pressed) {
            loadInitialData()
        }
    }

    function loadInitialData() {
        if (cashSourceModelFetch.rowCount === 0) {
            cashSourceModelFetch.setSearchQuery("")
            cashSourceModelFetch.refresh()
        }
    }

    Connections {
        target: cashSourceModelFetch

        function onLoadingChanged() {
            if (!cashSourceModelFetch.loading) {
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
                refreshing: cashSourceModelFetch.loading

                onRefreshingChanged: {
                    if (refreshing) {
                        cashSourceModelFetch.refresh()
                    }
                }

                ListView {
                    id: listView
                    model: cashSourceModelFetch

                    delegate: QQC2.ItemDelegate {
                        width: listView.width
                        highlighted: ListView.isCurrentItem

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "wallet-open"
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
                                    text: i18n("Balance: %1", Number(model.balance || 0).toLocaleString(Qt.locale(), 'f', 2))
                                    elide: Text.ElideRight
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    opacity: 0.7
                                }
                            }

                            QQC2.Label {
                                text: model.type || ""
                                font.italic: true
                                opacity: 0.7
                            }
                        }

                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Name: %1\nType: %2\nBalance: %3",
                                                model.name || "",
                                                model.type || "",
                                                Number(model.balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                                                )

                        onClicked: {
                            root.currentIndex = index
                            root.activated(index)
                            root.popup.close()

                            const sourceId = model.id
                            cashSourceApiFetch.getCashSource(sourceId)
                        }
                    }

                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - (Kirigami.Units.largeSpacing * 4)
                        visible: listView.count === 0 && !cashSourceModelFetch.loading
                        text: currentSearchText ?
                                  i18n("No cash source found matching '%1'", currentSearchText) :
                                  i18n("No cash sources available")
                    }

                    footer: QQC2.ItemDelegate {
                        visible: cashSourceModelFetch.currentPage < cashSourceModelFetch.totalPages &&
                                 !cashSourceModelFetch.loading
                        width: parent.width
                        height: visible ? implicitHeight : 0

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: i18n("Load More... (Page %1 of %2)",
                                           cashSourceModelFetch.currentPage,
                                           cashSourceModelFetch.totalPages)
                            }
                        }

                        onClicked: {
                            cashSourceModelFetch.loadPage(cashSourceModelFetch.currentPage + 1)
                        }
                    }
                }
            }

            QQC2.BusyIndicator {
                Layout.alignment: Qt.AlignCenter
                running: cashSourceModelFetch.loading
                visible: running
            }
        }
    }

    Keys.onReturnPressed: {
        root.enterPressed(editText)
    }

    Component.onCompleted: {
        cashSourceModelFetch.setApi(cashSourceApiFetch)
        cashSourceModelFetch.setSearchQuery("")
        inputField.forceActiveFocus()
        if (defaultSourceId > 0) {
            cashSourceApiFetch.getCashSource(defaultSourceId)

                  // for (let i = 0; i < cashSourceModelFetch.count; i++) {
                  //     if (cashSourceModelFetch.get(i).id === defaultSourceId) {
                  //         currentIndex = i
                  //         break
                  //     }
                  // }
              }
    }

    Connections {
        target: cashSourceApiFetch
        function onCashSourceReceived(source) {
            if (source) {
                root.editText = source.name || ""
                root.selectedId = source.id  // Store the ID
                root.itemSelected(source)
                inputField.forceActiveFocus()
            }
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            inputField.forceActiveFocus()
        }
    }
}
