import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: parent.width
    height: parent.height
    color: "black"

    Text {
        id: loadingText
        anchors.centerIn: parent
        text: "Motion Based Authentication"
        font.pixelSize: 24
        color: "transparent"

        states: [
            State {
                name: "fadeIn"
                PropertyChanges { target: loadingText; color: "white"; opacity: 1.0 }
            },
            State {
                name: "fadeOut"
                PropertyChanges { target: loadingText; opacity: 0.0 }
            }
        ]

        transitions: [
            Transition {
                from: ""; to: "fadeIn"
                SequentialAnimation {
                    ColorAnimation { target: loadingText; property: "color"; from: "transparent"; to: "white"; duration: 2000 }
                }
            },
            Transition {
                from: "fadeIn"; to: "fadeOut"
                SequentialAnimation {
                    PauseAnimation { duration: 1000 }
                    PropertyAnimation { target: loadingText; property: "opacity"; from: 1.0; to: 0.0; duration: 1000 }
                }
            }
        ]
    }

    Component.onCompleted: {
        loadingText.state = "fadeIn"
    }

    Timer {
        interval: 4000 // Safety measure, slightly more than the total animation duration
        running: true
        repeat: false
        onTriggered: {
            if (loadingText.opacity !== 0.0) {
                stack.push("MainPage.qml");
            }
        }
    }

    Connections {
        target: loadingText
        onStateChanged: {
            if (loadingText.state === "fadeIn") {
                loadingText.state = "fadeOut"
            } else if (loadingText.state === "fadeOut") {
                stack.push("MainPage.qml")
            }
        }
    }
}
