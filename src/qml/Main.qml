import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
Kirigami.ApplicationWindow {
    id: rootWindow
    title: "DGest"
    header: Kirigami.ApplicationHeaderStyle.None
    globalDrawer:  Kirigami.ApplicationHeaderStyle.None
    footer:  Kirigami.ApplicationHeaderStyle.None
    pageStack.initialPage: Qt.resolvedUrl("qrc:/DGest/qml/pages/Login.qml")


}
