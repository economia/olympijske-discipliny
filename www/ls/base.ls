new Tooltip!watchElements!
_gaq?.push(['_trackEvent', 'ig', ig.projectName]);
get-ordered-games = ([row]) ->
    fields = for field of row
        location = field
        year = field.split " " .pop! |> parseInt _, 10
        continue unless year
        {location, year}
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
        lastSport.yearlyEvents[index].events.push name

margin =
    top: 0
    right: 0
    bottom: 30
    left: 20
fullHeight = 650 # window.innerHeight
fullWidth = 970 # window.innerWidth
height = fullHeight - margin.bottom - margin.top
width = fullWidth - margin.left - margin.right
sumOfEvents = sports.reduce do
    (sum, sport) -> sum += sport.yearlyEvents[* - 1].events.length
    0
colors = <[#e41a1c #377eb8 #4daf4a #984ea3 #ff7f00 #ffff33 #a65628 #f781bf #4daf4a #984ea3 ]>
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
    ..y (yearlyEvents) -> yearlyEvents.events.length
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
    ..interpolate \basis

detailArea = d3.svg.area!
    ..x (yearlyEvents) ~> x yearlyEvents.year
    ..y1 (yearlyEvents) ~> y yearlyEvents.y
    ..y0 (yearlyEvents) ~> y 0
    ..interpolate \basis

svg = d3.select ig.containers['discipliny'] .append \svg
    ..attr \width fullWidth
    ..attr \height fullHeight
drawing = svg.append \g
    ..attr \class \drawing
    ..attr \transform "translate(#{margin.left}, #{margin.top})"
graph = drawing.append \g
    ..attr \class \graph

draw-x-axis = ->
    xAxis = d3.svg.axis!
        ..scale x
        ..tickFormat -> it
        ..tickSize 4
        ..ticks 10
        ..outerTickSize 0
        ..orient \bottom
    xAxisGroup = drawing.append \g
        ..attr \class "axis x"
        ..attr \transform "translate(0, #{height})"
        ..call xAxis
        ..selectAll "text"
            ..attr \dy 21

firstDrawComplete = no
draw-all = (selected = null, cb) ->
    y.domain [0 sumOfEvents]
    graph.selectAll \g.sport .data sports
        ..enter!append \g
            ..attr \class \sport
            ..append \path
    path = graph.selectAll "g.sport path"
        ..attr \d ~> area it.yearlyEvents
        ..attr \data-tooltip (.name)
    fillContainer = switch firstDrawComplete
        | yes => path.transition!duration 800
        | no  => path

    fillContainer
        ..style \fill (d) ->
            | selected != null and selected != d => grayscaleColor d.color
            | otherwise => color d.color
        ..style \fill-opacity (d) ->
            | selected != null and selected != d => 0.3
            | otherwise => 1
    if cb
        if firstDrawComplete then setTimeout cb, 800 else cb!

    firstDrawComplete := yes

draw-detail = (sport) ->
    <~ draw-all sport
    max = Math.max ...sport.yearlyEvents.map (.events.length)
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
        ..interpolate \basis

    graph.selectAll \g.event .data events
        ..enter!append \g
            ..attr \class \event
            ..append \path
                ..style \opacity 0

    path = graph.selectAll "g.event path"
        ..attr \d ~> area it.games
        ..attr \fill (.color)
        ..attr \data-tooltip (.name)
        ..transition!
            ..delay (d, i) -> 500 + len * 50 - i * 50
            ..duration 800
            ..style \opacity 1

draw-all!
draw-x-axis!


draw-detail sports.1
