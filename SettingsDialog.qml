import QtQuick
import QtQuick.Layouts
import md3.Core

Window {
    id: root
    flags: Qt.Window | Qt.WindowCloseButtonHint | Qt.WindowTitleHint | Qt.WindowMinMaxButtonsHint
    title: "设置"
    width: 800
    height: 600
    minimumWidth: 640
    minimumHeight: 480
    visible: false
    color: Theme.color.surface

    property int currentPage: 0
    property var navItems: [
        { icon: "icons/schedule.svg", text: "课表" },
        { icon: "icons/dashboard.svg", text: "外观" },
        { icon: "icons/image-collection.svg", text: "组件" },
        { icon: "icons/settings.svg", text: "行为" },
        { icon: "icons/notifications.svg", text: "通知" },
        { icon: "icons/info.svg", text: "关于" }
    ]

    onVisibleChanged: {
        if (visible) {
            animContainer.opacity = 0
            animContainer.scale = 0.92
            animContainer.opacity = 1
            animContainer.scale = 1
        }
    }

    QtObject {
        id: theme
        readonly property color primary: Qt.color(Theme.color.primary)
        readonly property color onSurface: Qt.color(Theme.color.onSurfaceColor)
        readonly property color onSurfaceVariant: Qt.color(Theme.color.onSurfaceVariantColor)
        readonly property color surfaceContainer: Qt.color(Theme.color.surfaceContainer)
        readonly property color surfaceContainerHigh: Qt.color(Theme.color.surfaceContainerHigh)
        readonly property color primaryContainer: Qt.color(Theme.color.primaryContainer)
        readonly property color outlineVariant: Qt.color(Theme.color.outlineVariant)
    }

    Item {
        id: animContainer
        anchors.fill: parent
        scale: 1
        opacity: 1

        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 140
            Layout.fillHeight: true
            color: Theme.color.surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Repeater {
                    model: root.navItems
                    delegate: Item {
                        id: navItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        property bool selected: index === root.currentPage
                        property bool hovered: false

                        Rectangle {
                            id: navBg
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 12
                            color: navItem.selected ? Theme.color.primaryContainer
                                   : navItem.hovered ? Theme.color.surfaceContainerHigh
                                   : "transparent"
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12
                            Image {
                                source: modelData.icon
                                sourceSize: Qt.size(22, 22)
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                            }
                            Text {
                                text: modelData.text
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: navItem.selected ? Theme.color.primary : Theme.color.onSurfaceVariantColor
                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }
                        }

                        Ripple {
                            anchors.fill: navBg
                            clipRadius: 12
                            onClicked: root.currentPage = index
                            onHoveredChanged: navItem.hovered = hovered
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.color.surface

            Item {
                id: page0
                anchors.fill: parent
                anchors.margins: 24
                opacity: root.currentPage === 0 ? 1 : 0
                visible: opacity > 0.01
                y: root.currentPage === 0 ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                clip: true
                Flickable {
                    id: flick0
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: page0.visible ? col0.implicitHeight : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ColumnLayout {
                        id: col0
                        spacing: 16
                        width: parent.width

                            Text { text: "课表设置"; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        Text { text: "课表文件"; font.pixelSize: 14; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }

                        RowLayout {
                            spacing: 12
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 12
                                color: Theme.color.surfaceContainer
                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 24
                                    text: csesParser.loaded ? csesParser.filePath : "未导入课表"
                                    font.pixelSize: 13
                                    color: csesParser.loaded ? Theme.color.onSurfaceColor : Theme.color.onSurfaceVariantColor
                                    elide: Text.ElideMiddle
                                }
                            }
                            Button {
                                text: "导入"
                                type: "filled"
                                onClicked: {
                                    if (csesParser.importSchedule()) {
                                        importResult.text = "课表导入成功！"
                                        importResult.color = Theme.color.primary
                                    } else {
                                        importResult.text = "无法解析课表文件"
                                        importResult.color = Theme.color.error
                                    }
                                }
                            }
                        }
                        Text {
                            id: importResult
                            font.pixelSize: 12
                            color: Theme.color.onSurfaceVariantColor
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        Text { text: "时间设置"; font.pixelSize: 14; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }

                        RowLayout {
                            spacing: 12
                            Text { text: "时间偏移(分钟)"; font.pixelSize: 14; color: Theme.color.onSurfaceColor; Layout.preferredWidth: 140 }
                            RowLayout {
                                spacing: 4
                                Button {
                                    text: "-"
                                    type: "text"
                                    Layout.preferredWidth: 36
                                    onClicked: { var v = parseInt(offsetField.text) - 1; if (v >= -60) { offsetField.text = v.toString(); csesParser.timeOffset = v; } }
                                }
                                TextField {
                                    id: offsetField
                                    text: csesParser.timeOffset.toString()
                                    type: "filled"
                                    Layout.preferredWidth: 70
                                    
                                    
                                    onTextChanged: {
                                        var v = parseInt(text)
                                        if (!isNaN(v) && v >= -60 && v <= 60) csesParser.timeOffset = v
                                    }
                                }
                                Button {
                                    text: "+"
                                    type: "text"
                                    Layout.preferredWidth: 36
                                    onClicked: { var v = parseInt(offsetField.text) + 1; if (v <= 60) { offsetField.text = v.toString(); csesParser.timeOffset = v; } }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            spacing: 12
                            Text { text: "预备铃提前(分钟)"; font.pixelSize: 14; color: Theme.color.onSurfaceColor; Layout.preferredWidth: 140 }
                            RowLayout {
                                spacing: 4
                                Button {
                                    text: "-"
                                    type: "text"
                                    Layout.preferredWidth: 36
                                    onClicked: { var v = parseInt(prepField.text) - 1; if (v >= 0) { prepField.text = v.toString(); csesParser.preparationTime = v; } }
                                }
                                TextField {
                                    id: prepField
                                    text: csesParser.preparationTime.toString()
                                    type: "filled"
                                    Layout.preferredWidth: 70
                                    
                                    
                                    onTextChanged: {
                                        var v = parseInt(text)
                                        if (!isNaN(v) && v >= 0 && v <= 10) csesParser.preparationTime = v
                                    }
                                }
                                Button {
                                    text: "+"
                                    type: "text"
                                    Layout.preferredWidth: 36
                                    onClicked: { var v = parseInt(prepField.text) + 1; if (v <= 10) { prepField.text = v.toString(); csesParser.preparationTime = v; } }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            spacing: 12
                            Text { text: "当前周次"; font.pixelSize: 14; color: Theme.color.onSurfaceColor; Layout.preferredWidth: 140 }
                            RowLayout {
                                spacing: 4
                                Button {
                                    text: "-"
                                    type: "text"
                                    Layout.preferredWidth: 36
                                    onClicked: { var v = parseInt(weekField.text) - 1; if (v >= 0) { weekField.text = v.toString(); csesParser.currentWeek = v; } }
                                }
                                TextField {
                                    id: weekField
                                    text: csesParser.currentWeek.toString()
                                    type: "filled"
                                    Layout.preferredWidth: 70
                                    
                                    
                                    onTextChanged: {
                                        var v = parseInt(text)
                                        if (!isNaN(v) && v >= 0 && v <= 30) csesParser.currentWeek = v
                                    }
                                }
                                Button {
                                    text: "+"
                                    type: "text"
                                    Layout.preferredWidth: 36
                                    onClicked: { var v = parseInt(weekField.text) + 1; if (v <= 30) { weekField.text = v.toString(); csesParser.currentWeek = v; } }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        Switch {
                            text: "开机自启"
                            checked: csesParser.getAutoStart()
                            onClicked: csesParser.setAutoStart(!csesParser.getAutoStart())
                        }

                        }
                }
                ScrollBar {
                    target: flick0
                    orientation: Qt.Vertical
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                }
            }

            Item {
                id: page1
                anchors.fill: parent
                anchors.margins: 24
                opacity: root.currentPage === 1 ? 1 : 0
                visible: opacity > 0.01
                y: root.currentPage === 1 ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                clip: true
                Flickable {
                    id: flick1
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: page1.visible ? col1.implicitHeight : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ColumnLayout {
                        id: col1
                            spacing: 16
                            width: parent.width

                            Text { text: "外观设置"; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        RowLayout {
                            spacing: 12
                            Text { text: "缩放比例"; font.pixelSize: 14; color: Theme.color.onSurfaceColor; Layout.preferredWidth: 100 }
                            Slider {
                                id: scaleSlider
                                from: 50; to: 200
                                value: Math.round(csesParser.widgetScale * 100)
                                Layout.fillWidth: true
                                onMoved: {
                                    csesParser.widgetScale = value / 100
                                    scaleVal.text = value + "%"
                                }
                            }
                            Text {
                                id: scaleVal
                                text: Math.round(csesParser.widgetScale * 100) + "%"
                                font.pixelSize: 12; color: Theme.color.onSurfaceVariantColor
                                Layout.preferredWidth: 42
                            }
                        }

                        RowLayout {
                            spacing: 12
                            Text { text: "不透明度"; font.pixelSize: 14; color: Theme.color.onSurfaceColor; Layout.preferredWidth: 100 }
                            Slider {
                                id: opacitySlider
                                from: 20; to: 100
                                value: Math.round(csesParser.widgetOpacity * 100)
                                Layout.fillWidth: true
                                onMoved: {
                                    csesParser.widgetOpacity = value / 100
                                    opacityVal.text = value + "%"
                                }
                            }
                            Text {
                                id: opacityVal
                                text: Math.round(csesParser.widgetOpacity * 100) + "%"
                                font.pixelSize: 12; color: Theme.color.onSurfaceVariantColor
                                Layout.preferredWidth: 42
                            }
                        }

                        Switch {
                            id: topSwitch
                            text: "窗口置顶"

                            Component.onCompleted: {
                                topSwitch.checked = !csesParser.alwaysOnBottom
                            }

                            Connections {
                                target: csesParser
                                function onAlwaysOnBottomChanged() {
                                    topSwitch.checked = !csesParser.alwaysOnBottom
                                }
                            }

                            onClicked: {
                                csesParser.alwaysOnBottom = !topSwitch.checked
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        RowLayout {
                            spacing: 12
                            Text { text: "字体"; font.pixelSize: 14; color: Theme.color.onSurfaceColor; Layout.preferredWidth: 100 }
                            ComboBox {
                                id: fontCombo
                                model: Qt.fontFamilies()
                                Layout.fillWidth: true
                                Component.onCompleted: {
                                    var idx = model.indexOf(csesParser.fontFamily)
                                    if (idx >= 0) currentIndex = idx
                                }
                                onCurrentTextChanged: {
                                    if (currentText) csesParser.fontFamily = currentText
                                }
                            }
                        }

                        }
                }
                ScrollBar {
                    target: flick1
                    orientation: Qt.Vertical
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                }
            }

            Loader {
                id: page2_components
                anchors.fill: parent
                opacity: root.currentPage === 2 ? 1 : 0
                visible: opacity > 0.01
                y: root.currentPage === 2 ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                source: "ComponentSettingsPage.qml"
            }

            Item {
                id: page3_behavior
                anchors.fill: parent
                anchors.margins: 24
                opacity: root.currentPage === 3 ? 1 : 0
                visible: opacity > 0.01
                y: root.currentPage === 3 ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                clip: true
                Flickable {
                    id: flick2
                    anchors.fill: parent
                        contentWidth: width
                        contentHeight: page3_behavior.visible ? col2.implicitHeight : 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: col2
                            spacing: 14
                            width: parent.width

                            Text { text: "行为设置"; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        Switch {
                            text: "上课时自动隐藏"
                            checked: csesParser.hideInClass
                            onCheckedChanged: csesParser.hideInClass = checked
                        }
                        Switch {
                            text: "迷你模式"
                            checked: csesParser.miniMode
                            onCheckedChanged: csesParser.miniMode = checked
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        Text { text: "自动隐藏"; font.pixelSize: 14; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }

                        Switch {
                            text: "窗口最大化时隐藏"
                            checked: csesParser.hideOnMaximized
                            onCheckedChanged: csesParser.hideOnMaximized = checked
                        }

                        }
                }
                ScrollBar {
                    target: flick2
                    orientation: Qt.Vertical
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                }
            }

            Item {
                id: page4_notifications
                anchors.fill: parent
                anchors.margins: 24
                opacity: root.currentPage === 4 ? 1 : 0
                visible: opacity > 0.01
                y: root.currentPage === 4 ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                clip: true
                Flickable {
                    id: flick3
                    anchors.fill: parent
                        contentWidth: width
                        contentHeight: page4_notifications.visible ? col3.implicitHeight : 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: col3
                            spacing: 16
                            width: parent.width

                            Text { text: "通知设置"; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        Switch {
                            text: "通知铃声"
                            checked: csesParser.notificationSound
                            onCheckedChanged: csesParser.notificationSound = checked
                        }

                        RowLayout {
                            spacing: 12
                            Text { text: "音量"; font.pixelSize: 14; color: Theme.color.onSurfaceColor; Layout.preferredWidth: 60 }
                            Slider {
                                id: volumeSlider
                                from: 0; to: 100
                                value: Math.round(csesParser.soundVolume * 100)
                                Layout.fillWidth: true
                                onMoved: {
                                    csesParser.soundVolume = value / 100
                                    volumeVal.text = value + "%"
                                }
                            }
                            Text {
                                id: volumeVal
                                text: Math.round(csesParser.soundVolume * 100) + "%"
                                font.pixelSize: 12; color: Theme.color.onSurfaceVariantColor
                                Layout.preferredWidth: 42
                            }
                        }

                        Button {
                            text: "试听铃声"
                            type: "outlined"
                            onClicked: csesParser.testNotificationSound()
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }

                        Text { text: "铃声文件"; font.pixelSize: 14; color: Theme.color.onSurfaceColor }

                        RowLayout {
                            spacing: 12
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 12
                                color: Theme.color.surfaceContainer
                                Text {
                                    id: soundFileLabel
                                    anchors.centerIn: parent
                                    width: parent.width - 24
                                    text: csesParser.soundFilePath ? csesParser.soundFilePath.split('/').pop().split('\\').pop() : "未设置"
                                    font.pixelSize: 13
                                    color: Theme.color.onSurfaceVariantColor
                                    elide: Text.ElideMiddle
                                }
                            }
                            Button {
                                text: "选择"
                                type: "outlined"
                                onClicked: {
                                    var path = csesParser.selectSoundFile()
                                    if (path) soundFileLabel.text = path.split('/').pop().split('\\').pop()
                                }
                            }
                        }

                        }
                }
                ScrollBar {
                    target: flick3
                    orientation: Qt.Vertical
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 8
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                }
            }

            Item {
                id: page5_about
                anchors.fill: parent
                anchors.margins: 24
                opacity: root.currentPage === 5 ? 1 : 0
                visible: opacity > 0.01
                y: root.currentPage === 5 ? 0 : 12
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                clip: true
                Flickable {
                    id: flick4
                    anchors.fill: parent
                        contentWidth: width
                        contentHeight: page5_about.visible ? col4.implicitHeight : 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: col4
                            spacing: 12
                            width: parent.width
                            Item { Layout.preferredHeight: 20 }
                        Image {
                            source: "icons/logo.svg"
                            sourceSize: Qt.size(96, 96)
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 96
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "NEO ClassBoard"
                            font.pixelSize: 22; font.weight: Font.Bold
                            color: Theme.color.onSurfaceColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "版本 1.2.7"
                            font.pixelSize: 12; color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.color.outlineVariant }
                        Text {
                            text: "一款轻量级桌面课表小组件\n支持 CSES 课表格式导入、换课、调休日、预备铃等功能"
                            font.pixelSize: 14; color: Theme.color.onSurfaceColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Item { Layout.preferredHeight: 8 }
                        Text { text: "技术栈"; font.pixelSize: 14; font.weight: Font.Bold; color: Theme.color.onSurfaceColor }
                        Text {
                            text: "Qt 6 (QML + C++)\nMaterial Design 3 组件库\nCSES YAML 课表格式"
                            font.pixelSize: 14; color: Theme.color.onSurfaceColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Item { Layout.preferredHeight: 20 }
                        Text {
                            text: "Made with Qt 6 & MD3"
                            font.pixelSize: 12; color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    ScrollBar {
                        target: flick4
                        orientation: Qt.Vertical
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 8
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                    }
                }
            }
        }
    }
    }
}