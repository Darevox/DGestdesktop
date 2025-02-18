import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../components"

Kirigami.Dialog {
    id: statisticsDialog
    title: i18n("Statistics - %1", dialogClientName)
    preferredWidth: Kirigami.Units.gridUnit * 50
    preferredHeight: Kirigami.Units.gridUnit * 35
    standardButtons: Kirigami.Dialog.Close

    property int dialogClientId: 0
    property string dialogClientName: ""

    // Loading indicator
    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: clientApi.isLoading
        visible: running
        z: 999
    }

    // Main content
    ColumnLayout {
        anchors.fill: parent
        visible: !clientApi.isLoading

        // Summary Cards
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing

            // Total Sales Card
            Kirigami.Card {
                Layout.fillWidth: true
                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        source: "business-sales"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            text: i18n("Total Sales")
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            text: Number(statistics?.total_sales || 0).toLocaleString(Qt.locale(), 'f', 2)
                            Layout.fillWidth: true
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                            color: Kirigami.Theme.positiveTextColor
                        }
                    }
                }
            }

            // Total Payments Card
            Kirigami.Card {
                Layout.fillWidth: true
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
                        }

                        QQC2.Label {
                            text: Number(statistics?.total_payments || 0).toLocaleString(Qt.locale(), 'f', 2)
                            Layout.fillWidth: true
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                            color: Kirigami.Theme.neutralTextColor
                        }
                    }
                }
            }

            // Outstanding Balance Card
            Kirigami.Card {
                Layout.fillWidth: true
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
                            text: i18n("Outstanding Balance")
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            text: Number(statistics?.outstanding_balance || 0).toLocaleString(Qt.locale(), 'f', 2)
                            Layout.fillWidth: true
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                            color: Kirigami.Theme.negativeTextColor
                        }
                    }
                }
            }
        }

        // Additional Statistics
        Kirigami.FormLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            QQC2.Label {
                Kirigami.FormData.label: i18n("Last Sale:")
                text: statistics?.last_sale_date ? Qt.formatDateTime(new Date(statistics.last_sale_date), "yyyy-MM-dd") : "-"
            }

            QQC2.Label {
                Kirigami.FormData.label: i18n("Last Payment:")
                text: statistics?.last_payment_date ? Qt.formatDateTime(new Date(statistics.last_payment_date), "yyyy-MM-dd") : "-"
            }

            QQC2.Label {
                Kirigami.FormData.label: i18n("Total Sales Count:")
                text: statistics?.total_sales_count || "0"
            }

            QQC2.Label {
                Kirigami.FormData.label: i18n("Average Sale Amount:")
                text: Number(statistics?.average_sale_amount || 0).toLocaleString(Qt.locale(), 'f', 2)
            }

            QQC2.Label {
                Kirigami.FormData.label: i18n("Payment Ratio:")
                text: statistics?.payment_ratio ? (statistics.payment_ratio * 100).toFixed(2) + "%" : "0%"
            }
        }

        // Period Statistics
        Kirigami.FormLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            visible: statistics?.period_statistics

            Kirigami.Heading {
                level: 4
                text: i18n("Last 30 Days")
            }

            QQC2.Label {
                Kirigami.FormData.label: i18n("Sales:")
                text: Number(statistics?.period_statistics?.sales || 0).toLocaleString(Qt.locale(), 'f', 2)
            }

            QQC2.Label {
                Kirigami.FormData.label: i18n("Payments:")
                text: Number(statistics?.period_statistics?.payments || 0).toLocaleString(Qt.locale(), 'f', 2)
            }
        }
    }

    // Data handling
    property var statistics: ({})

    Connections {
        target: clientApi
        function onStatisticsReceived(data) {
            statistics = data
        }

        function onErrorStatisticsReceived(message, status, details) {
            applicationWindow().showPassiveNotification(message, "short")
        }
    }

    Component.onCompleted: {
        if (dialogClientId > 0) {
            clientApi.getStatistics(dialogClientId)
        }
    }
}
