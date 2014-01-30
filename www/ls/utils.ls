ig.utils = utils = {}

utils.to-grayscale = (input) ->
    color = window.Color input
    color.greyscale!hexString!

utils.proxyAddr = (addr) ->
    "/site/api/cs/proxies/detail/?url=http://datasklad.ihned.cz/#{ig.projectName}/#addr"

d3.pCsv = ->
    arguments[0] = utils.proxyAddr arguments[0]
    d3.csv ...arguments

utils.draw-bg = (element, padding = {}) ->
    top = element.offsetTop
    height = element.offsetHeight
    if padding.top
        top += that
        height -= that
    if padding.bottom
        height += that

    bg = document.createElement \div
        ..style.top    = "#{top}px"
        ..style.height = "#{height}px"
        ..className    = "ig-background"

    ihned = document.querySelector '#ihned'
    if ihned
        that.parentNode.insertBefore bg, ihned
