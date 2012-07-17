Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.FormView extends Backbone.View
  template  : JST['backbone/templates/tasks/form']

  tagName   : 'div'
  className : 'task-form'

  events:
    'submit form'          : 'update'
    'click .new-subtask'   : 'newSubtask'
    'click .delete'        : 'delete'
    'click .cancel'        : 'cancel'
    'click .complete'      : (ev) -> ev.preventDefault(); @action 'complete'
    'click .undo-complete' : (ev) -> ev.preventDefault(); @action 'undoComplete'
    'focus'                : 'focus'

  initialize: ->
    @model.bind 'change', @render, @

  newSubtask: (ev) ->
    ev.preventDefault()
    @triggerDomEv 'newModel'
    @triggerDomEv 'closeEditItem'
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
      @triggerDomEv 'closeEditItem'
      @render()

    return

  update: (ev) ->
    ev.preventDefault()

    attrs =
      objective: @$('[name="objective"]').val()

    @model.save attrs, success: (task) => @triggerDomEv 'closeEditItem'

    return

  action: (action) ->
    @model[action] success: (task) => @triggerDomEv 'closeEditItem'

  focus: (ev) ->
    @$('[name="objective"]').focus()
    return

  triggerDomEv: (evName) -> $(@el).trigger(evName, [@model.cid])

  render : ->
    $(@el).html @template(@model)
    return this
