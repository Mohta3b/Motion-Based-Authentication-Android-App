import QtQuick
import QtQuick.Controls
import QtSensors
import QtQuick.Dialogs

// import SensorShowcaseModule

Rectangle {
    width: parent.width
    height: parent.height
    color: "black"

    // property var newPattern: []

    property int data_rate: processor.dataRate


    ProcessorSingleton {
        id: processor

        onAccelerometerDataProcessed: {
            // Handle processed data from C++
            // console.log("Processed Accelerometer Data:", result)
            // Display the processed result in QML
            processedAccelerometerDataText.text = result
        }

        onGyroscopeDataProcessed: {
            // Handle processed data from C++
            // console.log("Processed Gyroscope Data:", result)
            // Display the processed result in QML
            processedGyroscopeDataText.text = result
        }

        onLocationDataProcessed: {
            // Handle processed data from C++
            // console.log("Processed Location Data:", result)
            // data is like X: 0.000, Y: 0.000
            // Display the processed result in QML
            var parts = result.split(", ")
            var newX = parseFloat(parts[0].split(":")[1].trim())
            var newY = parseFloat(parts[1].split(":")[1].trim())
            liveLocation.addPoint(newX, newY)
        }

        onPathDataProcessed: {
            // Handle processed data from C++
            console.log("Processed Path Data:", result)

            // Display the processed result in QML
            patternText.text = result
        }
    }


    // Accelerometer
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
            // set right alignment
            horizontalAlignment: Text.AlignHCenter
        }

        // Display pattern data received from C++ in a rectangle as vector. received path is like QString("Path: startX: %1, startY: %2, endX: %3, endY: %4, direction: %5, angle: %6")
        Rectangle {
            width: parent.width - 10
            height: parent.height / 2
            color: "black"
            border.color: "white"
            border.width: 2
            anchors.horizontalCenter: parent.horizontalCenter

            LiveLocation {
                id: liveLocation
                anchors.fill: parent
            }
        }

        Text {
            id: processedAccelerometerDataText
            text: ""
            font.pixelSize: 16
            color: "white"
        }

        Text {
            id: processedGyroscopeDataText
            text: ""
            font.pixelSize: 16
            color: "white"
        }

        Text {
            id: patternText
            text: ""
            font.pixelSize: 14
            color: "red"
        }

        Button {
            text: "Finish"
            anchors.horizontalCenter: parent.horizontalCenter
            // place in the bottom of the screen
            // anchors.bottom: parent.bottom
            font.pixelSize: 22
            padding: 14
            width: parent.width
            // anchors.bottom: parent.bottom
            background: Rectangle {
                color: "green"
                radius: 8  // Optional: if you want rounded corners
            }
            onClicked: {
                root.patternDefined = true

                // send save signal to cpp file
                processor.savePattern()

                // Show popup message
                popup.open()
                // Automatically close the popup after a delay
                // popupTimer.start()
            }
        }

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
