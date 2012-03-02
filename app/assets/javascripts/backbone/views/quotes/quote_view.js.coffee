Lt.Views.Quotes ||= {}

class Lt.Views.Quotes.QuoteView extends Backbone.View
  template  : JST['backbone/templates/quotes/quote']

  tagName   : 'div'
  className : 'quote'

  events:
    'dblclick' : 'edit'

  initialize: ->
    @model.bind 'change', @render, @

  edit: (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    @$el.trigger('editQuote', [@model.cid])
    return

  render: ->
    $(@el).html @template(@model.toJSON())
    return this
