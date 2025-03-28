// languageAndLocalizationPage.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import "../../components"
import "../team/"

FormCard.FormCardPage {
    id: languageAndLocalizationPage
    title: i18nc("@title", "Language & Localization")

    property int teamId: 0
    property var teamData: ({})
    property bool isLoading: teamApi.isLoading
    property string currentLocale: teamData.locale || "en"

    // Loading indicator
    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: isLoading
        visible: running
        z: 999
    }

    // Error message display
    Kirigami.InlineMessage {
        id: inlineMsg
        Layout.fillWidth: true
        showCloseButton: true
        visible: false
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Kirigami.Units.largeSpacing
        }
    }

    // Main content
    ColumnLayout {
        anchors {
            fill: parent
            topMargin: inlineMsg.visible ? inlineMsg.height + Kirigami.Units.largeSpacing : 0
            leftMargin: Kirigami.Units.largeSpacing
            rightMargin: Kirigami.Units.largeSpacing
        }
        spacing: Kirigami.Units.largeSpacing
        enabled: !isLoading

        FormCard.FormHeader {
            title: i18nc("@title:group", "Language & Localization")
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormComboBoxDelegate {
                id: languageComboBox
                text: i18n("Language")
                model: ListModel {
                    id: languagesModel
                    ListElement { text: "English"; value: "en" }
                    ListElement { text: "Français"; value: "fr" }
                    // ListElement { text: "العربية"; value: "ar" }
                }
                textRole: "text"
                valueRole: "value"
                currentIndex: {
                    for (let i = 0; i < languagesModel.count; i++) {
                        if (languagesModel.get(i).value === currentLocale) {
                            return i;
                        }
                    }
                    return 0; // Default to English if no match
                }
                onActivated: {
                    let newLocale = languagesModel.get(currentIndex).value;
                    console.log("New locale selected:", newLocale, "Current locale:", currentLocale);
                    if (newLocale !== currentLocale) {
                        teamApi.updateTeamLocale(teamData.id, newLocale);
                    }
                }
            }

            FormCard.FormTextDelegate {
                text: i18n("Language setting affects invoices and documents")
                description: i18n("Choose the language for this team's documents")
            }
        }

        // Add spacer to push content up
        Item {
            Layout.fillHeight: true
        }
    }

    Connections {
        target: teamApi

        function onTeamReceived(team) {
            console.log("Team received:", JSON.stringify(team));
            languageAndLocalizationPage.teamData = team;

            // Update locale if available
            if (team.locale) {
                currentLocale = team.locale;
                updateComboBoxSelection();
            }
        }

        function onLocaleReceived(locale) {
            console.log("Locale received:", locale);
            currentLocale = locale;
            updateComboBoxSelection();
        }

        function onLocaleUpdated(locale) {
            console.log("Locale updated:", locale);
            currentLocale = locale;
            applicationWindow().gnotification.showNotification(
                "",
                i18n("Team language updated successfully"),
                Kirigami.MessageType.Positive,
                "short"
            );
        }

        function onLocaleError(message, status, details) {
            console.error("Locale error:", message, status, details);
            inlineMsg.text = message;
            inlineMsg.visible = true;
            inlineMsg.type = Kirigami.MessageType.Error;
        }
    }

    // Helper function to update combo box selection
    function updateComboBoxSelection() {
        for (let i = 0; i < languagesModel.count; i++) {
            if (languagesModel.get(i).value === currentLocale) {
                languageComboBox.currentIndex = i;
                break;
            }
        }
    }

    Component.onCompleted: {
        console.log("Language page completed");

        // Initialize with current team ID
        languageAndLocalizationPage.teamId = api.getTeamId();
        console.log("Team ID:", languageAndLocalizationPage.teamId);

        // Fetch team data
        if (languageAndLocalizationPage.teamId > 0) {
            console.log("Fetching team data for team ID:", languageAndLocalizationPage.teamId);
            teamApi.getTeam(languageAndLocalizationPage.teamId);
            teamApi.getTeamLocale(languageAndLocalizationPage.teamId);
        } else {
            console.log("Invalid team ID:", languageAndLocalizationPage.teamId);
        }
    }
}
