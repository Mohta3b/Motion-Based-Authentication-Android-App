// import QtQuick
// import QtQuick.Controls
// import QtCharts

// Item {
//     // id: liveLocation
//     width: parent.width
//     height: parent.height

//     property real locationX: 0
//     property real locationY: 0

//     ChartView {
//         id: chartView
//         width: parent.width
//         height: parent.height
//         antialiasing: true

//         ValuesAxis {
//             id: xAxis
//             min: -100
//             max: 100
//         }

//         ValuesAxis {
//             id: yAxis
//             min: -100
//             max: 100
//         }

//         LineSeries {
//             id: lineSeries
//             axisX: xAxis
//             axisY: yAxis
//             name: "Live Location"
//             color: "blue"
//         }
//     }

//     Component.onCompleted: {
//         // Add initial point
//         lineSeries.append(locationX, locationY)
//     }

//     function addPoint(newX, newY) {
//         // Add new point to the series
//         lineSeries.append(newX, newY)

//         // Optionally update the axes if needed
//         if (newX < xAxis.min) xAxis.min = newX
//         if (newX > xAxis.max) xAxis.max = newX
//         if (newY < yAxis.min) yAxis.min = newY
//         if (newY > yAxis.max) yAxis.max = newY
//     }
// }

import QtQuick 2.15

Item {
    id: liveLocation

    property var points: []

    signal pointAdded(real x, real y)

    function addPoint(x, y) {
        points.push({ "x": x, "y": y });
        pointAdded(x, y);
    }

    function clearPoints() {
        points = [];
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = canvas.getContext("2d")
            ctx.clearRect(0, 0, canvas.width, canvas.height)

            var scaleFactor = 10  // Adjust this value to scale the points

            // Calculate canvas center
            var centerX = canvas.width / 2
            var centerY = canvas.height / 2

            ctx.beginPath()
            ctx.strokeStyle = "red"
            ctx.lineWidth = 2

            for (var i = 0; i < liveLocation.points.length; i++) {
                var point = liveLocation.points[i]
                var x = centerX + point.x * scaleFactor
                var y = centerY - point.y * scaleFactor  // Invert y-axis for correct drawing

                if (i === 0) {
                    ctx.moveTo(x, y)
                } else {
                    ctx.lineTo(x, y)
                }
            }

            ctx.stroke()
        }

        Connections {
            target: liveLocation

            onPointAdded: {
                canvas.requestPaint()
            }
        }
    }
}
