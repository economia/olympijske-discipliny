_gaq?.push(['_trackEvent', 'ig', ig.projectName]);
get-ordered-games = ([row]) ->
    fields = for field of row
        location = field
        [...locationParts, year] = field.split " "
        year = parseInt year, 10
        locationName = locationParts.join " "
        continue unless year
        {location, locationName, year}
    fields.sort (a, b) -> a.year - b.year

(err, data) <~ d3.pCsv "/data/discipliny.csv"
orderedGames = get-ordered-games data
lastSport = null
sports = []
data.forEach (event) ->
    if event["Sport"]
        name = that
        yearlyEvents = orderedGames.map ({location, year})-> {location, year, events: []}
        sport = {name, yearlyEvents}
        lastSport := sport
        sports.push lastSport

    for {location, year}, index in orderedGames
        name = event[location]
        continue if not name
        locationId = index
        name .= replace /^X:/ ""
        lastSport.yearlyEvents[index].events.push name

margin =
    top: 20
    right: 0
    bottom: 37
    left: 0
container = d3.select ig.containers['discipliny']
fullHeight = ig.containers['discipliny'].offsetHeight
fullWidth = ig.containers['discipliny'].offsetWidth
height = fullHeight - margin.bottom - margin.top
width = fullWidth - margin.left - margin.right
sumOfEvents = sports.reduce do
    (sum, sport) -> sum += Math.sqrt sport.yearlyEvents[* - 1].events.length
    0
