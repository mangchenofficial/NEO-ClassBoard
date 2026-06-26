import QtQuick
import QtQuick.Layouts
import md3.Core

Item {
    id: root
    anchors.fill: parent

    property int clickCount: 0

    Rectangle {
        anchors.fill: parent
        radius: Theme.shape.cornerMedium
        color: Theme.color.primaryContainer

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "示例"
                font.family: Theme.typography.labelLarge.family
                font.pixelSize: Theme.typography.labelLarge.size
                font.weight: Font.Bold
                color: Theme.color.onPrimaryContainerColor
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.clickCount
                font.family: Theme.typography.titleMedium.family
                font.pixelSize: Theme.typography.titleMedium.size
                font.weight: Font.Bold
                color: Theme.color.onPrimaryContainerColor
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.clickCount++
        }
    }
}