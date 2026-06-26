import QtQuick
import QtQuick.Layouts
import md3.Core

Rectangle {
    id: root

    property string fontFamily: "MiSans"
    property real bgOpacity: 1.0

    color: Theme.color.surfaceContainerLow
    radius: Theme.shape.cornerMedium
    opacity: root.bgOpacity

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\u5929\u6c14"
            font.family: root.fontFamily
            font.pixelSize: 9
            color: Theme.color.onSurfaceColor
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\u2600 26\u00b0"
            font.family: root.fontFamily
            font.pixelSize: 16
            font.weight: Font.Bold
            color: Theme.color.onSurfaceColor
        }
    }
}