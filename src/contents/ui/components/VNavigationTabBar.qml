import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

ListView {
    id: root
    width: parent.width
    height: parent.height
    property bool drawerCollapsed: false

    model: ListModel {
        ListElement {
            name: "Dashboard"
            icon: "dashboard-show"
            pathPage: "qrc:/DGest/contents/ui/pages/Welcome.qml"
        }
        ListElement {
            name: "Cashier"
            icon: "view-financial-account-cash"
            pathPage: "qrc:/DGest/contents/ui/pages/Cashier.qml"
        }
        ListElement {
            name: "Stock"
            icon: "package"
            pathPage: "qrc:/DGest/contents/ui/pages/Stock.qml"
        }
        ListElement {
            name: "Sales"
            icon: "view-financial-account-savings"
            pathPage: "qrc:/DGest/contents/ui/pages/Sales.qml"
        }
        ListElement {
            name: "Purchases"
            icon: "view-financial-account-investment"
            pathPage: "qrc:/DGest/contents/ui/pages/Purchases.qml"
        }
        ListElement {
            name: "Clients"
            icon: "group"
            pathPage: "qrc:/DGest/contents/ui/pages/Clients.qml"
        }
        ListElement {
            name: "Suppliers"
            icon: "kr_setjumpback"
            pathPage: "qrc:/DGest/contents/ui/pages/Suppliers.qml"
        }
        ListElement {
            name: "Accounts"
            icon: "im-user"
            pathPage: "qrc:/DGest/contents/ui/pages/Accounts.qml"
        }
        ListElement {
            name: "Settings"
            icon: "settings-configure"
            pathPage: "qrc:/DGest/contents/ui/pages/Settings.qml"
        }
    }

    delegate: QQC2.ItemDelegate {
        width: ListView.view.width
        height: !root.drawerCollapsed ? 50 : 40
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                Layout.preferredWidth: !root.drawerCollapsed ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.small
                Layout.preferredHeight: !root.drawerCollapsed ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.small
                source: model.icon
                color: root.currentIndex === index ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: model.name
                visible: !root.drawerCollapsed
                color: root.currentIndex === index ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }
        }
        onClicked: {
            root.currentIndex = index
            applicationWindow().pageStack.replace(Qt.resolvedUrl(model.pathPage))
        }
        background: Rectangle {
            color: root.currentIndex === index ?
                       Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) :
                       "transparent"
        }
    }
}