colors = <[#e41a1c #377eb8 #4daf4a #ff7f00 #028E9B #984ea3 #a65628 #f781bf #4daf4a #a65628 #984ea3 #ff7f00 #e41a1c #4daf4a #4daf4a #377eb8 #ff7f00 #e41a1c #ff7f00 #984ea3 #a65628 #4daf4a #f781bf ]>
grayscaleColors = colors.map ig.utils.to-grayscale


color = d3.scale.ordinal!
    ..range colors


grayscaleColor = d3.scale.ordinal!
    ..range grayscaleColors

x = d3.scale.linear!
    ..domain [1908 2014]
    ..range [0 width]

y = d3.scale.linear!
    ..range [height, 0]

stack = d3.layout.stack!
    ..values (sport) -> sport.yearlyEvents
    ..x (yearlyEvents) -> yearlyEvents.year
    ..y (yearlyEvents) -> Math.sqrt yearlyEvents.events.length
    ..order \inside-out
stack sports

sports .= sort (a, b) ->
    aLastEvent = a.yearlyEvents[* - 8]
    bLastEvent = b.yearlyEvents[* - 8]
    aLastEvent.y0 - bLastEvent.y0

sports.forEach (sport, index) -> sport.color = index

area = d3.svg.area!
    ..x (yearlyEvents) ~> x yearlyEvents.year
    ..y1 (yearlyEvents) ~> y yearlyEvents.y0 + yearlyEvents.y
    ..y0 (yearlyEvents) ~> y yearlyEvents.y0
    ..interpolate \cardinal

detailArea = d3.svg.area!
    ..x (yearlyEvents) ~> x yearlyEvents.year
    ..y1 (yearlyEvents) ~> y yearlyEvents.y ** 2
    ..y0 (yearlyEvents) ~> y 0
    ..interpolate \monotone

svg = container.append \svg
    ..attr \width fullWidth
    ..attr \height fullHeight
drawing = svg.append \g
    ..attr \class \drawing
    ..attr \transform "translate(#{margin.left}, #{margin.top})"
graph = drawing.append \g
    ..attr \class \graph
gameNames = {}
orderedGames.forEach ({year, locationName}) -> gameNames[year] = locationName
xAxisTicks = null
draw-x-axis = ->
    xAxis = d3.svg.axis!
        ..scale x
        ..tickFormat -> it
        ..tickSize 2
        ..tickValues orderedGames.map (.year)
        ..outerTickSize 0
        ..orient \bottom
    xAxisGroup = drawing.append \g
        ..attr \class "axis x"
        ..attr \transform "translate(0, #{height})"
        ..call xAxis
    xAxisTicks := xAxisGroup.selectAll \g.tick
        ..select "text"
            ..attr \class \year
            ..attr \dy 8
            ..attr \dx (d, i) -> switch i
                | 0 => 12
                | 17 => -4
                | 18 => 4
                | 22 => -3
                | 23 => -11
                | otherwise => 0
        ..append \text
            ..attr \class \name
            ..attr \dy 31
            ..attr \dx (d, i) -> switch i
                | 0 => 22
                | 17 => -4
                | 18 => 4
                | 22 => -3
                | 23 => -16
                | otherwise => 0
            ..text -> gameNames[it]
highlightedYear = null
highlight-year = (year) ->
    return if highlightedYear == year
    highlightedYear := year
    xAxisTicks.classed \active -> it == year

firstDrawComplete = no
draw-all = (selected = null, cb) ->
    if selected and typeof! selected != \Array
        selected = [selected]
    y.domain [0 sumOfEvents]
    graph.selectAll \g.sport .data sports
        ..enter!append \g
            ..attr \class \sport
            ..append \path
    path = graph.selectAll "g.sport path"
        ..attr \data-tooltip (.name)
        ..on \click -> draw-detail it
    fillContainer = switch firstDrawComplete
        | yes => path.transition!duration 800
        | no  => path

    fillContainer
        ..attr \d ~> area it.yearlyEvents
        ..style \fill (d) ->
            | selected != null and d not in selected => grayscaleColor d.color
            | otherwise => color d.color
        ..style \fill-opacity (d) ->
            | selected != null and d not in selected => 0.3
            | otherwise => 1
    if cb
        if firstDrawComplete then setTimeout cb, 800 else cb!

    firstDrawComplete := yes

draw-detail = (sport) ->
    container.classed \detail yes
    backButton.classed \disabled no
    detailHeader.text sport.name
    <~ draw-all sport
    max = Math.max ...sport.yearlyEvents.map (.events.length)
    if max < 5 then max = 5
    y.domain [0 max]

    allGroups = graph.selectAll "g.sport"
    activeGroups = allGroups.filter -> it == sport
    inactiveGroups = allGroups.filter -> it != sport
    activeGroups.select \path
        ..transition!
            ..duration 800
            ..attr \d ~> detailArea it.yearlyEvents
    inactiveGroups
        ..attr \transform "translate(0, 0)"
        ..transition!
            ..duration 800
            ..attr \transform "translate(0, -#{height * 1.5})"

    events = []
    events_assoc = {}
    for {events:yearlyEvents, year} in sport.yearlyEvents
        for eventName in yearlyEvents
            if not events_assoc[eventName]
                event = {name: eventName, years: []}
                events_assoc[eventName] = event
                events.push event
    for event in events
        event.games = sport.yearlyEvents.map (game) ->
            present = event.name in game.events
            {game, present}
        event.gamesPresent = event.games.filter (.present)
    events .= sort (a, b) ->
        a.gamesPresent.0.game.year - b.gamesPresent.0.game.year

    stack = d3.layout.stack!
        ..values (event) -> event.games
        ..x (game) -> game.game.year
        ..y (game) -> if game.present then 1 else 0
    stack events
    baseColor = color sports.indexOf sport
    len = events.length
    hueStep = 2
    hue = Color baseColor .hue!
    if hue < 0 then hue += 360
    for event, i in events
        i = len - i
        percentage = i / len / 3
        newHue = hue + i * hueStep
        if newHue > 360 then newHue -= 360
        event.color = Color baseColor
            .darken percentage
            .hue newHue
            .hexString!

    eventColor = d3.scale.ordinal!
        ..range colors

    area = d3.svg.area!
        ..x (game) ~> x game.game.year
        ..y1 (game) ~> y game.y0 + game.y
        ..y0 (game) ~> y game.y0
        ..interpolate \monotone

    graph.selectAll \g.event .data events
        ..enter!append \g
            ..attr \class \event
            ..append \path
                ..style \opacity 0

    path = graph.selectAll "g.event path"
        ..attr \d ~> area it.games
        ..attr \fill (.color)
        ..attr \data-tooltip ->
            out = "<b>#{it.name}<br /></b>"
            out += it.gamesPresent.map (.game.location) .join "<br />"
            escape out
        ..transition!
            ..delay (d, i) -> 500 + len * 50 - i * 50
            ..duration 800
            ..style \opacity 1
    <~ setTimeout _, 500 + 800 + len * 50
    activeGroups.select \path .style \opacity 0

redraw-all = ->
    container.classed \detail no
    backButton.classed \disabled yes
    allGroups = graph.selectAll "g.sport"
    allGroups.select \path .style \opacity 1
    maxDelay = 0
    eventGroup = graph.selectAll "g.event"
        ..style \opacity 1
        ..transition!
            ..delay (d, i) -> maxDelay := i * 40
            ..duration 200
            ..style \opacity 0
    <~ setTimeout _, maxDelay + 400
    eventGroup.remove!
    graph.selectAll \g.sport
        ..transition!
            ..duration 800
            ..attr \transform "translate(0, 0)"
    draw-all!

lastStory = {index: -1, element: null}
nextStory = {index: null, element: null, timeout: null}
prepare-story-element = (story) ->
    newStoryElement = d3.select document.createElement \div
    if lastStory.index == -1
        newStoryElement.attr \class "story"
    else
        newStoryElement.attr \class "story left"
    newStoryElement.append \h2 .html that if story.header
    newStoryElement.append \p .html that if story.content
    if story.attachment
        figure = newStoryElement.append \figure .html that
        if story.caption
            figure.append \figcaption .html that
    newStoryElement

draw-story = (index) ->
    return if index == lastStory.index
    index %%= ig.stories.length
    story = ig.stories[index]
    if index == nextStory.index
        newStoryElement = nextStory.element
    else
        newStoryElement = prepare-story-element story
        storyContainer.0.0.appendChild newStoryElement.0.0
    lastStoryElement = lastStory.element
    lastStoryIndex = lastStory.index

    storySelector.classed \active (d, i) -> i == Math.floor index / 2
    lastStory.index = index
    lastStory.element = newStoryElement
    year = +ig.stories[index - index % 2].header.split ", " .0
    highlight-year year
    if story.detail
        draw-detail sports[that]
    else if story.highlight
        draw-all that.map -> sports[it]
    else
        draw-all!
    clearTimeout that if nextStory.timeout
    nextStory.timeout = setTimeout do
        ->
            nextStory.index = (index + 1) %% ig.stories.length
            nextStory.element = prepare-story-element ig.stories[nextStory.index]
            storyContainer.0.0.appendChild nextStory.element.0.0
            nextStory.timeout = null
        600
    return if lastStoryIndex == -1
    if lastStoryIndex < index
        lastStoryElement?classed \right true
    else
        newStoryElement.attr \class 'story right'
        lastStoryElement?classed \left true
    setTimeout do
        -> newStoryElement.attr \class \story
        0

    setTimeout lastStoryElement~remove, 800

backButton = container.append \a
    ..attr \class "backButton disabled"
    ..on \click redraw-all

storyContainer = container.append \div
    ..attr \class "stories"
    ..append \div
        ..attr \class \nextButton
        ..append \div
        ..append \div
        ..append \div
        ..on \click -> draw-story lastStory.index + 1
storySelector = container.append \ul
    .attr \class \stories
    .selectAll \li .data ig.stories.filter (.header)
        .enter!append \li
            .html (d, i) -> d.header.split "," .0
            .on \click (d, i) -> draw-story i * 2
draw-all!
draw-x-axis!

ig.utils.draw-bg do
    ig.containers['discipliny']
    top: -3px + margin.top
    bottom: -1 * margin.bottom + 3
detailHeader = container.append \h1
draw-story 0
drawing.on \mousemove ->
    left = d3.event.x - ig.utils.offset ig.containers['discipliny'] .left
    domain = 2014 - 1908
    range = width
    lastDiff = Infinity
    closestYear = null
    mouseYear = Math.round 1908 + domain * left / range
    for {year}:game in orderedGames
        diff = Math.abs mouseYear - year
        break if diff > lastDiff
        lastDiff = diff
        closestYear = year
    highlight-year closestYear
drawing.on \mouseout -> highlight-year null
d3.select document
    ..on \keydown ->
        switch d3.event.keyCode
        | 39 => draw-story lastStory.index + 1
        | 37 => draw-story lastStory.index - 1
