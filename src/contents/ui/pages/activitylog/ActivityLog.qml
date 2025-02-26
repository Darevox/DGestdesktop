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
//TODO Fix sorting in table
Kirigami.Page {
    id: root
    title: i18nc("@title:group", "Activity Logs")

    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    property ListModel logTypesModel: ListModel {
        id: logTypesList
        Component.onCompleted: {
            append({ text: i18n("All"), value: "" })
            append({ text: i18n("Create"), value: "Create" })
            append({ text: i18n("Delete"), value: "Delete" })
            append({ text: i18n("Update"), value: "Update" })
            append({ text: i18n("Download"), value: "download" })
            append({ text: i18n("Send"), value: "send" })
            append({ text: i18nc("@item:inlistbox Status update", "Status Update"), value: "status update" })
            append({ text: i18n("Payment"), value: "payment" })
            append({ text: i18nc("@item:inlistbox Price update", "Price Update"), value: "price update" })
            append({ text: i18n("Transfer"), value: "transfer" })
            append({ text: i18n("Deposit"), value: "Withdrawal" })
        }
    }

    property ListModel modelTypesModel: ListModel {
        id: modelTypesList
        Component.onCompleted: {
            append({ text: i18n("All"), value: "" })
            append({ text: i18n("Product"), value: "Product" })
            append({ text: i18nc("@item:inlistbox", "Cash Source"), value: "cashsource" })
            append({ text: i18n("Purchase"), value: "purchase" })
            append({ text: i18n("Sale"), value: "sale" })
            append({ text: i18n("Invoice"), value: "invoice" })
            append({ text: i18n("Client"), value: "client" })
            append({ text: i18n("Supplier"), value: "supplier" })
        }
    }

    // Left overlay for filters
    Kirigami.OverlayDrawer {
        id: filterSheet

        edge: Qt.RightEdge
        modal: true
        handleVisible : false
        width:  Kirigami.Units.gridUnit * 30


        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Heading{
                text:i18n("Filtering")

            }
            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

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
                        let value = modelTypesModel.get(currentIndex).value
                        console.log("VVVVVVVVV : ",value)
                        if (currentIndex !== -1) {
                            let value = modelTypesModel.get(currentIndex).value
                            console.log("VVVVVVVVV 2: ",value)
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
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

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
                    Component.onCompleted : {
                        let oneMonthAgo = new Date()
                        oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1)
                        value = oneMonthAgo

                    }
                }

                FormCard.FormDateTimeDelegate {
                    id: endDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18nc("@label:listbox", "End Date")
                    value:  new Date()
                    onValueChanged: {
                        if (value && startDateField.value) {
                            activityLogModel.filterByDateRange(startDateField.value, value)
                        }
                    }
                }
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

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
                        let oneMonthAgo = new Date()
                        oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1)
                        startDateField.value = oneMonthAgo

                        // Set end date to current date/time
                        endDateField.value = new Date()
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
            icon.name: "view-filter"
            text: i18n("Filter")
            onTriggered: filterSheet.open()
        }
        // Kirigami.Action {
        //     icon.name: "overflow-menu"
        //     Kirigami.Action {
        //         text: i18n("Export")
        //         onTriggered: showPassiveNotification(i18n("Export feature coming soon"))
        //     }
        //     Kirigami.Action {
        //         text: i18n("Statistics")
        //         onTriggered: statisticsSheet.open()
        //     }
        // }
    ]

    header: RowLayout {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        DBusyIndicator {
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

        Tables.KTableView {
            id: view
            enabled: !activityLogModel.loading
            model: activityLogModel
            interactive: false
            clip: true
            alternatingRows: true
            sortOrder: activityLogModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: ActivityLogRoles.CreatedAtRole
            selectionMode: TableView.SelectionMode.SingleSelection
            selectionBehavior: TableView.SelectRows
            contentWidth: parent.width
            property var nonSortableColumns: {
                   return {

                   }
               }

            // onColumnClicked: function (index, headerComponent) {
            //     if (Object.keys(nonSortableColumns).includes(String(headerComponent.role)) ||
            //             Object.values(nonSortableColumns).includes(headerComponent.textRole)) {
            //         return; // Exit if column shouldn't be sortable
            //     }
            //     if (view.sortRole !== headerComponent.role) {

            //         activityLogModel.sortField=headerComponent.textRole
            //         activityLogModel.sortDirection="asc"

            //         view.sortRole = headerComponent.role;

            //         view.sortOrder = Qt.AscendingOrder;

            //     } else {
            //         //view.sortOrder = view.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder
            //         // view.sortOrder = view.sortOrder === "asc" ? "desc": "asc"
            //         activityLogModel.sortDirection=view.sortOrder === Qt.AscendingOrder ? "desc" : "asc"
            //         view.sortOrder = activityLogModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder



            //     }

            //     view.model.sort(view.sortRole, view.sortOrder);

            //     // After sorting we need update selection
            //     __resetSelection();
            // }

            function __resetSelection() {
                // NOTE: Making a forced copy of the list
                let selectedIndexes = Array(...view.selectionModel.selectedIndexes)

                let currentRow = view.selectionModel.currentIndex.row;
                let currentColumn = view.selectionModel.currentIndex.column;

                view.selectionModel.clear();
                for (let i in selectedIndexes) {
                    view.selectionModel.select(selectedIndexes[i], ItemSelectionModel.Select);
                }

                view.selectionModel.setCurrentIndex(view.model.index(currentRow, currentColumn), ItemSelectionModel.Select);
            }

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Nº")
                    textRole: "id"
                    role: ActivityLogRoles.IdRole
                    width: root.width * 0.05
                    itemDelegate: QQC2.Label {
                        text: modelData
                        horizontalAlignment: Text.AlignRight
                        font.weight: Font.Medium
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Log Type")
                    textRole: "logType"
                    role: ActivityLogRoles.LogTypeRole
                    width: root.width * 0.20
                    itemDelegate: QQC2.Label {
                        text: {
                                for (let i = 0; i < logTypesModel.count; i++) {
                                    if (logTypesModel.get(i).value.toLowerCase() === modelData.toLowerCase()) {
                                        return logTypesModel.get(i).text;
                                    }
                                }
                                return modelData;
                            }
                        color: {
                            switch(modelData.toLowerCase()) {
                                case 'create': return Kirigami.Theme.positiveTextColor;
                                case 'update': return Kirigami.Theme.neutralTextColor;
                                case 'delete': return Kirigami.Theme.negativeTextColor;
                                default: return Kirigami.Theme.textColor;
                            }
                        }
                        font.weight: Font.Medium
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Model Type")
                    textRole: "modelType"
                    role: ActivityLogRoles.ModelTypeRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        //  text: modelData
                        color: Kirigami.Theme.neutralTextColor
                        text: {
                                 // Find the matching text in modelTypesModel
                                 for (let i = 0; i < modelTypesModel.count; i++) {
                                     if (modelTypesModel.get(i).value.toLowerCase() === modelData.toLowerCase()) {
                                         return modelTypesModel.get(i).text;
                                     }
                                 }
                                 return modelData;
                             }
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Model ID")
                    textRole: "modelIdentifier"
                    role: ActivityLogRoles.ModelIdentifierRole
                    width:  root.width * 0.18
                    itemDelegate: QQC2.Label {
                        text: modelData
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignLeft
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "User")
                    textRole: "userIdentifier"
                    role: ActivityLogRoles.UserIdentifierRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: modelData
                        elide: Text.ElideRight
                        font.weight: Font.Medium
                    }
                    headerDelegate: TableHeaderLabel {}
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Created At")
                    textRole: "createdAt"
                    role: ActivityLogRoles.CreatedAtRole
                    width: root.width * 0.25
                    itemDelegate: QQC2.Label {
                        text: {
                            // Assuming createdAt is a valid date string or timestamp
                            let date = new Date(modelData);
                            return Qt.formatDateTime(date, "yyyy-MM-dd HH:mm:ss");
                        }
                        horizontalAlignment: Text.AlignRight
                        font.family: "Monospace"
                    }
                    headerDelegate: TableHeaderLabel {}
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
    Connections {
        target: activityLogApi

        function onLogError(message, status, details) {
            applicationWindow().gnotification.showNotification("",
                                                               message, // message
                                                               Kirigami.MessageType.Error, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )

        }
    }

    Component.onCompleted: {
        activityLogModel.setApi(activityLogApi)
    }
}
