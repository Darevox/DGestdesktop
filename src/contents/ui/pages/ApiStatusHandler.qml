
import QtQuick 2.15
import org.kde.kirigami as Kirigami

QtObject {
    id: root

    // Define status codes as readonly properties
    readonly property var apiStatus: QtObject {
        readonly property int success: 0
        readonly property int validationError: 1
        readonly property int networkError: 2
        readonly property int serverError: 3
        readonly property int authenticationError: 4
        readonly property int unknownError: 5
    }

    // Map status codes to message types using a function
    function getMessageType(status) {
        switch (status) {
            case apiStatus.networkError:
            case apiStatus.serverError:
                return Kirigami.MessageType.Error
            case apiStatus.authenticationError:
            case apiStatus.validationError:
                return Kirigami.MessageType.Warning
            case apiStatus.success:
                return Kirigami.MessageType.Positive
            default:
                return Kirigami.MessageType.Information
        }
    }
}
