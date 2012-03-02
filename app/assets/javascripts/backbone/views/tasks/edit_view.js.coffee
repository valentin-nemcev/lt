Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.EditView extends Backbone.View
  template  : JST['backbone/templates/tasks/edit']

  tagName   : 'div'
  className : 'task-form'

  events:
    'submit form'        : 'update'
    'click .new-subtask' : 'newSubtask'
    'click .delete'      : 'delete'
    'click .cancel'      : 'cancel'
    'focus'              : 'focus'

  initialize: ->
    @model.bind 'change', @render, @

  newSubtask: (ev) ->
    ev.preventDefault()
    @triggerDomEv 'newSubtask'
    @triggerDomEv 'closeEditTask'
    return

  delete: (ev) ->
    ev.preventDefault()
    @model.destroy()
    return

  cancel: (ev) ->
    ev.preventDefault()
    if @model.isNew()
      @delete(ev)
    else
      @triggerDomEv 'closeEditTask'
      @render()

    return

  update: (ev) ->
    ev.preventDefault()

    attrs =
      body: @$('[name="body"]').val()
      done: @$('[name="done"]').is(':checked')
      deadline: @$('[name="deadline"]').val()

    @model.save attrs, success: (task) => @triggerDomEv 'closeEditTask'

    return

  focus: (ev) ->
    @$('[name="body"]').focus()
    return

  triggerDomEv: (evName) -> $(@el).trigger(evName, [@model.cid])

  render : ->
    $(@el).html @template(@model)
    return this
