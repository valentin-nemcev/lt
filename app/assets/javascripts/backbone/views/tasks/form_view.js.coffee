Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.FormView extends Backbone.View
  template  : JST['backbone/templates/tasks/form']

  tagName   : 'div'
  className : 'form'

  events:
    'submit form'            : -> @save(); false
    'click [control=save]'   : -> @save(); false
    'click [control=cancel]' : -> @cancel(); false

  initialize: ->
    @model.bind 'change'     , @change     , @
    @model.bind 'changeState', @changeState, @

  cancel: ->
    if @model.isNew()
      @model.destroy()
    else
      @trigger 'close'
      @change()

    return

  save: ->
    attrs = {}
    for {name: name, value: value} in @$('form').serializeArray()
      attrs[name] = value
    @model.save(attrs)
    @trigger('close')

    return this

  changeState: ->
    isNew = @model.getState() is 'new'
    @$('form').attr form: if isNew then 'new-task' else 'update-task'
    @$('[input=type]').toggle(isNew)

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
