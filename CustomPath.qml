import QtQuick

Item {
    property real startX: 0
    property real startY: 0
    property real endX: 0
    property real endY: 0
    property string direction: ""
    property real angle: 0

    // if direction is up, draw and arrow pointing up and etc
    Rectangle {
        id: arrow
        width: 10
        height: 10
        color: "red"
        anchors.centerIn: parent
        rotation: angle
        clip: true
        Rectangle {
            width: 10
            height: 10
            color: "green"
            anchors.centerIn: parent
            Rectangle {
                width: 10
                height: 10
                color: "white"
                anchors.centerIn: parent
            }
        }
    }

    onDirectionChanged: {
        if (direction === "up") {
            angle = 0
        } else if (direction === "down") {
            angle = 180
        } else if (direction === "left") {
            angle = 270
        } else if (direction === "right") {
            angle = 90
        }
    }
}

