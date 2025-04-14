// Login.qml
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard 1.0 as FormCard
import QtQuick.Layouts
//import Qt5Compat.GraphicalEffects
import com.dervox.dim
import "../."
import "../../components"
Kirigami.Page {
    id: loginPage
    title: i18n("Login")
    header: Kirigami.ApplicationHeaderStyle.None
    globalToolBarStyle: Kirigami.ApplicationHeaderStyle.None
    footer: Kirigami.ApplicationHeaderStyle.None

    property bool showNoPage: false
    property bool isLoading: false

    QQC2.ScrollView {
        id: scrollView
        anchors.fill: parent

        // Disable horizontal scrolling
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        Item {
            // Ensure the item is at least as tall as the ScrollView
            width: scrollView.width
            height: Math.max(scrollView.height, mainLayout.implicitHeight)

            ColumnLayout {
                id: mainLayout
                anchors.centerIn: parent  // This centers both vertically and horizontally
                width: Math.min(parent.width - (Kirigami.Settings.isMobile ? 0 : Kirigami.Units.largeSpacing * 4),
                                Kirigami.Units.gridUnit * 50)

                // Status message
                Kirigami.InlineMessage {
                    id: statusMessage
                    Layout.fillWidth: true
                    visible: false
                    showCloseButton: !Kirigami.Settings.isMobile
                }

                FormCard.FormCard {
                    id: formCard
                    Layout.fillWidth: true

                    // Logo section
                    // Custom logo item that respects the form layout
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 12  // Give enough height

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Kirigami.Units.largeSpacing

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "DIM"
                                font {
                                    pointSize: 72
                                    weight: Font.Bold
                                    family: "Arial"
                                }
                                color: Kirigami.Theme.activeTextColor
                            }

                            Kirigami.Heading {
                                Layout.alignment: Qt.AlignHCenter
                                text: i18n("Welcome back!")
                                level: 1
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }


                    FormCard.FormDelegateSeparator {}

                    FormCard.FormTextFieldDelegate {
                        id: emailField
                        label: i18n("Email")
                        statusMessage: ""
                        status: Kirigami.MessageType.Information
                        placeholderText: i18n("Enter your email")
                        enabled: !loginPage.isLoading

                        onAccepted: passwordField.forceActiveFocus()

                        validator: RegularExpressionValidator {
                            regularExpression: /\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/
                        }
                    }

                    FormCard.FormPasswordFieldDelegate {
                        id: passwordField
                        label: i18n("Password")
                        statusMessage: ""
                        status: Kirigami.MessageType.Information
                        placeholderText: i18n("Enter your password")
                        enabled: !loginPage.isLoading

                        onAccepted: loginButton.clicked()
                    }

                    FormCard.FormCheckDelegate {
                        id: rememberMeCheck
                        text: i18n("Keep me signed in")
                        enabled: !loginPage.isLoading
                    }

                    FormCard.FormDelegateSeparator {}

                    // Login button section
                    FormCard.FormTextDelegate {
                        contentItem: ColumnLayout {
                            spacing: Kirigami.Units.largeSpacing

                            QQC2.Button {
                                id: loginButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                text: i18n("Sign In")
                                enabled: !loginPage.isLoading &&
                                         emailField.text.length > 0 &&
                                         passwordField.text.length > 0

                                onClicked: performLogin()
                            }

                            DBusyIndicator {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                                running: loginPage.isLoading
                                visible: running
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: Kirigami.Units.smallSpacing

                                QQC2.Label {
                                    text: i18n("Don't have an account?")
                                }

                                QQC2.Label {
                                    text: i18n("Sign Up!")
                                    color: Kirigami.Theme.linkColor

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("https://dim.dervox.com")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // No page component
    NoPage {
        id: noPage
        anchors.fill: parent
        visible: loginPage.showNoPage
        onReconnectClicked: {
            loginPage.showNoPage = false
            noPage.isRequasting = true
            loginPage.checkLoginStatus()
        }
    }
    DBusyIndicator {
        anchors.centerIn:  parent
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
        running: noPage.isRequasting
        visible: running
    }
    // API Connections
    Connections {
        target: api
        function onLoginError(message, status, errorMessageDetails) {
            showError(message + " " + errorMessageDetails, status)
            loginPage.isLoading = false
        }

        function onUserInfoReceived() {
            handleSuccessfulLogin()
        }

        function onUserInfoError(message, status, errorMessageDetails) {
            handleUserInfoError(message, status, errorMessageDetails)
        }
    }

    Connections {
        target: subscriptionApi

        function onStatusReceived() {
            const statusPlan = subscriptionApi.getStatusString()
            if (statusPlan !== "active") {
                expiredDialog.active = true
            } else {
                // applicationWindow().pageStack.replace(
                //     Qt.createComponent("com.dervox.dim", "Welcome")
                // )
                applicationWindow().loadGlobalDrawer()
                applicationWindow().loadHeader()
                // applicationWindow().pageStack.clear()
                // applicationWindow().pageStack.push(Qt.createComponent("com.dervox.dim", "Dashboard"))
            }
        }
    }

    // Subscription expired dialog
    Loader {
        id: expiredDialog
        active: false
        asynchronous: true

        onLoaded: item.open()
        sourceComponent:ExpiredSubscription{}
        Connections {
            target: expiredDialog.item
            function onClosed() {
                api.logout()
                loginPage.isLoading = false
                expiredDialog.active = false
            }
        }
    }

    // Auto-login check timer
    Timer {
        id: loginCheckTimer
        interval: 300
        repeat: false
        running: true

        onTriggered: checkLoginStatus()
    }

    // Functions
    function performLogin() {
        if (!emailField.acceptableInput) {
            showError(i18n("Please enter a valid email address"),
                      Kirigami.MessageType.Warning)
            return
        }

        loginPage.isLoading = true
        api.login(emailField.text, passwordField.text, rememberMeCheck.checked)
    }

    function handleSuccessfulLogin() {
        const token = api.getToken()
        noPage.isRequasting = false
        // Helper function to set token
        function setApiToken(api, token) {
            try {
                if (typeof api.saveToken === "function") {
                    api.saveToken(token)
                } else if (api.token !== undefined) {
                    api.token = token
                } else {
                    console.warn("No method to set token for API:", api)
                }
            } catch (error) {
                console.error("Error setting token for API:", api, error)
            }
        }

        // List of all APIs
        const apiList = {
            subscription: subscriptionApi,
            team: teamApi,
            product: productApi,
            productFetch: productApiFetch,
            activityLog: activityLogApi,
            supplier: supplierApi,
            cashSource: cashSourceApi,
            cashSourceFetch: cashSourceApiFetch,
            cashTransaction: cashTransactionApi,
            purchase: purchaseApi,
            client: clientApi,
            clientFetch: clientApiFetch,
            sale: saleApi,
            invoice: invoiceApi,
            dashboardAnalytics: dashboardAnalyticsApi
        }

        // Set token for each API
        try {
            Object.values(apiList).forEach(api => setApiToken(api, token))

            // Get subscription status after setting tokens
            subscriptionApi.getStatus(token)
        } catch (error) {
            console.error("Error in handleSuccessfulLogin:", error)
            updateStatusMessage(i18n("Error setting up application. Please try again."),
                                Kirigami.MessageType.Error)
        }
    }


    function handleUserInfoError(message, status, errorMessageDetails) {
        loginPage.isLoading = false
        noPage.isRequasting = false
        const messageType = gApiStatusHandler.getMessageType(status)
        if (messageType === Kirigami.MessageType.Error) {
            loginPage.showNoPage = true
            scrollView.visible=false
            noPage.isRequasting = false
        } else if (messageType === Kirigami.MessageType.Warning) {
            api.saveToken("")
            applicationWindow().pageStack.replace(
                        Qt.resolvedUrl("qrc:/dim/contents/ui/pages/user/Login.qml")
                        )
        } else {
            showError(message + " " + errorMessageDetails, status)
        }
    }

    function showError(message, status) {
        statusMessage.type = gApiStatusHandler.getMessageType(status)
        statusMessage.text = message
        statusMessage.visible = true
    }

    function checkLoginStatus() {
        if (api.getRememberMe() && api.isLoggedIn()) {
            loginPage.isLoading = true
            api.getUserInfo()
        } else {
            loginPage.isLoading = false
        }
    }
    Component.onCompleted:{

    }
}
