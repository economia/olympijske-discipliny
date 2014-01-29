new Tooltip!watchElements!
get-ordered-games = ([row]) ->
    fields = for field of row
        location = field
        year = field.split " " .pop! |> parseInt _, 10
        continue unless year
        {location, year}
    fields.sort (a, b) -> a.year - b.year

(err, data) <~ d3.csv "../data/discipliny.csv"
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
max = sports.reduce do
    (sum, sport) -> sum += sport.yearlyEvents[* - 1].events.length
    0
colors = <[#e41a1c #377eb8 #4daf4a #984ea3 #ff7f00 #ffff33 #a65628 #f781bf #4daf4a #984ea3 ]>
grayscaleColors = colors.map utils.to-grayscale


color = d3.scale.ordinal!
    ..range colors


grayscaleColor = d3.scale.ordinal!
    ..range grayscaleColors

x = d3.scale.linear!
    ..domain [1908 2014]
    ..range [0 width]

y = d3.scale.linear!
    ..domain [0 max]
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
    ..interpolate \monotone

svg = d3.select \.discipliny .append \svg
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
draw-all = (selected = null) ->
    graph.selectAll \path.sport .data sports
        ..enter!append \path
            ..attr \class \sport
    path = graph.selectAll \path.sport
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
    firstDrawComplete := yes

draw-all!
draw-x-axis!
