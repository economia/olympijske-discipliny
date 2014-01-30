window.ig =
    projectName : "sochi-discipliny"
    containers: {}

anchors = document.querySelectorAll "*[data-ig]"
for anchor in anchors
    content = anchor.getAttribute \data-ig
    div = document.createElement \div
        ..className = "ig #{ig.projectName} #{content}"
    if anchor.getAttribute 'data-width'
        div.style.width = "#{that}px"
    if anchor.getAttribute 'data-height'
        div.style.height = "#{that}px"

    parent = anchor.parentElement
    parent.replaceChild div, anchor
    ig.containers[content] = div

if div
    style = document.createElement \link
        ..setAttribute \rel \stylesheet
        ..setAttribute \type \text/css

    server = switch window.location.host in <[127.0.0.1 localhost hn.sulek.eu service.ihned.cz datasklad.ihned.cz]>
        | yes => ""
        | no => "http://datasklad.ihned.cz"
    style.href = server + "/#{ig.projectName}/www/screen.css"
    div.parentNode.insertBefore style, div
