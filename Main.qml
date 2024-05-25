import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import SensorShowcaseModule

ApplicationWindow {
    id: root

    readonly property int defaultFontSize: 22
    readonly property int imageSize: width / 2

    // patternDefind boolean to check if the pattern is defined or not
    property bool patternDefined: false
    // savedPattern is the pattern saved by the user and it is list of paths
    property var savedPattern: []
    property var inputPattern: []

    width: 420
    height: 760
    visible: true
    title: "Motion Based Authentication"


    StackView {
        id: stack
        anchors.fill: parent
        // anchors.margins: width / 12

        initialItem: Loader {
            source: "LoadingPage.qml" // Load the loading page initially
        }

        function onPatternPageFinished() {
            // Pop PatternPage
            stack.pop()
            // Pop DefinePatternPage or AuthenticationPage
            stack.pop()
        }
    }
}
