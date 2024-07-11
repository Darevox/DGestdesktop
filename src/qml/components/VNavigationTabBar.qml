import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

ListView {
    id: root
    width: parent.width
    height: parent.height

    property bool drawerCollapsed: false
    model: ListModel {
        ListElement { name: "Dashboard"; icon: "dashboard-show" }
        ListElement { name: "Cashier"; icon: "view-financial-account-cash" }
        ListElement { name: "Stock"; icon: "package" }
        ListElement { name: "Sales"; icon: "view-financial-account-savings" }
        ListElement { name: "Purchases"; icon: "view-financial-account-investment" }
        ListElement { name: "Clients"; icon: "group" }
        ListElement { name: "Suppliers"; icon: "kr_setjumpback" }
        ListElement { name: "Accounts"; icon: "im-user" }
        ListElement { name: "Settings"; icon: "settings-configure" }


    }
    delegate: ItemDelegate {
        width: ListView.view.width
        height: !root.drawerCollapsed ? 50 : 40
        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: !root.drawerCollapsed ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.small
                Layout.preferredHeight: !root.drawerCollapsed ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.small
                // Layout.preferredWidth: Kirigami.Units.iconSizes.small
                // Layout.preferredHeight: Kirigami.Units.iconSizes.small
                source: model.icon
                color: root.currentIndex === index ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }
            Label {
                Layout.fillWidth: true
                text: model.name
                visible: !root.drawerCollapsed
                color: root.currentIndex === index ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }
        }
        onClicked: root.currentIndex = index
        background: Rectangle {
            color: root.currentIndex === index ?
                       Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) :
                       "transparent"
        }
    }
}
