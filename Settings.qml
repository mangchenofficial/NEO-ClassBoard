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
    color: Theme.color.surfaceBright
    
    signal importClicked()
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            Layout.preferredWidth: 64
            Layout.fillHeight: true
            color: Theme.color.surfaceContainer
            
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
                        color: navScheduleHover.containsMouse ? Theme.color.primaryContainer : "transparent"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                iconSize: 24
                                svgPath: "M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11z"
                                color: Theme.color.primary
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "课表"
                                font.pixelSize: 10
                                color: Theme.color.primary
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
                        color: navAboutHover.containsMouse ? Theme.color.primaryContainer : "transparent"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2

                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                iconSize: 24
                                svgPath: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"
                                color: Theme.color.onSurfaceVariantColor
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "关于"
                                font.pixelSize: 10
                                color: Theme.color.onSurfaceVariantColor
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
            color: Theme.color.surfaceBright
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16
                
                Text {
                    text: "课表设置"
                    font.family: Theme.typography.titleLarge.family
                    font.pixelSize: 22
                    font.weight: Theme.typography.titleLarge.weight
                    color: Theme.color.onSurfaceColor
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.color.outlineVariant
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: "课表文件"
                        font.family: Theme.typography.bodyLarge.family
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Theme.color.onSurfaceColor
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: Theme.color.surfaceContainer
                            radius: Theme.shape.cornerSmall
                            
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: csesParser.loaded ? csesParser.filePath : "未导入课表"
                                font.pixelSize: 13
                                color: csesParser.loaded ? Theme.color.onSurfaceColor : Theme.color.onSurfaceVariantColor
                                elide: Text.ElideMiddle
                            }
                        }
                        
                        Rectangle {
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 88
                            color: importBtnHover.containsMouse ? Qt.darker(Theme.color.primary, 1.2) : Theme.color.primary
                            radius: Theme.shape.cornerFull
                            
                            Text {
                                anchors.centerIn: parent
                                text: "导入"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: Theme.color.onPrimaryColor
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