import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Effects
import md3.Core

Window {
    id: root
    flags: Qt.FramelessWindowHint | Qt.Popup | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint
    color: "transparent"
    visible: false
    width: menuBackground.implicitWidth
    height: menuBackground.implicitHeight

    signal showHideRequested()
    signal settingsRequested()
    signal rescheduleRequested(int day)
    signal swapRequested()
    signal quitRequested()

    property int currentRescheduleDay: 0
    property var _colors: Theme.color
    property var _shape: Theme.shape
    property var _elevation: Theme.elevation
    property var _state: Theme.state
    property var _typography: Theme.typography

    property real _dp: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0

    function showAt(x, y) {
        var screenW = Screen.desktopAvailableWidth
        var screenH = Screen.desktopAvailableHeight
        var menuW = root.width
        var menuH = root.height

        var nx = x - menuW / 2
        var ny = y + 4

        if (nx + menuW > screenW) nx = screenW - menuW - 4
        if (ny + menuH > screenH) ny = y - menuH - 4
        if (nx < 4) nx = 4
        if (ny < 4) ny = 4

        root.x = nx
        root.y = ny
        root.visible = true
        root.requestActivate()
    }

    function hideMenu() {
        root.visible = false
    }

    Rectangle {
        id: shadowSource
        anchors.fill: menuBackground
        radius: menuBackground.radius
        color: _colors.surfaceContainer
        visible: false
    }

    MultiEffect {
        source: shadowSource
        anchors.fill: shadowSource
        shadowEnabled: true
        shadowColor: _colors.shadow
        shadowBlur: _elevation.level2 * 0.5
        shadowVerticalOffset: _elevation.level2
        shadowOpacity: 0.2
        z: 0
    }

    Rectangle {
        id: menuBackground
        z: 1
        implicitWidth: Math.max(236, contentColumn.implicitWidth + 16)
        implicitHeight: Math.min(contentColumn.implicitHeight + 16, Screen.desktopAvailableHeight * 0.8)
        color: _colors.surfaceContainer
        radius: _shape.cornerExtraSmall
        clip: true

        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: contentColumn.implicitWidth
            contentHeight: contentColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: contentColumn
                width: flickable.width
                spacing: 0

                MenuItem {
                    Layout.fillWidth: true
                    text: "显示/隐藏"
                    iconCode: "dashboard"
                    onClicked: { root.showHideRequested(); root.hideMenu() }
                }

                MenuItem {
                    Layout.fillWidth: true
                    text: "设置"
                    iconCode: "settings"
                    onClicked: { root.settingsRequested(); root.hideMenu() }
                }

                MenuSeparator { Layout.fillWidth: true }

                MenuItem {
                    id: rescheduleItem
                    Layout.fillWidth: true
                    text: "调休日"
                    iconCode: "schedule"
                    expandable: true
                    expanded: rescheduleSubMenu.visible
                    onClicked: { rescheduleSubMenu.visible = !rescheduleSubMenu.visible }
                }

                ColumnLayout {
                    id: rescheduleSubMenu
                    visible: false
                    spacing: 0
                    Layout.fillWidth: true

                    SubMenuItem {
                        Layout.fillWidth: true
                        text: "不调休"
                        checked: root.currentRescheduleDay === 0
                        onClicked: { root.rescheduleRequested(0); root.hideMenu() }
                    }

                    Repeater {
                        model: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
                        SubMenuItem {
                            Layout.fillWidth: true
                            text: modelData
                            checked: root.currentRescheduleDay === (index + 1)
                            onClicked: { root.rescheduleRequested(index + 1); root.hideMenu() }
                        }
                    }
                }

                MenuSeparator { Layout.fillWidth: true }

                MenuItem {
                    Layout.fillWidth: true
                    text: "换课"
                    iconCode: "swap_horiz"
                    onClicked: { root.swapRequested(); root.hideMenu() }
                }

                MenuSeparator { Layout.fillWidth: true }

                MenuItem {
                    Layout.fillWidth: true
                    text: "退出"
                    iconCode: ""
                    onClicked: { root.quitRequested(); root.hideMenu() }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -30
        z: -1
        onClicked: root.hideMenu()
    }

    onActiveChanged: {
        if (!active) root.hideMenu()
    }

    component MenuItem: Item {
        id: itemRoot
        implicitWidth: 220
        implicitHeight: 44

        property string text: ""
        property string iconCode: ""
        property bool expandable: false
        property bool expanded: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: _shape.cornerExtraSmall
            color: _colors.onSurfaceColor
            opacity: {
                if (mouseArea.pressed) return _state.pressedStateLayerOpacity
                if (mouseArea.containsMouse) return _state.hoverStateLayerOpacity
                return 0
            }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 10

            Text {
                visible: iconCode !== ""
                text: iconCode
                font.family: Theme.iconFont.name
                font.pixelSize: 20
                color: _colors.onSurfaceColor
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: itemRoot.text
                font.family: _typography.labelLarge.family
                font.pixelSize: _typography.labelLarge.size
                font.weight: _typography.labelLarge.weight
                color: _colors.onSurfaceColor
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                visible: expandable
                text: expanded ? "expand_less" : "expand_more"
                font.family: Theme.iconFont.name
                font.pixelSize: 20
                color: _colors.onSurfaceVariantColor
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: itemRoot.clicked()
        }
    }

    component SubMenuItem: Item {
        id: subRoot
        implicitWidth: 220
        implicitHeight: 40

        property string text: ""
        property bool checked: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: _shape.cornerExtraSmall
            color: _colors.onSurfaceColor
            opacity: {
                if (subMouseArea.pressed) return _state.pressedStateLayerOpacity
                if (subMouseArea.containsMouse) return _state.hoverStateLayerOpacity
                return 0
            }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 44
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: subRoot.text
                font.family: _typography.labelLarge.family
                font.pixelSize: _typography.labelLarge.size
                font.weight: _typography.labelLarge.weight
                color: _colors.onSurfaceColor
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                visible: checked
                text: "check"
                font.family: Theme.iconFont.name
                font.pixelSize: 18
                color: _colors.primary
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: subMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: subRoot.clicked()
        }
    }

    component MenuSeparator: Item {
        implicitWidth: 200
        implicitHeight: 13

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 16
            height: 1
            color: _colors.outlineVariant
        }
    }
}