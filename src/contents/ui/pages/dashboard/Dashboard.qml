import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
//import com.dervox.DashboardModel 1.0
import "."
import "../../components"
import org.kde.kirigamiaddons.dateandtime as Kdateandtime

Kirigami.Page {
    id: root
    title: i18n("Dashboard")

    // DashboardModel {
    //     id: dashboardModel
    //     onError: {
    //         applicationWindow().gnotification.showNotification(
    //             "",
    //             message,
    //             Kirigami.MessageType.Error,
    //             "short",
    //             "dialog-close"
    //         )
    //     }
    // }

    // actions: [
    //     Kirigami.Action {
    //         text: i18n("Refresh")
    //         icon.name: "view-refresh"
    //         onTriggered: dashboardModel.refresh()
    //     }
    // ]
    // DBusyIndicator {
    //     anchors.centerIn: parent
    //     running: dashboardModel.loading
    //     visible: running
    //     z:99
    // }
    header: ColumnLayout{
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing * 2
            visible : !dashboardModel.loading
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 3
                Layout.rightMargin: Kirigami.Units.largeSpacing * 3
                spacing: Kirigami.Units.largeSpacing
                DateRangeSelector {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.largeSpacing
                    onDateRangeChanged: (start, end) => {
                                            dashboardModel.setDateRange(start, end)
                                        }
                }
                Label {
                    Layout.margins : Kirigami.Units.largeSpacing * 2
                    text: {
                        if (dashboardModel.periodInfo && dashboardModel.periodInfo.timeframe) {
                            const start = new Date(dashboardModel.periodInfo.start_date)
                            const end = new Date(dashboardModel.periodInfo.end_date)
                            return i18n("Showing data from %1 to %2",
                                        start.toLocaleDateString(),
                                        end.toLocaleDateString())
                        }
                        return ""
                    }
                    Layout.alignment: Qt.AlignHCenter
                    opacity: 0.7
                    visible: dashboardModel.periodInfo !== undefined
                }


            }
            // Summary Cards Row
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 3
                Layout.rightMargin: Kirigami.Units.largeSpacing * 3
                spacing: Kirigami.Units.largeSpacing
                StatsCard {
                    Layout.preferredWidth: parent.width / 4
                    title: i18n("Total Sales")
                    value: dashboardModel.totalSales.toFixed(2)  + " DH"
                    subtitle: i18n("All-time: %1 DH", dashboardModel.allTimeSales.toFixed(2))
                    iconCard: "view-financial-category-income"
                    valueColor: Kirigami.Theme.positiveTextColor
                }

                StatsCard {
                    Layout.preferredWidth: parent.width / 4
                    title: i18n("Total Orders")
                    value: dashboardModel.totalOrders
                    subtitle: i18n("All-time: %1", dashboardModel.allTimeOrders)
                    iconCard: "view-financial-category-expense"
                }

                StatsCard {
                    Layout.preferredWidth: parent.width / 4
                    title: i18n("Low Stock")
                    value: dashboardModel.lowStockCount
                    subtitle: i18n("Items need attention")
                    iconCard: "package"
                    valueColor: Kirigami.Theme.neutralTextColor
                }

                StatsCard {
                    Layout.preferredWidth: parent.width / 4
                    title: i18n("Revenue")
                    value:  dashboardModel.totalRevenue.toFixed(2)  + " DH"
                    subtitle: i18n("All-time:  %1 DH",
                                   (dashboardModel.allTimeSales - dashboardModel.allTimePurchases).toFixed(2))
                    iconCard: "view-financial-account-investment-security"
                    valueColor: dashboardModel.totalRevenue >= 0 ?
                                    Kirigami.Theme.positiveTextColor :
                                    Kirigami.Theme.negativeTextColor
                }

            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing * 2
            visible : dashboardModel.loading

            // Date Range Selector Skeleton
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                Layout.leftMargin: Kirigami.Units.largeSpacing * 3
                Layout.rightMargin: Kirigami.Units.largeSpacing * 3
                SkeletonLoaders {
                    Layout.margins: Kirigami.Units.largeSpacing
                    Layout.preferredWidth: parent.width / 3

                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                }

                SkeletonLoaders {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit* 2
                }
            }

            // Summary Cards Skeleton
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                Layout.leftMargin: Kirigami.Units.largeSpacing * 3
                Layout.rightMargin: Kirigami.Units.largeSpacing * 3
                Repeater {
                    model: 4
                    delegate: Kirigami.Card {
                        Layout.preferredWidth: parent.width / 4
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5

                        contentItem:
                            RowLayout {
                            spacing: Kirigami.Units.gridUnit
                            SkeletonLoaders {
                                Layout.fillHeight: true
                                Layout.margins : Kirigami.Units.smallSpacing
                                Layout.preferredWidth: parent.width / 4.5
                                Layout.preferredHeight: Kirigami.Units.gridUnit
                            }

                            ColumnLayout {
                                spacing: Kirigami.Units.smallSpacing

                                SkeletonLoaders {
                                    Layout.fillWidth: true
                                    Layout.topMargin : Kirigami.Units.smallSpacing
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                }

                                SkeletonLoaders {
                                    Layout.preferredWidth: parent.width / 2
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                }

                                SkeletonLoaders {
                                    Layout.preferredWidth: parent.width / 1.5
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                    Layout.bottomMargin : Kirigami.Units.smallSpacing
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    ColumnLayout{
        visible: dashboardModel.loading
        anchors.fill: parent
        // Charts Skeleton
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // Two main chart placeholders
            Kirigami.Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                SkeletonLoaders {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                }
            }

            Kirigami.Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                SkeletonLoaders {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                }
            }
            Kirigami.Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                SkeletonLoaders {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                }
            }
        }


        // Top Items Skeleton (simplified)
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // Left card
            Kirigami.Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                SkeletonLoaders {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                }
            }

            // Right card
            Kirigami.Card {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 15
                SkeletonLoaders {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                }
            }
        }

        // // Top Items Skeleton
        // RowLayout {
        //     Layout.fillWidth: true
        //     Layout.margins: Kirigami.Units.largeSpacing
        //     spacing: Kirigami.Units.largeSpacing

        //     Repeater {
        //         model: 2
        //         delegate: Kirigami.Card {
        //             Layout.preferredWidth: parent.width / 2
        //             Layout.preferredHeight: Kirigami.Units.gridUnit * 10

        //             contentItem: ColumnLayout {
        //                 spacing: Kirigami.Units.smallSpacing

        //                 SkeletonLoaders {
        //                     Layout.fillWidth: true
        //                     Layout.preferredHeight: Kirigami.Units.gridUnit
        //                 }

        //                 Repeater {
        //                     model: 5
        //                     delegate: RowLayout {
        //                         Layout.fillWidth: true
        //                         spacing: Kirigami.Units.smallSpacing

        //                         SkeletonLoaders {
        //                             Layout.preferredWidth: Kirigami.Units.gridUnit * 2
        //                             Layout.preferredHeight: Kirigami.Units.gridUnit
        //                         }

        //                         SkeletonLoaders {
        //                             Layout.fillWidth: true
        //                             Layout.preferredHeight: Kirigami.Units.gridUnit
        //                         }
        //                     }
        //                 }
        //             }
        //         }
        //     }
        // }



        // RowLayout {
        //     Layout.fillWidth: true
        //     Layout.margins: Kirigami.Units.largeSpacing
        //     spacing: Kirigami.Units.largeSpacing

        //     Repeater {
        //         model: 3
        //         delegate: Kirigami.Card {
        //             Layout.preferredWidth: parent.width / 3
        //             Layout.preferredHeight: Kirigami.Units.gridUnit * 15

        //             contentItem: ColumnLayout {
        //                 spacing: Kirigami.Units.smallSpacing

        //                 SkeletonLoaders {
        //                     Layout.fillWidth: true
        //                     Layout.preferredHeight: Kirigami.Units.gridUnit
        //                 }

        //                 SkeletonLoaders {
        //                     Layout.fillWidth: true
        //                     Layout.fillHeight: true
        //                 }
        //             }
        //         }
        //     }
        // }

    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        visible : !dashboardModel.loading
        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            // Charts Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing
                LineChartCard {
                    Layout.preferredWidth: parent.width / 2
                    title: i18n("Sales Trend")
                    value:   dashboardModel.totalSales.toFixed(2)  + " DH"
                    subtitle: {
                        if (dashboardModel.periodInfo && dashboardModel.periodInfo.timeframe) {
                            switch(dashboardModel.periodInfo.timeframe) {
                            case "daily": return i18n("Today's sales")
                            case "24hours": return i18n("Last 24 hours")
                            case "weekly": return i18n("Weekly sales")
                            case "monthly": return i18n("Monthly sales")
                            case "yearly": return i18n("Yearly sales")
                            case "all": return i18n("All-time sales")
                            default: return i18n("Sales over time")
                            }
                        }
                        return i18n("Sales over time")
                    }
                    chartData: dashboardModel.salesHistory
                    chartColor: Kirigami.Theme.positiveTextColor
                    timeframe: dashboardModel.timeframe
                }

                LineChartCard {
                    Layout.preferredWidth: parent.width / 2
                    title: i18n("Purchase Trend")
                    value:  dashboardModel.totalPurchases.toFixed(2)  + " DH"
                    subtitle: {
                        if (dashboardModel.periodInfo && dashboardModel.periodInfo.timeframe) {
                            switch(dashboardModel.periodInfo.timeframe) {
                            case "daily": return i18n("Today's purchases")
                            case "24hours": return i18n("Last 24 hours")
                            case "weekly": return i18n("Weekly purchases")
                            case "monthly": return i18n("Monthly purchases")
                            case "yearly": return i18n("Yearly purchases")
                            case "all": return i18n("All-time purchases")
                            default: return i18n("Purchases over time")
                            }
                        }
                        return i18n("Purchases over time")
                    }
                    chartData: dashboardModel.purchaseHistory
                    chartColor: Kirigami.Theme.neutralTextColor
                    timeframe: dashboardModel.timeframe
                }



                PieChartCard {
                    Layout.preferredWidth: parent.width / 2
                    title: i18n("Customer Distribution")
                    subtitle: i18n("Top customers by spending")
                    names: {
                        let customerNames = []
                        if (dashboardModel.topCustomers) {
                            customerNames = dashboardModel.topCustomers.map(function(customer) {
                                return customer.name || "Unknown"
                            })
                        }
                        return customerNames
                    }
                    values: {
                        let customerValues = []
                        if (dashboardModel.topCustomers) {
                            customerValues = dashboardModel.topCustomers.map(function(customer) {
                                return Number(customer.total_spent) || 0
                            })
                        }
                        return customerValues
                    }
                    colors: [
                        Kirigami.Theme.positiveTextColor,
                        Kirigami.Theme.neutralTextColor,
                        Kirigami.Theme.negativeTextColor,
                        Kirigami.Theme.activeTextColor,
                        Kirigami.Theme.linkColor
                    ]
                }
            }

            // Top Items Row
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                TopItemsCard {
                    Layout.preferredWidth: parent.width / 2
                    title: i18n("Top Products")
                    model: dashboardModel.topProducts
                    iconCard: "package"
                }

                TopItemsCard {
                    Layout.preferredWidth: parent.width / 2
                    title: i18n("Top Customers")
                    model: dashboardModel.topCustomers
                    iconCard: "user"
                }
            }
        }
    }


    Component.onCompleted: {
        dashboardAnalyticsApi.testMode = false;  // Enable test mode
        dashboardModel.setApi(dashboardAnalyticsApi)
        // applicationWindow().loadGlobalDrawer()
        // applicationWindow().loadHeader()
    }
}
