import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

ListView {
                   id: root
                   width: parent.width
                   height: contentHeight
                   property bool drawerCollapsed: false
                   property var settingsModules: [
                                      {
                                                         moduleId: "general",
                                                         text: i18nc("@action:button", "Appearance"),
                                                         icon: { name: "configure" },
                                                         pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/GeneralSettingsPage.qml",
                                                         category: "General"
                                      },
                                      {
                                                         moduleId: "accounts",
                                                         text: i18nc("@action:button", "Accounts & Subscriptions"),
                                                         icon: { name: "user" },
                                                         pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/AccountsSettingsPage.qml",
                                                         category: "General"
                                      },
                                      {
                                                         moduleId: "team",
                                                         text: i18nc("@action:button", "Team information"),
                                                         icon: { name: "gnumeric-group" },
                                                         pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/TeamSettingsPage.qml",
                                                         category: "Team Settings"
                                      },
                                      {
                                                         moduleId: "invoice",
                                                         text: i18nc("@action:button", "Language & Localization"),
                                                         icon: { name: "set-language" },
                                                         pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/LanguageAndLocalization.qml",
                                                         category: "Invoice & Receipt"
                                      },
                                      {
                                                         moduleId: "invoice",
                                                         text: i18nc("@action:button", "Document Settings"),
                                                         icon: { name: "document-properties" },
                                                         pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/DocumentSettingsPage.qml",
                                                         category: "Invoice & Receipt"
                                      },
                                      {
                                                         moduleId: "about",
                                                         text: i18nc("@action:button", "About DIM"),
                                                         icon: { name: "documentinfo" },
                                                         pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/AboutSettingsPage.qml",
                                                         category: i18nc("@title:group", "About")
                                      }
                   ]

                   model: ListModel {
                                      id: navigationModel
                                      Component.onCompleted: {
                                                         // Add items dynamically
                                                         append({
                                                                                   name: i18n("Dashboard"),
                                                                                   icon: "dashboard-show",
                                                                                   pathPage: "Dashboard"
                                                                });
                                                         append({
                                                                                   name: i18n("Quick Sale"),
                                                                                   icon: "view-financial-category-income",
                                                                                   pathPage: "QuickSalePage"
                                                                });
                                                         append({
                                                                                   name: i18n("Cashier"),
                                                                                   icon: "view-financial-account-cash",
                                                                                   pathPage: "CashSource"
                                                                });
                                                         append({
                                                                                   name: i18n("Cash Transaction"),
                                                                                   icon: "view-financial-account-reopen",
                                                                                   pathPage: "CashTransaction"
                                                                });
                                                         append({
                                                                                   name: i18n("Invoices"),
                                                                                   icon: "view-financial-account-checking",
                                                                                   pathPage: "Invoice"
                                                                });
                                                         append({
                                                                                   name: i18n("Stock"),
                                                                                   icon: "package",
                                                                                   pathPage: "Products"
                                                                });
                                                         append({
                                                                                   name: i18n("Activity Log"),
                                                                                   icon: "view-calendar-list",
                                                                                   pathPage: "ActivityLog"
                                                                });
                                                         append({
                                                                                   name: i18n("Sales"),
                                                                                   icon: "view-financial-account-savings",
                                                                                   pathPage: "Sale"
                                                                });
                                                         append({
                                                                                   name: i18n("Purchases"),
                                                                                   icon: "view-financial-account-investment",
                                                                                   pathPage: "Purchase"
                                                                });
                                                         append({
                                                                                   name: i18n("Clients"),
                                                                                   icon: "group",
                                                                                   pathPage: "Client"
                                                                });
                                                         append({
                                                                                   name: i18n("Suppliers"),
                                                                                   icon: "kr_setjumpback",
                                                                                   pathPage: "Supplier"
                                                                });
                                                         // append({
                                                         //     name: i18n("Accounts"),
                                                         //     icon: "im-user",
                                                         //     pathPage: "Accounts"
                                                         // });
                                                         append({
                                                                                   name: i18n("Settings"),
                                                                                   icon: "settings-configure",
                                                                                   pathPage: "Settings"
                                                                });
                                      }
                   }
                   delegate: QQC2.ItemDelegate {
                                      width: ListView.view.width
                                      height: !root.drawerCollapsed ? Kirigami.Units.gridUnit * 4 : Kirigami.Units.gridUnit * 2
                                      contentItem: RowLayout {
                                                         spacing: Kirigami.Units.smallSpacing
                                                         Kirigami.Icon {
                                                                            Layout.preferredWidth: !root.drawerCollapsed ? Kirigami.Units.iconSizes.large : Kirigami.Units.iconSizes.small
                                                                            Layout.preferredHeight: !root.drawerCollapsed ? Kirigami.Units.iconSizes.large : Kirigami.Units.iconSizes.small
                                                                            source: model.icon
                                                                            color: root.currentIndex === index ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                                         }
                                                         QQC2.Label {
                                                                            Layout.fillWidth: true
                                                                            text: model.name
                                                                            visible: !root.drawerCollapsed
                                                                            color: root.currentIndex === index ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                                                            font.bold:true
                                                         }
                                      }
                                      onClicked: {
                                                         root.currentIndex = index

                                                         // Special handling for Settings
                                                         if (model.pathPage === "Settings") {
                                                                            console.log("Settings clicked, pushing ConfigPage with " + root.settingsModules.length + " modules");

                                                                            // Push the settings page
                                                                            applicationWindow().pageStack.replace(
                                                                                                                                     Qt.resolvedUrl("qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/ConfigPage.qml"),
                                                                                                                                     {
                                                                                                                                                        modulesList: root.settingsModules,
                                                                                                                                                        defaultModule: ""
                                                                                                                                     }
                                                                                                                                     );
                                                         } else {
                                                                            // Normal page handling for other menu items
                                                                            applicationWindow().pageStack.replace(Qt.createComponent("com.dervox.dim", model.pathPage));
                                                         }
                                      }
                                      background: Rectangle {
                                                         color: root.currentIndex === index ?
                                                                                   Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) :
                                                                                   "transparent"
                                      }
                   }
                   Component.onCompleted: {
                                      root.currentIndex=1
                                      applicationWindow().pageStack.replace( Qt.createComponent("com.dervox.dim", "Dashboard"))
                   }
}
