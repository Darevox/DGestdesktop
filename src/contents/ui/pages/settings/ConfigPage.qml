// ConfigPage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami

Kirigami.Page {
    id: configPage
    title: i18nc("@title:window", "Settings")

    // Directly define the modules in the expected format
    property var modulesList: []
    // Default module to open
    property string defaultModule: ""

    // Debug helper
    function debugLog(message) {
        console.log("[ConfigPage] " + message);
    }

    Component.onCompleted: {
        debugLog("ConfigPage created with " + modulesList.length + " modules");
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar with modules list
        Controls.ScrollView {
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 15
            contentWidth: availableWidth

            ListView {
                id: categoriesView
                model: modulesList
                clip: true

                // Initial selection
                Component.onCompleted: {
                    debugLog("ListView completed, items count: " + count);

                    if (defaultModule && count > 0) {
                        for (let i = 0; i < count; i++) {
                            if (modulesList[i].moduleId === defaultModule) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }

                    if (count > 0) {
                        contentLoader.source = modulesList[currentIndex].pageUrl;
                    }
                }

                // Delegate for module items
                delegate: Controls.ItemDelegate {
                    required property var modelData
                    required property int index

                    width: categoriesView.width
                    highlighted: ListView.isCurrentItem

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            source: modelData.icon.name
                        }

                        Controls.Label {
                            text: modelData.text
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    onClicked: {
                        debugLog("Clicked on module: " + modelData.moduleId + ", URL: " + modelData.pageUrl);
                        categoriesView.currentIndex = index;
                        contentLoader.source = modelData.pageUrl;
                    }
                }

                section {
                    property: "category"
                    delegate: Kirigami.ListSectionHeader {
                        required property string section
                        label: section
                        visible: section !== ""  // Only show if there's a category
                        width: categoriesView.width
                    }
                }
            }
        }

        // Visual separator
        Kirigami.Separator {
            Layout.fillHeight: true
        }

        // Module content area
        Item {
            id: contentContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loader for the content
            Loader {
                id: contentLoader
                anchors.fill: parent

                onStatusChanged: {
                    if (status === Loader.Error) {
                        debugLog("ERROR: Failed to load component: " + source);
                    } else if (status === Loader.Ready) {
                        debugLog("Component loaded successfully: " + source);
                    }
                }

                // Show a busy indicator while loading
                Controls.BusyIndicator {
                    anchors.centerIn: parent
                    running: contentLoader.status === Loader.Loading
                    visible: running
                }
            }
        }
    }
}
