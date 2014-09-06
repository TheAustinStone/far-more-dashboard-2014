class Dashing.Meter extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      $meter = $(@node).find(".meter")
      $meter.val(value).trigger('change')

  onData: (data) ->
    # make the data re-load itself every time it refreshes
    @set('value', 0)

    setTimeout(=>
      @set('value', data.value)
    , 500)

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
