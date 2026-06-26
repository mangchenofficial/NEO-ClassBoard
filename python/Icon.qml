import QtQuick

Item {
    id: root
    property string svgPath: ""
    property color color: "#000000"
    property int iconSize: 24

    width: iconSize
    height: iconSize

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = root.color
            ctx.beginPath()
            parseSvgPath(ctx, root.svgPath)
            ctx.fill()
        }
    }

    function parseSvgPath(ctx, d) {
        if (!d) return
        var tokens = d.match(/[A-Za-z]|[\-\d.]+/g)
        if (!tokens) return
        var i = 0, cmd, x, y, cpx1, cpy1, cpx2, cpy2
        var currentX = 0, currentY = 0
        var startX = 0, startY = 0

        while (i < tokens.length) {
            cmd = tokens[i++]
            switch (cmd) {
            case 'M':
                x = parseFloat(tokens[i++])
                y = parseFloat(tokens[i++])
                ctx.moveTo(x, y)
                currentX = x; currentY = y
                startX = x; startY = y
                break
            case 'm':
                x = currentX + parseFloat(tokens[i++])
                y = currentY + parseFloat(tokens[i++])
                ctx.moveTo(x, y)
                currentX = x; currentY = y
                startX = x; startY = y
                break
            case 'L':
                x = parseFloat(tokens[i++])
                y = parseFloat(tokens[i++])
                ctx.lineTo(x, y)
                currentX = x; currentY = y
                break
            case 'l':
                x = currentX + parseFloat(tokens[i++])
                y = currentY + parseFloat(tokens[i++])
                ctx.lineTo(x, y)
                currentX = x; currentY = y
                break
            case 'H':
                x = parseFloat(tokens[i++])
                ctx.lineTo(x, currentY)
                currentX = x
                break
            case 'h':
                x = currentX + parseFloat(tokens[i++])
                ctx.lineTo(x, currentY)
                currentX = x
                break
            case 'V':
                y = parseFloat(tokens[i++])
                ctx.lineTo(currentX, y)
                currentY = y
                break
            case 'v':
                y = currentY + parseFloat(tokens[i++])
                ctx.lineTo(currentX, y)
                currentY = y
                break
            case 'C':
                cpx1 = parseFloat(tokens[i++]); cpy1 = parseFloat(tokens[i++])
                cpx2 = parseFloat(tokens[i++]); cpy2 = parseFloat(tokens[i++])
                x = parseFloat(tokens[i++]); y = parseFloat(tokens[i++])
                ctx.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, x, y)
                currentX = x; currentY = y
                break
            case 'c':
                cpx1 = currentX + parseFloat(tokens[i++])
                cpy1 = currentY + parseFloat(tokens[i++])
                cpx2 = currentX + parseFloat(tokens[i++])
                cpy2 = currentY + parseFloat(tokens[i++])
                x = currentX + parseFloat(tokens[i++])
                y = currentY + parseFloat(tokens[i++])
                ctx.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, x, y)
                currentX = x; currentY = y
                break
            case 'Q':
                cpx1 = parseFloat(tokens[i++]); cpy1 = parseFloat(tokens[i++])
                x = parseFloat(tokens[i++]); y = parseFloat(tokens[i++])
                ctx.quadraticCurveTo(cpx1, cpy1, x, y)
                currentX = x; currentY = y
                break
            case 'q':
                cpx1 = currentX + parseFloat(tokens[i++])
                cpy1 = currentY + parseFloat(tokens[i++])
                x = currentX + parseFloat(tokens[i++])
                y = currentY + parseFloat(tokens[i++])
                ctx.quadraticCurveTo(cpx1, cpy1, x, y)
                currentX = x; currentY = y
                break
            case 'Z':
            case 'z':
                ctx.closePath()
                currentX = startX; currentY = startY
                break
            }
        }
    }

    onSvgPathChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
}