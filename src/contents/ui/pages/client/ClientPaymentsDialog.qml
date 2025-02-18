import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import "../../components"

Kirigami.Dialog {
    id: paymentsDialog
    title: i18n("Payment History - %1", dialogClientName)
    preferredWidth: Kirigami.Units.gridUnit * 60
    preferredHeight: Kirigami.Units.gridUnit * 40
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

    // Empty state message
    Kirigami.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - (Kirigami.Units.largeSpacing * 4)
        visible: !clientApi.isLoading && (!paymentsData || paymentsData.data.length === 0)
        text: i18n("No payment records found")
        icon.name: "office-chart-line"
    }

    // Main content
    QQC2.ScrollView {
        anchors.fill: parent
        anchors.bottomMargin: paginationBar.height
        visible: !clientApi.isLoading && paymentsData && paymentsData.data && paymentsData.data.length > 0

        DKTableView {
            id: paymentsTable
            model: ListModel {}
            alternatingRows: true

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18n("Date")
                    textRole: "payment_date"
                    minimumWidth: paymentsDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Reference")
                    textRole: "reference_number"
                    minimumWidth: paymentsDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Amount")
                    textRole: "amount"
                    minimumWidth: paymentsDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Method")
                    textRole: "payment_method"
                    minimumWidth: paymentsDialog.width * 0.15
                    width: minimumWidth
                },
                Tables.HeaderComponent {
                    title: i18n("Sale Reference")
                    textRole: "sale_reference"
                    minimumWidth: paymentsDialog.width * 0.15
                    width: minimumWidth
                }
            ]
        }
    }

    // Pagination
    footer: PaginationBar {
        id: paginationBar
        currentPage: paymentsData?.current_page || 1
        totalPages: paymentsData?.last_page || 1
        totalItems: paymentsData?.total || 0
        onPageChanged: clientApi.getPayments(dialogClientId, page)
    }

    // Data handling
    property var paymentsData: ({})

    Connections {
        target: clientApi
        function onPaymentsReceived(data) {
            paymentsData = data
            updatePaymentsModel()
        }

        function onErrorPaymentsReceived(message, status, details) {
            applicationWindow().showPassiveNotification(message, "short")
        }
    }

    function updatePaymentsModel() {
        paymentsTable.model.clear()
        if (paymentsData && paymentsData.data) {
            paymentsData.data.forEach(function(payment) {
                paymentsTable.model.append({
                    payment_date: Qt.formatDateTime(new Date(payment.payment_date), "yyyy-MM-dd"),
                    reference_number: payment.reference_number,
                    amount: Number(payment.amount).toLocaleString(Qt.locale(), 'f', 2),
                    payment_method: payment.payment_method,
                    sale_reference: payment.sale_reference
                })
            })
        }
    }

    Component.onCompleted: {
        if (dialogClientId > 0) {
            clientApi.getPayments(dialogClientId)
        }
    }
}
