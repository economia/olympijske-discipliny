window.utils = {}

utils.to-grayscale = ->
    r = it.substr 1, 2
    g = it.substr 3, 2
    b = it.substr 5, 2
    all = [r, g, b].reduce do
        (sum, color) -> sum + parseInt color, 16
        0
    avg = Math.round all / 3
    hex = avg.toString 16
    '#' + hex + hex + hex
