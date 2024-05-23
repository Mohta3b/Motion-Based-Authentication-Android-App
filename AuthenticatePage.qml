import QtQuick
import QtQuick.Controls
import QtSensors
import QtQuick.Dialogs

Rectangle {
    width: parent.width
    height: parent.height

    property var inputPattern: []

    

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "Perform your pattern"
        }

        // Add sensor components here to capture user pattern
        // Example only; proper sensor integration needed

        Button {
            text: "Finish"
            onClicked: {
                if (JSON.stringify(inputPattern) === JSON.stringify(ApplicationWindow.storedPattern)) {
                    messageDialog.text = "Authentication Successful!"
                } else {
                    messageDialog.text = "Authentication Denied!"
                }
                messageDialog.open()
            }
        }

        Button {
            text: "Back"
            onClicked: {
                stack.pop()
            }
        }

        MessageDialog {
            id: messageDialog
            text: ""
            title: "Result"
            buttons: StandardButton.Ok
        }
    }
}
