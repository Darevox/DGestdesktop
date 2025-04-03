import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: pageRoot

    implicitWidth: Kirigami.Units.gridUnit * 20

    leftPadding: 0
    rightPadding: 0
    bottomPadding: 0
    topPadding: 0
    title: qsTr("DIM")

    //flickable: mainListView
    actions: [
        Kirigami.Action {
            text: qsTr("Home")
            icon.name: "go-home"
            displayHint: Kirigami.DisplayHint.IconOnly
            enabled: root.pageStack.lastVisibleItem !== pageRoot
            onTriggered: root.pageStack.pop(pageRoot)
        }
    ]

    ListModel {
        id: pagesModel
        ListElement {
            title: "Dashboard"
            targetPage: "Dashboard"
            img: "/contents/ui/img/chips.svg"
        }
        ListElement {
            title: "Client"
            targetPage: "Client"
            img: "/contents/ui/img/drawers.svg"
        }
        ListElement {
            title: "Invoice"
            targetPage: "Invoice"
            img: "/contents/ui/img/progress-bar.svg"
        }
        ListElement {
            title: "Settings"
            targetPage: "Settings"
            img: "/contents/ui/img/formlayout.svg"
        }
        ListElement {
            title: "Stock"
            targetPage: "Stock"
            img: "/contents/ui/img/cardlayout.svg"
        }
        ListElement {
            title: "Client"
            targetPage: "Client"
            img: "/contents/ui/img/drawers.svg"
        }
        ListElement {
            title: "Client"
            targetPage: "Client"
            img: "/contents/ui/img/drawers.svg"
        }
        ListElement {
            title: "Invoice"
            targetPage: "Invoice"
            img: "/contents/ui/img/progress-bar.svg"
        }
        ListElement {
            title: "Settings"
            targetPage: "Settings"
            img: "/contents/ui/img/formlayout.svg"
        }
        ListElement {
            title: "Stock"
            targetPage: "Stock"
            img: "/contents/ui/img/cardlayout.svg"
        }
        ListElement {
            title: "Client"
            targetPage: "Client"
            img: "/contents/ui/img/drawers.svg"
        }
        ListElement {
            title: "Client"
            targetPage: "Client"
            img: "/contents/ui/img/drawers.svg"
        }
    }


    background: Rectangle {
        anchors.fill: parent
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }
    ColumnLayout {
        spacing: 0
        Repeater {
            focus: true
          //  model: applicationWindow().pageStack.wideMode ? filteredModel : 0
            delegate: QQC2.ItemDelegate {
                id: searchDelegate

                required property string title
                required property string targetPage
                required property string img

                Layout.fillWidth: true
                text: title
                action:{
                      applicationWindow().pageStack.layers.push(Qt.createComponent("com.dervox.dim", searchDelegate.targetPage));

                }
            }
        }
        Kirigami.CardsLayout {
            id: cardsLayout
            visible: !applicationWindow().pageStack.wideMode
            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: Kirigami.Units.gridUnit
            Layout.fillWidth: true  // Fill available width

            // Force 2 columns
            maximumColumns: 2

            // Adjust column width limits to ensure the cards fit
            minimumColumnWidth: Kirigami.Units.gridUnit * 15
            maximumColumnWidth: Kirigami.Units.gridUnit * 20

            Repeater {
                focus: true
                model: pagesModel
                delegate: Kirigami.Card {
                    id: listItem

                    required property string title
                    required property string targetPage
                    required property string img

                    // Make card responsive but with constraints
                    Layout.fillWidth: true
                    Layout.preferredWidth: cardsLayout.width / 2 - Kirigami.Units.gridUnit * 5

                    // Create proper action for keyboard handling
                    property Kirigami.Action cardAction: Kirigami.Action {
                        onTriggered: {
                            applicationWindow().pageStack.push(Qt.createComponent("com.dervox.dim", listItem.targetPage));
                        }
                    }

                    banner {
                        source: Qt.resolvedUrl(img)
                        title: title
                        titleAlignment: Qt.AlignBottom | Qt.AlignLeft
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border {
                            width: listItem.activeFocus ? 2 : 0
                            color: Kirigami.Theme.activeTextColor
                        }
                    }
                    activeFocusOnTab: true
                    showClickFeedback: true
                    onClicked: applicationWindow().pageStack.push(Qt.createComponent("com.dervox.dim", listItem.targetPage));

                    // Use the action for keyboard navigation
                    Keys.onReturnPressed: cardAction.trigger()
                    Keys.onEnterPressed: cardAction.trigger()
                    highlighted: false // Remove dependency on action.checked
                }
            }
        }

    }
}
