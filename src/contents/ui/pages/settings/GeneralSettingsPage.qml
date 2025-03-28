import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

FormCard.FormCardPage {
    id: generalSettingsPage
    title: i18nc("@title", "General Settings")

    FormCard.FormHeader {
        title: i18nc("@title:group", "Appearance")
    }

    FormCard.FormCard {
        FormCard.FormComboBoxDelegate {
            id: combobox
            text: i18nc("@label:listbox", "Current Color Scheme")
            displayMode: FormCard.FormComboBoxDelegate.ComboBox
            editable: false
            model: isEmpty ? [{"display": i18nc("@label:listbox", "No color schemes available")}] : applicationWindow().gColorSchemeModel
            textRole: "display"
            valueRole: "index"
            currentIndex: applicationWindow().gColorSchemeModel.activeSchemeIndex
            property bool isEmpty: applicationWindow().gColorSchemeModel.count === 0

            onCurrentIndexChanged: {
                applicationWindow().gColorSchemeModel.activateScheme(currentIndex);
            }
        }

        FormCard.FormSectionText{
            text: i18n("Scale UI")
        }

        FormCard.FormSectionText {
            RowLayout {
                anchors.fill: parent
                QQC2.Slider {
                    id: scaleSlider
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    from: 50
                    to: 200
                    stepSize: 5
                    snapMode: QQC2.Slider.SnapOnRelease
                    value: appSettings.scaleValue

                    property bool wasPressed: false

                    onPressedChanged: {
                        if (pressed) {
                            wasPressed = true;
                        } else if (wasPressed) {
                            wasPressed = false;
                            if (value !== appSettings.scaleValue) {
                                restartPromptDialog.open();
                            }
                        }
                    }
                }
                QQC2.Label {
                    text: scaleSlider.value + "%"
                }
            }
        }
        FormCard.FormSectionText{
            text: i18n("")
        }
    }

    Kirigami.PromptDialog {
        id: restartPromptDialog
        title: i18n("Scale Change")
        subtitle: i18n("The application needs to restart to apply the new scale. Do you want to restart now?")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            appSettings.applyScale(scaleSlider.value)
            appSettings.makeRestart()
        }
        onRejected: {
            scaleSlider.value = appSettings.scaleValue
        }
    }
}
