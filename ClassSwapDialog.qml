import QtQuick
import QtQuick.Layouts
import md3.Core

Window {
    id: root
    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    title: "换课"
    width: 560
    height: 500
    visible: false
    color: Theme.color.surface

    property var todayClassNames: {
        var classes = csesParser.getTodayClassesRaw()
        var names = []
        for (var i = 0; i < classes.length; i++) {
            var cls = classes[i]
            names.push((i + 1) + ". " + cls.subject + " (" + cls.start_time.substring(0, 5) + "-" + cls.end_time.substring(0, 5) + ")")
        }
        return names
    }

    property var subjectNames: {
        var names = []
        var subs = csesParser.subjects
        for (var i = 0; i < subs.length; i++) names.push(subs[i].name)
        return names
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        Text {
            text: "换课"
            font.pixelSize: 22; font.weight: Font.Bold
            color: Theme.color.onSurfaceColor
        }
        Text {
            text: "仅影响当天课表，不会修改原始文件"
            font.pixelSize: 13; color: Theme.color.onSurfaceVariantColor
        }

        Text {
            text: "交换两节课"
            font.pixelSize: 15; font.weight: Font.Bold
            color: Theme.color.primary
        }

        RowLayout {
            spacing: 12
            ComboBox {
                id: comboA
                model: todayClassNames
                Layout.fillWidth: true
            }
            Text {
                text: "\u21C4"
                font.pixelSize: 20; color: Theme.color.primary
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
            }
            ComboBox {
                id: comboB
                model: todayClassNames
                Layout.fillWidth: true
                Component.onCompleted: {
                    if (todayClassNames.length > 1) currentIndex = 1
                }
            }
        }

        Button {
            text: "交换"
            type: "filled"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                csesParser.swapClasses(comboA.currentIndex, comboB.currentIndex)
                root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.color.outlineVariant
        }

        Text {
            text: "替换单节课"
            font.pixelSize: 15; font.weight: Font.Bold
            color: Theme.color.primary
        }

        RowLayout {
            spacing: 12
            ComboBox {
                id: comboTarget
                model: todayClassNames
                Layout.fillWidth: true
            }
            Text {
                text: "\u2192"
                font.pixelSize: 18; color: Theme.color.primary
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
            }
            ComboBox {
                id: comboNew
                model: subjectNames
                Layout.fillWidth: true
            }
        }

        Button {
            text: "替换"
            type: "filled"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                csesParser.replaceClass(comboTarget.currentIndex, comboNew.currentText)
                root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.color.outlineVariant
        }

        Button {
            text: "清除所有换课"
            type: "filledTonal"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                csesParser.clearSwaps()
                root.close()
            }
        }

        Item { Layout.fillHeight: true }
    }
}