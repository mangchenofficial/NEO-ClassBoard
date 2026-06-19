import QtQuick
import md3.Core
Item {
    id: control
    
    property real value: 0.0
    property bool indeterminate: false
    property bool wavy: false
    
    implicitWidth: 200
    implicitHeight: wavy ? 16 : 4
    
    property var _colors: Theme.color
    
    // Animation control
    property bool _initialized: false
    Component.onCompleted: _initialized = true
    
    property real _visualValue: Math.max(0.0, Math.min(1.0, control.value))
    Behavior on _visualValue {
        enabled: control._initialized
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }
    
    // Standard Linear Progress
    Rectangle {
        id: track
        anchors.fill: parent
        visible: !control.wavy
        color: _colors.surfaceContainerHighest
        radius: height / 2
        clip: true
        
        // Determinate Indicator
        Rectangle {
            visible: !control.indeterminate
            height: parent.height
            width: parent.width * control._visualValue
            color: _colors.primary
            radius: height / 2
        }
        
        // Indeterminate Indicator
        Item {
            anchors.fill: parent
            visible: control.indeterminate
            
            // First bar
            Rectangle {
                id: bar1
                height: parent.height
                color: _colors.primary
                radius: height / 2
                
                SequentialAnimation {
                    running: control.indeterminate && control.visible && !control.wavy
                    loops: Animation.Infinite
                    
                    ParallelAnimation {
                        NumberAnimation { target: bar1; property: "x"; from: -parent.width; to: parent.width; duration: 2000; easing.type: Easing.InOutCubic }
                        SequentialAnimation {
                            NumberAnimation { target: bar1; property: "width"; from: 0; to: parent.width * 0.5; duration: 1000; easing.type: Easing.OutCubic }
                            NumberAnimation { target: bar1; property: "width"; from: parent.width * 0.5; to: 0; duration: 1000; easing.type: Easing.InCubic }
                        }
                    }
                }
            }
            
            // Second bar (delayed)
            Rectangle {
                id: bar2
                height: parent.height
                color: _colors.primary
                radius: height / 2
                
                SequentialAnimation {
                    running: control.indeterminate && control.visible && !control.wavy
                    loops: Animation.Infinite
                    
                    PauseAnimation { duration: 1000 }
                    
                    ParallelAnimation {
                        NumberAnimation { target: bar2; property: "x"; from: -parent.width; to: parent.width; duration: 2000; easing.type: Easing.InOutCubic }
                        SequentialAnimation {
                            NumberAnimation { target: bar2; property: "width"; from: 0; to: parent.width * 0.5; duration: 1000; easing.type: Easing.OutCubic }
                            NumberAnimation { target: bar2; property: "width"; from: parent.width * 0.5; to: 0; duration: 1000; easing.type: Easing.InCubic }
                        }
                    }
                }
            }
        }
    }

    // Wavy Linear Progress
    Canvas {
        id: wavyCanvas
        visible: control.wavy
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Cooperative

        property color activeColor: control._colors.primary
        property real progress: control.value

        onActiveColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        property real phase: 0.0

        NumberAnimation on phase {
            running: control.wavy && control.visible
            from: 0
            to: Math.PI * 2
            duration: 1000
            loops: Animation.Infinite
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var w = width;
            var h = height;
            var cy = h / 2;
            var amplitude = h * 0.3;
            var frequency = 0.12;

            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.strokeStyle = activeColor;

            var endX;
            if (control.indeterminate) {
                var phaseProgress = (phase % (Math.PI * 2)) / (Math.PI * 2);
                var barWidth = w * 0.5;
                var startX = (w + barWidth) * phaseProgress - barWidth;
                endX = startX + barWidth;
                if (endX > w) endX = w;
                if (startX < 0) { endX += -startX; startX = 0; }
                if (endX > w) endX = w;
            } else {
                endX = w * Math.max(0, Math.min(1, progress));
            }

            // Active wave only - no background track
            ctx.beginPath();
            for (var x = 0; x <= endX; x+=1) {
                var y = cy + amplitude * Math.sin((x * frequency) + phase);
                if (x === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();
        }

        onPhaseChanged: requestPaint()
    }
}

