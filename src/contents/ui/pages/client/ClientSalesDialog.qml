import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import Qt.labs.qmlmodels
import "../../components"

Kirigami.Dialog {
    id: salesDialog
    title: i18n("Sales History - %1", dialogClientName)
  //  width: Kirigami.Units.gridUnit * 60
    width: applicationWindow().width / 2
    height: Kirigami.Units.gridUnit * 40
    standardButtons: Kirigami.Dialog.Close

    property int dialogClientId: 0
    property string dialogClientName: ""

    // Define roles
    QtObject {
        id: roles
        readonly property int reference: Qt.UserRole + 1
        readonly property int date: Qt.UserRole + 2
        readonly property int total: Qt.UserRole + 3
        readonly property int paid: Qt.UserRole + 4
        readonly property int balance: Qt.UserRole + 5
        readonly property int status: Qt.UserRole + 6
    }

    // Main content
    contentItem: Item{
         clip:true
        QQC2.ScrollView {
        // anchors.fill: parent
        anchors.bottomMargin: paginationBar.height
        visible: !clientApi.isLoading && salesData && salesData.data && salesData.data.length > 0
        Layout.margins :  Kirigami.Units.largeSpacing
        Tables.KTableView {
            id: salesTable
            alternatingRows: true
            Layout.margins :  Kirigami.Units.largeSpacing
            clip:true
            model: TableModel {
                id: tableModel

                // Define role names for each column
                TableModelColumn { display: "reference" }
                TableModelColumn { display: "date" }
                TableModelColumn { display: "total" }
                TableModelColumn { display: "paid" }
                TableModelColumn { display: "balance" }
                TableModelColumn { display: "status" }

                rows: []
            }

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18n("Reference")
                    width: salesDialog.width / 6
                    role: 1
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Date")
                    width: salesDialog.width / 6
                    role: 2
                    itemDelegate: QQC2.Label {
                        text: modelData ? Qt.formatDateTime(new Date(modelData), "dd/MM/yyyy") : ""
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Total")
                    width: salesDialog.width / 6
                    role: 3
                    itemDelegate: QQC2.Label {
                        text: modelData ? Number(modelData).toLocaleString(Qt.locale(), 'f', 2) : "0.00"
                        horizontalAlignment: Text.AlignRight
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Paid")
                    width: salesDialog.width / 6
                    role:4
                    itemDelegate: QQC2.Label {
                        text: modelData ? Number(modelData).toLocaleString(Qt.locale(), 'f', 2) : "0.00"
                        horizontalAlignment: Text.AlignRight
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Balance")
                    width: salesDialog.width / 6
                    role: 5
                    itemDelegate: QQC2.Label {
                        text: modelData ? Number(modelData).toLocaleString(Qt.locale(), 'f', 2) : "0.00"
                        horizontalAlignment: Text.AlignRight
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Status")
                    width: salesDialog.width / 6
                    role: 6
                    itemDelegate: DStatusBadge {
                        text: {
                            switch(String(modelData)) {
                                case "paid": return i18n("Paid")
                                case "partial": return i18n("Partial")
                                case "unpaid": return i18n("Unpaid")
                                default: return modelData || ""
                            }
                        }
                        textColor: {
                            switch(String(modelData)) {
                                case "paid": return Kirigami.Theme.positiveTextColor
                                case "partial": return Kirigami.Theme.neutralTextColor
                                case "unpaid": return Kirigami.Theme.negativeTextColor
                                default: return Kirigami.Theme.textColor
                            }
                        }
                    }
                }
            ]
        }

    }

    // Loading indicator
    DBusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: clientApi.isLoading
        visible: running
        z: 999
    }

    // Empty state message
    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        text: i18n("No sales records found")
        visible: !clientApi.isLoading && (!salesData || salesData.data.length === 0)
        icon.name: "view-list-details"
    }
}
    // Pagination
    footer: PaginationBar {
        id: paginationBar
        currentPage: salesData?.current_page || 1
        totalPages: salesData?.last_page || 1
        totalItems: salesData?.total || 0
        onPageChanged: clientApi.getSales(dialogClientId, page)
    }

    property var salesData: ({})



    Connections {
        target: clientApi
        function onSalesReceived(data) {
            console.log("Received sales data:", JSON.stringify(data));
            salesData = data;
            updateSalesModel();
        }
    }


    function updateSalesModel() {
        if (salesData && salesData.data) {
            let newRows = salesData.data.map(sale => ({
                                                          reference: sale.reference_number,
                                                          date: sale.sale_date,
                                                          total: sale.total_amount,
                                                          paid: sale.paid_amount,
                                                          balance: sale.total_amount - sale.paid_amount,
                                                          status: sale.payment_status
                                                      }));
            tableModel.rows = newRows;
        }
    }


    onDialogClientIdChanged: {
        if (dialogClientId > 0) {
            clientApi.getSales(dialogClientId)
        }
    }

}
