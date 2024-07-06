import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
Kirigami.Page {
    Controls.Label {
        // Center label horizontally and vertically within parent object
        anchors.centerIn: parent
        text: i18n("Hello World!")
    }
}
