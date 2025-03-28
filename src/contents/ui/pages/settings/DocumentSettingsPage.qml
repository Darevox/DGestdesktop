// DocumentSettingsPage.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import "../../components"
import org.kde.kirigamiaddons.components 1.0 as KirigamiComponents
import Qt.labs.platform 1.1 as Platform

Kirigami.ScrollablePage {
    id: documentSettingsPage
    title: i18nc("@title", "Document Settings")

    property bool isLoading: false
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.ToolBar

    header: QQC2.ToolBar {
        contentItem: RowLayout {
            Item { Layout.fillWidth: true }

            QQC2.Button {
                text: i18n("Reset to Defaults")
                icon.name: "edit-reset"
                onClicked: {
                    resetDialog.open()
                }
            }

            QQC2.Button {
                text: i18n("Save Settings")
                icon.name: "document-save"
                highlighted: true
                onClicked: {
                    documentConfigManager.saveDocumentConfig()
                }
            }
        }
    }

    // Reset confirmation dialog
    Kirigami.PromptDialog {
        id: resetDialog
        title: i18n("Reset Settings")
        subtitle: i18n("Are you sure you want to reset all document settings to defaults?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            documentConfigManager.resetToDefaults()
        }
    }

    // Main content
    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Kirigami.Units.largeSpacing

        // Two-column layout
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing

            // Left column - Settings
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1.5
                spacing: Kirigami.Units.largeSpacing

                // Document Content Section
                FormCard.FormHeader {
                    title: i18nc("@title:group", "Document Content")
                    Layout.fillWidth: true
                }

                FormCard.FormCard {
                    Layout.fillWidth: true

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Client Information")
                        checked: documentConfigManager.showClientInfo
                        description: i18n("Display client details (name, address, contact info)")
                        onCheckedChanged: {
                            documentConfigManager.setShowClientInfo(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Amount in Words")
                        checked: documentConfigManager.showAmountInWords
                        description: i18n("Display the total amount written in words")
                        onCheckedChanged:{
                            documentConfigManager.setShowAmountInWords(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Payment Methods")
                        checked: documentConfigManager.showPaymentMethods
                        description: i18n("Display payment methods used for this transaction")
                        onCheckedChanged:{

                            documentConfigManager.setShowPaymentMethods(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Tax Numbers")
                        checked: documentConfigManager.showTaxNumbers
                        description: i18n("Display tax identification numbers (RC, NIF..)")
                        onCheckedChanged: {

                            documentConfigManager.setShowTaxNumbers(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Notes")
                        checked: documentConfigManager.showNotes
                        description: i18n("Display additional notes on documents")
                        onCheckedChanged: {

                            documentConfigManager.setShowNotes(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Thanks Message")
                        checked: documentConfigManager.showThanksMessage
                        description: i18n("Display additional Thanks Message on documents")
                        onCheckedChanged: {

                            documentConfigManager.setShowThanksMessage(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Terms & Conditions")
                        checked: documentConfigManager.showTermsConditions
                        description: i18n("Display terms and conditions on documents")
                        onCheckedChanged: {

                            documentConfigManager.setShowTermsConditions(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }
                }

                // Appearance Section
                FormCard.FormHeader {
                    title: i18nc("@title:group", "Appearance")
                    Layout.fillWidth: true
                }

                FormCard.FormCard {
                    Layout.fillWidth: true

                    FormCard.FormSwitchDelegate {
                        text: i18n("Show Logo")
                        checked: documentConfigManager.logoEnabled
                        description: i18n("Display company logo on documents")
                        onCheckedChanged:{

                            documentConfigManager.setLogoEnabled(checked)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: Kirigami.Units.smallSpacing

                        QQC2.Label {
                            text: i18n("Theme Color:")
                        }

                        Rectangle {
                            id: colorPreview
                            width: Kirigami.Units.gridUnit * 2
                            height: Kirigami.Units.gridUnit * 2
                            color: documentConfigManager.primaryColor
                            border.width: 1
                            border.color: Kirigami.Theme.disabledTextColor
                            radius: 3

                            MouseArea {
                                anchors.fill: parent
                                onClicked: colorDialog.open()
                            }
                        }

                        QQC2.Label {
                            text: documentConfigManager.primaryColor
                            font.family: "monospace"
                        }

                        Platform.ColorDialog {
                            id: colorDialog
                            title: i18n("Select Theme Color")
                            currentColor: documentConfigManager.primaryColor
                            options: Platform.ColorDialog.ShowAlphaChannel

                            onAccepted: {
                                // Convert to hex format
                                const hex = color.toString().substr(0, 7)
                                documentConfigManager.setPrimaryColor(hex)
                                documentPreview.config = getPreviewConfig();
                            }
                        }
                    }
                }

                // Default Text Section
                FormCard.FormHeader {
                    title: i18nc("@title:group", "Default Text")
                    Layout.fillWidth: true
                }

                FormCard.FormCard {
                    Layout.fillWidth: true

                    FormCard.FormTextAreaDelegate {
                        label: i18n("Default Notes")
                        text: documentConfigManager.defaultNotes
                        placeholderText: i18n("Enter default notes to appear on invoices")
                        onTextChanged: {

                            documentConfigManager.setDefaultNotes(text)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormTextAreaDelegate {
                        label: i18n("Default Thanks Message")
                        text: documentConfigManager.thanksMessage
                        placeholderText: i18n("Enter default Thanks Message to appear on invoices")
                        onTextChanged: {

                            documentConfigManager.setThanksMessage(text)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormTextAreaDelegate {
                        label: i18n("Default Terms & Conditions")
                        text: documentConfigManager.defaultTerms
                        placeholderText: i18n("Enter default terms to appear on documents")
                        onTextChanged: {

                            documentConfigManager.setDefaultTerms(text)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormTextAreaDelegate {
                        label: i18n("Footer Text")
                        text: documentConfigManager.footerText
                        placeholderText: i18n("Use %teamName%, %teamEmail%, %teamPhone% as variables")
                        onTextChanged: {

                            documentConfigManager.setFooterText(text)
                            documentPreview.config = getPreviewConfig();
                        }
                    }
                }

                // Numbering Section
                FormCard.FormHeader {
                    title: i18nc("@title:group", "Document Numbering")
                    Layout.fillWidth: true
                    visible : false
                }

                FormCard.FormCard {
                    Layout.fillWidth: true
                    visible : true
                    FormCard.FormTextFieldDelegate {
                        label: i18n("Invoice Prefix")
                        text: documentConfigManager.invoicePrefix
                        placeholderText: i18n("e.g. INV-")
                        onTextChanged: {

                            documentConfigManager.setInvoicePrefix(text)
                            documentPreview.config = getPreviewConfig();
                        }
                    }

                    FormCard.FormTextFieldDelegate {
                        label: i18n("Quote Prefix")
                        text: documentConfigManager.quotePrefix
                        placeholderText: i18n("e.g. QUOTE-")
                        onTextChanged:{

                            documentConfigManager.setQuotePrefix(text)
                            documentPreview.config = getPreviewConfig();
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            // Right column - Preview
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: 1.2
                spacing: Kirigami.Units.largeSpacing
                Layout.bottomMargin:  parent.height / 3
                Layout.topMargin:   Kirigami.Units.largeSpacing * 4
                // Layout.rightMargin:   Kirigami.Units.largeSpacing * 2
                // FormCard.FormHeader {
                //     title: i18nc("@title:group", "Document Preview")
                //     Layout.fillWidth: true
                // }

                Kirigami.Card {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins:   Kirigami.Units.smallSpacing

                    header: Kirigami.Heading {
                        text: i18n("Document Preview")
                        level: 2
                    }

                    ColumnLayout {

                        //  Layout.preferredHeight: Kirigami.Units.gridUnit * 25  // Added explicit height limit
                        //   Layout.fillHeight: false  // Don't fill all available height
                        anchors.fill: parent
                        anchors.margins:Kirigami.Units.smallSpacing
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Item { Layout.fillWidth: true }
                            QQC2.CheckBox {
                                id: previewAsQuote
                                text: i18n("Preview as Quote")
                                checked: false
                                onCheckedChanged: {
                                    documentPreview.isQuote = checked;
                                    documentPreview.config = getPreviewConfig(); // Update preview when switching
                                }
                            }

                            QQC2.Button {
                                text: i18n("Refresh Preview")
                                icon.name: "view-refresh"
                                visible:false
                                onClicked: {
                                    documentPreview.config = getPreviewConfig();
                                }
                            }
                        }

                        DocumentPreview {
                            id: documentPreview
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            isQuote: previewAsQuote.checked
                            config: getPreviewConfig()
                            teamName: "Your Company"
                            teamEmail: "company@example.com"
                            teamPhone: "+212 555-1234"
                        }
                    }
                }
            }
        }
    }

    // Helper function
    function getPreviewConfig() {
        return {
            showClientInfo: documentConfigManager.showClientInfo,
            showAmountInWords: documentConfigManager.showAmountInWords,
            showPaymentMethods: documentConfigManager.showPaymentMethods,
            showTaxNumbers: documentConfigManager.showTaxNumbers,
            showNotes: documentConfigManager.showNotes,
            showThanksMessage: documentConfigManager.showThanksMessage,
            showTermsConditions: documentConfigManager.showTermsConditions,
            primaryColor: documentConfigManager.primaryColor,
            logoEnabled: documentConfigManager.logoEnabled,
            defaultNotes: documentConfigManager.defaultNotes,
            thanksMessage: documentConfigManager.thanksMessage,
            defaultTerms: documentConfigManager.defaultTerms,
            footerText: documentConfigManager.footerText
        };
    }
}
