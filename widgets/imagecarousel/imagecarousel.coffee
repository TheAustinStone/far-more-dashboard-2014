class Dashing.Imagecarousel extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @nextImage()
    @startCarousel()

  onData: (data) ->
    # attempt to pick up where we left off, but default to starting over
    @currentIndex = Math.max(0, @get('urls').indexOf(@get('current_url')))

  startCarousel: ->
    setInterval(@nextImage, 7000)

  nextImage: =>
    urls = @get('urls')
    if urls
      $(@node).fadeOut =>
        @currentIndex = (@currentIndex + 1) % urls.length
        @set 'current_url', urls[@currentIndex]
        $(@node)
          .css('background-image', 'url(' + @get('current_url') + ')')
          .fadeIn()
