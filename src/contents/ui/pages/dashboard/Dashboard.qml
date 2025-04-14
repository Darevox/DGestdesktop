import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "."
import "../../components"
import org.kde.kirigamiaddons.dateandtime as Kdateandtime

Kirigami.ScrollablePage {
    id: root
    title: i18n("Dashboard")
    // Responsive breakpoints
    property bool isLarge: width >= Kirigami.Units.gridUnit * 50  // Increased from 40 to 50
    property bool isMedium: width >= Kirigami.Units.gridUnit * 35 && width < Kirigami.Units.gridUnit * 50  // Updated range
    property bool isSmall: width >= Kirigami.Units.gridUnit * 20 && width < Kirigami.Units.gridUnit * 35   // Updated range
    property bool isTiny: width < Kirigami.Units.gridUnit * 20    // Unchanged
    property bool isMobile: Kirigami.Settings.isMobile || isTiny  // Unchanged
    header: Kirigami.ApplicationHeaderStyle.None
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    Kirigami.Theme.inherit: false
    background: Rectangle {
        color: Qt.darker(Kirigami.Theme.backgroundColor, 1.1)
        border.width: 0
        radius: Kirigami.Units.smallSpacing
    }
    // Calculate columns dynamically
    property int statsCardsColumns: isTiny ? 1 : (isSmall ? 2 : (isMedium ? 3 : 4))
    property int chartCardsColumns: isTiny ? 1 : (isSmall ? 1 : (isMedium ? 2 : (isLarge ? 3 : 2)))
    property int topItemsColumns: isSmall || isTiny ? 1 : 2

    // Main content using ColumnLayout
    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        // Only display if not loading
        visible: !dashboardModel.loading

        // Date range selector section with restored DateRangeSelector
        Kirigami.Card {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            background: Rectangle {
                color: Qt.lighter(Kirigami.Theme.backgroundColor,1.2)
                border.width: 0
                radius: Kirigami.Units.smallSpacing
            }
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing
                width: parent.width
                DateRangeSelector {
                    Layout.margins:  Kirigami.Units.largeSpacing

                    Layout.fillWidth: true
                    onDateRangeChanged: (start, end) => {
                                            dashboardModel.setDateRange(start, end)
                                        }
                }

                // Make this text wrap to handle long dates
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: Kirigami.Units.smallSpacing

                    // Ensure the text wraps properly
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter

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
                    opacity: 0.7
                    visible: dashboardModel.periodInfo !== undefined
                }
            }
        }

        // Summary Stats Cards using GridLayout
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            // Set columns based on screen size
            columns: statsCardsColumns

            StatsCard {
                Layout.fillWidth: true
                title: i18n("Total Sales")
                value: dashboardModel.totalSales.toFixed(2) + " DH"
                subtitle: i18n("All-time: %1 DH", dashboardModel.allTimeSales.toFixed(2))
                iconCard: "view-financial-category-income"
                valueColor: Kirigami.Theme.positiveTextColor
            }

            StatsCard {
                Layout.fillWidth: true
                title: i18n("Total Orders")
                value: dashboardModel.totalOrders
                subtitle: i18n("All-time: %1", dashboardModel.allTimeOrders)
                iconCard: "view-financial-category-expense"
            }

            StatsCard {
                Layout.fillWidth: true
                title: i18n("Low Stock")
                value: dashboardModel.lowStockCount
                subtitle: i18n("Items need attention")
                iconCard: "package"
                valueColor: Kirigami.Theme.neutralTextColor
            }

            StatsCard {
                Layout.fillWidth: true
                title: i18n("Revenue")
                value: dashboardModel.totalRevenue.toFixed(2) + " DH"
                subtitle: i18n("All-time: %1 DH",
                               (dashboardModel.allTimeSales - dashboardModel.allTimePurchases).toFixed(2))
                iconCard: "view-financial-account-investment-security"
                valueColor: dashboardModel.totalRevenue >= 0 ?
                                Kirigami.Theme.positiveTextColor :
                                Kirigami.Theme.negativeTextColor
            }
        }

        // Charts with GridLayout
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            // Set columns based on screen size
            columns: chartCardsColumns

            LineChartCard {
                Layout.fillWidth: true
                title: i18n("Sales Trend")
                value: dashboardModel.totalSales.toFixed(2) + " DH"
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
                Layout.fillWidth: true
                title: i18n("Purchase Trend")
                value: dashboardModel.totalPurchases.toFixed(2) + " DH"
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
                Layout.fillWidth: true
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

        // Top Items with GridLayout
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            // Set columns based on screen size
            columns: topItemsColumns

            TopItemsCard {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 15
                title: i18n("Top Products")
                model: dashboardModel.topProducts
                iconCard: "package"
            }

            TopItemsCard {
                Layout.fillWidth: true
                height: Kirigami.Units.gridUnit * 15
                title: i18n("Top Customers")
                model: dashboardModel.topCustomers
                iconCard: "user"
            }
        }
    }


    // Loading skeletons content with proper SkeletonLoaders
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing
        visible: dashboardModel.loading

        // Date Range Selector Skeleton
        Kirigami.Card {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            implicitHeight: Kirigami.Units.gridUnit * 4
            background: Rectangle {
                color: Qt.lighter(Kirigami.Theme.backgroundColor,1.2)
                border.width: 0
                radius: Kirigami.Units.smallSpacing
            }
            contentItem: Item {
                width: parent.width
                height: Kirigami.Units.gridUnit * 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    SkeletonLoaders {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                    }

                    SkeletonLoaders {
                        Layout.preferredWidth: parent.width / 2
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                    }
                }
            }
        }

        // Summary Cards Skeleton using GridLayout
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            // Set columns based on screen size
            columns: statsCardsColumns

            Repeater {
                model: 4
                delegate: Kirigami.Card {
                    Layout.fillWidth: true
                    implicitHeight: Kirigami.Units.gridUnit * 7
                    background: Rectangle {
                        color: Qt.lighter(Kirigami.Theme.backgroundColor,1.2)
                        border.width: 0
                        radius: Kirigami.Units.smallSpacing
                    }
                    contentItem: Item {
                        anchors.fill: parent

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.largeSpacing
                            spacing: Kirigami.Units.largeSpacing

                            // Icon placeholder
                            SkeletonLoaders {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                                Layout.preferredHeight: Kirigami.Units.iconSizes.large
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Content placeholder
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.smallSpacing

                                // Title
                                SkeletonLoaders {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit
                                }

                                // Value
                                SkeletonLoaders {
                                    Layout.preferredWidth: parent.width * 0.7
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                }

                                // Subtitle
                                SkeletonLoaders {
                                    Layout.preferredWidth: parent.width * 0.9
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
                                }
                            }
                        }
                    }
                }
            }
        }

        // Charts Skeleton with GridLayout
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            // Set columns based on screen size
            columns: chartCardsColumns

            // Line chart skeletons
            Repeater {
                model: 2
                delegate: Kirigami.Card {
                    background: Rectangle {
                        color: Qt.lighter(Kirigami.Theme.backgroundColor,1.2)
                        border.width: 0
                        radius: Kirigami.Units.smallSpacing
                    }
                    Layout.fillWidth: true
                    implicitHeight: Kirigami.Units.gridUnit * 16

                    contentItem: Item {
                        anchors.fill: parent

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.largeSpacing
                            spacing: Kirigami.Units.largeSpacing

                            // Header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing

                                    // Title
                                    SkeletonLoaders {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Kirigami.Units.gridUnit
                                    }

                                    // Subtitle
                                    SkeletonLoaders {
                                        Layout.preferredWidth: parent.width * 0.6
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.7
                                    }
                                }

                                // Value
                                SkeletonLoaders {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5
                                }
                            }

                            // Chart area
                            SkeletonLoaders {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            // Labels bottom row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Repeater {
                                    model: 5
                                    delegate: SkeletonLoaders {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Pie chart skeleton
            Kirigami.Card {
                Layout.fillWidth: true
                implicitHeight: Kirigami.Units.gridUnit * 16
                background: Rectangle {
                    color: Qt.lighter(Kirigami.Theme.backgroundColor,1.2)
                    border.width: 0
                    radius: Kirigami.Units.smallSpacing
                }
                contentItem: Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.largeSpacing

                        // Header
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            // Title
                            SkeletonLoaders {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit
                            }

                            // Subtitle
                            SkeletonLoaders {
                                Layout.preferredWidth: parent.width * 0.6
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 0.7
                            }
                        }

                        // Chart content area
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            // Pie area - left circle
                            SkeletonLoaders {
                                width: parent.width * 0.6
                                height: parent.height
                                anchors.left: parent.left

                                // Make it more circular
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width, parent.height) * 0.7
                                    height: width
                                    radius: width / 2
                                    color: Kirigami.Theme.backgroundColor
                                    border.width: 1
                                    border.color: Kirigami.Theme.disabledTextColor
                                    opacity: 0.6
                                }
                            }

                            // Legend area - right column
                            Column {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * 0.35
                                spacing: Kirigami.Units.smallSpacing

                                Repeater {
                                    model: 5
                                    delegate: RowLayout {
                                        width: parent.width
                                        height: Kirigami.Units.gridUnit
                                        spacing: Kirigami.Units.smallSpacing

                                        // Color dot
                                        SkeletonLoaders {
                                            Layout.preferredWidth: Kirigami.Units.gridUnit * 0.7
                                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.7
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        // Text
                                        SkeletonLoaders {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                                        }

                                        // Value
                                        SkeletonLoaders {
                                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Top Items Skeleton with GridLayout
        GridLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            // Set columns based on screen size
            columns: topItemsColumns

            Repeater {
                model: 2
                delegate: Kirigami.Card {
                    background: Rectangle {
                        color: Qt.lighter(Kirigami.Theme.backgroundColor,1.2)
                        border.width: 0
                        radius: Kirigami.Units.smallSpacing
                    }
                    Layout.fillWidth: true
                    implicitHeight: Kirigami.Units.gridUnit * 18

                    contentItem: Item {
                        anchors.fill: parent

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.largeSpacing
                            spacing: Kirigami.Units.largeSpacing

                            // Header with icon and title
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.largeSpacing

                                // Icon
                                SkeletonLoaders {
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                                }

                                // Title
                                SkeletonLoaders {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
                                }
                            }

                            // List items
                            Column {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.smallSpacing

                                Repeater {
                                    model: 5
                                    delegate: Item {
                                        width: parent.width
                                        height: Kirigami.Units.gridUnit * 3

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: Kirigami.Units.smallSpacing
                                            color: Kirigami.Theme.backgroundColor
                                            opacity: 0.5
                                            radius: Kirigami.Units.smallSpacing

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: Kirigami.Units.smallSpacing
                                                spacing: Kirigami.Units.largeSpacing

                                                // Item icon
                                                SkeletonLoaders {
                                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                // Content
                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: Kirigami.Units.smallSpacing

                                                    SkeletonLoaders {
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
                                                    }

                                                    SkeletonLoaders {
                                                        Layout.fillWidth: true
                                                        Layout.preferredWidth: parent.width * 0.8
                                                        Layout.preferredHeight: Kirigami.Units.gridUnit * 0.6
                                                    }
                                                }

                                                // Value
                                                SkeletonLoaders {
                                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
                                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        dashboardAnalyticsApi.testMode = false;
        dashboardModel.setApi(dashboardAnalyticsApi)
    }
}
