// DateRangeSelector.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.dateandtime as Kdateandtime

ColumnLayout {
    id: root

    property date startDate: new Date()
    property date endDate: new Date()
    signal dateRangeChanged(date startDate, date endDate)
    property string currentPeriod: "daily"
    Layout.alignment: Qt.AlignHCenter || Qt.AlignVCenter

    ButtonGroup {
        id: periodGroup
        Layout.alignment: Qt.AlignHCenter || Qt.AlignVCenter

        onCheckedButtonChanged: {
            if (checkedButton) {
                setPeriod(checkedButton.period)
            }
        }
    }

    // Use Flow for responsive button layout
    Flow {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        Layout.alignment: Qt.AlignHCenter || Qt.AlignVCenter

        Repeater {
            model: [
                { text: i18n("Today"), period: "daily" },
                { text: i18n("Past 24h"), period: "24hours" },
                { text: i18n("Week"), period: "weekly" },
                { text: i18n("Month"), period: "monthly" },
                { text: i18n("Year"), period: "yearly" }
            ]

            delegate: Button {
                property string period: modelData.period
                text: modelData.text
                checkable: true
                ButtonGroup.group: periodGroup
                checked: index === 0
            }
        }
    }

    function setPeriod(period) {
        let start = new Date()
        let end = new Date()
        root.currentPeriod = period

        switch (period) {
        case "daily":
            start = new Date(end.getFullYear(), end.getMonth(), end.getDate())
            end = new Date(start)
            end.setHours(23, 59, 59)
            start.setHours(0, 0, 0)
            break
        case "24hours":
            end = new Date()
            start = new Date(end)
            start.setHours(end.getHours() - 24)
            break
        case "weekly":
            end = new Date()
            start = new Date(end)
            start.setDate(end.getDate() - 6)
            start.setHours(0, 0, 0)
            end.setHours(23, 59, 59)
            break
        case "monthly":
            end = new Date()
            start = new Date(end.getFullYear(), end.getMonth(), 1)
            end = new Date(end.getFullYear(), end.getMonth() + 1, 0)
            start.setHours(0, 0, 0)
            end.setHours(23, 59, 59)
            break
        case "yearly":
            end = new Date()
            start = new Date(end.getFullYear(), 0, 1)
            end = new Date(end.getFullYear(), 11, 31)
            start.setHours(0, 0, 0)
            end.setHours(23, 59, 59)
            break
        case "all":
            end = new Date()
            start = new Date(2000, 0, 1)  // Or your preferred start date
            start.setHours(0, 0, 0)
            end.setHours(23, 59, 59)
            break
        // case "custom":
        //     start = startDateFieldPopUp.value
        //     end = endDateFieldPopUp.value
        //     start.setHours(0, 0, 0)
        //     end.setHours(23, 59, 59)
        //     break
        }

        // Update model timeframe and dates
        dashboardModel.timeframe = period

        // Format dates to ISO string for debugging
        console.log("Period changed:", period)
        console.log("Start date:", start.toISOString())
        console.log("End date:", end.toISOString())

        // Convert JavaScript Date to format expected by the model
        let startStr = Qt.formatDate(start, "yyyy-MM-dd")
        let endStr = Qt.formatDate(end, "yyyy-MM-dd")

        // Update the model with new dates
        dashboardModel.setDateRange(startStr, endStr)
    }
}
