import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: root

    property string fontFamily: "MiSans"
    property int currentWeek: 0
    property real bgOpacity: 1.0

    implicitWidth: timeLayout.implicitWidth
    implicitHeight: timeLayout.implicitHeight

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.color.surfaceContainerLow
        radius: Theme.shape.cornerMedium
        opacity: root.bgOpacity
    }

    ColumnLayout {
        id: timeLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                var days = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
                var now = new Date()
                return days[now.getDay()]
            }
            font.family: root.fontFamily
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Theme.color.onSurfaceColor
        }

        Text {
            id: timeText
            Layout.alignment: Qt.AlignHCenter
            text: {
                var now = new Date()
                return String(now.getHours()).padStart(2, '0') + ":" + String(now.getMinutes()).padStart(2, '0')
            }
            font.family: root.fontFamily
            font.pixelSize: 20
            font.weight: Font.Bold
            color: Theme.color.onSurfaceColor

            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: {
                    var now = new Date()
                    parent.text = String(now.getHours()).padStart(2, '0') + ":" + String(now.getMinutes()).padStart(2, '0')
                }
                Component.onCompleted: triggered()
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.currentWeek > 0
            text: "第" + root.currentWeek + "周"
            font.family: root.fontFamily
            font.pixelSize: 9
            color: Theme.color.onSurfaceColor
        }
    }
}