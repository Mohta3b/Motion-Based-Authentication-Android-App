import QtQuick
import QtQuick.Controls
import QtSensors
import QtQuick.Dialogs

import SensorShowcaseModule

Rectangle {
    width: parent.width
    height: parent.height
    color: "black"

    property var newPattern: []

    property int data_rate: 5 // every 1/n second

    // Accelerometer
    Processor {
        id: processor
        onAccelerometerDataProcessed: {
            // Handle processed data from C++
            console.log("Processed Accelerometer Data:", result)
            // Display the processed result in QML
            processedDataText.text = result
        }
    }

    Accelerometer {
        id: accelerometer

        property real x: 0
        property real y: 0
        property real z: 0

        active: true
        dataRate: data_rate

        onReadingChanged: {
            x = (reading as AccelerometerReading).x
            y = (reading as AccelerometerReading).y
            z = (reading as AccelerometerReading).z
            // imageTranslation.x = -x * 10
            // imageTranslation.y = y * 10

            // var reading = accelerometer.reading

            processor.processAccelerometerData(x, y, z)
        }
    }

    // Gyroscope
    Gyroscope {
        id: gyroscope

        property real x: 0
        property real y: 0
        property real z: 0

        active: true
        dataRate: data_rate

        onReadingChanged: {
            x = (reading as GyroscopeReading).x
            y = (reading as GyroscopeReading).y
            z = (reading as GyroscopeReading).z

            processor.processGyroscopeData(x, y, z)
        }
    }

    // Button {
    //     text: "Back"
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.top: parent.top
    //     anchors.left: parent.left
    //     anchors.margins: 10
    //     font.pixelSize: 14
    //     padding: 10
    //     width: parent.width / 5
    //     onClicked: {
    //         stack.pop()
    //     }
    // }

    // ToolButton {
    //     id: back
    //     text: qsTr("Back")
    //     background: "white"
    //     palette {
    //         buttonText: "black"
    //     }
    //     font.pixelSize: root.defaultFontSize - 4
    //     visible: stack.depth > 1
    //     onClicked: {
    //         stack.pop();
    //         // heading.text = root.title;
    //     }
    // }

    Button {
        text: "Back"
        anchors.left: parent.left + 2
        font.pixelSize: 16
        padding: 10
        onClicked: {
            stack.pop()
        }
    }


    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "Define your new pattern!"
            font.pixelSize: 20
            color: "white"
        }

        Text {
            id: processedDataText
            text: ""
            font.pixelSize: 16
            color: "white"
        }


        // Add sensor components here to capture new pattern
        // Example only; proper sensor integration needed
        // ProgressXYZBar {
        //     // Layout.fillWidth: true
        //     fontSize: root.fontSize
        //     xText: "X: " + accelerometer.x.toFixed(2)
        //     xValue: 0.5 + (accelerometer.x / 100)
        //     yText: "Y: " + accelerometer.y.toFixed(2)
        //     yValue: 0.5 + (accelerometer.y / 100)
        //     zText: "Z: " + accelerometer.z.toFixed(2)
        //     zValue: 0.5 + (accelerometer.z / 100)

        // }

        Button {
            text: "Finish"
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 22
            padding: 14
            width: parent.width
            // anchors.bottom: parent.bottom
            background: Rectangle {
                color: "green"
                radius: 8  // Optional: if you want rounded corners
            }
            onClicked: {
                ApplicationWindow.patternDefined = true
                ApplicationWindow.storedPattern = newPattern

                // Show popup message
                popup.open()
                // Automatically close the popup after a delay
                popupTimer.start()
            }
        }


        // Button {
        //     text: "Back"
        //     anchors.horizontalCenter: parent.horizontalCenter
        //     font.pixelSize: 16
        //     padding: 10
        //     onClicked: {
        //         stack.pop()
        //     }
        // }

        Popup {
            id: popup
            modal: true
            width: 300
            height: 150
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
