Lt.Views.Quotes ||= {}

class Lt.Views.Quotes.IndexView extends Backbone.View
  template  : JST['backbone/templates/quotes/index']

  initialize: () ->
    @collection.bind 'reset'   , @reset, @
    @collection.bind 'add'     , @add,   @
    @collection.bind 'destroy' , @destroy, @

  reset: (quotes) =>
    @add quote for quote in quotes.models
    return

  add: (quote) =>
    quoteView = new Lt.Views.Quotes.QuoteView model: quote
    formView  = new Lt.Views.Quotes.EditView  model: quote
    $li = $('<li/>', 'id': 'quote-' + quote.cid)
      .append(quoteView.render().el, formView.render().el)
    @$("ul.quotes").append($li)
    @toggleEditQuote($li, quote.isNew())

    return

  destroy: (quote) ->
    @$('#quote-' + quote.cid).remove()

  events:
    'editQuote'      : 'editOrCloseQuote'
    'closeEditQuote' : 'editOrCloseQuote'
    'click .new'     : 'newQuote'

  editOrCloseQuote: (ev, quoteCid) ->
    @toggleEditQuote(@$('#quote-' + quoteCid), ev.type == 'editQuote')

  toggleEditQuote: ($li, edit) ->
    $li.children('.quote').toggle(!edit)
    $form = $li.children('.quote-form')
    $form.toggle(edit)
    $form.trigger('focus') if edit

  newQuote: (ev) ->
    ev.preventDefault()

    newQuote = new Lt.Models.Quote()
    @collection.add newQuote

    return

  render: =>
    @$el.html @template()
    @reset(@collection)

    return this
