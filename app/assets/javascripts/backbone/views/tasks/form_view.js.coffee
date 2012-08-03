Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.FormView extends Backbone.View
  template  : JST['backbone/templates/tasks/form']

  tagName   : 'div'
  className : 'form'

  events:
    'submit form': (ev) -> ev.preventDefault(); @save()

  initialize: ->
    @model.bind 'change', @change, @


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

  change: ->
    for input in @$(':input')
      $input = $(input)
      $input.attr value: @model.get($input.attr('name'))

  render : ->
    data =
      form: if @model.isNew() then 'new-task' else 'update-task'
      showActionControl: @model.isNew()

    $(@el).html @template(data)
    @change()
    return this
