import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 18

    property string title: ""
    property var model: []
    property string iconCard: ""
    property color accentColor: Kirigami.Theme.highlightColor

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: root.iconCard
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }

            Kirigami.Heading {
                level: 2
                text: root.title
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.model
            clip: true

            delegate: ItemDelegate {
                id: itemDelegate
                width: parent.width
                height: Kirigami.Units.gridUnit * 3

                contentItem: Item {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing * 2
                    // Calculate value width first so we can reserve space for it
                    Label {
                        id: valueLabel
                        visible: false // Just for measurement
                        text: {
                            if (modelData.total_spent)
                                return Number(modelData.total_spent).toFixed(2) + " DH"
                            else if (modelData.total_revenue)
                                return Number(modelData.total_revenue).toFixed(2) + " DH"
                            else
                                return modelData.value || ""
                        }
                        font.bold: true
                    }

                    // Main content with proper spacing
                    RowLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            source: modelData.icon || "package"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0 // Tighter spacing

                            // Reserve right space for the value
                            Layout.rightMargin: valueLabel.width + Kirigami.Units.largeSpacing

                            Label {
                                text: modelData.name || ""
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Label {
                                property int maxWidth: parent.width - Kirigami.Units.largeSpacing

                                text: modelData.description || ""
                                opacity: 0.7
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                elide: Text.ElideRight
                                Layout.preferredWidth: maxWidth
                                Layout.fillWidth: true

                                // Hide if the parent is too narrow to display properly
                                visible: maxWidth > Kirigami.Units.gridUnit * 6
                            }
                        }

                        // Value label - now absolutely positioned to ensure it's visible
                        Label {
                            text: {
                                if (modelData.total_spent)
                                    return Number(modelData.total_spent).toFixed(2) + " DH"
                                else if (modelData.total_revenue)
                                    return Number(modelData.total_revenue).toFixed(2) + " DH"
                                else
                                    return modelData.value || ""
                            }
                            color: root.accentColor
                            font.bold: true
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
