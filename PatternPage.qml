import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Shapes 1.15

Rectangle {
    id: patternPage
    width: parent.width
    height: parent.height
    color: "#00000000"

    property var chart: []
    property var lines: []

    function drawChart() {
        // Clear existing items
        clearChart()

        var centerX = patternPage.width / 2;
        var centerY = patternPage.height / 2;

        for (var i = 0; i < root.inputPattern.length; i++) {
            var item = root.inputPattern[i];
            var startX = centerX + item.startX * centerX;
            var startY = centerY - item.startY * centerY;
            var endX = centerX + item.endX * centerX;
            var endY = centerY - item.endY * centerY;
            var direction = item.direction;

            // Correcting end coordinates based on direction
            if (direction === "right" && endX < startX) {
                endX = startX + (startX - endX);
            } else if (direction === "left" && endX > startX) {
                endX = startX - (endX - startX);
            } else if (direction === "up" && endY > startY) {
                endY = startY - (endY - startY);
            } else if (direction === "down" && endY < startY) {
                endY = startY + (startY - endY);
            }

            // Draw the line
            var lineItem = Qt.createQmlObject('import QtQuick 2.15; import QtQuick.Shapes 1.15; ShapePath { strokeColor: "black"; strokeWidth: 2; startX: ' + startX + '; startY: ' + startY + '; PathLine { x: ' + endX + '; y: ' + endY + ' } }', patternPage);
            lineItem.parent = patternPage;
            patternPage.lines.push(lineItem);

            // Calculate the angle of the line
            var angle = Math.atan2(endY - startY, endX - startX) * 180 / Math.PI;

            // Add an arrow at the end of the line
            var arrowSize = 10;
            var arrowX = endX - arrowSize * Math.cos(angle * Math.PI / 180);
            var arrowY = endY - arrowSize * Math.sin(angle * Math.PI / 180);
            var arrowPath = "M " + arrowX + " " + arrowY;
            arrowPath += " L " + (arrowX + arrowSize * Math.cos((angle - 135) * Math.PI / 180)) + " " + (arrowY + arrowSize * Math.sin((angle - 135) * Math.PI / 180));
            arrowPath += " L " + (arrowX + arrowSize * Math.cos((angle + 135) * Math.PI / 180)) + " " + (arrowY + arrowSize * Math.sin((angle + 135) * Math.PI / 180));
            arrowPath += " Z";
            var arrowItem = Qt.createQmlObject('import QtQuick 2.15; import QtQuick.Shapes 1.15; Shape { width: parent.width; height: parent.height; ShapePath { strokeColor: "black"; strokeWidth: 2; fillColor: "black"; path: "' + arrowPath + '"; } }', patternPage);
            patternPage.lines.push(arrowItem);

            // Label the line with its index and direction
            var textItem = Qt.createQmlObject('import QtQuick 2.15; import QtQuick.Controls 2.15; Text { text: "' + (i + 1) + ' - ' + direction + '"; color: "black"; font.pixelSize: 12; }', patternPage);
            textItem.x = (startX + endX) / 2 - textItem.width / 2;
            textItem.y = (startY + endY) / 2 - textItem.height / 2;
            patternPage.chart.push(textItem);
        }
    }

    function clearChart() {
        for (var i = 0; i < patternPage.chart.length; i++) {
            patternPage.chart[i].destroy();
        }
        for (var j = 0; j < patternPage.lines.length; j++) {
            patternPage.lines[j].destroy();
        }
        patternPage.chart = [];
        patternPage.lines = [];
    }

    Component.onCompleted: {
        if (root.inputPattern && root.inputPattern.length > 0) {
            drawChart()
        }
    }

    Rectangle {
        id: borderRect
        width: patternPage.width
        height: patternPage.height * 0.6
        anchors.top: parent.top
        color: "#f0f0f0"
        border.color: "black"
        border.width: 2
        radius: 10

        Canvas {
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var centerX = width / 2;
                var centerY = height / 2;

                // Draw grid
                ctx.strokeStyle = "lightgray";
                ctx.lineWidth = 1;

                var step = 20;
                for (var x = step; x < width; x += step) {
                    ctx.beginPath();
                    ctx.moveTo(x, 0);
                    ctx.lineTo(x, height);
                    ctx.stroke();
                }

                for (var y = step; y < height; y += step) {
                    ctx.beginPath();
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                    ctx.stroke();
                }

                // Draw axes
                ctx.strokeStyle = "gray";
                ctx.lineWidth = 2;

                ctx.beginPath();
                ctx.moveTo(centerX, 0);
                ctx.lineTo(centerX, height);
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(0, centerY);
                ctx.lineTo(width, centerY);
                ctx.stroke();

                // Draw lines
                ctx.strokeStyle = "blue";
                ctx.lineWidth = 2;
                for (var i = 0; i < root.inputPattern.length; i++) {
                    var item = root.inputPattern[i];
                    var startX = centerX + item.startX * centerX;
                    var startY = centerY - item.startY * centerY;
                    var endX = centerX + item.endX * centerX;
                    var endY = centerY - item.endY * centerY;

                    // Correcting end coordinates based on direction
                    if (item.direction === "right" && endX < startX) {
                        endX = startX + (startX - endX);
                    } else if (item.direction === "left" && endX > startX) {
                        endX = startX - (endX - startX);
                    } else if (item.direction === "up" && endY > startY) {
                        endY = startY - (endY - startY);
                    } else if (item.direction === "down" && endY < startY) {
                        endY = startY + (startY - endY);
                    }

                    // Draw the line
                    ctx.beginPath();
                    ctx.moveTo(startX, startY);
                    ctx.lineTo(endX, endY);
                    ctx.stroke();

                    // Calculate the angle of the line
                    var angle = Math.atan2(endY - startY, endX - startX);

                    // Add an arrow at the end of the line
                    var arrowSize = 10;
                    ctx.beginPath();
                    ctx.moveTo(endX, endY);
                    ctx.lineTo(endX - arrowSize * Math.cos(angle - Math.PI / 6), endY - arrowSize * Math.sin(angle - Math.PI / 6));
                    ctx.lineTo(endX - arrowSize * Math.cos(angle + Math.PI / 6), endY - arrowSize * Math.sin(angle + Math.PI / 6));
                    ctx.closePath();
                    ctx.fill();

                    // Label the line with its index and direction
                    ctx.font = "12px Arial";
                    ctx.fillStyle = "black";
                    var text = (i + 1) + " - " + item.direction;
                    var textWidth = ctx.measureText(text).width;
                    ctx.fillText(text, (startX + endX) / 2 - textWidth / 2, (startY + endY) / 2);
                }
            }

            Component.onCompleted: requestPaint()
        }
    }

    Rectangle {
        id: listViewRect
        width: parent.width
        height: parent.height * 0.3
        anchors.top: borderRect.bottom
        color: "#263238"

        ListView {
            id: lineListView
            width: parent.width
            height: parent.height
            model: lineModel
            orientation: ListView.Horizontal // Changed to Horizontal
            clip: true
            highlight: Rectangle {
                color: "lightsteelblue"
                radius: 5
            }
            // View line models in a scrollBar element
            ScrollBar.horizontal: ScrollBar { // Changed to horizontal
                active: true
                policy: ScrollBar.AlwaysOn
            }
            delegate: Item {
                width: 200 // Set the width of each item
                height: parent.height
                Rectangle {
                    width: parent.width
                    height: parent.height
                    border.color: "black"
                    border.width: 2
                    radius: 10
                    color: "lightsteelblue"
                    Text {
                        id: lineText
                        text: model.lineInfo
                        color: "white"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }



        ListModel {
            id: lineModel
            Component.onCompleted: {
                if (root.inputPattern && root.inputPattern.length > 0) {
                    // define line number
                    var lineNumber = 1;
                    for (var i = 0; i < root.inputPattern.length; i++) {
                        var item = root.inputPattern[i];
                        var startX = item.startX;
                        var startY = item.startY;
                        var endX = item.endX;
                        var endY = item.endY;
                        var direction = item.direction;
                        var angle = item.angle;
                        var lineText = "Line " + lineNumber + ":\n";
                        lineText += "startX: " + startX + ", startY: " + startY + "\nendX: " + endX + ", endY: " + endY + "\ndirection: " + direction + "\nangle: " + angle;
                        lineModel.append({ "lineInfo": lineText });
                        lineNumber++;
                    }
                }
            }
        }

    Rectangle {
        width: parent.width
        height: parent.height * 0.1
        anchors.top: listViewRect.bottom
        color: "#263238"
        Button {
            text: "OK"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 22
            padding: 14
            width: parent.width * 0.8
            background: Rectangle {
                color: "green"
                radius: 8
            }
            onClicked: {
                stack.pop()
            }
        }
    }
}
