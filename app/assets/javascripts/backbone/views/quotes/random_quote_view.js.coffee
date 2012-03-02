Lt.Views.Quotes ||= {}

class Lt.Views.Quotes.RandomQuoteView extends Backbone.View
  template: JST['backbone/templates/quotes/random_quote']

  initialize: ->
    @presenter = new Lt.Views.Quotes.Presenter(@model)
    @model.bind 'change', @render, @

  events:
    'click a.next' : 'next'

  next: (ev) ->
    ev.preventDefault()
    @model.fetch_next()
    return

  render: ->
    @$el.html @template(@presenter)
    return this
