Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.EditView extends Backbone.View
  template : JST["backbone/templates/tasks/edit"]

  tagName: 'div'
  className: 'task-form'

  events:
    "submit form"        : "update"
    "click .new-subtask" : "newSubtask"
    "click .delete"      : "delete"
    "click .cancel"      : "cancel"
    "focus"              : "focus"

  initialize: ->
    @model.bind 'change', @render, @

  newSubtask: (ev) ->
    ev.preventDefault()
    @triggerEv 'newSubtask'
    @triggerEv 'closeEditTask'
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
      @triggerEv 'closeEditTask'
      @render

    return

  update : (ev) ->
    ev.preventDefault()

    attrs = body: @$('[name="body"]').val()
    @model.save(attrs,
      success : (task) =>
        @triggerEv 'closeEditTask'
    )
    return

  focus: (ev) ->
    @$('[name="body"]').focus()
    return

  triggerEv: (evName) -> $(@el).trigger(evName, [@model.cid])

  render : ->
    $(@el).html(@template(@model))
    return this
