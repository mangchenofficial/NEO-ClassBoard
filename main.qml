import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import md3.Core

Window {
    id: root
    visible: true
    width: (isMini ? 200 : 96 + 156 + (displayItems.length - 1) * 36 + (root.nextClassName !== "" ? 80 : 0)) * widgetScale
    height: (isMini ? 32 : 56) * widgetScale
    title: "课表小组件"
    
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    
    color: "transparent"
    
    property bool expanded: true
    property var todayClasses: []
    property var displayItems: []
    property int currentIndex: -1
    property int currentDisplayIndex: -1
    property string nextClassName: ""
    property bool showNotification: false
    property string notificationMsg: ""
    property bool isMini: csesParser.miniMode
    property bool shouldHide: {
        if (csesParser.hideInClass && csesParser.isInClassNow()) return true
        if (csesParser.hideOnMaximized && csesParser.isForegroundWindowMaximized()) return true
        return false
    }

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
    property real widgetScale: csesParser.widgetScale
    property real widgetOpacity: csesParser.widgetOpacity
    property string appFont: csesParser.fontFamily.length > 0 ? csesParser.fontFamily : Theme.typography.titleSmall.family
    
    NumberAnimation {
        id: moveAnim
        target: root
        property: "y"
        duration: 600
        easing.type: Easing.OutBack
    }
    
    onExpandedChanged: {
        moveAnim.from = y
        moveAnim.to = expanded ? 10 : -(height - Theme.shape.cornerMedium)
        moveAnim.start()
    }
    
    function refreshData() {
        if (!csesParser.loaded) {
            todayClasses = []
            displayItems = []
            currentIndex = -1
            currentDisplayIndex = -1
            return
        }
        todayClasses = csesParser.getTodayClasses()
        var items = []
        for (var i = 0; i < todayClasses.length; i++) {
            var cls = todayClasses[i]
            var entryType = cls.type || "class"
            if (entryType === "break") continue
            var name = ""
            var fullName = ""
            var isActivity = entryType === "activity"
            var isFree = entryType === "free"
            if (isActivity) {
                name = "活动"
                fullName = cls.subject || "活动"
            } else if (isFree) {
                name = "自习"
                fullName = cls.subject || "自习"
            } else {
                var subj = csesParser.getSubjectInfo(cls.subject)
                name = subj.simplified_name || cls.subject
                fullName = cls.subject
            }
            items.push({
                name: name,
                fullName: fullName,
                start: cls.start_time.substring(0, 5),
                end: cls.end_time.substring(0, 5),
                type: entryType,
                isBreak: false
            })
        }
        displayItems = items
        updateCurrentIndex()
    }
    
    function updateCurrentIndex() {
        if (!csesParser.loaded || todayClasses.length === 0) {
            currentIndex = -1
            if (nextClassName !== "") nextClassName = ""
            return
        }
        var now = new Date()
        var nowMinutes = now.getHours() * 60 + now.getMinutes()
        var found = -1
        for (var i = 0; i < todayClasses.length; i++) {
            var cls = todayClasses[i]
            var startMin = root.timeToMinutes(cls.start_time)
            var endMin = root.timeToMinutes(cls.end_time)
            if (nowMinutes >= startMin && nowMinutes < endMin) {
                found = i
                break
            }
        }
        var newNext = ""
        if (found === -1) {
            for (var j = 0; j < todayClasses.length; j++) {
                if (todayClasses[j].type === "break") continue
                var sm = root.timeToMinutes(todayClasses[j].start_time)
                if (sm > nowMinutes) {
                    var subj = csesParser.getSubjectInfo(todayClasses[j].subject)
                    newNext = subj.simplified_name || todayClasses[j].subject
                    break
                }
            }
        } else {
            for (var j2 = found + 1; j2 < todayClasses.length; j2++) {
                if (todayClasses[j2].type === "break") continue
                var subj2 = csesParser.getSubjectInfo(todayClasses[j2].subject)
                newNext = subj2.simplified_name || todayClasses[j2].subject
                break
            }
        }
        if (nextClassName !== newNext) nextClassName = newNext
        if (currentIndex !== found) currentIndex = found
        var dispIdx = -1
        for (var k = 0; k < todayClasses.length; k++) {
            if (todayClasses[k].type !== "break") dispIdx++
            if (k === found) break
        }
        if (currentDisplayIndex !== dispIdx) currentDisplayIndex = found >= 0 ? dispIdx : -1
    }
    
    Connections {
        target: csesParser
        function onLoadedChanged() {
            root.refreshData()
        }
        function onClassChanged(subject, type) {
            root.notificationMsg = csesParser.notificationText
            root.showNotification = true
            notifTimer.interval = 3000
            notifTimer.start()
        }
        function onPreparationBell(subjectName) {
            root.notificationMsg = "预备铃: 即将上 " + subjectName
            root.showNotification = true
            notifTimer.interval = 5000
            notifTimer.start()
        }
    }
    
    Timer {
        id: notifTimer
        interval: 3000
        onTriggered: root.showNotification = false
    }
    
    Rectangle {
        id: background
        anchors.fill: parent
        color: Theme.color.surfaceContainerLow
        opacity: {
            if (root.shouldHide) return 0
            if (csesParser.hoverFade && hoverArea.containsMouse) return 0.15
            if (hoverArea.containsMouse) return 0.85
            return root.widgetOpacity
        }
        radius: Theme.shape.cornerMedium
        
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            
            onEntered: {}
            onExited: {}
            onClicked: root.expanded = !root.expanded
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 0

        // 迷你模式：只显示当前课程
        RowLayout {
            visible: root.isMini
            anchors.fill: parent
            spacing: 8

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: {
                    var now = new Date()
                    return String(now.getHours()).padStart(2, '0') + ":" + String(now.getMinutes()).padStart(2, '0')
                }
                font.family: root.appFont
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Theme.color.onSurfaceColor

                Timer {
                    interval: 10000
                    running: true
                    repeat: true
                    onTriggered: parent.text = String(new Date().getHours()).padStart(2, '0') + ":" + String(new Date().getMinutes()).padStart(2, '0')
                    Component.onCompleted: triggered()
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: !csesParser.loaded
                text: "暂无课表"
                font.family: root.appFont
                font.pixelSize: 12
                color: Theme.color.onSurfaceColor
                opacity: 0.6
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: csesParser.loaded && root.currentDisplayIndex >= 0 && root.currentDisplayIndex < root.displayItems.length
                text: {
                    if (root.currentDisplayIndex < 0) return ""
                    var item = root.displayItems[root.currentDisplayIndex]
                    return item.name + "  " + item.start + " - " + item.end
                }
                font.family: root.appFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.color.onSurfaceColor
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                font.family: root.appFont
                font.pixelSize: 12
                color: Theme.color.onSurfaceColor

                property string _cdMini: ""
                visible: _cdMini !== ""
                text: _cdMini

                Timer {
                    interval: 1000
                    running: root.isMini
                    repeat: true
                    onTriggered: {
                        if (root.currentIndex < 0) { parent._cdMini = ""; return }
                        var now = new Date()
                        var nowMinutes = now.getHours() * 60 + now.getMinutes()
                        var nowSec = now.getSeconds()
                        var cls = root.todayClasses[root.currentIndex]
                        if (!cls) { parent._cdMini = ""; return }
                        var endMin = root.timeToMinutes(cls.end_time)
                        var remain = (endMin - nowMinutes) * 60 - nowSec
                        if (remain <= 0) { parent._cdMini = ""; return }
                        var rm = Math.floor(remain / 60)
                        var rs = remain % 60
                        parent._cdMini = rm + ":" + (rs < 10 ? "0" : "") + rs
                    }
                    onRunningChanged: { if (running) triggered() }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: root.nextClassName !== ""
                text: "下一节: " + root.nextClassName
                font.family: root.appFont
                font.pixelSize: 11
                color: Theme.color.onSurfaceColor
            }
        }

        // 正常模式
        RowLayout {
            visible: !root.isMini
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.preferredWidth: 90
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                text: {
                    var days = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
                    var now = new Date()
                    return days[now.getDay()]
                }
                font.family: root.appFont
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.color.onSurfaceColor
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    var now = new Date()
                    var h = String(now.getHours()).padStart(2, '0')
                    var m = String(now.getMinutes()).padStart(2, '0')
                    return h + ":" + m
                }
                font.family: root.appFont
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
                visible: csesParser.currentWeek > 0
                text: "第" + csesParser.currentWeek + "周"
                font.family: root.appFont
                font.pixelSize: 9
                color: Theme.color.onSurfaceColor
            }
        }
        
        Text {
            visible: !csesParser.loaded
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: "暂时没有课表"
            font.family: root.appFont
            font.pixelSize: 12
            color: Theme.color.onSurfaceColor
            opacity: 0.6
        }
        
        Text {
            visible: csesParser.loaded && displayItems.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: "今天没有课"
            font.family: root.appFont
            font.pixelSize: 12
            color: Theme.color.onSurfaceColor
            opacity: 0.6
        }
        
        Repeater {
            model: displayItems

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
                        font.family: root.appFont
                        font.pixelSize: selected ? 14 : 13
                        font.weight: selected ? Font.Bold : Font.Normal
                        color: Theme.color.onSurfaceColor
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        visible: selected
                        text: itemData.start + " - " + itemData.end
                        font.family: root.appFont
                        font.pixelSize: 11
                        color: Theme.color.onSurfaceColor
                        opacity: 0.7
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 36
                        Layout.maximumWidth: 36
                        Layout.minimumWidth: 36
                        horizontalAlignment: Text.AlignHCenter
                        font.family: root.appFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.color.onSurfaceColor

                        property string _cd: ""
                        visible: selected && _cd !== ""
                        text: _cd

                        Timer {
                            interval: 1000
                            running: parent.selected
                            repeat: true
                            onTriggered: {
                                if (root.currentIndex < 0) { parent._cd = ""; return }
                                var now = new Date()
                                var nowMinutes = now.getHours() * 60 + now.getMinutes()
                                var nowSec = now.getSeconds()
                                var cls = root.todayClasses[root.currentIndex]
                                if (!cls) { parent._cd = ""; return }
                                var endMin = root.timeToMinutes(cls.end_time)
                                var remain = (endMin - nowMinutes) * 60 - nowSec
                                if (remain <= 0) { parent._cd = ""; return }
                                var rm = Math.floor(remain / 60)
                                var rs = remain % 60
                                parent._cd = rm + ":" + (rs < 10 ? "0" : "") + rs
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
                            var startMin = root.timeToMinutes(itemData.start)
                            var endMin = root.timeToMinutes(itemData.end)
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
                    onClicked: root.expanded = !root.expanded
                }
            }
        }
        
        Rectangle {
            visible: root.nextClassName !== ""
            Layout.preferredWidth: 80
            Layout.fillHeight: true
            Layout.margins: 2
            color: Theme.color.primaryContainer
            radius: Theme.shape.cornerSmall
            opacity: 0.6
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "下一节"
                    font.family: root.appFont
                    font.pixelSize: 9
                    color: Theme.color.onPrimaryContainerColor
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.nextClassName
                    font.family: root.appFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.color.onPrimaryContainerColor
                }
            }
        }
    }
    }
    
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            root.updateCurrentIndex()
        }
    }
    
    Component.onCompleted: {
        refreshData()
        var screen = Qt.application.screens[0]
        x = (screen.width - width) / 2
        y = 10
    }
    
    Rectangle {
        id: notifBar
        visible: root.showNotification
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        width: 260
        height: 36
        radius: Theme.shape.cornerMedium
        color: Theme.color.inverseSurface
        opacity: 0.9

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Icon {
                iconSize: 16
                svgPath: "M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z"
                color: Theme.color.inverseOnSurface
            }

            Text {
                text: root.notificationMsg
                font.family: root.appFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.color.inverseOnSurface
            }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }
}
