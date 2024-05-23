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

    property int data_rate: processor.dataRate

    // Accelerometer
    Processor {
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

        onPathDataProcessed: {
            // Handle processed data from C++
            console.log("Processed Path Data:", result)

            // Split the result string into individual components
            var parts = result.split(",")

            // Extract and parse the data for each path attribute
            path.startX = parseFloat(parts[0].split(":")[1].trim())
            path.startY = parseFloat(parts[1].split(":")[1].trim())
            path.endX = parseFloat(parts[2].split(":")[1].trim())
            path.endY = parseFloat(parts[3].split(":")[1].trim())
            path.direction = parts[4].split(":")[1].trim()
            path.angle = parseFloat(parts[5].split(":")[1].trim())

            // Debug output to verify parsed values
            console.log("Parsed Values: ", path.startX, path.startY, path.endX, path.endY, path.direction, path.angle)

            // Display the parsed result
            patternText.text = "Pattern: " + path.startX + ", " + path.startY + ", " + path.endX + ", " + path.endY + ", " + path.direction + ", " + path.angle
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
 
        // set mode to User that don't use the gravity
        // mode: Accelerometer.User


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
            // let firstCall = false
            // if (lastTimeStamp == 0) {
            //     firstCall = true
            // }
            // let timeSinceLast = reading.timestamp - lastTimeStamp
            // lastTimeStamp = reading.timestamp

            // //Skipping the initial time jump from 0
            // if (firstCall === true)
            //     return
            // let normalizedX = x * (timeSinceLast / 1000000)
            // imageXRotation.angle += normalizedX
            // let normalizedY = y * (timeSinceLast / 1000000)
            // imageYRotation.angle -= normalizedY
            // let normalizedZ = z * (timeSinceLast / 1000000)
            // imageZRotation.angle += normalizedZ

            processor.processGyroscopeData(x, y, z)
        }
    }

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
            // set right alignment
            horizontalAlignment: Text.AlignHCenter
        }

        // Display pattern data received from C++ in a rectangle as vector. received path is like QString("Path: startX: %1, startY: %2, endX: %3, endY: %4, direction: %5, angle: %6")
        Rectangle {
            width: 200
            height: 200
            color: "black"
            border.color: "white"
            border.width: 2
            // center the rectangle
            anchors.horizontalCenter: parent.horizontalCenter
            
            CustomPath {
                id: path
                startX: 0
                startY: 0
                endX: 0
                endY: 0
                direction: ""
                angle: 0
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
