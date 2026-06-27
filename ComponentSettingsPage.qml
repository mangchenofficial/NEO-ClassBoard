import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 24

    property var builtinComponents: [
        { compId: "time", name: "日期", icon: "icons/schedule.svg", description: "显示今天的日期和星期。" },
        { compId: "classlist", name: "课程表", icon: "icons/dashboard.svg", description: "显示当前的课程表信息。" },
        { compId: "nextclass", name: "下一节", icon: "icons/notifications.svg", description: "显示下一节课的信息。" }
    ]

    property var availableComponents: builtinComponents

    property int selectedIndex: -1

    property var selectedPluginInst: null
    property var pluginSettingsSchema: []
    property int _pluginSettingsRev: 0

    ListModel {
        id: componentBarModel
    }

    function rebuildAvailableComponents() {
        var list = builtinComponents.slice()
        var plugins = pluginManager.plugins
        for (var i = 0; i < plugins.length; i++) {
            var p = plugins[i]
            list.push({
                compId: p.compId,
                name: p.name,
                icon: p.icon || "icons/dashboard.svg",
                description: p.description
            })
        }
        availableComponents = list
    }

    function syncComponentBarModel() {
        componentBarModel.clear()
        var order = csesParser.componentOrder
        for (var r = 0; r < order.length; r++) {
            var row = order[r]
            for (var i = 0; i < row.length; i++) {
                componentBarModel.append({ compId: row[i], rowIndex: r })
            }
        }
    }

    function updatePluginSettings() {
        var compId = root.selectedCompId()
        if (compId !== "" && pluginManager.isPlugin(compId)) {
            root.selectedPluginInst = pluginManager.pluginInstance(compId)
            root.pluginSettingsSchema = root.selectedPluginInst ? root.selectedPluginInst.settingsSchema() : []
        } else {
            root.selectedPluginInst = null
            root.pluginSettingsSchema = []
        }
        root._pluginSettingsRev++
    }

    onSelectedIndexChanged: updatePluginSettings()

    function componentName(compId) {
        for (var i = 0; i < availableComponents.length; i++) {
            if (availableComponents[i].compId === compId) return availableComponents[i].name
        }
        return compId
    }

    function componentIcon(compId) {
        for (var i = 0; i < availableComponents.length; i++) {
            if (availableComponents[i].compId === compId) return availableComponents[i].icon
        }
        return "icons/dashboard.svg"
    }

    function componentDescription(compId) {
        for (var i = 0; i < availableComponents.length; i++) {
            if (availableComponents[i].compId === compId) return availableComponents[i].description
        }
        return ""
    }

    function isAdded(compId) {
        var order = csesParser.componentOrder
        for (var r = 0; r < order.length; r++) {
            var row = order[r]
            for (var i = 0; i < row.length; i++) {
                if (row[i] === compId) return true
            }
        }
        return false
    }

    function calcGlobalIndex(rowIdx, localIdx) {
        var order = csesParser.componentOrder
        var cnt = 0
        for (var r = 0; r < rowIdx; r++) cnt += order[r].length
        return cnt + localIdx
    }

    function commitOrder() {
        csesParser.setComponentOrder(csesParser.componentOrder)
    }

    function dropComponent(srcRow, srcIdx, dropX, dropY) {
        var order = csesParser.componentOrder
        var rows = order.length
        if (rows === 0) return
        var rowHeight = 46
        var topMargin = 6

        var targetRow = Math.floor((dropY - topMargin) / rowHeight)
        targetRow = Math.max(0, Math.min(rows - 1, targetRow))

        if (srcRow === targetRow && order[srcRow].length <= 1) {
            return
        }

        var targetIdx = order[targetRow].length
        csesParser.moveComponent(srcRow, srcIdx, targetRow, targetIdx)
    }

    function selectedCompId() {
        if (root.selectedIndex < 0 || root.selectedIndex >= componentBarModel.count) return ""
        return componentBarModel.get(root.selectedIndex).compId
    }

    Component.onCompleted: {
        rebuildAvailableComponents()
        syncComponentBarModel()
    }

    Connections {
        target: csesParser
        function onComponentOrderChanged() { syncComponentBarModel() }
    }

    Connections {
        target: pluginManager
        function onPluginsChanged() {
            rebuildAvailableComponents()
            updatePluginSettings()
        }
    }

    Connections {
        target: root.selectedPluginInst
        ignoreUnknownSignals: true
        function onSettingsChanged() { root._pluginSettingsRev++ }
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
                    text: "组件"
                    font.family: Theme.typography.titleLarge.family
                    font.pixelSize: Theme.typography.titleLarge.size
                    font.weight: Font.Bold
                    color: Theme.color.onSurfaceColor
                }

                Text {
                    text: "管理主界面显示的组件，拖动组件栏可调整顺序。"
                    font.family: Theme.typography.bodyMedium.family
                    font.pixelSize: Theme.typography.bodyMedium.size
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
                    text: "组件栏"
                    font.family: Theme.typography.titleSmall.family
                    font.pixelSize: Theme.typography.titleSmall.size
                    font.weight: Theme.typography.titleSmall.weight
                    color: Theme.color.onSurfaceColor
                }

                Rectangle {
                    id: componentBarContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: {
                        var rows = csesParser.componentOrder.length
                        var total = 0
                        for (var r = 0; r < rows; r++) total += csesParser.componentOrder[r].length
                        if (total === 0) return 72
                        return rows * 52 + 12
                    }
                    radius: Theme.shape.cornerLarge
                    color: Theme.color.surfaceContainer
                    border.width: 1
                    border.color: Theme.color.outlineVariant

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "组件栏为空，从下方组件库添加"
                            font.pixelSize: 12
                            color: Theme.color.onSurfaceVariantColor
                            visible: {
                                var total = 0
                                var rows = csesParser.componentOrder
                                for (var r = 0; r < rows.length; r++) total += rows[r].length
                                return total === 0
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            Layout.fillHeight: true
                        }

                        Repeater {
                            model: csesParser.componentOrder

                            RowLayout {
                                property int rowIdx: index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                spacing: 4

                                Rectangle {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    radius: 11
                                    color: Theme.color.surfaceContainerHighest
                                    visible: csesParser.componentOrder.length > 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: rowIdx + 1
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Theme.color.onSurfaceVariantColor
                                    }
                                }

                                Row {
                                    id: componentRow
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4

                                    Repeater {
                                        model: modelData

                                        Rectangle {
                                            id: barItem
                                            property int compIdx: index
                                            property int compRow: rowIdx
                                            width: barItemContent.implicitWidth + 20
                                            height: parent.height
                                            radius: Theme.shape.cornerSmall
                                            color: dragArea.pressed
                                                   ? Theme.color.surfaceContainerHighest
                                                   : (root.selectedIndex === calcGlobalIndex(compRow, compIdx))
                                                     ? Theme.color.secondaryContainer
                                                     : dragArea.containsMouse
                                                       ? Theme.color.surfaceContainerHigh
                                                       : "transparent"
                                            opacity: csesParser.isComponentVisible(modelData) ? 1.0 : 0.45

                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            RowLayout {
                                                id: barItemContent
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Image {
                                                    source: "icons/drag_handle.svg"
                                                    sourceSize: Qt.size(20, 20)
                                                    Layout.preferredWidth: 20
                                                    Layout.preferredHeight: 20
                                                    opacity: 0.6
                                                }

                                                Image {
                                                    source: root.componentIcon(modelData)
                                                    sourceSize: Qt.size(16, 16)
                                                    Layout.preferredWidth: 16
                                                    Layout.preferredHeight: 16
                                                }

                                                Text {
                                                    text: root.componentName(modelData)
                                                    font.family: Theme.typography.labelLarge.family
                                                    font.pixelSize: Theme.typography.labelLarge.size
                                                    font.weight: Font.Bold
                                                    color: root.selectedIndex === calcGlobalIndex(compRow, compIdx)
                                                           ? Theme.color.onSecondaryContainerColor
                                                           : Theme.color.onSurfaceColor
                                                }
                                            }

                                            MouseArea {
                                                id: dragArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                drag.target: dragProxy
                                                drag.axis: Drag.XAndYAxis

                                                onPressed: {
                                                    root.selectedIndex = calcGlobalIndex(compRow, compIdx)
                                                    dragProxy.compId = modelData
                                                    dragProxy.srcRow = compRow
                                                    dragProxy.srcIdx = compIdx
                                                    var mapped = barItem.mapToItem(componentBarContainer, 0, 0)
                                                    dragProxy.x = mapped.x
                                                    dragProxy.y = mapped.y
                                                    dragProxy.width = barItem.width
                                                    dragProxy.height = barItem.height
                                                    dragProxy.visible = true
                                                }

                                                onReleased: {
                                                    dragProxy.visible = false
                                                    root.dropComponent(
                                                        dragProxy.srcRow, dragProxy.srcIdx,
                                                        dragProxy.x + dragProxy.width / 2,
                                                        dragProxy.y + dragProxy.height / 2
                                                    )
                                                }

                                                onClicked: {
                                                    root.selectedIndex = calcGlobalIndex(compRow, compIdx)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: dragProxy
                        visible: false
                        radius: Theme.shape.cornerSmall
                        color: Theme.color.surfaceContainerHighest
                        opacity: 0.92
                        z: 100

                        property string compId: ""
                        property int srcRow: -1
                        property int srcIdx: -1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                source: "icons/drag_handle.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                opacity: 0.6
                            }

                            Image {
                                source: root.componentIcon(dragProxy.compId)
                                sourceSize: Qt.size(18, 18)
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                            }

                            Text {
                                text: root.componentName(dragProxy.compId)
                                font.family: Theme.typography.labelLarge.family
                                font.pixelSize: Theme.typography.labelLarge.size
                                font.weight: Font.Bold
                                color: Theme.color.onSurfaceColor
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: Theme.shape.cornerSmall
                color: Theme.color.surfaceContainer

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 12

                    Text {
                        text: "组件行数"
                        font.family: Theme.typography.bodyLarge.family
                        font.pixelSize: 14
                        color: Theme.color.onSurfaceColor
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: csesParser.componentRows
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.color.primary
                    }

                    Button {
                        text: "−"
                        type: "text"
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        onClicked: csesParser.setComponentRows(Math.max(1, csesParser.componentRows - 1))
                    }

                    Button {
                        text: "+"
                        type: "text"
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        onClicked: csesParser.setComponentRows(Math.min(5, csesParser.componentRows + 1))
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
                    text: "组件库"
                    font.family: Theme.typography.titleSmall.family
                    font.pixelSize: Theme.typography.titleSmall.size
                    font.weight: Theme.typography.titleSmall.weight
                    color: Theme.color.onSurfaceColor
                }

                GridLayout {
                    id: libraryGrid
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: root.availableComponents

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: Theme.shape.cornerMedium
                            color: addArea.containsMouse
                                   ? Theme.color.surfaceContainerHigh
                                   : Theme.color.surfaceContainer
                            border.width: 1
                            border.color: root.isAdded(modelData.compId)
                                         ? "transparent"
                                         : Theme.color.outlineVariant
                            opacity: root.isAdded(modelData.compId) ? 0.55 : 1.0

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    radius: 22
                                    color: root.isAdded(modelData.compId)
                                           ? Theme.color.surfaceContainerHighest
                                           : Theme.color.primaryContainer

                                    Image {
                                        anchors.centerIn: parent
                                        width: 24
                                        height: 24
                                        source: modelData.icon
                                        sourceSize: Qt.size(24, 24)
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: Theme.color.primary
                                        border.width: 2
                                        border.color: Theme.color.surfaceContainer
                                        visible: root.isAdded(modelData.compId)

                                        Image {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            source: "icons/checkmark.svg"
                                            sourceSize: Qt.size(12, 12)
                                            fillMode: Image.PreserveAspectFit
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.typography.titleSmall.family
                                        font.pixelSize: Theme.typography.titleSmall.size
                                        font.weight: Font.Bold
                                        color: Theme.color.onSurfaceColor
                                    }

                                    Text {
                                        text: modelData.description
                                        font.family: Theme.typography.bodySmall.family
                                        font.pixelSize: Theme.typography.bodySmall.size
                                        color: Theme.color.onSurfaceVariantColor
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }

                                Image {
                                    source: "icons/add.svg"
                                    sourceSize: Qt.size(20, 20)
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    visible: !root.isAdded(modelData.compId)
                                    opacity: addArea.containsMouse ? 1.0 : 0.5
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            Ripple {
                                id: addArea
                                anchors.fill: parent
                                clipRadius: Theme.shape.cornerMedium
                                enabled: !root.isAdded(modelData.compId)
                                onClicked: {
                                    csesParser.addComponent(modelData.compId, -1)
                                }
                            }
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
                    text: "组件设置"
                    font.family: Theme.typography.titleSmall.family
                    font.pixelSize: Theme.typography.titleSmall.size
                    font.weight: Theme.typography.titleSmall.weight
                    color: Theme.color.onSurfaceColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: Theme.shape.cornerLarge
                    color: Theme.color.surfaceContainer
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    visible: root.selectedIndex >= 0
                            && root.selectedIndex < csesParser.componentOrder.length

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 24
                            color: Theme.color.primaryContainer

                            Image {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                source: root.componentIcon(root.selectedCompId())
                                sourceSize: Qt.size(26, 26)
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: root.selectedIndex >= 0
                                      ? root.componentName(root.selectedCompId())
                                      : ""
                                font.family: Theme.typography.titleMedium.family
                                font.pixelSize: Theme.typography.titleMedium.size
                                font.weight: Font.Bold
                                color: Theme.color.onSurfaceColor
                            }

                            Text {
                                text: root.selectedIndex >= 0
                                      ? root.componentDescription(root.selectedCompId())
                                      : ""
                                font.family: Theme.typography.bodySmall.family
                                font.pixelSize: Theme.typography.bodySmall.size
                                color: Theme.color.onSurfaceVariantColor
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: root.selectedIndex >= 0
                                         && pluginManager.isPlugin(root.selectedCompId())
                                text: root.selectedIndex >= 0
                                      ? "v" + pluginManager.pluginVersion(root.selectedCompId())
                                        + "  ·  " + pluginManager.pluginAuthor(root.selectedCompId())
                                      : ""
                                font.family: Theme.typography.labelSmall.family
                                font.pixelSize: Theme.typography.labelSmall.size
                                color: Theme.color.onSurfaceVariantColor
                                opacity: 0.7
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "删除"
                            type: "text"
                            icon: "delete"
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: {
                                csesParser.removeComponent(root.selectedIndex)
                                root.selectedIndex = -1
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: Theme.shape.cornerLarge
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    visible: root.selectedIndex < 0
                            || root.selectedIndex >= csesParser.componentOrder.length

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "未选择组件"
                            font.family: Theme.typography.titleSmall.family
                            font.pixelSize: Theme.typography.titleSmall.size
                            font.weight: Font.Bold
                            color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "点击组件栏上的组件以编辑设置"
                            font.family: Theme.typography.bodySmall.family
                            font.pixelSize: Theme.typography.bodySmall.size
                            color: Theme.color.onSurfaceVariantColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.selectedPluginInst !== null

                Text {
                    text: "插件设置"
                    font.family: Theme.typography.titleSmall.family
                    font.pixelSize: Theme.typography.titleSmall.size
                    font.weight: Theme.typography.titleSmall.weight
                    color: Theme.color.onSurfaceColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: pluginSettingsCol.implicitHeight + 32
                    radius: Theme.shape.cornerLarge
                    color: Theme.color.surfaceContainer
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    visible: root.pluginSettingsSchema.length > 0

                    ColumnLayout {
                        id: pluginSettingsCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        Repeater {
                            model: root.pluginSettingsSchema

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: modelData.label
                                    font.family: Theme.typography.bodyMedium.family
                                    font.pixelSize: Theme.typography.bodyMedium.size
                                    color: Theme.color.onSurfaceColor
                                    visible: modelData.type !== "bool"
                                }

                                Switch {
                                    Layout.fillWidth: true
                                    visible: modelData.type === "bool"
                                    text: modelData.label
                                    checked: {
                                        root._pluginSettingsRev
                                        return root.selectedPluginInst ? root.selectedPluginInst.getSetting(modelData.key) === true : false
                                    }
                                    onCheckedChanged: {
                                        if (root.selectedPluginInst) {
                                            var v = root.selectedPluginInst.getSetting(modelData.key)
                                            if (checked !== v) root.selectedPluginInst.setSetting(modelData.key, checked)
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: modelData.type === "int" || modelData.type === "double"
                                    spacing: 8

                                    Slider {
                                        Layout.fillWidth: true
                                        from: modelData.min !== undefined ? modelData.min : 0
                                        to: modelData.max !== undefined ? modelData.max : 100
                                        value: {
                                            root._pluginSettingsRev
                                            return root.selectedPluginInst ? (root.selectedPluginInst.getSetting(modelData.key) || 0) : 0
                                        }
                                        onMoved: {
                                            if (root.selectedPluginInst) {
                                                root.selectedPluginInst.setSetting(modelData.key, value)
                                            }
                                        }
                                    }

                                    Text {
                                        text: {
                                            root._pluginSettingsRev
                                            var v = root.selectedPluginInst ? root.selectedPluginInst.getSetting(modelData.key) : 0
                                            return modelData.type === "int" ? Math.round(v) : (Math.round(v * 10) / 10)
                                        }
                                        font.pixelSize: 12
                                        color: Theme.color.onSurfaceVariantColor
                                        Layout.preferredWidth: 42
                                    }
                                }

                                ComboBox {
                                    Layout.fillWidth: true
                                    visible: modelData.type === "choice"
                                    type: "outlined"
                                    model: {
                                        var opts = modelData.options || []
                                        var m = []
                                        for (var i = 0; i < opts.length; i++) {
                                            m.push({ text: opts[i].label, value: opts[i].value })
                                        }
                                        return m
                                    }
                                    currentIndex: {
                                        root._pluginSettingsRev
                                        if (!root.selectedPluginInst) return -1
                                        var val = root.selectedPluginInst.getSetting(modelData.key)
                                        for (var i = 0; i < model.length; i++) {
                                            if (model[i].value === val) return i
                                        }
                                        return -1
                                    }
                                    onActivated: {
                                        if (root.selectedPluginInst) {
                                            root.selectedPluginInst.setSetting(modelData.key, currentValue)
                                        }
                                    }
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    visible: modelData.type === "string"
                                    type: "outlined"
                                    text: {
                                        root._pluginSettingsRev
                                        return root.selectedPluginInst ? (root.selectedPluginInst.getSetting(modelData.key) || "") : ""
                                    }
                                    onTextChanged: {
                                        if (root.selectedPluginInst && text !== root.selectedPluginInst.getSetting(modelData.key)) {
                                            root.selectedPluginInst.setSetting(modelData.key, text)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    active: root.selectedPluginInst !== null
                            && pluginManager.settingsQmlUrlFor(root.selectedCompId()) !== ""
                    source: active ? pluginManager.settingsQmlUrlFor(root.selectedCompId()) : ""
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: Theme.shape.cornerLarge
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    visible: root.pluginSettingsSchema.length === 0
                            && (root.selectedPluginInst === null
                                || pluginManager.settingsQmlUrlFor(root.selectedCompId()) === "")

                    Text {
                        anchors.centerIn: parent
                        text: "此插件没有可配置的设置项"
                        font.family: Theme.typography.bodySmall.family
                        font.pixelSize: Theme.typography.bodySmall.size
                        color: Theme.color.onSurfaceVariantColor
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                Button {
                    text: "重置为默认"
                    type: "outlined"
                    onClicked: csesParser.resetComponents()
                }
            }
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