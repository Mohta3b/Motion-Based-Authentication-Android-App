import QtQuick
import QtQuick.Controls
import QtSensors
import QtQuick.Dialogs

// import SensorShowcaseModule

Rectangle {
    width: parent.width
    height: parent.height
    color: "#263238"

    // property var newPattern: []

    property int data_rate: processor.dataRate


    ProcessorSingleton {
        id: processor

        onGyroSensorEnabled: {
            gyroscope.start()
        }

        onGyroSensorDisabled: {
            gyroscope.stop()
        }

        onAccelSensorEnabled: {
            accelerometer.start()
        }

        onAccelSensorDisabled: {
            accelerometer.stop()
        }

        onAccelerometerDataProcessed: {
            // Update the text and progress bar based on the processed data
            processedAccelerometerDataText.text = result
            var matches = result.match(/Samples left for noise removal: (\d+)/)
            if (matches && matches.length > 1) {
                var samplesLeft = parseInt(matches[1])
                calibrationProgressBar.value = 20 - samplesLeft
                if (!calibrationDialog.visible) {
                    calibrationDialog.open()
                }
            } else {
                calibrationDialog.close()
            }
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

        onPatternSaved: {
            // Debug the result to ensure it's being received correctly
            console.log("Pattern Saved:", result)

            // Update the savedPattern property in the root component
            // result is like "startX: %1, startY: %2, endX: %3, endY: %4, direction: %5, angle: %6\n..."
            // property var savedPattern: [] in the root component
            root.savedPattern = []  // Clear previous pattern

            var parts = result.split("\n")
            for (var i = 0; i < parts.length; i++) {
                var path = parts[i]
                console.log("Processing line:", path)
                if (path.length > 0) {
                    // Extract values from the string and push to savedPattern
                    var regex = /startX: (-?\d+(\.\d+)?), startY: (-?\d+(\.\d+)?), endX: (-?\d+(\.\d+)?), endY: (-?\d+(\.\d+)?), direction: (left|right|up|down), angle: (-?\d+(\.\d+)?)/;

                    var match = regex.exec(path)
                    if (match) {
                        console.log("Regex match successful:", match)
                        root.savedPattern.push({
                            startX: parseFloat(match[1]),
                            startY: parseFloat(match[3]),
                            endX: parseFloat(match[5]),
                            endY: parseFloat(match[7]),
                            direction: match[9],
                            angle: parseFloat(match[10])
                        })
                    } else {
                        console.log("Regex match failed for line:", path)
                    }
                }
            }
            // Deep copy savedPattern to inputPattern
            root.inputPattern = []
            for (var j = 0; j < root.savedPattern.length; j++) {
                root.inputPattern.push(Object.assign({}, root.savedPattern[j]))
            }
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
        Rectangle {
            width: parent.width
            height: 1 // Adjust height as needed
            color: "white"
        }

        // Display pattern data received from C++ in a rectangle as vector. received path is like QString("Path: startX: %1, startY: %2, endX: %3, endY: %4, direction: %5, angle: %6")
        Rectangle {
            width: parent.width
            // adjust height as needed a little more than height of the entire screen
            height: parent.height * 0.5
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
            visible: false
        }

        Text {
            id: processedGyroscopeDataText
            text: ""
            font.pixelSize: 16
            color: "white"
            visible: false
        }

        Text {
            id: patternText
            text: ""
            font.pixelSize: 20
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
                // send save signal to cpp file
                processor.savePattern()

                root.patternDefined = true

                // Show popup message
                popup.open()
                // Automatically close the popup after a delay
                // popupTimer.start()
            }
        }

        Dialog {
            id: calibrationDialog
            title: "Calibrating"
            modal: true
            visible: false
            width: 300
            height: 150
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            standardButtons: Dialog.NoButton

            Column {
                spacing: 20
                padding: 20
                anchors.centerIn: parent

                Text {
                    text: "Calibrating Sensors"
                    font.pixelSize: 18
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 250
                    height: 20
                    color: "#616161"
                    radius: 10
                    border.color: "#B0BEC5"
                    border.width: 1

                    Rectangle {
                        id: progressIndicator
                        width: calibrationProgressBar.width * calibrationProgressBar.value / calibrationProgressBar.to
                        height: parent.height
                        color: "#4CAF50" // Green color for the progress indicator
                        radius: 10
                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }

                    ProgressBar {
                        id: calibrationProgressBar
                        from: 0
                        to: 20
                        value: 0
                        visible: false // Hide the default appearance of the ProgressBar
                    }
                }
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

            Rectangle {
                width: parent.width
                height: parent.height
                radius: 10
                
                color: "#04745c"
                border.color: "black"
                border.width: 2

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: "Pattern Defined Successfully!"
                        color: "Black"
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    // show Pattern in new page
                    Button {
                        text: "Show Pattern"
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 150
                        height: 40
                        background: Rectangle {
                            radius: 8
                            color: "#b5f3ee"
                        }
                        contentItem: Text {
                            text: "Show Pattern"
                            color: "black"
                            font.pixelSize: 16
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            popup.close()
                            stack.pop()
                            stack.push("PatternPage.qml")
                        }
                    }

                    Button {
                        text: "Ok"
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 100
                        height: 40
                        background: Rectangle {
                            radius: 8
                            color: "#b5f3ee"
                        }
                        contentItem: Text {
                            text: "Ok"
                            color: "black"
                            font.pixelSize: 16
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            popup.close()
                            stack.pop()
                        }
                    }
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
