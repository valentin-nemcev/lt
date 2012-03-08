Lt.Views.Quotes ||= {}

class Lt.Views.Quotes.ItemView extends Backbone.View
  template  : JST['backbone/templates/quotes/item']

  tagName   : 'div'
  className : 'quote'

  events:
    'dblclick' : 'edit'

  initialize: ->
    @presenter = new Lt.Views.Quotes.Presenter(@model)
    @model.bind 'change', @render, @

  edit: (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    @$el.trigger('editItem', [@model.cid])
    return

  render: ->
    $(@el).html @template(@presenter)
    return this
