// ActivityLogPage.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard

import "../../components"
import "."
import com.dervox.ActivityLogModel 1.0

Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Activity Logs")

    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    property var logTypesModel: ListModel {
        id: logTypesList
        ListElement { text: "All"; value: "" }
        ListElement { text: "Create"; value: "Create" }
        ListElement { text: "Delete"; value: "Delete" }
        ListElement { text: "Update"; value: "Update" }
    }

    property var modelTypesModel: ListModel {
        id: modelTypesList
        ListElement { text: "All"; value: "" }
        ListElement { text: "Product"; value: "Product" }
        ListElement { text: "Barcode"; value: "Barcode" }
    }
    // Left overlay for filters
    Kirigami.OverlayDrawer {
        id: filterSheet

        edge: Qt.RightEdge
        modal: true
        handleVisible : false
        width:  Kirigami.Units.gridUnit * 24


        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30

                FormCard.FormComboBoxDelegate {
                    id: logTypeCombo
                    text: i18nc("@label:listbox", "Log Type")
                    displayMode: FormCard.FormComboBoxDelegate.ComboBox
                    model: logTypesModel
                    textRole: "text"
                    currentIndex:0
                    description: i18n("Filter by type of activity")
                    onCurrentIndexChanged: {
                        if (currentIndex !== -1) {
                            let value = logTypesModel.get(currentIndex).value
                            activityLogModel.filterByLogType(value)
                        }
                    }
                }

                FormCard.FormComboBoxDelegate {
                    id: modelTypeCombo
                    text: i18nc("@label:listbox", "Model Type")
                    displayMode: FormCard.FormComboBoxDelegate.ComboBox
                    model: modelTypesModel
                    textRole: "text"
                    currentIndex:0
                    description: i18n("Filter by type of model")
                    onCurrentIndexChanged: {
                        if (currentIndex !== -1) {
                            let value = modelTypesModel.get(currentIndex).value
                            activityLogModel.filterByModelType(value)
                        }
                    }
                }

                FormCard.FormTextFieldDelegate {
                    id: userIdentifierField
                    label: i18n("User Identifier")
                    text: ""
                    // description: i18n("Filter by user")
                    onTextChanged: activityLogModel.filterByUserIdentifier(text)
                }
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30

                FormCard.FormDateTimeDelegate {
                    id: startDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18nc("@label:listbox", "Start Date")
                    value: undefined
                    onValueChanged: {
                        if (value && endDateField.value) {
                            activityLogModel.filterByDateRange(value, endDateField.value)
                        }
                    }
                }

                FormCard.FormDateTimeDelegate {
                    id: endDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18nc("@label:listbox", "End Date")
                    value: undefined
                    onValueChanged: {
                        if (value && startDateField.value) {
                            activityLogModel.filterByDateRange(startDateField.value, value)
                        }
                    }
                }
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30

                FormCard.FormButtonDelegate {
                    text: i18n("Apply Filters")
                    icon.name: "view-filter"
                    onClicked: {
                        activityLogModel.applyFilters()
                        filterSheet.close()
                    }
                }

                FormCard.FormButtonDelegate {
                    text: i18n("Clear Filters")
                    icon.name: "edit-clear-all"
                    onClicked: {
                        logTypeCombo.currentIndex = 0
                        modelTypeCombo.currentIndex = 0
                        userIdentifierField.text = ""
                        startDateField.value = undefined
                        endDateField.value = undefined
                        activityLogModel.clearFilters()
                    }
                }
            }
        }
    }

    // Statistics overlay using FormCard
    Kirigami.OverlaySheet {
        id: statisticsSheet
        header: Kirigami.Heading {
            text: i18n("Activity Statistics")
            level: 2
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30

                FormCard.FormTextDelegate {
                    text: i18n("Total Logs")
                    description: statisticsModel.totalLogs
                }

                FormCard.FormTextDelegate {
                    text: i18n("Analysis Period")
                    description: i18np("%1 day", "%1 days", statisticsModel.analysisPeriodDays)
                }
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30
                //  title: i18n("Log Type Distribution")

                Repeater {
                    model: statisticsModel.logTypeDistribution
                    delegate: FormCard.FormTextDelegate {
                        text: modelData.type
                        description: i18np("%1 log", "%1 logs", modelData.count)
                    }
                }
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30
                //    title: i18n("Most Active Models")

                Repeater {
                    model: statisticsModel.mostActiveModels
                    delegate: FormCard.FormTextDelegate {
                        text: modelData.modelType
                        description: i18np("%1 action", "%1 actions", modelData.count)
                    }
                }
            }
        }
    }
    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        z: 99
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !activityLogModel.loading && activityLogModel.rowCount === 0
        text: i18n("No activity logs found")
        icon.name: "view-history"
    }

    actions: [
        Kirigami.Action {
            icon.name: "filter"
            text: i18n("Filter")
            onTriggered: filterSheet.open()
        },
        Kirigami.Action {
            icon.name: "overflow-menu"
            Kirigami.Action {
                text: i18n("Export")
                onTriggered: showPassiveNotification(i18n("Export feature coming soon"))
            }
            Kirigami.Action {
                text: i18n("Statistics")
                onTriggered: statisticsSheet.open()
            }
        }
    ]

    header: RowLayout {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        QQC2.BusyIndicator {
            running: activityLogModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: {
                    activityLogModel.filterByUserIdentifier(searchField.text)
                    activityLogModel.applyFilters()
                }
            }

            onTextChanged: searchDelayTimer.restart()
        }

        Item {
            Layout.fillWidth: true
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !activityLogModel.loading && activityLogModel.rowCount > 0

        DKTableView {
            id: view
            enabled: !activityLogModel.loading
            model: activityLogModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder: activityLogModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: ActivityLogRoles.CreatedAtRole

            contentWidth: parent.width

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "ID")
                    textRole: "id"
                    role: ActivityLogRoles.IdRole
                    minimumWidth: root.width * 0.05
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Log Type")
                    textRole: "logType"
                    role: ActivityLogRoles.LogTypeRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Model Type")
                    textRole: "modelType"
                    role: ActivityLogRoles.ModelTypeRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Model ID")
                    textRole: "modelIdentifier"
                    role: ActivityLogRoles.ModelIdentifierRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "User")
                    textRole: "userIdentifier"
                    role: ActivityLogRoles.UserIdentifierRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Created At")
                    textRole: "createdAt"
                    role: ActivityLogRoles.CreatedAtRole
                    minimumWidth: root.width * 0.15
                    width: minimumWidth
                }
            ]
        }
    }

    footer: PaginationBar {
        id: paginationBar
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        currentPage: activityLogModel.currentPage
        totalPages: activityLogModel.totalPages
        totalItems: activityLogModel.totalItems
        onPageChanged: activityLogModel.loadPage(page)
    }


    Component.onCompleted: {
        activityLogModel.setApi(activityLogApi)
    }
}
