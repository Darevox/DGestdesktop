// CashTransactionPage.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."
import com.dervox.CashTransactionModel 1.0

Kirigami.Page {
    id: root
    title: isSourceView ? sourceViewTitle : i18nc("@title:group", "Cash Transactions")
    property bool isSourceView: false
    property string sourceViewTitle: ""
    property int currentSourceId: -1
    topPadding: 10
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10
    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    function showSourceTransactions(sourceId, sourceName) {
        isSourceView = true
        currentSourceId = sourceId
        sourceViewTitle = i18n("Transactions for %1", sourceName)
        cashTransactionModel.loadTransactionsBySource(sourceId)
    }
    // Summary Drawer
    Kirigami.OverlaySheet {
        id: summarySheet
        header: Kirigami.Heading {
            text: i18n("Transaction Summary")
            level: 2
        }

        FormCard.FormCard {
            Layout.fillWidth: true

            FormCard.FormTextDelegate {
                text: i18n("Total Deposits")
                description: cashTransactionModel.summary.total_deposits || "0.00"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Withdrawals")
                description: cashTransactionModel.summary.total_withdrawals || "0.00"
            }

            FormCard.FormTextDelegate {
                text: i18n("Total Transfers")
                description: cashTransactionModel.summary.total_transfers || "0.00"
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true
            //  title: i18n("Transactions by Type")

            Repeater {
                model: cashTransactionModel.summary.transactions_by_type || []
                delegate: FormCard.FormTextDelegate {
                    text: modelData.type
                    description: i18n("%1 transactions, Total: %2", modelData.count, modelData.total_amount)
                }
            }
        }

        FormCard.FormCard {
            Layout.fillWidth: true
            // title: i18n("Transactions by Source")

            Repeater {
                model: cashTransactionModel.summary.transactions_by_source || []
                delegate: FormCard.FormTextDelegate {
                    text: modelData.name
                    description: i18n("%1 transactions, Total: %2", modelData.count, modelData.total_amount)
                }
            }
        }
    }

    // Filter Drawer
    Kirigami.OverlayDrawer {
        id: filterSheet
        edge: Qt.RightEdge
        modal: true
        handleVisible: false
        width: Kirigami.Units.gridUnit * 30

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                text: i18n("Filter Transactions")
            }

            FormCard.FormCard {
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24

                FormCard.FormComboBoxDelegate {
                    id: typeField
                    text: i18n("Transaction Type")
                    model: [
                        { text: i18n("All"), value: "" },
                        { text: i18n("Deposit"), value: "deposit" },
                        { text: i18n("Withdrawal"), value: "withdrawal" },
                        { text: i18n("Transfer"), value: "transfer" }
                    ]
                    textRole: "text"
                    valueRole: "value"
                    onCurrentValueChanged: cashTransactionModel.setTransactionType(currentValue)
                }

                FormCard.FormDateTimeDelegate {
                    id: startDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18n("Start Date")
                }

                FormCard.FormDateTimeDelegate {
                    id: endDateField
                    dateTimeDisplay: FormCard.FormDateTimeDelegate.DateTimeDisplay.Date
                    text: i18n("End Date")
                }

                FormCard.FormSpinBoxDelegate {
                    id: minAmountField
                    label: i18n("Minimum Amount")
                    from: 0
                    to: 999999999
                }

                FormCard.FormSpinBoxDelegate {

                    id: maxAmountField
                    label: i18n("Maximum Amount")
                    from: 0
                    to: 999999999
                    // decimals: 2
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing

                QQC2.Button {
                    text: i18n("Apply Filters")
                    icon.name: "view-filter"
                    onClicked: {
                        cashTransactionModel.refresh()
                        filterSheet.close()
                    }
                }

                QQC2.Button {
                    text: i18n("Clear Filters")
                    icon.name: "edit-clear-all"
                    onClicked: {
                        typeField.currentIndex = 0
                        startDateField.value = undefined
                        endDateField.value = undefined
                        minAmountField.value = 0
                        maxAmountField.value = 0
                        cashTransactionModel.refresh()
                    }
                }
            }
        }
    }

    // Add Transaction Details Sheet
    CashTransactionDetails {
        id: transactionDetailsSheet
    }

    actions: [
        Kirigami.Action {
            icon.name: "filter"
            text: i18n("Filter")
            onTriggered: filterSheet.open()
        },
        Kirigami.Action {
            icon.name: "view-statistics"
            text: i18n("Summary")
            onTriggered: {
                cashTransactionModel.updateSummary(startDateField.value, endDateField.value)
                summarySheet.open()
            }
        }
    ]

    header: RowLayout {
        Kirigami.Action {
            visible: isSourceView
            onTriggered: {
                isSourceView = false
                currentSourceId = -1
                cashTransactionModel.refresh()
            }
        }
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        QQC2.BusyIndicator {
            running: cashTransactionModel.loading
        }

        Kirigami.SearchField {
            id: searchField
            Layout.margins: Kirigami.Units.smallSpacing
            Layout.preferredWidth: parent.width/4
            Timer {
                id: searchDelayTimer
                interval: 700
                repeat: false
                onTriggered: cashTransactionModel.searchQuery = searchField.text
            }
            onTextChanged: searchDelayTimer.restart()
        }

        Item { Layout.fillWidth: true }
    }

    Kirigami.PlaceholderMessage {
        id: emptyStateMessage
        anchors.centerIn: parent
        visible: !cashTransactionModel.loading && cashTransactionModel.rowCount === 0
        text: searchField.text !== "" ?
                  i18n("No transactions matching '%1'", searchField.text) :
                  i18n("No transactions found")
        explanation: i18n("Transactions will appear here")
        icon.name: "view-list-text"
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: view.width
        visible: !cashTransactionModel.loading && cashTransactionModel.rowCount > 0

        Tables.KTableView {
            id: view
            model: cashTransactionModel
            clip: true
            alternatingRows: true
            sortOrder: cashTransactionModel.sortDirection === "asc" ? Qt.AscendingOrder : Qt.DescendingOrder
            sortRole: CashTransactionRoles.TransactionDateRole
            // modelCheck: cashTransactionModel
            onCellDoubleClicked: function(row) {
                let transaction = cashTransactionModel.getTransaction(row)
                transactionDetailsSheet.transaction = transaction
                transactionDetailsSheet.open()
            }
            headerComponents: [
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Reference")
                    textRole: "referenceNumber"
                    role: CashTransactionRoles.ReferenceNumberRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Type")
                    textRole: "type"
                    role: CashTransactionRoles.TypeRole
                    width: root.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: {
                            switch(modelData) {
                                case "deposit": return i18n("Deposit")
                                case "withdrawal": return i18n("Withdrawal")
                                case "transfer": return i18n("Transfer")
                                default: return modelData || ""
                            }
                        }
                        color: {
                            switch(modelData) {
                                case "deposit": return Kirigami.Theme.positiveTextColor
                                case "withdrawal": return Kirigami.Theme.negativeTextColor
                                default: return Kirigami.Theme.textColor
                            }
                        }
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Amount")
                    textRole: "amount"
                    role: CashTransactionRoles.AmountRole
                    width: root.width * 0.10
                    itemDelegate: QQC2.Label {
                        text: Number(modelData).toLocaleString(Qt.locale(), 'f', 2)
                        horizontalAlignment: Text.AlignRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Category")
                    textRole: "category"
                    role: CashTransactionRoles.CategoryRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Description")
                    textRole: "description"
                    role: CashTransactionRoles.DescriptionRole
                    width: root.width * 0.30
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        elide: Text.ElideRight
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Date")
                    textRole: "transactionDate"
                    role: CashTransactionRoles.TransactionDateRole
                    width: root.width * 0.15
                    itemDelegate: QQC2.Label {
                        text: Qt.formatDateTime(modelData, "dd/MM/yyyy")
                    }
                },
                Tables.HeaderComponent {
                    title: i18nc("@title:column", "Actions")
                    role: Qt.UserRole + 100
                    width: root.width * 0.10
                    itemDelegate: QQC2.Button {
                        icon.name: "view-list-details"
                        text: i18n("Source")
                        onClicked: {
                            let transaction = cashTransactionModel.getTransaction(model.row)
                            transactionDetailsSheet.transaction = transaction
                            transactionDetailsSheet.open()
                        }

                    }
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
        currentPage: cashTransactionModel.currentPage
        totalPages: cashTransactionModel.totalPages
        totalItems: cashTransactionModel.totalItems
        onPageChanged: cashTransactionModel.loadPage(page)
    }

    Component.onCompleted: {
        cashTransactionModel.setApi(cashTransactionApi)
    }
}