class Dashing.Fullpie extends Dashing.Widget

  onData: (data) ->
    console.log data
    @render(data.value)

  render: (data) ->
    if !data
      data = @get("value")

    return unless data

    # data binding doesn't seem to work without this...
    $(@node).children(".title").text($(@node).attr("data-title"))

    width = 260
    height = 260
    radius = 130

    color = d3.scale.ordinal()
      .domain([1,10])
      .range( ['#222222','#333333','#444444','#555555','#666666','#777777','#888888','#999999','#aaaaaa'] )

    $(@node).children("svg").remove()

    vis = d3.select(@node).append("svg:svg")
      .data([data])
        .attr("width", width)
        .attr("height", height)
      .append("svg:g")
        .attr("transform", "translate(" + radius + "," + radius + ")")

    arc = d3.svg.arc().outerRadius(radius)
    pie = d3.layout.pie().value((d) -> d.value)

    arcs = vis.selectAll("g.slice")
      .data(pie)
      .enter().append("svg:g").attr("class", "slice")

    arcs.append("svg:path").attr("fill", (d, i) -> color i)
      .attr("fill-opacity", 0.4).attr("d", arc)

    sum=0
    for val in data
      sum += val.value

    arcs.append("svg:text")
      .attr("transform", (d, i) ->
        percent = Math.round(data[i].value/sum * 100)
        d.innerRadius = (radius * (100 - percent) / 100) - 75
        d.outerRadius = radius
        "translate(" + arc.centroid(d) + ")"
      )
      .attr('fill', "#fff")
      .attr("text-anchor", "middle").text((d, i) -> data[i].label)
      .append('svg:tspan')
      .attr('x', 0)
      .attr('dx', 2)
      .attr('dy', 15)
      .attr('font-size', '0.6em')
      .text((d,i) -> Math.round(data[i].value/sum * 100) + '%')
