import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import Qt.labs.qmlmodels
import "../../components"

Kirigami.Dialog {
    id: paymentsDialog
    title: i18n("Payment History - %1", dialogClientName)
    width: applicationWindow().width / 2
    height: Kirigami.Units.gridUnit * 40
    standardButtons: Kirigami.Dialog.Close

    property int dialogClientId: 0
    property string dialogClientName: ""

    // Main content
    contentItem: Item {
        QQC2.ScrollView {
        // anchors.fill: parent
        anchors.bottomMargin: paginationBar.height
        visible: !clientApi.isLoading && paymentsData && paymentsData.data && paymentsData.data.length > 0
        Layout.margins :  Kirigami.Units.largeSpacing

        Tables.KTableView {
            id: paymentsTable
            alternatingRows: true
            Layout.margins :  Kirigami.Units.largeSpacing
            clip:true
            model: TableModel {
                id: tableModel

                TableModelColumn { display: "date" }
                TableModelColumn { display: "reference" }
                TableModelColumn { display: "amount" }
                TableModelColumn { display: "method" }
                TableModelColumn { display: "sale_reference" }

                rows: []
            }

            headerComponents: [
                Tables.HeaderComponent {
                    title: i18n("Date")
                    width: paymentsDialog.width * 0.2
                    role: 1
                    itemDelegate: QQC2.Label {
                        text: modelData ? Qt.formatDateTime(new Date(modelData), "dd/MM/yyyy") : ""
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Reference")
                    width: paymentsDialog.width * 0.2
                    role: 2
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Amount")
                    width: paymentsDialog.width * 0.2
                    role: 3
                    itemDelegate: QQC2.Label {
                        text: modelData ? Number(modelData).toLocaleString(Qt.locale(), 'f', 2) : "0.00"
                        horizontalAlignment: Text.AlignRight
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Method")
                    width: paymentsDialog.width * 0.2
                    role: 4
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        padding: Kirigami.Units.smallSpacing
                    }
                },
                Tables.HeaderComponent {
                    title: i18n("Sale Reference")
                    width: paymentsDialog.width * 0.2
                    role: 5
                    itemDelegate: QQC2.Label {
                        text: modelData || ""
                        padding: Kirigami.Units.smallSpacing
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
            text: i18n("No payment records found")
            visible: !clientApi.isLoading && (!paymentsData || paymentsData.data.length === 0)
            icon.name: "office-chart-line"
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

    property var paymentsData: ({})

    Connections {
        target: clientApi
        function onPaymentsReceived(data) {
            console.log("Received payments data:", JSON.stringify(data));
            paymentsData = data;
            updatePaymentsModel();
        }
    }

    function updatePaymentsModel() {
        if (paymentsData && paymentsData.data) {
            let newRows = paymentsData.data.map(payment => ({
                                                                date: payment.payment_date,
                                                                reference: payment.reference_number,
                                                                amount: payment.amount,
                                                                method: payment.payment_method,
                                                                sale_reference: payment.sale_reference
                                                            }));
            console.log("Updating payment rows:", JSON.stringify(newRows));
            tableModel.rows = newRows;
        }
    }

    onDialogClientIdChanged: {
        if (dialogClientId > 0) {
            clientApi.getPayments(dialogClientId)
        }
    }
}
