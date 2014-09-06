class Dashing.Textcarousel extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @textElem = $(@node).find('p:first')
    @nextComment()
    @startCarousel()

  onData: (data) ->
    # attempt to pick up where we left off, but default to starting over
    @currentIndex = Math.max(0, @get('texts').indexOf(@get('current_text')))

  startCarousel: ->
    setInterval(@nextComment, 8000)

  nextComment: =>
    texts = @get('texts')
    if texts
      @textElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % texts.length
        @set 'current_text', texts[@currentIndex]
        @textElem.fadeIn()
