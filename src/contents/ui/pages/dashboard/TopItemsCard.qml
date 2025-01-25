import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.AbstractCard {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: Kirigami.Units.gridUnit * 15

    property string title: ""
    property var model: []
    property string iconCard: ""
    property color accentColor: Kirigami.Theme.highlightColor

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Kirigami.Icon {
                source: root.iconCard
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
            }

            Kirigami.Heading {
                level: 2
                text: root.title
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.model
            clip: true

            delegate: ItemDelegate {
                width: parent.width
                height: Kirigami.Units.gridUnit * 3

                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: modelData.icon || "package"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Label {
                            text: modelData.name || ""
                            font.bold: true
                        }

                        Label {
                            text: modelData.description || ""
                            opacity: 0.7
                        }
                    }

                    Label {
                        text: {
                            if (modelData.total_spent)
                                return "€" + Number(modelData.total_spent).toFixed(2)
                            else if (modelData.total_revenue)
                                return "€" + Number(modelData.total_revenue).toFixed(2)
                            else
                                return modelData.value || ""
                        }
                        color: root.accentColor
                        font.bold: true
                    }
                }
            }
        }
    }
}
