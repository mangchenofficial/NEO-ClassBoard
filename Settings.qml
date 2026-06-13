import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import md3.Core

Window {
    id: settingsRoot
    title: "设置"
    width: 560
    height: 400
    flags: Qt.Window
    color: "#FEF7FF"
    
    signal importClicked()
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            Layout.preferredWidth: 64
            Layout.fillHeight: true
            color: "#F3EDF7"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 16
                spacing: 4
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.shape.cornerSmall
                        color: navScheduleHover.containsMouse ? "#E8DEF8" : "transparent"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Canvas {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, 24, 24)
                                    ctx.fillStyle = "#6750A4"
                                    ctx.font = "bold 10px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText("S", 12, 12)
                                }
                                Component.onCompleted: requestPaint()
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "课表"
                                font.pixelSize: 10
                                color: "#6750A4"
                            }
                        }
                        
                        MouseArea {
                            id: navScheduleHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.shape.cornerSmall
                        color: navAboutHover.containsMouse ? "#E8DEF8" : "transparent"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Canvas {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, 24, 24)
                                    ctx.fillStyle = "#49454F"
                                    ctx.font = "bold 10px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText("i", 12, 12)
                                }
                                Component.onCompleted: requestPaint()
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "关于"
                                font.pixelSize: 10
                                color: "#49454F"
                            }
                        }
                        
                        MouseArea {
                            id: navAboutHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#FEF7FF"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16
                
                Text {
                    text: "课表设置"
                    font.family: Theme.typography.titleLarge.family
                    font.pixelSize: 22
                    font.weight: Theme.typography.titleLarge.weight
                    color: "#1C1B1F"
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#CAC4D0"
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: "课表文件"
                        font.family: Theme.typography.bodyLarge.family
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#1C1B1F"
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: "#F3EDF7"
                            radius: Theme.shape.cornerSmall
                            
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: csesParser.loaded ? csesParser.filePath : "未导入课表"
                                font.pixelSize: 13
                                color: csesParser.loaded ? "#1C1B1F" : "#49454F"
                                elide: Text.ElideMiddle
                            }
                        }
                        
                        Rectangle {
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 88
                            color: importBtnHover.containsMouse ? "#0842A0" : "#0B57D0"
                            radius: Theme.shape.cornerFull
                            
                            Text {
                                anchors.centerIn: parent
                                text: "导入"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#FFFFFF"
                            }
                            
                            MouseArea {
                                id: importBtnHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsRoot.importClicked()
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
        }
    }
}
