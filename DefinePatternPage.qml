import QtQuick
import QtQuick.Controls
import QtSensors
import QtQuick.Dialogs

Rectangle {
    width: parent.width
    height: parent.height
    color: "black"

    property var newPattern: []

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "Define your new pattern!"
            font.pixelSize: 20
            color: "white"
        }

        // Add sensor components here to capture new pattern
        // Example only; proper sensor integration needed

        Button {
            text: "Finish"
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 22
            padding: 14
            onClicked: {
                ApplicationWindow.patternDefined = true
                ApplicationWindow.storedPattern = newPattern

                // Show popup message
                popup.open()
                // Automatically close the popup after a delay
                popupTimer.start()
            }
        }

        Button {
            text: "Back"
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 16
            padding: 10
            onClicked: {
                stack.pop()
            }
        }

        Popup {
            id: popup
            modal: true
            width: 350
            height: 200
            visible: false
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            Text {
                text: "Pattern Defined Successfully!"
                color: "Black"
                font.pixelSize: 16
                anchors.centerIn: parent.Center
                horizontalAlignment: Text.AlignHCenter // Center horizontally
                verticalAlignment: Text.AlignVCenter // Center vertically
            }

            Button {
                text: "Ok"
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    popup.close()
                    stack.pop()
                }
            }
        }

        // Timer {
        //     id: popupTimer
        //     interval: 3000 // 3 seconds
        //     repeat: false
        //     onTriggered: {
        //         popup.close()
        //         stack.pop()
        //     }
        // }
    }
}
