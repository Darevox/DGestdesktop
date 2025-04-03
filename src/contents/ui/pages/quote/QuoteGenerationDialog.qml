// InvoiceGenerationDialog.qml
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
import "../../components"

Kirigami.Dialog {
    id: generationDialog
    title: isQuote ? i18n("Generate Quote") : i18n("Generate Invoice")

    property bool isQuote: false
    property int documentId: -1
    property bool useDefaultConfig: true
    standardButtons: Kirigami.Dialog.NoButton

    width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 32)

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // Busy indicator
        DBusyIndicator {
            id: busyIndicator
            Layout.alignment: Qt.AlignCenter
            running: saleApi.isLoading
            visible: running
        }

        Kirigami.Heading {
            level: 2
            text: isQuote ?
                      i18n("Generate Quote Document") :
                      i18n("Generate Invoice Document")
            Layout.alignment: Qt.AlignHCenter
        }

        FormCard.FormSwitchDelegate {
            text: i18n("Use Default Settings")
            checked: useDefaultConfig
            description: i18n("Use the default document settings")
            onCheckedChanged: useDefaultConfig = checked
        }

        // Custom config panel, shown when not using defaults
        ColumnLayout {
            visible: !useDefaultConfig
            enabled: !useDefaultConfig
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Layout.margins:      Kirigami.Units.largeSpacing

            Kirigami.Heading {
                level: 4
                text: i18n("Document Options")
            }

            QQC2.CheckBox {
                id: showClientInfoCheck
                text: i18n("Show Client Information")
                checked: documentConfigManager.showClientInfo
            }

            QQC2.CheckBox {
                id: showAmountInWordsCheck
                text: i18n("Show Amount in Words")
                checked: documentConfigManager.showAmountInWords
            }

            QQC2.CheckBox {
                id: showPaymentMethodsCheck
                text: i18n("Show Payment Methods")
                checked: documentConfigManager.showPaymentMethods
            }

            QQC2.CheckBox {
                id: showTaxNumbersCheck
                text: i18n("Show Tax Numbers")
                checked: documentConfigManager.showTaxNumbers
            }

            QQC2.CheckBox {
                id: showNotesCheck
                text: i18n("Show Notes")
                checked: documentConfigManager.showNotes
            }
            QQC2.CheckBox {
                id: showThanksMessageCheck
                text: i18n("Show Thanks Message")
                checked: documentConfigManager.showThanksMessage
            }

            QQC2.CheckBox {
                id: showTermsCheck
                text: i18n("Show Terms & Conditions")
                checked: documentConfigManager.showTermsConditions
            }

            QQC2.CheckBox {
                id: logoEnabledCheck
                text: i18n("Show Logo")
                checked: documentConfigManager.logoEnabled
            }
        }
    }

    footer: QQC2.DialogButtonBox {
        standardButtons: QQC2.DialogButtonBox.Cancel

        QQC2.Button {
            text: i18n("Generate Document")
            icon.name: "document-export"
            QQC2.DialogButtonBox.buttonRole: QQC2.DialogButtonBox.AcceptRole

            enabled: !saleApi.isLoading
            onClicked: {
                console.log("Generate button clicked, useDefaultConfig:", useDefaultConfig);

                // Create the request object
                let configData = {};

                if (!useDefaultConfig) {
                    // Create flat configuration object with the form values
                    configData = {
                        showClientInfo: showClientInfoCheck.checked,
                        showAmountInWords: showAmountInWordsCheck.checked,
                        showPaymentMethods: showPaymentMethodsCheck.checked,
                        showTaxNumbers: showTaxNumbersCheck.checked,
                        showNotes: showNotesCheck.checked,
                        showThanksMessage: showThanksMessageCheck.checked,
                        showTermsConditions: showTermsCheck.checked,
                        logoEnabled: logoEnabledCheck.checked,
                        primaryColor: documentConfigManager.primaryColor,
                        defaultNotes: documentConfigManager.defaultNotes,
                        defaultTerms: documentConfigManager.defaultTerms,
                        footerText: documentConfigManager.footerText,
                        thanksMessage: documentConfigManager.thanksMessage
                    };
                }
                else  {
                    // Create flat configuration object with the form values
                    configData = {
                        showClientInfo: documentConfigManager.showClientInfo,
                        showAmountInWords: documentConfigManager.showAmountInWords,
                        showPaymentMethods: documentConfigManager.showPaymentMethods,
                        showTaxNumbers: documentConfigManager.showTaxNumbers,
                        showNotes: documentConfigManager.showNotes,
                        showThanksMessage: documentConfigManager.showThanksMessage,
                        showTermsConditions: documentConfigManager.showTermsConditions,
                        logoEnabled: documentConfigManager.logoEnabled,
                        primaryColor: documentConfigManager.primaryColor,
                        defaultNotes: documentConfigManager.defaultNotes,
                        defaultTerms: documentConfigManager.defaultTerms,
                        footerText: documentConfigManager.footerText,
                        thanksMessage: documentConfigManager.thanksMessage
                    };
                }

                console.log("Sending config:", JSON.stringify(configData));
                saleApi.generateInvoice(documentId, configData);
            }


        }
    }

    Connections {
        target: saleApi

        function onInvoiceGenerated(invoice) {
            generationDialog.close();

            // Show success notification
            applicationWindow().showPassiveNotification(
                        i18n("Document generated successfully"),
                        "short"
                        );

            // Open the invoice URL if available
            if (invoice.url) {
                Qt.openUrlExternally(invoice.url);
            }
        }

        function onErrorInvoiceGenerated(message) {
            applicationWindow().showPassiveNotification(
                        i18n("Error: %1", message),
                        "long"
                        );
        }
    }
}
