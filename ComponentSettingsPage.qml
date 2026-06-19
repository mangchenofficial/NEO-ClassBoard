import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: root
    anchors.fill: parent
    anchors.margins: 24

    property var availableComponents: [
        { compId: "time", name: "日期", icon: "icons/schedule.svg", description: "显示今天的日期和星期。" },
        { compId: "classlist", name: "课程表", icon: "icons/dashboard.svg", description: "显示当前的课程表信息。" },
        { compId: "nextclass", name: "下一节", icon: "icons/notifications.svg", description: "显示下一节课的信息。" }
    ]

    property int selectedIndex: -1

    ListModel {
        id: componentBarModel
    }

    function syncComponentBarModel() {
        componentBarModel.clear()
        var order = csesParser.componentOrder
        for (var i = 0; i < order.length; i++) {
            componentBarModel.append({ compId: order[i] })
        }
    }

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
        for (var i = 0; i < order.length; i++) {
            if (order[i] === compId) return true
        }
        return false
    }

    function selectedCompId() {
        if (root.selectedIndex < 0 || root.selectedIndex >= componentBarModel.count) return ""
        return componentBarModel.get(root.selectedIndex).compId
    }

    Component.onCompleted: syncComponentBarModel()

    Connections {
        target: csesParser
        function onComponentOrderChanged() { syncComponentBarModel() }
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
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: Theme.shape.cornerLarge
                    color: Theme.color.surfaceContainer
                    border.width: 1
                    border.color: Theme.color.outlineVariant

                    ListView {
                        id: componentBar
                        anchors.fill: parent
                        anchors.margins: 8
                        orientation: ListView.Horizontal
                        spacing: 8
                        model: componentBarModel
                        displaced: Transition {
                            NumberAnimation { properties: "x"; duration: 200; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "组件栏为空，从下方组件库添加"
                            font.pixelSize: 12
                            color: Theme.color.onSurfaceVariantColor
                            visible: componentBarModel.count === 0
                        }

                        delegate: Rectangle {
                            id: barItem
                            width: barItemContent.implicitWidth + 28
                            height: componentBar.height
                            radius: Theme.shape.cornerSmall
                            color: dragArea.pressed
                                   ? Theme.color.surfaceContainerHighest
                                   : root.selectedIndex === index
                                     ? Theme.color.secondaryContainer
                                     : dragArea.containsMouse
                                       ? Theme.color.surfaceContainerHigh
                                       : "transparent"
                            opacity: csesParser.isComponentVisible(modelData) ? 1.0 : 0.45

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: barItemContent
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    source: "icons/drag_handle.svg"
                                    sourceSize: Qt.size(16, 16)
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    opacity: 0.6
                                }

                                Image {
                                    source: root.componentIcon(modelData)
                                    sourceSize: Qt.size(18, 18)
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                }

                                Text {
                                    text: root.componentName(modelData)
                                    font.family: Theme.typography.labelLarge.family
                                    font.pixelSize: Theme.typography.labelLarge.size
                                    font.weight: Font.Bold
                                    color: root.selectedIndex === index
                                           ? Theme.color.onSecondaryContainerColor
                                           : Theme.color.onSurfaceColor
                                }
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                drag.target: dragProxy
                                drag.axis: Drag.XAxis

                                property int dragIndex: index

                                onPressed: {
                                    root.selectedIndex = index
                                    dragProxy.compId = modelData
                                    dragProxy.dragIndex = index
                                    dragProxy.x = barItem.x
                                    dragProxy.y = barItem.y
                                    dragProxy.width = barItem.width
                                    dragProxy.height = barItem.height
                                    dragProxy.visible = true
                                }

                                onReleased: {
                                    dragProxy.visible = false
                                    var newOrder = []
                                    for (var i = 0; i < componentBarModel.count; i++) {
                                        newOrder.push(componentBarModel.get(i).compId)
                                    }
                                    csesParser.setComponentOrder(newOrder)
                                }

                                onPositionChanged: {
                                    if (!drag.active) return
                                    var target = componentBar.indexAt(dragProxy.x + dragProxy.width / 2, dragProxy.y + dragProxy.height / 2)
                                    if (target >= 0 && target !== dragProxy.dragIndex) {
                                        componentBarModel.move(dragProxy.dragIndex, target, 1)
                                        dragProxy.dragIndex = target
                                    }
                                }

                                onClicked: {
                                    root.selectedIndex = index
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
                            property int dragIndex: -1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    source: "icons/drag_handle.svg"
                                    sourceSize: Qt.size(16, 16)
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
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