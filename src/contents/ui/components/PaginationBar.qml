import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import QtQuick.Layouts 1.15

Rectangle {
    id: paginationBar
    color: "transparent"
    property int currentPage: 1
    property int totalPages: 100
    property int pageSize: 15
    property int totalItems: 0
    signal pageChanged(int page)
    height: 48
    radius: 4

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8

        QQC2.Label {
            text: qsTr("Page %1 of %2").arg(currentPage).arg(totalPages)
            font.pixelSize: 14
            color: "#666666"
            Layout.alignment: Qt.AlignVCenter
         //   visible: totalPages > 1  // Only show label if more than one page
        }

        Item {
            Layout.fillWidth: true
        }

        QQC2.ToolButton {
            id: prevButton
            text: qsTr("<")
            enabled: currentPage > 1
            onClicked: pageChanged(currentPage - 1)
            visible: totalPages > 1  // Only show if more than one page
        }

        Repeater {
            id: pageRepeater
            model: calculatePageModel()

            QQC2.ToolButton {
                property var pageData: modelData
                text: typeof pageData === 'number' ? pageData.toString() : pageData
                enabled: pageData !== '...' && pageData !== currentPage
                onClicked: {
                    if (typeof pageData === 'number') {
                        paginationBar.pageChanged(pageData)
                    }
                }
            }
        }

        QQC2.ToolButton {
            id: nextButton
            text: qsTr(">")
            enabled: currentPage < totalPages
            onClicked: pageChanged(currentPage + 1)
            visible: totalPages > 1  // Only show if more than one page
        }
    }

    // Function to calculate the page model dynamically
    function calculatePageModel() {
        if (totalPages <= 1) {
            return [1];  // Only show page 1 if there's only one page
        }

        let pages = [];

        // Always show first page
        pages.push(1);

        // Logic for middle section
        if (totalPages > 7) {
            // Add ellipsis and surrounding pages based on current page
            if (currentPage > 4) {
                pages.push('...');
            }

            // Calculate surrounding pages
            let start = Math.max(2, currentPage - 1);
            let end = Math.min(totalPages - 1, currentPage + 1);

            for (let i = start; i <= end; i++) {
                pages.push(i);
            }

            // Add ellipsis before last page if needed
            if (currentPage < totalPages - 3) {
                pages.push('...');
            }

            // Always show last page
            pages.push(totalPages);
        } else {
            // If total pages are 7 or less, show all page numbers
            for (let i = 2; i <= totalPages; i++) {
                pages.push(i);
            }
        }

        return pages;
    }

    // Handle the page change and update the current page
    onPageChanged: {
        currentPage = page
    }
}
