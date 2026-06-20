import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: root
    anchors.fill: parent

    readonly property var pluginInst: {
        var pm = pluginManager
        if (!pm || !pm.pluginInstance) return null
        return pm.pluginInstance("countdown")
    }
    readonly property var countdownStore: pluginInst ? pluginInst.store : null

    property int _settingsRev: 0
    Connections {
        target: pluginInst
        function onSettingsChanged() { root._settingsRev++ }
    }

    readonly property string cfgTitle: "倒计日"
    readonly property int cfgFontSize: 20
    readonly property bool cfgShowLabel: false
    readonly property string cfgColorScheme: { root._settingsRev; return pluginInst ? (pluginInst.getSetting("colorScheme") || "tertiary") : "tertiary" }

    readonly property color displayColor: {
        var s = root.cfgColorScheme
        if (s === "primary") return Theme.color.primaryContainer
        if (s === "secondary") return Theme.color.secondaryContainer
        return Theme.color.tertiaryContainer
    }
    readonly property color onDisplayColor: {
        var s = root.cfgColorScheme
        if (s === "primary") return Theme.color.onPrimaryContainerColor
        if (s === "secondary") return Theme.color.onSecondaryContainerColor
        return Theme.color.onTertiaryContainerColor
    }

    property int currentIndex: 0

    Rectangle {
        anchors.fill: parent
        radius: Theme.shape.cornerMedium
        color: root.displayColor
        border.width: 1
        border.color: Theme.color.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 1

            Item { Layout.fillHeight: true }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.cfgShowLabel
                text: root.cfgTitle
                font.family: Theme.typography.labelSmall.family
                font.pixelSize: Theme.typography.labelSmall.size
                color: root.onDisplayColor
                opacity: 0.8
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    var store = root.countdownStore
                    if (!store) return "--"
                    var ts = store.targets
                    if (ts.length === 0) return "--"
                    var idx = root.currentIndex % ts.length
                    return Math.abs(ts[idx].days)
                }
                font.family: Theme.typography.headlineMedium.family
                font.pixelSize: root.cfgFontSize
                font.weight: Font.Black
                color: root.onDisplayColor
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    var store = root.countdownStore
                    if (!store) return "天"
                    var ts = store.targets
                    if (ts.length === 0) return "暂无目标"
                    var idx = root.currentIndex % ts.length
                    var t = ts[idx]
                    var label = t.label !== "" ? t.label : "目标"
                    return t.past ? "已过 " + Math.abs(t.days) + " 天 · " + label
                                  : "天后 · " + label
                }
                font.family: Theme.typography.labelSmall.family
                font.pixelSize: Theme.typography.labelSmall.size
                color: root.onDisplayColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Qt.AlignHCenter
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                spacing: 4
                visible: root.countdownStore ? root.countdownStore.targets.length > 1 : false

                Repeater {
                    model: root.countdownStore ? root.countdownStore.targets.length : 0
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: root.onDisplayColor
                        opacity: root.currentIndex === index ? 1.0 : 0.3
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                var store = root.countdownStore
                if (!store) return
                var n = store.targets.length
                if (n > 1) root.currentIndex = (root.currentIndex + 1) % n
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            if (root.countdownStore) root.countdownStore.refresh()
        }
    }
}