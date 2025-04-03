import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../components"

Kirigami.Dialog {
    id: statisticsDialog
    title: i18n("Statistics - %1", dialogClientName)
    // preferredWidth: Kirigami.Units.gridUnit * 50
    // preferredHeight: Kirigami.Units.gridUnit * 35
    standardButtons: Kirigami.Dialog.Close

    property int dialogClientId: 0
    property string dialogClientName: ""


    // Main content
    contentItem: GridLayout {
        // Loading skeleton
        GridLayout {
            anchors.fill: parent
            visible: clientApi.isLoading
            columns: 1
            rowSpacing: Kirigami.Units.largeSpacing

            // Summary Cards Skeleton
            GridLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                columns: 3
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.largeSpacing

                Repeater {
                    model: 3
                    delegate: Kirigami.Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            // Icon skeleton
                            SkeletonLoaders {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                color: Kirigami.Theme.disabledTextColor
                                opacity: 0.3
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                // Title skeleton
                                SkeletonLoaders {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                    color: Kirigami.Theme.disabledTextColor
                                    opacity: 0.3
                                }

                                // Value skeleton
                                SkeletonLoaders {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                    color: Kirigami.Theme.disabledTextColor
                                    opacity: 0.3
                                }
                            }
                        }
                    }
                }
            }

            // Details Skeleton
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.gridUnit * 2

                // Left Column Skeleton
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: 4
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.largeSpacing

                            // Label skeleton
                            SkeletonLoaders {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight : Kirigami.Units.gridUnit
                                color: Kirigami.Theme.disabledTextColor
                                opacity: 0.3
                            }

                            // Value skeleton
                            SkeletonLoaders {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit
                                color: Kirigami.Theme.disabledTextColor
                                opacity: 0.3
                            }
                        }
                    }
                }

                // Right Column Skeleton
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: 4
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.largeSpacing

                            // Label skeleton
                            SkeletonLoaders {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: Kirigami.Units.gridUnit
                                color: Kirigami.Theme.disabledTextColor
                                opacity: 0.3
                            }

                            // Value skeleton
                            SkeletonLoaders {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit
                                color: Kirigami.Theme.disabledTextColor
                                opacity: 0.3
                            }
                        }
                    }
                }
            }
        }



        ColumnLayout {
            // anchors.fill: parent
            visible: !clientApi.isLoading
            spacing: Kirigami.Units.largeSpacing
            anchors.fill: parent

            // Summary Cards at the top
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: Kirigami.Units.largeSpacing
                columnSpacing: Kirigami.Units.largeSpacing
                Layout.margins :  Kirigami.Units.smallSpacing
                // Current Balance Card
                Kirigami.Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            source: "office-chart-bar"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                text: i18n("Current Balance")
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.
                            }

                            QQC2.Label {
                                text: Number(statistics?.client?.current_balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                                Layout.fillWidth: true
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.4
                                color: (statistics?.client?.current_balance || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                            }
                        }
                    }
                }

                // Total Sales Card
                Kirigami.Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            source: "view-financial-transfer-reconciled"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                text: i18n("Total Sales")
                                Layout.fillWidth: true
                                 elide: Text.ElideRight
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Label {
                                text: Number(statistics?.summary?.total_sales || 0).toLocaleString(Qt.locale(), 'f', 2)
                                Layout.fillWidth: true
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.4
                                color: Kirigami.Theme.positiveTextColor
                            }
                        }
                    }
                }

                // Total Payments Card
                Kirigami.Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            source: "wallet-open"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                text: i18n("Total Payments")
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                            }

                            QQC2.Label {
                                text: Number(statistics?.summary?.total_payments || 0).toLocaleString(Qt.locale(), 'f', 2)
                                Layout.fillWidth: true
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.4
                                color: Kirigami.Theme.neutralTextColor
                            }
                        }
                    }
                }
            }

            // Detailed Statistics in Two Columns
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.gridUnit * 2
                Layout.margins :  Kirigami.Units.smallSpacing

                // Left Column
                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Opening Balance:")
                        text: Number(statistics?.opening_balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                        color: (statistics?.opening_balance || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                    }

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Closing Balance:")
                        text: Number(statistics?.closing_balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                        color: (statistics?.closing_balance || 0) > 0 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                    }

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Total Sales Count:")
                        text: statistics?.transactions?.length || "0"
                    }

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Average Sale:")
                        text: {
                            const count = statistics?.transactions?.length || 0
                            const total = Number(statistics?.summary?.total_sales || 0)
                            const avg = count > 0 ? total / count : 0
                            return avg.toLocaleString(Qt.locale(), 'f', 2)
                        }
                    }
                }

                // Right Column
                Kirigami.FormLayout {
                    Layout.fillWidth: true

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Last Sale Date:")
                        text: {
                            const transactions = statistics?.transactions || []
                            if (transactions.length > 0) {
                                const lastSale = transactions[transactions.length - 1]
                                return Qt.formatDateTime(new Date(lastSale.date), "yyyy-MM-dd")
                            }
                            return "-"
                        }
                    }

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Last Payment Date:")
                        text: {
                            const transactions = statistics?.transactions || []
                            for (let i = transactions.length - 1; i >= 0; i--) {
                                if (transactions[i].payment_amount > 0) {
                                    return Qt.formatDateTime(new Date(transactions[i].date), "yyyy-MM-dd")
                                }
                            }
                            return "-"
                        }
                    }

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Payment Ratio:")
                        text: {
                            const totalSales = Number(statistics?.summary?.total_sales || 0)
                            const totalPayments = Number(statistics?.summary?.total_payments || 0)
                            const ratio = totalSales > 0 ? (totalPayments / totalSales * 100) : 0
                            return ratio.toFixed(1) + "%"
                        }
                        color: {
                            const ratio = Number(statistics?.summary?.total_payments || 0) / Number(statistics?.summary?.total_sales || 1)
                            return ratio >= 0.9 ? Kirigami.Theme.positiveTextColor :
                                                  ratio >= 0.7 ? Kirigami.Theme.neutralTextColor :
                                                                 Kirigami.Theme.negativeTextColor
                        }
                    }

                    QQC2.Label {
                        Kirigami.FormData.label: i18n("Outstanding Amount:")
                        text: Number(statistics?.summary?.outstanding_balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                        color: Number(statistics?.summary?.outstanding_balance || 0) > 0 ?
                                   Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                    }
                }
            }
        }
    }
    // Data handling
    property var statistics: ({})

    Connections {
        target: clientApi
        function onStatisticsReceived(data) {
            statistics = data.statement
        }

        function onErrorStatisticsReceived(message, status, details) {
            applicationWindow().showPassiveNotification(message, "short")
        }
    }

    onDialogClientIdChanged: {
        if (dialogClientId > 0) {
            clientApi.getStatistics(dialogClientId)
        }
    }
}
