class Dashing.Textcarousel extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @textElem = $(@node).find('p')
    @nextComment()
    @startCarousel()

  onData: (data) ->
    @currentIndex = 0

  startCarousel: ->
    setInterval(@nextComment, 8000)

  nextComment: =>
    texts = @get('texts')
    if texts
      @textElem.fadeOut =>
        @currentIndex = (@currentIndex + 1) % texts.length
        @set 'current_text', texts[@currentIndex]
        @textElem.fadeIn()
