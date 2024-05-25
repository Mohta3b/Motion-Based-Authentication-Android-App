import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: liveLocation
    width: parent.width
    height: parent.height
    color: "#00000000"

    property var dots: []
    property real scaleFactor: 0.8 // Adjust the scaling factor as needed

    // Function to add a point (dot) to the screen
    function addPoint(x, y) {
        var scaledX = (x + 1) * liveLocation.width / 2;
        var scaledY = (-y + 1) * liveLocation.height / 2;
        var dotItem = Qt.createQmlObject('import QtQuick 2.15; Rectangle { width: 10; height: 10; color: "red"; radius: 5; x: ' + scaledX + '; y: ' + scaledY + ' }', liveLocation);
        dotItem.parent = liveLocation;
        dots.push(dotItem);
    }

    // Clear all dots from the screen
    function clearDots() {
        for (var i = 0; i < dots.length; i++) {
            dots[i].destroy();
        }
        dots = [];
    }
}
