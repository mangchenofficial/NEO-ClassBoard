import QtQuick
import md3.Core

Canvas {
    id: root

    property color color: Theme.color.onSurfaceVariantColor

    implicitWidth: 24
    implicitHeight: 24
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.fillStyle = root.color
        var w = root.width
        var h = root.height
        if (w <= 0 || h <= 0) return
        var s = Math.min(w, h) / 24.0
        var ox = (w - 24 * s) / 2
        var oy = (h - 24 * s) / 2
        ctx.beginPath()
        ctx.moveTo(ox + 3 * s, oy + 3 * s)
        ctx.lineTo(ox + 10 * s, oy + 3 * s)
        ctx.bezierCurveTo(ox + 10 * s, oy + 1.9 * s, ox + 10.9 * s, oy + 1 * s, ox + 12 * s, oy + 1 * s)
        ctx.bezierCurveTo(ox + 13.1 * s, oy + 1 * s, ox + 14 * s, oy + 1.9 * s, ox + 14 * s, oy + 3 * s)
        ctx.lineTo(ox + 21 * s, oy + 3 * s)
        ctx.lineTo(ox + 21 * s, oy + 10 * s)
        ctx.bezierCurveTo(ox + 22.1 * s, oy + 10 * s, ox + 23 * s, oy + 10.9 * s, ox + 23 * s, oy + 12 * s)
        ctx.bezierCurveTo(ox + 23 * s, oy + 13.1 * s, ox + 22.1 * s, oy + 14 * s, ox + 21 * s, oy + 14 * s)
        ctx.lineTo(ox + 21 * s, oy + 21 * s)
        ctx.lineTo(ox + 14 * s, oy + 21 * s)
        ctx.bezierCurveTo(ox + 14 * s, oy + 22.1 * s, ox + 13.1 * s, oy + 23 * s, ox + 12 * s, oy + 23 * s)
        ctx.bezierCurveTo(ox + 10.9 * s, oy + 23 * s, ox + 10 * s, oy + 22.1 * s, ox + 10 * s, oy + 21 * s)
        ctx.lineTo(ox + 3 * s, oy + 21 * s)
        ctx.lineTo(ox + 3 * s, oy + 14 * s)
        ctx.bezierCurveTo(ox + 1.9 * s, oy + 14 * s, ox + 1 * s, oy + 13.1 * s, ox + 1 * s, oy + 12 * s)
        ctx.bezierCurveTo(ox + 1 * s, oy + 10.9 * s, ox + 1.9 * s, oy + 10 * s, ox + 3 * s, oy + 10 * s)
        ctx.closePath()
        ctx.fill()
    }
}