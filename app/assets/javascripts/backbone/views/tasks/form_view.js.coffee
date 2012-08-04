Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.FormView extends Backbone.View
  template  : JST['backbone/templates/tasks/form']

  tagName   : 'div'
  className : 'form'

  events:
    'submit form': -> @save(); false

  initialize: ->
    @model.bind 'change', @change, @
    @model.bind 'changeState', @changeState, @

  cancel: (ev) ->
    ev.preventDefault()
    if @model.isNew()
      @delete(ev)
    else
      @triggerDomEv 'closeEditItem'
      @render()

    return

  save: ->
    attrs = {}
    for {name: name, value: value} in @$('form').serializeArray()
      attrs[name] = value
    @model.save(attrs)
    @trigger('close')

    return this

  focus: (ev) ->
    @$('[name="objective"]').focus()
    return

  changeState: ->
    isNew = @model.getState() is 'new'
    @$('form').attr form: if isNew then 'new-task' else 'update-task'
    @$('.action-input').toggle(isNew)

    return this

  change: ->
    for input in @$(':input')
      $input = $(input)
      name = $input.attr('name')
      $input.val @model.get(name) if @model.has(name)

    return this

  render : ->
    $(@el).html @template()
    @change()
    @changeState()

    return this
