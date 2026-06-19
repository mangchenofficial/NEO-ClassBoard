import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: root

    property var displayItems: []
    property int currentDisplayIndex: -1
    property var todayClasses: []
    property int currentIndex: -1
    property string fontFamily: "MiSans"
    property bool loaded: true
    property real bgOpacity: 1.0

    signal itemClicked()

    Layout.fillWidth: true
    Layout.fillHeight: true

    Rectangle {
        anchors.fill: parent
        color: Theme.color.surfaceContainerLow
        radius: Theme.shape.cornerMedium
        opacity: root.bgOpacity
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

    function timeToMinutes(timeStr) {
        var negative = timeStr.charAt(0) === '-'
        var t = negative ? timeStr.substring(1) : timeStr
        var days = 0
        var dot = t.indexOf('.')
        if (dot >= 0) {
            days = parseInt(t.substring(0, dot))
            t = t.substring(dot + 1)
        }
        var parts = t.split(':')
        if (parts.length < 2) return 0
        var h = parseInt(parts[0])
        var m = parseInt(parts[1])
        var total = (days * 24 + h) * 60 + m
        return negative ? -total : total
    }

    Text {
        visible: !root.loaded
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: "暂时没有课表"
        font.family: root.fontFamily
        font.pixelSize: 12
        color: Theme.color.onSurfaceColor
        opacity: 0.6
    }

    Text {
        visible: root.loaded && root.displayItems.length === 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: "今天没有课"
        font.family: root.fontFamily
        font.pixelSize: 12
        color: Theme.color.onSurfaceColor
        opacity: 0.6
    }

    Repeater {
        model: root.displayItems

        Item {
            Layout.preferredWidth: selected ? 156 : 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: false

            property bool selected: index === root.currentDisplayIndex
            property var itemData: modelData

            Rectangle {
                id: tabBg
                anchors.fill: parent
                anchors.margins: 2
                radius: 6
                color: parent.selected ? Theme.color.secondaryContainer : "transparent"
                opacity: parent.selected ? 0.85 : 0
            }

            Rectangle {
                visible: parent.selected
                anchors.fill: tabBg
                anchors.margins: -3
                radius: tabBg.radius + 3
                color: "transparent"
                border.width: 2
                border.color: Theme.color.primary
                opacity: 0.4
                z: -1
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: !selected
                    horizontalAlignment: selected ? Text.AlignLeft : Text.AlignHCenter
                    elide: Text.ElideRight
                    text: itemData.name
                    font.family: root.fontFamily
                    font.pixelSize: selected ? 14 : 13
                    font.weight: selected ? Font.Bold : Font.Normal
                    color: Theme.color.onSurfaceColor
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: selected
                    text: itemData.start + " - " + itemData.end
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    color: Theme.color.onSurfaceColor
                    opacity: 0.7
                }

                Text {
                    id: cdText
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 36
                    Layout.maximumWidth: 36
                    Layout.minimumWidth: 36
                    horizontalAlignment: Text.AlignHCenter
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.color.onSurfaceColor

                    property string _cd: ""
                    visible: selected && _cd !== ""
                    text: _cd

                    Timer {
                        interval: 1000
                        running: selected
                        repeat: true
                        onTriggered: {
                            if (root.currentIndex < 0) { cdText._cd = ""; return }
                            var now = new Date()
                            var nowMinutes = now.getHours() * 60 + now.getMinutes()
                            var nowSec = now.getSeconds()
                            var cls = root.todayClasses[root.currentIndex]
                            if (!cls) { cdText._cd = ""; return }
                            var endMin = timeToMinutes(cls.end_time)
                            var remain = (endMin - nowMinutes) * 60 - nowSec
                            if (remain <= 0) { cdText._cd = ""; return }
                            var rm = Math.floor(remain / 60)
                            var rs = remain % 60
                            cdText._cd = rm + ":" + (rs < 10 ? "0" : "") + rs
                        }
                        onRunningChanged: { if (running) triggered() }
                    }
                }
            }

            LinearProgress {
                visible: selected
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: 6
                wavy: true

                Timer {
                    interval: 1000
                    running: parent.visible
                    repeat: true
                    onTriggered: {
                        var now = new Date()
                        var nowMinutes = now.getHours() * 60 + now.getMinutes()
                        var startMin = timeToMinutes(itemData.start)
                        var endMin = timeToMinutes(itemData.end)
                        var total = endMin - startMin
                        if (total <= 0) { parent.value = 0; return }
                        var elapsed = nowMinutes - startMin
                        parent.value = Math.max(0, Math.min(1, elapsed / total))
                    }
                    Component.onCompleted: triggered()
                }
            }

            Ripple {
                anchors.fill: parent
                onClicked: root.itemClicked()
            }
        }
    }
    }
}