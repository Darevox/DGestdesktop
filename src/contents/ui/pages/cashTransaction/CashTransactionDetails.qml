// TransactionDetailsSheet.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.tableview as Tables
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"
import "."
Kirigami.Dialog {
    id: transactionDetailsSheet
    preferredWidth: Kirigami.Units.gridUnit * 50
    property var transaction: ({})
    title : i18n("Transaction Details")
    RowLayout {
        spacing: Kirigami.Units.largeSpacing
        // Basic Transaction Info
        FormCard.FormCard {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            FormCard.FormTextDelegate {
                text: i18n("Reference Number")
                description: transaction.reference_number || ""
            }

            FormCard.FormTextDelegate {
                text: i18n("Date")
                description: Qt.formatDateTime(new Date(transaction.transaction_date), "dd/MM/yyyy hh:mm")
            }

            FormCard.FormTextDelegate {
                text: i18n("Type")
                description: {
                    switch(transaction.type) {
                    case "transfer": return i18n("Transfer")
                    case "deposit": return i18n("Deposit")
                    case "withdrawal": return i18n("Withdrawal")
                    default: return transaction.type || ""
                    }
                }
            }

            FormCard.FormTextDelegate {
                text: i18n("Amount")
                description: Number(transaction.amount).toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormTextDelegate {
                text: i18n("Category")
                description: transaction.category || i18n("Uncategorized")
                visible: transaction.category !== ""
            }

            FormCard.FormTextDelegate {
                text: i18n("Description")
                description: transaction.description || i18n("No description")
            }
        }

        // Source Account Details
        FormCard.FormCard {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.fillHeight: true
            Kirigami.Heading {
                Layout.margins : Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignTop
                text: transaction.type === "transfer" ? i18n("Source Account") : i18n("Account")
            }
            FormCard.FormTextDelegate {
                text: i18n("Name")
                description: transaction.cash_source?.name || ""
            }

            FormCard.FormTextDelegate {
                text: i18n("Type")
                description: {
                    switch(transaction.cash_source?.type) {
                    case "cash": return i18n("Cash")
                    case "bank": return i18n("Bank Account")
                    default: return transaction.cash_source?.type || ""
                    }
                }
            }

            FormCard.FormTextDelegate {
                text: i18n("Current Balance")
                description: Number(transaction.cash_source?.balance).toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormTextDelegate {
                text: i18n("Account Number")
                description: transaction.cash_source?.account_number || i18n("N/A")
                visible: transaction.cash_source?.type === "bank"
            }

            FormCard.FormTextDelegate {
                text: i18n("Bank Name")
                description: transaction.cash_source?.bank_name || i18n("N/A")
                visible: transaction.cash_source?.type === "bank"
            }

            FormCard.FormTextDelegate {
                text: i18n("Status")
                description: transaction.cash_source?.status || ""
            }
        }

        // Destination Account Details (for transfers)
        FormCard.FormCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.alignment: Qt.AlignTop
            visible: transaction.type === "transfer" && transaction.transfer_destination
            Kirigami.Heading {
                text: i18n("Destination Account")
                Layout.margins : Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignTop

            }

            FormCard.FormTextDelegate {
                text: i18n("Name")
                description: transaction.transfer_destination?.name || ""
            }

            FormCard.FormTextDelegate {
                text: i18n("Type")
                description: {
                    switch(transaction.transfer_destination?.type) {
                    case "cash": return i18n("Cash")
                    case "bank": return i18n("Bank Account")
                    default: return transaction.transfer_destination?.type || ""
                    }
                }
            }

            FormCard.FormTextDelegate {
                text: i18n("Current Balance")
                description: Number(transaction.transfer_destination?.balance).toLocaleString(Qt.locale(), 'f', 2)
            }

            FormCard.FormTextDelegate {
                text: i18n("Account Number")
                description: transaction.transfer_destination?.account_number || i18n("N/A")
                visible: transaction.transfer_destination?.type === "bank"
            }

            FormCard.FormTextDelegate {
                text: i18n("Bank Name")
                description: transaction.transfer_destination?.bank_name || i18n("N/A")
                visible: transaction.transfer_destination?.type === "bank"
            }

            FormCard.FormTextDelegate {
                text: i18n("Status")
                description: transaction.transfer_destination?.status || ""
            }
        }

        // Metadata
        FormCard.FormCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.alignment: Qt.AlignTop
            Kirigami.Heading {
                text: i18n("Additional Information")
                Layout.margins : Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignTop

            }

            FormCard.FormTextDelegate {
                text: i18n("Created At")
                description: Qt.formatDateTime(new Date(transaction.cash_source?.created_at), "dd/MM/yyyy hh:mm")
            }

            FormCard.FormTextDelegate {
                text: i18n("Last Updated")
                description: Qt.formatDateTime(new Date(transaction.cash_source?.updated_at), "dd/MM/yyyy hh:mm")
            }
        }
    }
    customFooterActions: [
        Kirigami.Action {
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: transactionDetailsSheet.close()
        }
    ]
    footerLeadingComponent :  QQC2.Button {
        text: i18n("View Source Transactions")
        icon.name: "view-list-details"
        visible: transaction.cash_source?.id
        onClicked: {
            showSourceTransactions(
                        transaction.cash_source.id,
                        transaction.cash_source.name
                        )
            transactionDetailsSheet.close()
        }
    }

    Connections {
        target: cashTransactionApi
        function errorTransactionReceived(message, status, details){
            applicationWindow().gnotification.showNotification("",
                                                               message, // message
                                                               Kirigami.MessageType.Error, // message type
                                                               "short",
                                                               "dialog-close"
                                                               )

        }
    }
}
