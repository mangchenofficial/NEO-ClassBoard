import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import md3.Core

Window {
    id: root
    visible: true
    width: (isMini ? 320 : root.componentBarWidth) * widgetScale
    height: (isMini ? 40 : 64) * widgetScale
    title: "课表小组件"
    
    flags: Qt.FramelessWindowHint

    function compWidth(compId) {
        if (compId === "time") return 96
        if (compId === "nextclass") return 80
        if (compId === "classlist") {
            return Math.max(200, displayItems.length > 0 ? 156 + (displayItems.length - 1) * 36 : 200)
        }
        if (pluginManager && pluginManager.isPlugin(compId)) {
            var pw = pluginManager.preferredWidth(compId)
            if (pw > 0) return pw
        }
        return 120
    }

    readonly property real componentBarWidth: {
        if (!csesParser) return 320
        var order = csesParser.componentOrder
        var w = 12
        for (var i = 0; i < order.length; i++) {
            if (!csesParser.isComponentVisible(order[i])) continue
            w += compWidth(order[i]) + 12
        }
        return Math.max(w, 320)
    }

    Timer {
        id: zOrderTimer
        interval: 500
        running: csesParser && csesParser.alwaysOnBottom
        repeat: true
        onTriggered: root.lower()
    }
    
    color: "transparent"
    
    property bool expanded: true
    property var todayClasses: []
    property var displayItems: []
    property int currentIndex: -1
    property int currentDisplayIndex: -1
    property string nextClassName: ""
    property bool showNotification: false
    property string notificationMsg: ""
    property bool isMini: csesParser ? csesParser.miniMode : false
    property int hideTick: 0
    property bool shouldHide: {
        hideTick
        if (!csesParser) return false
        if (csesParser.hideInClass && csesParser.isInClassNow()) return true
        if (csesParser.hideOnMaximized && csesParser.isForegroundWindowMaximized()) return true
        return false
    }

    Timer {
        id: hideCheckTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.hideTick++
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
    property real widgetScale: csesParser ? csesParser.widgetScale : 1.0
    property real widgetOpacity: csesParser ? csesParser.widgetOpacity : 1.0
    property string appFont: csesParser && csesParser.fontFamily && csesParser.fontFamily.length > 0 ? csesParser.fontFamily : Theme.typography.titleSmall.family
    
    NumberAnimation {
        id: moveAnim
        target: root
        property: "y"
        duration: 600
        easing.type: Easing.OutBack
    }
    
    function targetY() {
        if (root.shouldHide || !root.expanded)
            return -(height - Theme.shape.cornerMedium)
        return 10
    }

    function centerX() {
        var screen = Qt.application.screens[0]
        x = (screen.width - width) / 2
    }

    function moveToTarget() {
        moveAnim.from = y
        moveAnim.to = targetY()
        moveAnim.start()
    }

    onExpandedChanged: moveToTarget()
    onShouldHideChanged: moveToTarget()
    onWidthChanged: centerX()
    
    function refreshData() {
        if (!csesParser || !csesParser.loaded) {
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
        if (!csesParser || !csesParser.loaded || todayClasses.length === 0) {
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
        function onAlwaysOnBottomChanged() {
            if (!csesParser.alwaysOnBottom) {
                root.raise()
            }
        }
    }
    
    Timer {
        id: notifTimer
        interval: 3000
        onTriggered: root.showNotification = false
    }
    
    property real componentOpacity: {
        if (hoverArea.containsMouse) return 0.85
        return root.widgetOpacity
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: root.isMini ? Theme.color.surfaceContainerHighest : "transparent"
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: {
                    var now = new Date()
                    return String(now.getHours()).padStart(2, '0') + ":" + String(now.getMinutes()).padStart(2, '0')
                }
                font.family: root.appFont
                font.pixelSize: 20
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
                visible: !csesParser || !csesParser.loaded
                text: "暂无课表"
                font.family: root.appFont
                font.pixelSize: 12
                color: Theme.color.onSurfaceColor
                opacity: 0.6
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: csesParser && csesParser.loaded && root.currentDisplayIndex >= 0 && root.currentDisplayIndex < root.displayItems.length
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item { Layout.fillWidth: true }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 12

                    Repeater {
                        model: csesParser ? csesParser.componentOrder : []
                        Item {
                            Layout.preferredWidth: root.compWidth(modelData)
                            Layout.fillWidth: {
                                var compId = modelData
                                if (pluginManager && pluginManager.isPlugin(compId)) return pluginManager.fillWidth(compId)
                                return false
                            }
                            Layout.fillHeight: true
                            visible: csesParser && csesParser.isComponentVisible(modelData)

                            Loader {
                                anchors.fill: parent
                                active: !(pluginManager && pluginManager.isPlugin(modelData))
                                sourceComponent: {
                                    var compId = modelData
                                    if (compId === "time") return timeComponent
                                    if (compId === "classlist") return classListComponent
                                    if (compId === "nextclass") return nextClassComponent
                                    return null
                                }
                            }

                            Loader {
                                anchors.fill: parent
                                active: pluginManager && pluginManager.isPlugin(modelData)
                                source: active ? pluginManager.qmlUrlFor(modelData) : ""
                                opacity: root.componentOpacity
                                onStatusChanged: {
                                    if (status === Loader.Error)
                                        console.warn("Failed to load plugin component:", modelData)
                                }
                            }
                        }
                    }
                }

            Item { Layout.fillWidth: true }
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
    
    Component {
        id: timeComponent
        TimeSection {
            anchors.fill: parent
            fontFamily: root.appFont
            currentWeek: csesParser.currentWeek
            bgOpacity: root.componentOpacity
        }
    }

    Component {
        id: classListComponent
        ClassList {
            anchors.fill: parent
            displayItems: root.displayItems
            currentDisplayIndex: root.currentDisplayIndex
            todayClasses: root.todayClasses
            currentIndex: root.currentIndex
            fontFamily: root.appFont
            loaded: csesParser.loaded
            bgOpacity: root.componentOpacity
            onItemClicked: root.expanded = !root.expanded
        }
    }

    Component {
        id: nextClassComponent
        NextClassWidget {
            anchors.fill: parent
            nextClassName: root.nextClassName
            fontFamily: root.appFont
            bgOpacity: root.componentOpacity
        }
    }

    Component.onCompleted: {
        refreshData()
        centerX()
        y = targetY()
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
        
        Text {
            anchors.centerIn: parent
            text: root.notificationMsg
            font.family: root.appFont
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.color.inverseOnSurface
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }
}