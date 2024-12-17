import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import "../../components"

Kirigami.Dialog {
    id: salesDialog
    title: i18n("Sales History - %1", dialogClientName)
    preferredWidth: Kirigami.Units.gridUnit * 60
    preferredHeight: Kirigami.Units.gridUnit * 40
    standardButtons: Kirigami.Dialog.Close

    property int dialogClientId: 0
    property string dialogClientName: ""

    // Loading indicator
    QQC2.BusyIndicator {
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
        visible: !clientApi.isLoading && (!salesData || salesData.data.length === 0)
        text: i18n("No sales records found")
        icon.name: "view-list-details"
    }

    // Main content
    QQC2.ScrollView {
        anchors.fill: parent
        anchors.bottomMargin: paginationBar.height
        visible: !clientApi.isLoading && salesData && salesData.data && salesData.data.length > 0

        DKTableView {
            id: salesTable
            model: ListModel {}
            alternatingRows: true

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18n("Date")
                    textRole: "sale_date"
                    minimumWidth: salesDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Reference")
                    textRole: "reference_number"
                    minimumWidth: salesDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Total")
                    textRole: "total_amount"
                    minimumWidth: salesDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Paid")
                    textRole: "paid_amount"
                    minimumWidth: salesDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Balance")
                    textRole: "balance"
                    minimumWidth: salesDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Status")
                    textRole: "payment_status"
                    minimumWidth: salesDialog.width * 0.15
                    width: minimumWidth
                }
            ]
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

    // Data handling
    property var salesData: ({})

    Connections {
        target: clientApi
        function onSalesReceived(data) {
            salesData = data
            updateSalesModel()
        }

        function onErrorSalesReceived(message, status, details) {
            applicationWindow().showPassiveNotification(message, "short")
        }
    }

    function updateSalesModel() {
        salesTable.model.clear()
        if (salesData && salesData.data) {
            salesData.data.forEach(function(sale) {
                salesTable.model.append({
                    sale_date: Qt.formatDateTime(new Date(sale.sale_date), "yyyy-MM-dd"),
                    reference_number: sale.reference_number,
                    total_amount: Number(sale.total_amount).toLocaleString(Qt.locale(), 'f', 2),
                    paid_amount: Number(sale.paid_amount).toLocaleString(Qt.locale(), 'f', 2),
                    balance: Number(sale.total_amount - sale.paid_amount).toLocaleString(Qt.locale(), 'f', 2),
                    payment_status: sale.payment_status
                })
            })
        }
    }

    Component.onCompleted: {
        if (dialogClientId > 0) {
            clientApi.getSales(dialogClientId)
        }
    }
}
