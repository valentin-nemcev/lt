Lt.Views.Quotes ||= {}

class Lt.Views.Quotes.Presenter

  constructor: (@model) ->
    @model.bind 'change', @_update, @
    @_update()

  nl2br = (text = '') -> text.replace /\n/g, '<br/>'

  trimProtocol = (url = '') -> url.replace /^https?:\/\//, ''

  _update: ->
    _.extend this, @model.toJSON()

    @contentHtml = nl2br @content
    @sourceTitle = trimProtocol @source
