ig.utils = utils = {}

utils.to-grayscale = (input) ->
    color = window.Color input
    color.greyscale!hexString!

utils.proxyAddr = (addr) ->
    "/site/api/cs/proxies/detail/?url=http://datasklad.ihned.cz/#{ig.projectName}/#addr"

d3.pCsv = ->
    arguments[0] = utils.proxyAddr arguments[0]
    d3.csv ...arguments
