import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 24

    property var pluginsList: []
    property int selectedIndex: -1
    property string statusMessage: ""
    property int _settingsRev: 0

    function refreshList() {
        pluginsList = pluginManager.plugins
        if (selectedIndex >= pluginsList.length) selectedIndex = -1
        updateSettingsRev()
    }

    function selectedPlugin() {
        if (selectedIndex < 0 || selectedIndex >= pluginsList.length) return null
        return pluginsList[selectedIndex]
    }

    function selectedPluginInst() {
        var p = selectedPlugin()
        if (!p) return null
        return pluginManager.pluginInstance(p.compId)
    }

    function updateSettingsRev() {
        _settingsRev++
    }

    function showStatus(msg) {
        statusMessage = msg
        statusTimer.restart()
    }

    function handleImportResult(r) {
        if (r === "") return
        if (r.indexOf("OK:") === 0) showStatus("导入成功：" + r.substring(3))
        else showStatus("导入失败：" + r)
    }

    Component.onCompleted: refreshList()

    Connections {
        target: pluginManager
        function onPluginsChanged() { refreshList() }
    }

    Connections {
        target: selectedPluginInst()
        ignoreUnknownSignals: true
        function onSettingsChanged() { updateSettingsRev() }
    }

    Timer {
        id: statusTimer
        interval: 3500
        onTriggered: statusMessage = ""
    }

    Dialog {
        id: confirmRemove
        title: "卸载插件"
        text: selectedIndex >= 0 && selectedPlugin()
              ? "确定要卸载「" + selectedPlugin().name + "」吗？此操作将删除插件文件夹，不可恢复。"
              : ""
        acceptText: "卸载"
        rejectText: "取消"
        onAccepted: {
            var p = selectedPlugin()
            if (!p) return
            var err = pluginManager.removePlugin(p.compId)
            if (err) showStatus("卸载失败：" + err)
            else { showStatus("已卸载：" + p.name); selectedIndex = -1 }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.rightMargin: 12
        contentWidth: width
        contentHeight: root.visible ? contentColumn.implicitHeight : 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 24

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "插件"
                    font.pixelSize: Theme.typography.titleLarge.size
                    font.family: Theme.typography.titleLarge.family
                    font.weight: Font.Bold
                    color: Theme.color.onSurfaceColor
                }

                Text {
                    text: "管理扩展组件。导入插件文件夹或压缩包，启用后可在「组件」页面添加到主界面。"
                    font.pixelSize: Theme.typography.bodyMedium.size
                    font.family: Theme.typography.bodyMedium.family
                    color: Theme.color.onSurfaceVariantColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.color.outlineVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "导入与刷新"
                    font.pixelSize: Theme.typography.titleSmall.size
                    font.family: Theme.typography.titleSmall.family
                    font.weight: Theme.typography.titleSmall.weight
                    color: Theme.color.onSurfaceColor
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        text: "导入文件夹"
                        type: "filled"
                        icon: "add"
                        onClicked: handleImportResult(pluginManager.importFromFolder())
                    }

                    Button {
                        text: "导入压缩包"
                        type: "outlined"
                        icon: "add"
                        onClicked: handleImportResult(pluginManager.importFromArchive())
                    }

                    Button {
                        text: "刷新"
                        type: "text"
                        icon: "edit"
                        onClicked: { pluginManager.reload(); showStatus("已刷新插件列表") }
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Theme.shape.cornerSmall
                    color: Theme.color.surfaceContainer
                    visible: pluginManager.pluginsDir() !== ""

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: "插件目录：" + pluginManager.pluginsDir()
                            font.pixelSize: Theme.typography.labelSmall.size
                            font.family: Theme.typography.labelSmall.family
                            color: Theme.color.onSurfaceVariantColor
                            elide: Text.ElideMiddle
                        }

                        Button {
                            text: "更改"
                            type: "text"
                            icon: "edit"
                            Layout.preferredHeight: 32
                            onClicked: {
                                var newDir = pluginManager.choosePluginsDir()
                                if (newDir !== "") showStatus("插件目录已更改为：" + newDir)
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: statusMessage !== ""
                    text: statusMessage
                    font.pixelSize: Theme.typography.labelMedium.size
                    font.family: Theme.typography.labelMedium.family
                    color: Theme.color.primary
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.color.outlineVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "已安装插件"
                        font.pixelSize: Theme.typography.titleSmall.size
                        font.family: Theme.typography.titleSmall.family
                        font.weight: Theme.typography.titleSmall.weight
                        color: Theme.color.onSurfaceColor
                    }

                    Text {
                        text: "(" + pluginsList.length + ")"
                        font.pixelSize: Theme.typography.labelMedium.size
                        font.family: Theme.typography.labelMedium.family
                        color: Theme.color.onSurfaceVariantColor
                    }

                    Item { Layout.fillWidth: true }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: pluginsList.length > 0

                    Repeater {
                        model: pluginsList

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            radius: Theme.shape.cornerMedium
                            color: root.selectedIndex === index
                                   ? Theme.color.secondaryContainer
                                   : itemArea.containsMouse
                                     ? Theme.color.surfaceContainerHigh
                                     : Theme.color.surfaceContainer
                            border.width: 1
                            border.color: root.selectedIndex === index
                                          ? Theme.color.primary
                                          : Theme.color.outlineVariant

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    radius: 24
                                    color: root.selectedIndex === index
                                           ? Theme.color.primary
                                           : Theme.color.primaryContainer

                                    Item {
                                        anchors.centerIn: parent
                                        width: 26
                                        height: 26

                                        Image {
                                            anchors.fill: parent
                                            source: modelData.icon
                                            visible: modelData.icon !== ""
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        PluginIcon {
                                            anchors.fill: parent
                                            visible: modelData.icon === ""
                                            color: root.selectedIndex === index
                                                   ? Theme.color.onPrimaryColor
                                                   : Theme.color.onPrimaryContainerColor
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        spacing: 8

                                        Text {
                                            text: modelData.name
                                            font.pixelSize: Theme.typography.titleSmall.size
                                            font.family: Theme.typography.titleSmall.family
                                            font.weight: Font.Bold
                                            color: Theme.color.onSurfaceColor
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 18
                                            radius: 9
                                            color: Theme.color.surfaceContainerHighest
                                            visible: modelData.version !== ""
                                            Layout.preferredWidth: versionText.implicitWidth + 16

                                            Text {
                                                id: versionText
                                                anchors.centerIn: parent
                                                text: "v" + modelData.version
                                                font.pixelSize: Theme.typography.labelSmall.size
                                                font.family: Theme.typography.labelSmall.family
                                                color: Theme.color.onSurfaceVariantColor
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.author !== "" ? modelData.author : "未知作者"
                                        font.pixelSize: Theme.typography.bodySmall.size
                                        font.family: Theme.typography.bodySmall.family
                                        color: Theme.color.onSurfaceVariantColor
                                    }

                                    Text {
                                        text: modelData.description
                                        font.pixelSize: Theme.typography.bodySmall.size
                                        font.family: Theme.typography.bodySmall.family
                                        color: Theme.color.onSurfaceVariantColor
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            Ripple {
                                id: itemArea
                                anchors.fill: parent
                                clipRadius: Theme.shape.cornerMedium
                                hoverEnabled: true
                                onClicked: root.selectedIndex = index
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 96
                    radius: Theme.shape.cornerMedium
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    visible: pluginsList.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        PluginIcon {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            color: Theme.color.onSurfaceVariantColor
                            opacity: 0.5
                        }

                        Text {
                            text: "暂无插件"
                            font.pixelSize: Theme.typography.titleSmall.size
                            font.family: Theme.typography.titleSmall.family
                            font.weight: Font.Bold
                            color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "点击上方「导入文件夹」或「导入压缩包」安装插件"
                            font.pixelSize: Theme.typography.bodySmall.size
                            font.family: Theme.typography.bodySmall.family
                            color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.color.outlineVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "插件详情"
                    font.pixelSize: Theme.typography.titleSmall.size
                    font.family: Theme.typography.titleSmall.family
                    font.weight: Theme.typography.titleSmall.weight
                    color: Theme.color.onSurfaceColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: detailCol.implicitHeight + 32
                    radius: Theme.shape.cornerLarge
                    color: Theme.color.surfaceContainer
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    visible: root.selectedIndex >= 0

                    ColumnLayout {
                        id: detailCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 24
                                color: Theme.color.primaryContainer

                                Item {
                                    anchors.centerIn: parent
                                    width: 26
                                    height: 26

                                    Image {
                                        anchors.fill: parent
                                        source: selectedPlugin() ? selectedPlugin().icon : ""
                                        visible: selectedPlugin() && selectedPlugin().icon !== ""
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    PluginIcon {
                                        anchors.fill: parent
                                        visible: selectedPlugin() && selectedPlugin().icon === ""
                                        color: Theme.color.onPrimaryContainerColor
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: selectedPlugin() ? selectedPlugin().name : ""
                                    font.pixelSize: Theme.typography.titleMedium.size
                                    font.family: Theme.typography.titleMedium.family
                                    font.weight: Font.Bold
                                    color: Theme.color.onSurfaceColor
                                }

                                Text {
                                    text: selectedPlugin()
                                          ? "v" + selectedPlugin().version
                                            + "  ·  " + (selectedPlugin().author !== "" ? selectedPlugin().author : "未知作者")
                                          : ""
                                    font.pixelSize: Theme.typography.labelSmall.size
                                    font.family: Theme.typography.labelSmall.family
                                    color: Theme.color.onSurfaceVariantColor
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: "卸载"
                                type: "text"
                                icon: "delete"
                                Layout.alignment: Qt.AlignVCenter
                                onClicked: confirmRemove.open()
                            }
                        }

                        Text {
                            text: selectedPlugin() ? selectedPlugin().description : ""
                            font.pixelSize: Theme.typography.bodySmall.size
                            font.family: Theme.typography.bodySmall.family
                            color: Theme.color.onSurfaceVariantColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.color.outlineVariant
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 16
                            rowSpacing: 6

                            Text {
                                text: "组件 ID"
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceVariantColor
                            }
                            Text {
                                text: selectedPlugin() ? selectedPlugin().compId : ""
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                font.weight: Font.Bold
                                color: Theme.color.onSurfaceColor
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }

                            Text {
                                text: "首选宽度"
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceVariantColor
                            }
                            Text {
                                text: selectedPlugin()
                                      ? (selectedPlugin().preferredWidth > 0
                                         ? selectedPlugin().preferredWidth + " px"
                                         : "自适应")
                                      : ""
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceColor
                            }

                            Text {
                                text: "填充剩余宽度"
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceVariantColor
                            }
                            Text {
                                text: selectedPlugin() ? (selectedPlugin().fillWidth ? "是" : "否") : ""
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceColor
                            }

                            Text {
                                text: "QML 组件"
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceVariantColor
                            }
                            Text {
                                text: selectedPlugin() ? selectedPlugin().qmlUrl : ""
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceColor
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }

                            Text {
                                text: "插件目录"
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceVariantColor
                            }
                            Text {
                                text: selectedPlugin() ? selectedPlugin().pluginDir : ""
                                font.pixelSize: Theme.typography.labelSmall.size
                                font.family: Theme.typography.labelSmall.family
                                color: Theme.color.onSurfaceColor
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }
                        }

                        // 插件设置 API
                        Rectangle {
                            Layout.fillWidth: true
                            visible: selectedPlugin() && selectedPlugin().hasSettings
                            Layout.preferredHeight: 1
                            color: Theme.color.outlineVariant
                        }

                        Text {
                            text: "插件设置"
                            font.pixelSize: Theme.typography.titleSmall.size
                            font.family: Theme.typography.titleSmall.family
                            font.weight: Font.Bold
                            color: Theme.color.onSurfaceColor
                            visible: selectedPlugin() && selectedPlugin().hasSettings
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: selectedPlugin() && selectedPlugin().hasSettings

                            Repeater {
                                model: {
                                    root._settingsRev
                                    var sp = selectedPlugin()
                                    if (!sp) return []
                                    var inst = pluginManager.pluginInstance(sp.compId)
                                    return inst ? inst.settingsSchema() : []
                                }

                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: Theme.typography.labelMedium.size
                                        font.family: Theme.typography.labelMedium.family
                                        color: Theme.color.onSurfaceColor
                                        Layout.preferredWidth: 90
                                    }

                                    Item { Layout.fillWidth: true }

                                    // bool -> Switch
                                    Switch {
                                        visible: modelData.type === "bool"
                                        checked: modelData.value === true
                                        onClicked: {
                                            var sp = selectedPlugin()
                                            if (sp) pluginManager.pluginInstance(sp.compId).setSetting(modelData.key, !checked)
                                        }
                                    }

                                    // int/double -> Slider
                                    RowLayout {
                                        visible: modelData.type === "int" || modelData.type === "double"
                                        spacing: 8

                                        Slider {
                                            id: numSlider
                                            from: modelData.min !== undefined ? modelData.min : 0
                                            to: modelData.max !== undefined ? modelData.max : 100
                                            value: modelData.value !== undefined ? modelData.value : 0
                                            stepSize: modelData.type === "int" ? 1 : 0.1
                                            onMoved: {
                                                var sp = selectedPlugin()
                                                if (sp) {
                                                    var v = modelData.type === "int" ? Math.round(value) : value
                                                    pluginManager.pluginInstance(sp.compId).setSetting(modelData.key, v)
                                                }
                                            }
                                        }

                                        Text {
                                            text: modelData.value !== undefined ? modelData.value : ""
                                            font.pixelSize: Theme.typography.labelSmall.size
                                            font.family: Theme.typography.labelSmall.family
                                            color: Theme.color.onSurfaceVariantColor
                                            Layout.preferredWidth: 32
                                            horizontalAlignment: Qt.AlignRight
                                        }
                                    }

                                    // string -> TextField
                                    TextField {
                                        visible: modelData.type === "string"
                                        text: modelData.value !== undefined ? modelData.value : ""
                                        type: "outlined"
                                        Layout.preferredWidth: 160
                                        onEditingFinished: {
                                            var sp = selectedPlugin()
                                            if (sp) pluginManager.pluginInstance(sp.compId).setSetting(modelData.key, text)
                                        }
                                    }

                                    // choice -> ComboBox
                                    ComboBox {
                                        visible: modelData.type === "choice"
                                        model: {
                                            var opts = modelData.options ? modelData.options : []
                                            var m = []
                                            for (var i = 0; i < opts.length; i++) {
                                                m.push({ text: opts[i].label, value: opts[i].value })
                                            }
                                            return m
                                        }
                                        type: "outlined"
                                        Layout.preferredWidth: 160
                                        currentIndex: {
                                            var curVal = modelData.value
                                            var opts = modelData.options ? modelData.options : []
                                            for (var i = 0; i < opts.length; i++) {
                                                if (opts[i].value === curVal) return i
                                            }
                                            return -1
                                        }
                                        onActivated: {
                                            var sp = selectedPlugin()
                                            if (sp) {
                                                var opts = modelData.options ? modelData.options : []
                                                if (index >= 0 && index < opts.length) {
                                                    pluginManager.pluginInstance(sp.compId).setSetting(modelData.key, opts[index].value)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 插件自定义设置组件
                        Loader {
                            Layout.fillWidth: true
                            Layout.preferredHeight: item ? item.implicitHeight : 0
                            active: selectedPlugin() && selectedPlugin().settingsQmlUrl !== ""
                            visible: active
                            source: active ? selectedPlugin().settingsQmlUrl : ""
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 96
                    radius: Theme.shape.cornerLarge
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    visible: root.selectedIndex < 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "未选择插件"
                            font.pixelSize: Theme.typography.titleSmall.size
                            font.family: Theme.typography.titleSmall.family
                            font.weight: Font.Bold
                            color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "点击上方列表中的插件以查看详情与设置"
                            font.pixelSize: Theme.typography.bodySmall.size
                            font.family: Theme.typography.bodySmall.family
                            color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }
        }
    }

    ScrollBar {
        target: flick
        orientation: Qt.Vertical
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 2
        anchors.topMargin: 4
        anchors.bottomMargin: 4
    }
}