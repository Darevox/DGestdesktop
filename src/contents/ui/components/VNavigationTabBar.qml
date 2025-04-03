import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

ListView {
    id: root
    width: parent.width
    height: parent.height  // Use full height of parent
    clip: true  // Enable clipping to prevent items from appearing outside the ListView

    // Enable scrolling
    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                       policy: QQC2.ScrollBar.AlwaysOff
                       visible: false
                   }

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

    // Function to toggle category expansion
    function toggleCategory(categoryIndex) {
        // Get the category from the model
        var category = navigationModel.get(categoryIndex);
        var wasExpanded = category.expanded;

        // Toggle the expanded state
        navigationModel.setProperty(categoryIndex, "expanded", !wasExpanded);

        // Find all items for this category
        var categoryObj = navCategories[category.categoryId];

        if (wasExpanded) {
            // If it was expanded, remove all items for this category
            var i = categoryIndex + 1;
            while (i < navigationModel.count &&
                   navigationModel.get(i).type === "item" &&
                   navigationModel.get(i).categoryId === category.categoryId) {
                navigationModel.remove(i);
            }
        } else {
            // If it was collapsed, add all items for this category
            for (var j = 0; j < categoryObj.items.length; j++) {
                navigationModel.insert(categoryIndex + j + 1, {
                    type: "item",
                    name: categoryObj.items[j].name,
                    icon: categoryObj.items[j].icon,
                    pathPage: categoryObj.items[j].pathPage,
                    categoryId: category.categoryId
                });
            }
        }
    }

    // Store our navigation categories
    property var navCategories: ({})

    model: ListModel {
        id: navigationModel
        // We'll populate this in Component.onCompleted
    }

    delegate: Loader {
        width: ListView.view.width

        property var delegateModel: model
        property int delegateIndex: index

        sourceComponent: model.type === "category" ? categoryComponent : itemComponent

        Component {
            id: categoryComponent

            QQC2.ItemDelegate {
                width: parent.width
                height: root.drawerCollapsed ? Kirigami.Units.gridUnit * 1.5 : Kirigami.Units.gridUnit * 2.5

                contentItem: RowLayout {
                    spacing: 0
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.largeSpacing * 2
                    anchors.rightMargin: Kirigami.Units.largeSpacing * 2
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    anchors.bottomMargin: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: delegateModel.name
                        font.bold: true
                        visible: !root.drawerCollapsed
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                    }

                    // Kirigami.Icon {
                    //     Layout.preferredWidth: !root.drawerCollapsed ? Kirigami.Units.iconSizes.small : 0
                    //     Layout.preferredHeight: !root.drawerCollapsed ? Kirigami.Units.iconSizes.small : 0
                    //     source: delegateModel.expanded ? "go-down-symbolic" : "go-next-symbolic"
                    //     visible: !root.drawerCollapsed
                    //     color: Kirigami.Theme.textColor
                    // }
                }

                background: Rectangle {
                    color: root.drawerCollapsed
                        ? "transparent"
                        : Qt.rgba(Kirigami.Theme.highlightColor.r,
                                 Kirigami.Theme.highlightColor.g,
                                 Kirigami.Theme.highlightColor.b, 0.06)


                    // Add a bottom border
                    Rectangle {
                        width: parent.width
                        height: 1
                        anchors.bottom: parent.bottom
                        color: Qt.rgba(Kirigami.Theme.textColor.r,
                                      Kirigami.Theme.textColor.g,
                                      Kirigami.Theme.textColor.b, 0.1)
                        visible: !root.drawerCollapsed
                    }
                }

                onClicked: {
                    if (!root.drawerCollapsed) {
                       // root.toggleCategory(delegateIndex);
                    }
                }
            }
        }

        Component {
            id: itemComponent

            QQC2.ItemDelegate {
                width: parent.width
                height: !root.drawerCollapsed ? Kirigami.Units.gridUnit * 2.5 : Kirigami.Units.gridUnit * 2

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    // Indent for items
                    Item {
                        width: !root.drawerCollapsed ? Kirigami.Units.largeSpacing : 0
                        visible: !root.drawerCollapsed
                    }

                    Kirigami.Icon {
                        Layout.preferredWidth: !root.drawerCollapsed ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: !root.drawerCollapsed ? Kirigami.Units.iconSizes.medium : Kirigami.Units.iconSizes.small
                        source: delegateModel.icon
                        color: root.currentIndex === delegateIndex ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: delegateModel.name
                        visible: !root.drawerCollapsed
                        color: root.currentIndex === delegateIndex ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        font.bold: root.currentIndex === delegateIndex
                    }
                }

                background: Rectangle {
                    color: root.currentIndex === delegateIndex ?
                        Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2) :
                        "transparent"
                }

                onClicked: {
                    root.currentIndex = delegateIndex;

                    // Special handling for Settings
                    if (delegateModel.pathPage === "Settings") {
                        console.log("Settings clicked, pushing ConfigPage with " + root.settingsModules.length + " modules");

                        applicationWindow().pageStack.replace(
                            Qt.resolvedUrl("qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/ConfigPage.qml"),
                            {
                                modulesList: root.settingsModules,
                                defaultModule: ""
                            }
                        );
                    } else {
                        applicationWindow().pageStack.replace(Qt.createComponent("com.dervox.dim", delegateModel.pathPage));
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // Define categories and their items
        navCategories = {
            "main": {
                name: i18n("Main"),
                expanded: true,
                items: [
                    {
                        name: i18n("Dashboard"),
                        icon: "dashboard-show",
                        pathPage: "Dashboard"
                    },
                    {
                        name: i18n("Quick Sale"),
                        icon: "view-financial-category-income",
                        pathPage: "QuickSalePage"
                    }
                ]
            },
            "finance": {
                name: i18n("Finance"),
                expanded: true,
                items: [
                    {
                        name: i18n("Cashier"),
                        icon: "view-financial-account-cash",
                        pathPage: "CashSource"
                    },
                    {
                        name: i18n("Cash Transaction"),
                        icon: "view-financial-account-reopen",
                        pathPage: "CashTransaction"
                    },
                    {
                        name: i18n("Invoices"),
                        icon: "view-financial-account-checking",
                        pathPage: "Invoice"
                    }
                ]
            },
            "inventory": {
                name: i18n("Inventory"),
                expanded: true,
                items: [
                    {
                        name: i18n("Stock"),
                        icon: "package",
                        pathPage: "Products"
                    },
                    {
                        name: i18n("Purchases"),
                        icon: "view-financial-account-investment",
                        pathPage: "Purchase"
                    }
                ]
            },
            "business": {
                name: i18n("Business"),
                expanded: true,
                items: [
                    {
                        name: i18n("Activity Log"),
                        icon: "view-calendar-list",
                        pathPage: "ActivityLog"
                    },
                    {
                        name: i18n("Sales"),
                        icon: "view-financial-account-savings",
                        pathPage: "Sale"
                    },
                    {
                        name: i18n("Quotes"),
                        icon: "view-financial-account-savings",
                        pathPage: "Quote"
                    },
                    {
                        name: i18n("Clients"),
                        icon: "group",
                        pathPage: "Client"
                    },
                    {
                        name: i18n("Suppliers"),
                        icon: "kr_setjumpback",
                        pathPage: "Supplier"
                    }
                ]
            },
            "system": {
                name: i18n("System"),
                expanded: true,
                items: [
                    {
                        name: i18n("Settings"),
                        icon: "settings-configure",
                        pathPage: "Settings"
                    }
                ]
            }
        };

        // Populate navigation model
        var categoryOrder = ["main", "finance", "inventory", "business", "system"];
        var dashboardItemIndex = -1;

        // Add categories and their items to the model
        for (var i = 0; i < categoryOrder.length; i++) {
            var catId = categoryOrder[i];
            var category = navCategories[catId];

            // Add the category header
            navigationModel.append({
                type: "category",
                name: category.name,
                expanded: category.expanded,
                categoryId: catId
            });

            // If category is expanded, add its items
            if (category.expanded) {
                for (var j = 0; j < category.items.length; j++) {
                    var item = category.items[j];
                    navigationModel.append({
                        type: "item",
                        name: item.name,
                        icon: item.icon,
                        pathPage: item.pathPage,
                        categoryId: catId
                    });

                    // Remember the dashboard index for initial selection
                    if (item.pathPage === "Dashboard") {
                        dashboardItemIndex = navigationModel.count - 1;
                    }
                }
            }
        }

        // Set initial selection and load the dashboard
        if (dashboardItemIndex !== -1) {
            root.currentIndex = dashboardItemIndex;
        }
        applicationWindow().pageStack.replace(Qt.createComponent("com.dervox.dim", "Dashboard"));
    }

    // Minimal spacing between items
    spacing: 1
}
