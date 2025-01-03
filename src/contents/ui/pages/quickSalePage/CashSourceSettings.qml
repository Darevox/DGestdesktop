// CashSourceSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard
//import com.dervox.FavoriteManager

import "../../components"

Kirigami.ScrollablePage {
    id: root
    title: i18n("Cash Source Settings")
    Kirigami.FormLayout {
        Layout.fillWidth: true

        // Current default cash source display
        Label {
            Kirigami.FormData.label: i18n("Current Default:")
            text: defaultCashSourceName
            property string defaultCashSourceName: i18n("None")
        }

        // Cash source selection
        DSearchableComboBoxCashSource {
            Kirigami.FormData.label: i18n("Set Default:")
            Layout.fillWidth: true
            onItemSelected: function(source) {
                favoriteManager.setDefaultCashSource(source.id)
            }
        }

        // List of all cash sources
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 15
            model: cashSourceModel // You'll need to create this

            delegate: ItemDelegate {
                width: ListView.view.width
                highlighted: model.id === favoriteManager.getDefaultCashSource()

                contentItem: RowLayout {
                    Label {
                        text: model.name
                        Layout.fillWidth: true
                    }
                    Button {
                        text: i18n("Set as Default")
                        visible: !parent.highlighted
                        onClicked: favoriteManager.setDefaultCashSource(model.id)
                    }
                }
            }
        }
    }
    // FavoriteManager {
    //     id: favoriteManager
    // }

}
