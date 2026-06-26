import QtQuick
import QtQuick.Layouts
import md3.Core

Window {
    id: root
    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    title: "课表编辑器"
    width: 860
    height: 620
    visible: false
    color: Theme.color.surface

    property int currentDay: 0
    property var dayNames: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    property var subjectModel: []
    property var classModel: []

    function refreshSubjectModel() {
        var subs = csesParser.subjects
        var items = []
        for (var i = 0; i < subs.length; i++) {
            var s = subs[i]
            var text = s.name
            if (s.simplified_name) text += " (" + s.simplified_name + ")"
            if (s.teacher) text += " - " + s.teacher
            items.push(text)
        }
        subjectModel = items
    }

    function refreshClassModel() {
        var classes = csesParser.getClassesForDay(currentDay + 1)
        var items = []
        for (var i = 0; i < classes.length; i++) {
            items.push(classes[i])
        }
        classModel = items
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "课表编辑器"
            font.pixelSize: 24; font.weight: Font.Bold
            color: Theme.color.onSurfaceColor
        }

        Tabs {
            id: tabs
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: [{ text: "科目" }, { text: "时间线" }, { text: "课程表" }]
            type: "primary"

            RowLayout {
                spacing: 16
                ListView {
                    id: subjectList
                    Layout.preferredWidth: 280
                    Layout.fillHeight: true
                    model: subjectModel
                    clip: true

                    delegate: Item {
                        width: subjectList.width
                        height: 44

                        Rectangle {
                            id: itemBg
                            anchors.fill: parent
                            radius: 8
                            color: ListView.isCurrentItem ? Theme.color.primaryContainer : "transparent"
                        }

                        Text {
                            text: modelData
                            font.pixelSize: 14
                            color: Theme.color.onSurfaceColor
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 16
                            anchors.fill: parent
                        }

                        Ripple {
                            anchors.fill: itemBg
                            clipRadius: 8
                            onClicked: subjectList.currentIndex = index
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.color.surfaceContainer

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        TextField {
                            id: nameEdit
                            label: "科目名称"
                            placeholderText: "如：语文"
                            type: "filled"
                            Layout.fillWidth: true
                        }
                        TextField {
                            id: simplifiedEdit
                            label: "简称"
                            placeholderText: "如：语"
                            type: "filled"
                            Layout.fillWidth: true
                        }
                        TextField {
                            id: teacherEdit
                            label: "教师"
                            placeholderText: "可选"
                            type: "filled"
                            Layout.fillWidth: true
                        }
                        TextField {
                            id: roomEdit
                            label: "教室"
                            placeholderText: "可选"
                            type: "filled"
                            Layout.fillWidth: true
                        }

                        Item { Layout.preferredHeight: 4 }

                        Button {
                            text: "添加科目"
                            type: "filled"
                            onClicked: {
                                if (!nameEdit.text) return
                                csesParser.addSubject({
                                    "name": nameEdit.text,
                                    "simplified_name": simplifiedEdit.text || nameEdit.text.charAt(0),
                                    "teacher": teacherEdit.text,
                                    "room": roomEdit.text
                                })
                                refreshSubjectModel()
                                nameEdit.text = ""; simplifiedEdit.text = ""
                                teacherEdit.text = ""; roomEdit.text = ""
                            }
                        }
                        Button {
                            text: "删除选中"
                            type: "filledTonal"
                            onClicked: {
                                if (subjectList.currentIndex >= 0) {
                                    csesParser.removeSubject(subjectList.currentIndex)
                                    refreshSubjectModel()
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
            }

            ColumnLayout {
                spacing: 12
                RowLayout {
                    spacing: 12
                    Text { text: "选择星期"; font.pixelSize: 14; color: Theme.color.onSurfaceColor }
                    ComboBox {
                        id: dayCombo
                        model: dayNames
                        currentIndex: root.currentDay
                        Layout.preferredWidth: 150
                        onCurrentIndexChanged: {
                            root.currentDay = currentIndex
                            refreshClassModel()
                        }
                    }
                    Item { Layout.fillWidth: true }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Flickable {
                        id: schedFlick
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: schedCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: schedCol
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            color: Theme.color.surfaceContainer
                            radius: 8
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                Text { text: "科目"; Layout.fillWidth: true; font.weight: Font.Bold; font.pixelSize: 13; color: Theme.color.onSurfaceColor }
                                Text { text: "开始时间"; Layout.preferredWidth: 120; font.weight: Font.Bold; font.pixelSize: 13; color: Theme.color.onSurfaceColor }
                                Text { text: "结束时间"; Layout.preferredWidth: 120; font.weight: Font.Bold; font.pixelSize: 13; color: Theme.color.onSurfaceColor }
                                Text { text: "类型"; Layout.preferredWidth: 100; font.weight: Font.Bold; font.pixelSize: 13; color: Theme.color.onSurfaceColor }
                            }
                        }

                        Repeater {
                            model: classModel
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 46
                                color: index % 2 === 0 ? "transparent" : Theme.color.surfaceContainerHigh
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 4
                                    ComboBox {
                                        Layout.fillWidth: true
                                        model: {
                                            var names = []
                                            var subs = csesParser.subjects
                                            for (var i = 0; i < subs.length; i++) names.push(subs[i].name)
                                            return names
                                        }
                                        currentIndex: {
                                            var subs = csesParser.subjects
                                            for (var i = 0; i < subs.length; i++) {
                                                if (subs[i].name === modelData.subject) return i
                                            }
                                            return -1
                                        }
                                        
                                    }
                                    TextField {
                                        Layout.preferredWidth: 120
                                        text: modelData.start_time
                                        
                                        type: "filled"
                                    }
                                    TextField {
                                        Layout.preferredWidth: 120
                                        text: modelData.end_time
                                        
                                        type: "filled"
                                    }
                                    ComboBox {
                                        Layout.preferredWidth: 100
                                        model: ["class", "break", "activity", "free"]
                                        currentIndex: {
                                            var types = ["class", "break", "activity", "free"]
                                            var t = modelData.type || "class"
                                            return types.indexOf(t)
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                    ScrollBar {
                        target: schedFlick
                        orientation: Qt.Vertical
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 8
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                    }
                }

                RowLayout {
                    spacing: 12
                    Button {
                        text: "添加课程"
                        type: "filled"
                        onClicked: {
                            var subs = csesParser.subjects
                            var name = subs.length > 0 ? subs[0].name : "未命名"
                            csesParser.addClassEntry(currentDay + 1, {
                                "subject": name,
                                "start_time": "08:00:00",
                                "end_time": "08:40:00",
                                "type": "class"
                            })
                            refreshClassModel()
                        }
                    }
                    Button {
                        text: "删除选中行"
                        type: "filledTonal"
                        onClicked: {
                            csesParser.removeClassEntry(currentDay + 1, 0)
                            refreshClassModel()
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16
                Text {
                    text: "在「时间线」标签页中按星期编辑课程\n在「科目」标签页中管理科目信息\n\n编辑完成后点击底部「导出课表」保存为 CSES 文件"
                    font.pixelSize: 15
                    color: Theme.color.onSurfaceVariantColor
                    lineHeight: 1.8
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
                Item { Layout.fillHeight: true }
            }
        }

        RowLayout {
            Item { Layout.fillWidth: true }
            Button {
                text: "导出课表"
                type: "filled"
                onClicked: {
                    var path = csesParser.selectExportPath()
                    if (!path) return
                    if (csesParser.exportToFile(path)) {
                        exportMsg.text = "课表已导出！"
                        exportMsg.color = Theme.color.primary
                    } else {
                        exportMsg.text = "导出失败"
                        exportMsg.color = Theme.color.error
                    }
                }
            }
        }
        Text {
            id: exportMsg
            font.pixelSize: 12
            color: Theme.color.onSurfaceVariantColor
        }
    }

    Component.onCompleted: {
        refreshSubjectModel()
        refreshClassModel()
    }
}
}