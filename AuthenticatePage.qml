import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtSensors


Rectangle {
    width: parent.width
    height: parent.height
    color: "#263238" // Darker color for the background

    property int data_rate: processor.dataRate


    ProcessorSingleton {
        id: processor // Reference to the Processor component

        // onAccelerometerDataProcessed: {
        //     // Update the text and progress bar based on the processed data
        //     processedAccelerometerDataText.text = result
        //     var matches = result.match(/Samples left for noise removal: (\d+)/)
        //     if (matches && matches.length > 1) {
        //         var samplesLeft = parseInt(matches[1])
        //         progressBar.value = 20 - samplesLeft
        //         progressBar.visible = true
        //         calibrationText.visible = true
        //     } else {
        //         progressBar.visible = false
        //         calibrationText.visible = false
        //     }
        // }

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

        onPatternMatched: {
            // Handle pattern match result from C++
            console.log("Pattern Matched:", result)
            // result is like Pattern matched or Patter not matched
            if (result === "Pattern matched") {
                accessGrantedPopup.open()
            } else {
                accessDeniedPopup.open()
            }
        }
    }

    Accelerometer {
        id: accelerometer
        property real x: 0
        property real y: 0
        property real z: 0
        dataRate: data_rate
        // if capture button text was start, then active: false else active: true
        active: captureButton.text === "Finish"
        onReadingChanged: {
            x = (reading as AccelerometerReading).x
            y = (reading as AccelerometerReading).y
            z = (reading as AccelerometerReading).z
            processor.processAccelerometerData(x, y, z)
        }
    }

    Gyroscope {
        id: gyroscope
        property real x: 0
        property real y: 0
        property real z: 0
        dataRate: data_rate
        // if capture button text was start, then active: false else active: true
        active: captureButton.text === "Finish"
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
        spacing: 40
        // Header
        Text {
            text: "Enter your Pattern!"
            font.pixelSize: 20
            color: "white"
            // set right alignment
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: parent.Top
        }
        // Divider line
        Rectangle {
            width: parent.width
            height: 1 // Adjust height as needed
            color: "white"
        }
        // LiveLocation to show user's movement
        Rectangle {
            width: parent.width - 5
            height: parent.height / 2
            color: "#37474F" // Darker color for the background
            border.color: "white"
            border.width: 2
            anchors.horizontalCenter: parent.horizontalCenter
            LiveLocation {
                id: liveLocation
                anchors.fill: parent
            }
        }
        // Rectangle contain Text and buttons
        Text {
            id: processedAccelerometerDataText
            text: ""
            font.pixelSize: 16
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            visible: false
        }

        // Text {
        //     id: calibrationText
        //     text: "Calibrating..."
        //     font.pixelSize: 18
        //     color: "yellow"
        //     horizontalAlignment: Text.AlignHCenter
        //     visible: false
        // }

        // ProgressBar {
        //     id: progressBar
        //     width: parent.width - 40
        //     value: 0
        //     from: 0
        //     to: 20
        //     visible: false
        // }
        
        // Pattern text to show the pattern
        Text {
            id: patternText
            text: ""
            font.pixelSize: 18
            color: "red"
            horizontalAlignment: Text.AlignHCenter // Center horizontally
        }
        // Button to start/finish capturing data
        Button {
            id: captureButton
            text: "Start"
            font.pixelSize: 22
            padding: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            background: Rectangle {
                id: bid
                radius: 8
                color: "green"
            }
            contentItem: Text {
                text: captureButton.text
                color: "white"
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter // Center horizontally
                verticalAlignment: Text.AlignVCenter // Center vertically
            }
            onClicked: {
                if (captureButton.text === "Start") {
                    captureButton.text = "Finish"
                    bid.color = "#B71C1C"

                    // Start capturing data
                    // processor.startCapturing()
                } else {
                    // Finish capturing data
                    captureButton.text = "Start"
                    bid.color = "green"

                    // Check if pattern matches
                    // processor.checkPatternMatch()
                    processor.checkPatternMatch(root.savedPattern)
                }
            }
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
        id: accessGrantedPopup
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
            color: "#2E7D32" // Dark green background color
            border.color: "#1B5E20"
            border.width: 2

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Access Granted!"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Button {
                    text: "Ok"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    height: 40
                    background: Rectangle {
                        radius: 8
                        color: "white"
                    }
                    contentItem: Text {
                        text: "Ok"
                        color: "#2E7D32"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        accessGrantedPopup.close()
                        stack.pop()
                    }
                }
            }
        }
    }

    Popup {
        id: accessDeniedPopup
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
            color: "#B71C1C" // Dark red background color
            border.color: "#7F0000"
            border.width: 2

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Access Denied!"
                    color: "white"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Button {
                    text: "Ok"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    height: 40
                    background: Rectangle {
                        radius: 8
                        color: "white"
                    }
                    contentItem: Text {
                        text: "Ok"
                        color: "#B71C1C"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        accessDeniedPopup.close()
                        stack.pop()
                    }
                }
            }
        }
    }
}
