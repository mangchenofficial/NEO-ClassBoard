import QtQuick
import QtQuick.Layouts
import md3.Core

Rectangle {
    id: root

    property string nextClassName: ""
    property string fontFamily: "MiSans"
    property real bgOpacity: 1.0

    visible: root.nextClassName !== ""

    color: Theme.color.surfaceContainerLow
    radius: Theme.shape.cornerMedium
    opacity: root.bgOpacity

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "下一节"
            font.family: root.fontFamily
            font.pixelSize: 9
            color: Theme.color.onSurfaceColor
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.nextClassName
            font.family: root.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            color: Theme.color.onSurfaceColor
        }
    }
}