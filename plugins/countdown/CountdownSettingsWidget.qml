import QtQuick
import QtQuick.Layouts
import md3.Core

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 10

    property var pluginInst: {
        var pm = pluginManager
        if (!pm || !pm.pluginInstance) return null
        return pm.pluginInstance("countdown")
    }
    property var countdownStore: pluginInst ? pluginInst.store : null

    function fmtDate(d) {
        var y = d.getFullYear()
        var m = ("0" + (d.getMonth() + 1)).slice(-2)
        var day = ("0" + d.getDate()).slice(-2)
        return y + "-" + m + "-" + day
    }

    Text {
        text: "目标管理"
        font.pixelSize: Theme.typography.titleSmall.size
        font.family: Theme.typography.titleSmall.family
        font.weight: Font.Bold
        color: Theme.color.onSurfaceColor
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextField {
            id: labelInput
            Layout.fillWidth: true
            placeholderText: "名称（如：期末考试）"
            type: "outlined"
        }

        TextField {
            id: dateInput
            Layout.preferredWidth: 160
            placeholderText: "日期"
            type: "outlined"
            readOnly: true
        }

        IconButton {
            icon: "calendar_month"
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            onClicked: datePicker.open()
        }

        Button {
            text: "添加"
            type: "filled"
            enabled: labelInput.text !== "" && dateInput.text.length === 10
            onClicked: {
                if (root.countdownStore && root.countdownStore.addTarget(labelInput.text, dateInput.text)) {
                    labelInput.text = ""
                    dateInput.text = ""
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: root.countdownStore && root.countdownStore.targets.length > 0

        Repeater {
            Layout.fillWidth: true
            model: root.countdownStore ? root.countdownStore.targets : []

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: Theme.shape.cornerSmall
                color: Theme.color.surfaceContainerHighest

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: modelData.label !== "" ? modelData.label : "未命名"
                            font.pixelSize: Theme.typography.labelLarge.size
                            font.family: Theme.typography.labelLarge.family
                            font.weight: Font.Bold
                            color: Theme.color.onSurfaceColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.date + " · " + (modelData.past ? "已过 " : "还有 ") + Math.abs(modelData.days) + " 天"
                            font.pixelSize: Theme.typography.labelSmall.size
                            font.family: Theme.typography.labelSmall.family
                            color: Theme.color.onSurfaceVariantColor
                        }
                    }

                    Text {
                        text: Math.abs(modelData.days)
                        font.pixelSize: 22
                        font.weight: Font.Black
                        color: modelData.past ? Theme.color.onSurfaceVariantColor : Theme.color.primary
                    }

                    IconButton {
                        icon: "delete"
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        onClicked: root.countdownStore.removeTarget(index)
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.countdownStore || root.countdownStore.targets.length === 0
        text: "暂无目标，添加一个重要日期开始倒计日。"
        font.pixelSize: Theme.typography.bodySmall.size
        font.family: Theme.typography.bodySmall.family
        color: Theme.color.onSurfaceVariantColor
        horizontalAlignment: Qt.AlignHCenter
        wrapMode: Text.WordWrap
    }

    DatePicker {
        id: datePicker
        title: "选择目标日期"
        onAccepted: function(d) {
            dateInput.text = root.fmtDate(d)
            datePicker.close()
        }
    }
}