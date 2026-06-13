import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import md3.Core

Window {
    id: root
    visible: true
    width: 960 * widgetScale
    height: (isMini ? 32 : 56) * widgetScale
    title: "课表小组件"
    
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    
    color: "transparent"
    
    property int _tick: 0
    property bool expanded: true
    property var todayClasses: []
    property var displayItems: []
    property int currentIndex: -1
    property string countdownText: ""
    property string nextClassName: ""
    property bool showNotification: false
    property string notificationMsg: ""
    property bool isMini: csesParser.miniMode
    property bool shouldHide: {
        if (csesParser.hideInClass && csesParser.isInClassNow()) return true
        if (csesParser.hideOnMaximized && csesParser.isForegroundWindowMaximized()) return true
        return false
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
            return
        }
        todayClasses = csesParser.getTodayClasses()
        var items = []
        for (var i = 0; i < todayClasses.length; i++) {
            var cls = todayClasses[i]
            var entryType = cls.type || "class"
            var name = ""
            var fullName = ""
            var isBreak = entryType === "break"
            var isActivity = entryType === "activity"
            var isFree = entryType === "free"
            if (isBreak) {
                name = "课间"
                fullName = "课间"
            } else if (isActivity) {
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
                isBreak: isBreak
            })
        }
        displayItems = items
        updateCurrentIndex()
    }
    
    function updateCurrentIndex() {
        if (!csesParser.loaded || todayClasses.length === 0) {
            currentIndex = -1
            countdownText = ""
            nextClassName = ""
            return
        }
        var now = new Date()
        var nowMinutes = now.getHours() * 60 + now.getMinutes()
        var nowSec = now.getSeconds()
        var found = -1
        for (var i = 0; i < todayClasses.length; i++) {
            var cls = todayClasses[i]
            var startParts = cls.start_time.split(":")
            var endParts = cls.end_time.split(":")
            var startMin = parseInt(startParts[0]) * 60 + parseInt(startParts[1])
            var endMin = parseInt(endParts[0]) * 60 + parseInt(endParts[1])
            if (nowMinutes >= startMin && nowMinutes < endMin) {
                found = i
                var remain = (endMin - nowMinutes) * 60 - nowSec
                var rm = Math.floor(remain / 60)
                var rs = remain % 60
                countdownText = rm + ":" + (rs < 10 ? "0" : "") + rs
                break
            }
        }
        if (found === -1) {
            countdownText = ""
            for (var j = 0; j < todayClasses.length; j++) {
                var sp = todayClasses[j].start_time.split(":")
                var sm = parseInt(sp[0]) * 60 + parseInt(sp[1])
                if (sm > nowMinutes) {
                    var subj = csesParser.getSubjectInfo(todayClasses[j].subject)
                    nextClassName = subj.simplified_name || todayClasses[j].subject
                    break
                }
            }
        } else {
            nextClassName = ""
            if (found + 1 < todayClasses.length) {
                var subj2 = csesParser.getSubjectInfo(todayClasses[found + 1].subject)
                nextClassName = subj2.simplified_name || todayClasses[found + 1].subject
            }
        }
        currentIndex = found
    }
    
    Connections {
        target: csesParser
        function onLoadedChanged() {
            root.refreshData()
        }
        function onClassChanged(subject, type) {
            root.notificationMsg = csesParser.notificationText
            root.showNotification = true
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
        color: "#F0F4F9"
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
                    root._tick
                    var now = new Date()
                    return String(now.getHours()).padStart(2, '0') + ":" + String(now.getMinutes()).padStart(2, '0')
                }
                font.family: root.appFont
                font.pixelSize: 14
                font.weight: Font.Bold
                color: "#000000"
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: !csesParser.loaded
                text: "暂无课表"
                font.family: root.appFont
                font.pixelSize: 12
                color: "#000000"
                opacity: 0.6
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: csesParser.loaded && root.currentIndex >= 0 && root.currentIndex < root.displayItems.length
                text: {
                    if (root.currentIndex < 0) return ""
                    var item = root.displayItems[root.currentIndex]
                    return item.name + "  " + item.start + " - " + item.end
                }
                font.family: root.appFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "#000000"
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: root.countdownText !== ""
                text: root.countdownText
                font.family: root.appFont
                font.pixelSize: 12
                color: "#000000"
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: root.nextClassName !== ""
                text: "下一节: " + root.nextClassName
                font.family: root.appFont
                font.pixelSize: 11
                color: "#000000"
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
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        root._tick
                        var now = new Date()
                        return (now.getMonth() + 1) + "/" + now.getDate()
                    }
                    font.family: root.appFont
                    font.pixelSize: 9
                    color: "#000000"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                text: {
                    var days = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
                    root._tick
                    var now = new Date()
                    return days[now.getDay()]
                }
                font.family: root.appFont
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#000000"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    root._tick
                    var now = new Date()
                    var h = String(now.getHours()).padStart(2, '0')
                    var m = String(now.getMinutes()).padStart(2, '0')
                    return h + ":" + m
                }
                font.family: root.appFont
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#1C1B1F"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: csesParser.currentWeek > 0
                text: "第" + csesParser.currentWeek + "周"
                font.family: root.appFont
                font.pixelSize: 9
                color: "#000000"
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
            color: "#000000"
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
            color: "#000000"
            opacity: 0.6
        }
        
        Repeater {
            model: displayItems
            
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                property bool selected: index === root.currentIndex
                property var itemData: modelData
                
                Rectangle {
                    id: tabBg
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.shape.cornerSmall
                    color: parent.selected ? "#D3E3FD" : (itemData.isBreak ? "#F0F4F9" : "transparent")
                    opacity: parent.selected ? 0.7 : (itemData.isBreak ? 0.5 : 0)

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    visible: parent.selected
                    anchors.fill: tabBg
                    anchors.margins: -4
                    radius: tabBg.radius + 4
                    color: "transparent"
                    border.width: 2
                    border.color: "#400B57D0"
                    z: -1

                    Behavior on visible { NumberAnimation { duration: 200 } }
                }
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: itemData.name
                        font.family: root.appFont
                        font.pixelSize: itemData.isBreak ? 10 : 13
                        font.weight: parent.parent.selected ? Font.Bold : Font.Normal
                        color: parent.parent.selected ? "#000000" : (itemData.isBreak ? "#000000" : "#000000")
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: parent.parent.selected && root.countdownText !== ""
                        text: root.countdownText
                        font.family: root.appFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#000000"
                    }
                }
                
                Rectangle {
                    id: progressIndicator
                    visible: parent.selected
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    radius: 1
                    color: "#000000"
                    
                    property real progress: {
                        root._tick
                        var now = new Date()
                        var nowMinutes = now.getHours() * 60 + now.getMinutes()
                        var startParts = itemData.start.split(":")
                        var endParts = itemData.end.split(":")
                        var startMin = parseInt(startParts[0]) * 60 + parseInt(startParts[1])
                        var endMin = parseInt(endParts[0]) * 60 + parseInt(endParts[1])
                        var total = endMin - startMin
                        if (total <= 0) return 0
                        var elapsed = nowMinutes - startMin
                        return Math.max(0, Math.min(1, elapsed / total))
                    }
                    
                    width: parent.width * progress
                    
                    Behavior on width {
                        NumberAnimation { duration: 1000; easing.type: Easing.OutQuad }
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
            color: "#E8DEF8"
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
                    color: "#000000"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.nextClassName
                    font.family: root.appFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#000000"
                }
            }
        }
    }
    }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root._tick++
            root.updateCurrentIndex()
        }
    }
    
    Component.onCompleted: {
        var screen = Qt.application.screens[0]
        x = (screen.width - width) / 2
        y = 10
        refreshData()
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
        color: "#1C1B1F"
        opacity: 0.9
        
        Text {
            anchors.centerIn: parent
            text: root.notificationMsg
            font.family: root.appFont
            font.pixelSize: 13
            font.weight: Font.Bold
            color: "#FFFFFF"
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }
}
