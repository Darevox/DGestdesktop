import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
Kirigami.PromptDialog {
    id: aboutDialog
    title: "About"
    preferredWidth: Kirigami.Units.gridUnit * 24
    standardButtons: Kirigami.Dialog.NoButton
    customFooterActions: [
        Kirigami.Action {
            text: qsTr("Cancel")
            icon.name: "dialog-cancel"
            onTriggered: {
                aboutDialog.close();
            }
        }
    ]

    FormCard.FormHeader {
        title: i18n("App")
    }

    FormCard.FormCard {
        FormCard.FormTextDelegate {
            text: i18n("DGest")
            description: "inventory management and point of sale software"

        }
        FormCard.FormTextDelegate {
            text: i18n("Version")
            description: "1.0 Mona"

        }
        FormCard.FormButtonDelegate {
            id: webSiteButton
            icon.name: "internet-services"
            text: i18n("Home page")
            onClicked: root.pageStack.layers.push(aboutkde)
        }



    }
    FormCard.FormHeader {
        title: i18n("Team")
    }
    FormCard.FormCard {
        FormCard.FormTextDelegate {
            text: i18n("Dervox ")
            description: "Dervox Team © 2024 "
        }
        FormCard.FormButtonDelegate {
            id: webSiteButton1
            icon.name: "internet-services"
            text: i18n("Home page")
            onClicked: root.pageStack.layers.push(aboutkde)
        }

    }


}

