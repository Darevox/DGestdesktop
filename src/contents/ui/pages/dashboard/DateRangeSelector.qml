import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.dateandtime as Kdateandtime
import org.kde.kirigamiaddons.formcard as FormCard

RowLayout {
    id: root

    property date startDate: new Date()
    property date endDate: new Date()
    signal dateRangeChanged(date startDate, date endDate)
    property string currentPeriod: "daily"

    ButtonGroup {
        id: periodGroup
        onCheckedButtonChanged: {
            if (checkedButton) {
                setPeriod(checkedButton.period)
            }
        }
    }

    Repeater {
        model: [
            { text: i18n("Today"), period: "daily" },
            { text: i18n("Past 24h"), period: "24hours" },
            { text: i18n("Week"), period: "weekly" },
            { text: i18n("Month"), period: "monthly" },
            { text: i18n("Year"), period: "yearly" },
            { text: i18n("All Time"), period: "all" },
            { text: i18n("Custom"), period: "custom" }
        ]

        Button {
            property string period: modelData.period
            text: modelData.text
            checkable: true
            ButtonGroup.group: periodGroup
            checked: index === 0
        }
    }

    Rectangle {
        visible: periodGroup.checkedButton?.period === "custom"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        color: Kirigami.Theme.backgroundColor
        // border.color: Kirigami.Theme.disabledTextColor
        Kdateandtime.DatePopup{
            id: startDateFieldPopUp
        }
        Kdateandtime.DatePopup {
            id: endDateFieldPopUp
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing

            TextField {
                id: startDateField
                placeholderText: i18n("Start Date")
                Layout.fillWidth: true
                text:  Qt.formatDate(startDateFieldPopUp.value, "yyyy-MM-dd")
                horizontalAlignment: TextInput.AlignHCenter
                MouseArea{
                    anchors.fill:parent
                    onClicked:startDateFieldPopUp.open()
                }
            }
            Label {
                text: "–"
            }
            TextField {
                id: endDateField
                placeholderText: i18n("End Date")
                Layout.fillWidth: true
                text:  Qt.formatDate(endDateFieldPopUp.value, "yyyy-MM-dd")
                horizontalAlignment: TextInput.AlignHCenter
                MouseArea{
                    anchors.fill:parent
                    onClicked:endDateFieldPopUp.open()
                }
            }
            Button{

                text : "Get Status"
                onClicked: setPeriod("custom")


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
        case "custom":
            start = startDateFieldPopUp.value
            end = endDateFieldPopUp.value
            start.setHours(0, 0, 0)
            end.setHours(23, 59, 59)
            break
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
