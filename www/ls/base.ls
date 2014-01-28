get-ordered-games = ([row]) ->
    fields = for field of row
        location = field
        year = field.split " " .pop! |> parseInt _, 10
        continue unless year
        {location, year}
    fields.sort (a, b) -> a.year - b.year

(err, data) <~ d3.csv "../data/discipliny.csv"
orderedGames = get-ordered-games data
orderedGames.unshift {location: null, year: null}
gamesLength = orderedGames.length
lastSport = null
events = data.map (event) ->
    if event["Sport"]
        lastSport := that
    sport = lastSport
    occurences = for {location}, index in orderedGames
        name = event[location]
        continue if not name
        locationId = index
        {name, locationId}
    occurences = null unless occurences.length
    {sport, occurences}
events .= filter (.occurences)
events .= sort (a, b) ->
    | a.sport > b.sport =>  1
    | a.sport < b.sport => -1
    | a.occurences.0.locationId - b.occurences.0.locationId => that

lastParents = []
root = {name: "root", children: []}
rootChildren = root.children
lastSport = null
events.forEach (event) ->
    if lastSport != event.sport
        lastSport := event.sport
        node = {name: event.sport, children: []}
        lastLocationId = event.occurences.0.locationId
        orderedGames.forEach (location, index) ->
            lastParents[index] := node
        rootChildren.push node
    event.occurences.forEach ({name, locationId}) ->
        parent = lastParents[locationId]
        node = {name, children: []}
        parent.children.push node
        for index in [locationId til gamesLength]
            lastParents[index] := node

window.root = root
return
# console.log root
width = 8000
height = 2200
cluster = d3.layout.cluster!
    ..size [height, width]

diagonal = d3.svg.diagonal!
    ..projection (d) -> [d.y, d.x]

svg = d3.select "body" .append "svg"
    ..attr "width", width
    ..attr "height", height

nodes = cluster.nodes root
links = cluster.links nodes

link = svg.selectAll ".link" .data links
    ..enter!append "path"
        ..attr "class", "link"
        ..attr "d", diagonal

node = svg.selectAll ".node" .data nodes
    ..enter!append "g"
        ..attr "class", "node"
        ..attr "transform" (d) -> "translate(" + d.y + "," + d.x + ")"

node.append "circle"
    .attr "r", 4.5

node.append "text"
    .attr "dx", (d) -> if d.children then -8 else 8
    .attr "dy", 3
    .style "text-anchor", (d) -> if d.children then "end" else "start"
    .text (.name)


# d3.select(self.frameElement).style("height", height + "px");
