// In your main file (where your settings button is)
import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import org.kde.kirigami 2.19 as Kirigami

Controls.Button {
    id: settingsButton

    icon.name: 'settings-configure-symbolic'
    text: i18nc("@action:button", "Settings")

    // Define your settings modules
    property var settingsModules: [
        {
            moduleId: "general",
            text: i18nc("@action:button", "General"),
            icon: { name: "configure" },
            pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/GeneralSettingsPage.qml",
            category: "General"
        },
        {
            moduleId: "team",
            text: i18nc("@action:button", "Team Settings"),
            icon: { name: "gnumeric-group" },
            pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/TeamSettingsPage.qml",
            category: ""
        },
        {
            moduleId: "accounts",
            text: i18nc("@action:button", "Accounts"),
            icon: { name: "user" },
            pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/AccountsSettingsPage.qml",
            category: ""
        },
        {
            moduleId: "about",
            text: i18nc("@action:button", "About DIM"),
            icon: { name: "documentinfo" },
            pageUrl: "qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/AboutSettingsPage.qml",
            category: i18nc("@title:group", "About")
        }
    ]

    onClicked: {
        console.log("Settings button clicked, pushing ConfigPage with " + settingsModules.length + " modules");

        // Push the settings page to the page stack
        applicationWindow().pageStack.replace(
            Qt.resolvedUrl("qrc:/qt/qml/com/dervox/dim/contents/ui/pages/settings/ConfigPage.qml"),
            {
                modulesList: settingsModules,
                defaultModule: ""
            }
        );
    }

}
