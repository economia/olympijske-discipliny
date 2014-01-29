window.utils = {}

utils.to-grayscale = (input) ->
    color = window.Color input
    color.greyscale!hexString!

