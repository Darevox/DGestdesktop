// TableHeaderLabel.qml
import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.19 as Kirigami

Component {
    id: tableHeaderLabel
    QQC2.Label {
        text: modelData ?? ""
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        leftPadding: Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        font.bold: true
        QQC2.ToolTip.visible: truncated && hover.hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        QQC2.ToolTip.text: text

        HoverHandler {
            id: hover
            enabled: parent.truncated
        }
    }
}
