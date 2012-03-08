Lt.Views.Quotes ||= {}

class Lt.Views.Quotes.FormView extends Backbone.View
  template  : JST['backbone/templates/quotes/form']

  tagName   : 'div'
  className : 'quote-form'

  events:
    'submit form'   : 'update'
    'click .delete' : 'delete'
    'click .cancel' : 'cancel'
    'focus'         : 'focus'

  initialize: ->
    @model.bind 'change', @render, @

  delete: (ev) ->
    ev.preventDefault()
    @model.destroy()
    return

  cancel: (ev) ->
    ev.preventDefault()
    if @model.isNew()
      @delete(ev)
    else
      @triggerDomEv 'closeEditItem'
      @render()

    return

  update: (ev) ->
    ev.preventDefault()

    attrs =
      content: @$('[name="content"]').val()
      source:  @$('[name="source"]').val()

    @model.save attrs, success: (quote) => @triggerDomEv 'closeEditItem'

    return

  focus: (ev) ->
    @$('[name="content"]').focus()
    return

  triggerDomEv: (evName) -> $(@el).trigger(evName, [@model.cid])

  render: ->
    $(@el).html @template(@model)
    return this
