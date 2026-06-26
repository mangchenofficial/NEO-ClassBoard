import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls
import md3.Core 1.0
import CsesEditor

Window {
    id: root
    title: editorBackend.filePath ? "CSES 编辑器 - " + editorBackend.filePath : "CSES 编辑器 - 未命名"
    width: 1100
    height: 700
    minimumWidth: 900
    minimumHeight: 550
    visible: true
    color: Theme.color.surface

    CsesEditorBackend {
        id: editorBackend
        objectName: "editorBackend"
        onFilePathChanged: root.title = editorBackend.filePath ? "CSES 编辑器 - " + editorBackend.filePath : "CSES 编辑器 - 未命名"
    }

    QtObject {
        id: t
        readonly property color primary: Qt.color(Theme.color.primary)
        readonly property color onPrimary: Qt.color(Theme.color.onPrimaryColor)
        readonly property color onSurface: Qt.color(Theme.color.onSurfaceColor)
        readonly property color onSurfaceVariant: Qt.color(Theme.color.onSurfaceVariantColor)
        readonly property color surface: Qt.color(Theme.color.surface)
        readonly property color surfaceContainer: Qt.color(Theme.color.surfaceContainer)
        readonly property color surfaceContainerHigh: Qt.color(Theme.color.surfaceContainerHigh)
        readonly property color surfaceContainerHighest: Qt.color(Theme.color.surfaceContainerHighest)
        readonly property color surfaceVariant: Qt.color(Theme.color.surfaceVariant)
        readonly property color outline: Qt.color(Theme.color.outline)
        readonly property color outlineVariant: Qt.color(Theme.color.outlineVariant)
        readonly property color error: Qt.color(Theme.color.error)
        readonly property color primaryContainer: Qt.color(Theme.color.primaryContainer)
        readonly property color onPrimaryContainer: Qt.color(Theme.color.onPrimaryContainerColor)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: t.surfaceContainer
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 4

                MdButton {
                    text: "新建"
                    type: MdButton.Type.Text
                    onClicked: editorBackend.newFile()
                }
                MdButton {
                    text: "打开"
                    type: MdButton.Type.Text
                    onClicked: editorBackend.openFile()
                }
                MdButton {
                    text: "保存"
                    type: MdButton.Type.Text
                    enabled: editorBackend.modified
                    onClicked: editorBackend.saveFile()
                }
                MdButton {
                    text: "另存为"
                    type: MdButton.Type.Text
                    onClicked: editorBackend.saveAsFile()
                }
                Item { Layout.fillWidth: true }
                MdButton {
                    text: "科目管理"
                    type: MdButton.Type.Text
                    highlighted: !schedulePanel.visible
                    onClicked: {
                        schedulePanel.visible = false
                        subjectPanel.visible = true
                    }
                }
                MdButton {
                    text: "课表编辑"
                    type: MdButton.Type.Text
                    highlighted: !subjectPanel.visible
                    onClicked: {
                        subjectPanel.visible = false
                        schedulePanel.visible = true
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: t.outlineVariant
            opacity: 0.5
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item {
                id: subjectPanel
                Layout.preferredWidth: 300
                Layout.fillHeight: true
                visible: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        MdLabel {
                            text: "科目列表"
                            type: MdLabel.Type.Title
                            Layout.fillWidth: true
                        }
                        MdButton {
                            text: "+ 添加"
                            type: MdButton.Type.Filled
                            onClicked: {
                                subjectEdit.name = ""
                                subjectEdit.simplified = ""
                                subjectEdit.teacher = ""
                                subjectEdit.room = ""
                                subjectEdit.editIndex = -1
                                subjectEdit.visible = true
                            }
                        }
                    }

                    ListView {
                        id: subjectList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: editorBackend.subjects
                        spacing: 4
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 44
                            radius: 12
                            color: mouseArea.containsMouse ? t.surfaceContainerHigh : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 8

                                MdLabel {
                                    text: modelData.name || ""
                                    type: MdLabel.Type.Body
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                MdLabel {
                                    text: modelData.simplified_name || ""
                                    type: MdLabel.Type.Body
                                    color: t.onSurfaceVariant
                                    visible: text !== ""
                                }
                                MdButton {
                                    icon.name: "icons/edit.svg"
                                    type: MdButton.Type.Text
                                    width: 36; height: 36
                                    onClicked: {
                                        subjectEdit.name = modelData.name || ""
                                        subjectEdit.simplified = modelData.simplified_name || ""
                                        subjectEdit.teacher = modelData.teacher || ""
                                        subjectEdit.room = modelData.room || ""
                                        subjectEdit.editIndex = index
                                        subjectEdit.visible = true
                                    }
                                }
                                MdButton {
                                    icon.name: "icons/delete.svg"
                                    type: MdButton.Type.Text
                                    width: 36; height: 36
                                    onClicked: editorBackend.removeSubject(index)
                                }
                            }
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: t.outlineVariant
                opacity: 0.5
                visible: subjectPanel.visible && schedulePanel.visible
            }

            Item {
                id: schedulePanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        MdLabel {
                            text: "课表编辑"
                            type: MdLabel.Type.Title
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: 7
                            MdButton {
                                text: editorBackend.dayNames[index]
                                type: scheduleTabIndex === index ? MdButton.Type.Filled : MdButton.Type.Text
                                onClicked: scheduleTabIndex = index
                            }
                        }
                        Item { Layout.fillWidth: true }
                        MdButton {
                            text: "+ 添加课程"
                            type: MdButton.Type.Filled
                            onClicked: {
                                classEdit.subject = ""
                                classEdit.startH = 8; classEdit.startM = 0
                                classEdit.endH = 8; classEdit.endM = 40
                                classEdit.classType = "class"
                                classEdit.editIndex = -1
                                classEdit.visible = true
                            }
                        }
                    }

                    property int scheduleTabIndex: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: t.outlineVariant
                        opacity: 0.5
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        MdLabel { text: "名称:"; type: MdLabel.Type.Body }
                        MdTextField {
                            id: scheduleNameField
                            Layout.preferredWidth: 160
                            text: daySchedule.name || ""
                            onTextChanged: updateScheduleInfo()
                        }
                        Item { Layout.preferredWidth: 24 }
                        MdLabel { text: "周次:"; type: MdLabel.Type.Body }
                        MdTextField {
                            id: scheduleWeeksField
                            Layout.preferredWidth: 120
                            text: daySchedule.weeks || "all"
                            onTextChanged: updateScheduleInfo()
                        }
                        Item { Layout.fillWidth: true }
                        MdLabel {
                            text: "共 " + dayClasses.length + " 节课"
                            type: MdLabel.Type.Body
                            color: t.onSurfaceVariant
                        }
                    }

                    function updateScheduleInfo() {
                        editorBackend.updateScheduleInfo(scheduleTabIndex, scheduleNameField.text, scheduleWeeksField.text)
                    }

                    property var daySchedule: {
                        var s = editorBackend.getSchedule(scheduleTabIndex)
                        scheduleNameField.text = s.name || ""
                        scheduleWeeksField.text = s.weeks || "all"
                        return s
                    }

                    property var dayClasses: daySchedule.classes || []

                    ListView {
                        id: classList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: schedulePanel.dayClasses
                        spacing: 4
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 48
                            radius: 12
                            color: mouseArea2.containsMouse ? t.surfaceContainerHigh : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 8

                                MdLabel {
                                    text: String(index + 1).padStart(2, '0')
                                    type: MdLabel.Type.Body
                                    color: t.onSurfaceVariant
                                    Layout.preferredWidth: 24
                                }

                                Rectangle {
                                    Layout.preferredWidth: 4
                                    Layout.preferredHeight: 28
                                    radius: 2
                                    color: modelData.type && modelData.type !== "class" ? t.error : t.primary
                                }

                                MdLabel {
                                    text: modelData.subject || ""
                                    type: MdLabel.Type.Title
                                    Layout.preferredWidth: 120
                                    elide: Text.ElideRight
                                }
                                MdLabel {
                                    text: modelData.type && modelData.type !== "class" ? "[" + modelData.type + "]" : ""
                                    type: MdLabel.Type.Body
                                    color: t.error
                                    visible: modelData.type && modelData.type !== "class"
                                }
                                MdLabel {
                                    text: (modelData.start_time || "") + "  ~  " + (modelData.end_time || "")
                                    type: MdLabel.Type.Body
                                    color: t.onSurfaceVariant
                                    Layout.fillWidth: true
                                }

                                MdButton {
                                    text: "↑"
                                    type: MdButton.Type.Text
                                    width: 32; height: 32
                                    enabled: index > 0
                                    onClicked: editorBackend.moveClass(schedulePanel.scheduleTabIndex, index, index - 1)
                                }
                                MdButton {
                                    text: "↓"
                                    type: MdButton.Type.Text
                                    width: 32; height: 32
                                    enabled: index < dayClasses.length - 1
                                    onClicked: editorBackend.moveClass(schedulePanel.scheduleTabIndex, index, index + 1)
                                }
                                MdButton {
                                    icon.name: "icons/edit.svg"
                                    type: MdButton.Type.Text
                                    width: 32; height: 32
                                    onClicked: {
                                        classEdit.subject = modelData.subject || ""
                                        var st = (modelData.start_time || "08:00:00").split(":")
                                        var et = (modelData.end_time || "08:40:00").split(":")
                                        classEdit.startH = parseInt(st[0]) || 0
                                        classEdit.startM = parseInt(st[1]) || 0
                                        classEdit.endH = parseInt(et[0]) || 0
                                        classEdit.endM = parseInt(et[1]) || 0
                                        classEdit.classType = modelData.type || "class"
                                        classEdit.editIndex = index
                                        classEdit.visible = true
                                    }
                                }
                                MdButton {
                                    icon.name: "icons/delete.svg"
                                    type: MdButton.Type.Text
                                    width: 32; height: 32
                                    onClicked: editorBackend.removeClass(schedulePanel.scheduleTabIndex, index)
                                }
                            }
                            MouseArea {
                                id: mouseArea2
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: subjectEdit
        anchors.centerIn: parent
        width: 420
        height: 300
        radius: 16
        color: t.surfaceContainerHigh
        visible: false
        property string name: ""
        property string simplified: ""
        property string teacher: ""
        property string room: ""
        property int editIndex: -1

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            MdLabel {
                text: subjectEdit.editIndex >= 0 ? "编辑科目" : "添加科目"
                type: MdLabel.Type.Headline
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                MdTextField {
                    id: subjNameField
                    Layout.preferredWidth: 160
                    placeholderText: "科目名称"
                    text: subjectEdit.name
                    onTextChanged: subjectEdit.name = text
                }
                MdTextField {
                    id: subjSimplifiedField
                    Layout.preferredWidth: 80
                    placeholderText: "简称"
                    text: subjectEdit.simplified
                    onTextChanged: subjectEdit.simplified = text
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                MdTextField {
                    id: subjTeacherField
                    Layout.fillWidth: true
                    placeholderText: "教师"
                    text: subjectEdit.teacher
                    onTextChanged: subjectEdit.teacher = text
                }
                MdTextField {
                    id: subjRoomField
                    Layout.fillWidth: true
                    placeholderText: "教室"
                    text: subjectEdit.room
                    onTextChanged: subjectEdit.room = text
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                MdButton {
                    text: "取消"
                    type: MdButton.Type.Text
                    onClicked: subjectEdit.visible = false
                }
                MdButton {
                    text: "确定"
                    type: MdButton.Type.Filled
                    onClicked: {
                        if (!subjectEdit.name.trim()) return
                        if (subjectEdit.editIndex >= 0) {
                            editorBackend.updateSubject(subjectEdit.editIndex, subjectEdit.name, subjectEdit.simplified, subjectEdit.teacher, subjectEdit.room)
                        } else {
                            editorBackend.addSubject(subjectEdit.name, subjectEdit.simplified, subjectEdit.teacher, subjectEdit.room)
                        }
                        subjectEdit.visible = false
                    }
                }
            }
        }
    }

    Rectangle {
        id: classEdit
        anchors.centerIn: parent
        width: 420
        height: 280
        radius: 16
        color: t.surfaceContainerHigh
        visible: false
        property string subject: ""
        property int startH: 8
        property int startM: 0
        property int endH: 8
        property int endM: 40
        property string classType: "class"
        property int editIndex: -1

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            MdLabel {
                text: classEdit.editIndex >= 0 ? "编辑课程" : "添加课程"
                type: MdLabel.Type.Headline
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                MdLabel { text: "科目:"; type: MdLabel.Type.Body }
                ComboBox {
                    id: classSubjectCombo
                    Layout.preferredWidth: 160
                    model: editorBackend.getSubjectNames()
                    editable: true
                    onCurrentTextChanged: classEdit.subject = currentText
                    Component.onCompleted: {
                        var idx = find(classEdit.subject)
                        if (idx >= 0) currentIndex = idx
                        else editText = classEdit.subject
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                MdLabel { text: "开始:"; type: MdLabel.Type.Body }
                SpinBox {
                    id: startHSpin
                    from: -1; to: 23
                    value: classEdit.startH
                    onValueChanged: classEdit.startH = value
                }
                MdLabel { text: "时"; type: MdLabel.Type.Body }
                SpinBox {
                    id: startMSpin
                    from: 0; to: 59
                    value: classEdit.startM
                    onValueChanged: classEdit.startM = value
                }
                MdLabel { text: "分"; type: MdLabel.Type.Body }
                Item { Layout.preferredWidth: 16 }
                MdLabel { text: "结束:"; type: MdLabel.Type.Body }
                SpinBox {
                    id: endHSpin
                    from: -1; to: 23
                    value: classEdit.endH
                    onValueChanged: classEdit.endH = value
                }
                MdLabel { text: "时"; type: MdLabel.Type.Body }
                SpinBox {
                    id: endMSpin
                    from: 0; to: 59
                    value: classEdit.endM
                    onValueChanged: classEdit.endM = value
                }
                MdLabel { text: "分"; type: MdLabel.Type.Body }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                MdLabel { text: "类型:"; type: MdLabel.Type.Body }
                ComboBox {
                    id: classTypeCombo
                    Layout.preferredWidth: 120
                    model: ["class", "break", "self-study", "activity", "exam"]
                    onCurrentTextChanged: classEdit.classType = currentText
                    Component.onCompleted: {
                        var idx = find(classEdit.classType)
                        if (idx >= 0) currentIndex = idx
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                MdButton {
                    text: "取消"
                    type: MdButton.Type.Text
                    onClicked: classEdit.visible = false
                }
                MdButton {
                    text: "确定"
                    type: MdButton.Type.Filled
                    onClicked: {
                        if (!classEdit.subject.trim()) return
                        var pad = function(n) { return n < 10 ? "0" + n : "" + n }
                        var st = pad(classEdit.startH) + ":" + pad(classEdit.startM) + ":00"
                        var et = pad(classEdit.endH) + ":" + pad(classEdit.endM) + ":00"
                        if (classEdit.editIndex >= 0) {
                            editorBackend.updateClass(schedulePanel.scheduleTabIndex, classEdit.editIndex, classEdit.subject, st, et, classEdit.classType)
                        } else {
                            editorBackend.addClass(schedulePanel.scheduleTabIndex, classEdit.subject, st, et, classEdit.classType)
                        }
                        classEdit.visible = false
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (editorBackend.subjects.length === 0) {
            var defaults = [
                ["语文","语"],["数学","数"],["英语","英"],["物理","物"],["化学","化"],
                ["生物","生"],["历史","历"],["政治","政"],["地理","地"],
                ["信息技术","信"],["体育","体"],["音乐","音"],["美术","美"],
                ["自习","自"],["班会","班"],["早读","早"],["周测","测"]
            ]
            for (var i = 0; i < defaults.length; i++) {
                editorBackend.addSubject(defaults[i][0], defaults[i][1], "", "")
            }
        }
    }
}