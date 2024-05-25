import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts


Rectangle {
    width: parent.width
    height: parent.height
    color: "#263238" // Darker color for the background

    ProcessorSingleton {
        id: processor
    }

    Column {
        anchors.fill: parent
        anchors.centerIn: parent
        spacing: 40


        // Header
        Text {
            text: "Motion Based Authentication"
            font.pixelSize: 24
            color: "white"
            horizontalAlignment: Text.AlignHCenter // Center horizontally
            anchors.horizontalCenter: parent.horizontalCenter
            font.bold: true
            // anchors.horizontalCenter: parent.horizontalCenter // Center horizontally
            anchors.topMargin: 20 // Add top margin to create space between header and body
            anchors.bottomMargin: 10 // Add bottom margin to create space between header and body
        }


        // Divider line
        Rectangle {
            width: parent.width
            height: 1 // Adjust height as needed
            color: "#607d8b" // Lighter color for the line
        }



        // Centered buttons
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter // Center vertically
            spacing: 20

            Button {
                text: "Authenticate"
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 18
                padding: 12
                background: Rectangle {
                    radius: 8
                    color: "#2ecc71" // Button color
                }
                contentItem: Text {
                    text: "Authenticate"
                    color: "white"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter // Center horizontally
                    verticalAlignment: Text.AlignVCenter // Center vertically
                }

                onClicked: {
                    if (!root.patternDefined) {
                        messageDialog.text = "There is no pattern defined yet!"
                        messageDialog.open()
                    } else {
                        processor.startCapturing()
                        stack.push("AuthenticatePage.qml")
                    }
                }
            }

            Button {
                text: "Define New Pattern"
                font.pixelSize: 18
                padding: 12
                background: Rectangle {
                    radius: 8
                    color: "#3498db" // Button color
                }
                contentItem: Text {
                    text: "Define New Pattern"
                    color: "white"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter // Center horizontally
                    verticalAlignment: Text.AlignVCenter // Center vertically
                }
                onClicked: {
                    // delete processor and create new instance
                    processor.defineNewPattern()
                    stack.push("DefinePatternPage.qml")
                }
            }
        }
    }
    MessageDialog {
                id: messageDialog
                text: ""
                title: "Error"
                buttons: StandardButton.Ok
            }
}
