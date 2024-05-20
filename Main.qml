import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root

    readonly property int defaultFontSize: 22
    readonly property int imageSize: width / 2

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
        }
}
