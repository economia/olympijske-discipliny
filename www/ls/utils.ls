ig.utils = utils = {}

utils.to-grayscale = (input) ->
    color = window.Color input
    color.greyscale!hexString!

utils.proxyAddr = (addr) ->
    switch window.location.host in <[service.ihned.cz datasklad.ihned.cz]>
    | yes => "../#{addr}"
    | no  => "/site/api/cs/proxies/detail/?url=http://datasklad.ihned.cz/#{ig.projectName}/#addr"

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
utils.offset = (element, side) ->
    top = 0
    left = 0
    do
        top += element.offsetTop
        left += element.offsetLeft
    while element = element.offsetParent
    {top, left}
