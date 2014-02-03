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

utils.draw-bg = (baseElement, padding = {}) ->
    bgElement = document.createElement \div
        ..className    = "ig-background"
    ihned = document.querySelector '#ihned'
    if ihned
        that.parentNode.insertBefore bgElement, ihned
    reposition = -> reposition-bg baseElement, bgElement, padding
    reposition!
    setInterval reposition, 1000


reposition-bg = (baseElement, bgElement, padding) ->
    {top} = utils.offset baseElement
    height = baseElement.offsetHeight
    if padding.top
        top += that
        height -= that
    if padding.bottom
        height += that
    bgElement
        ..style.top    = "#{top}px"
        ..style.height = "#{height}px"


utils.offset = (element, side) ->
    top = 0
    left = 0
    do
        top += element.offsetTop
        left += element.offsetLeft
    while element = element.offsetParent
    {top, left}
