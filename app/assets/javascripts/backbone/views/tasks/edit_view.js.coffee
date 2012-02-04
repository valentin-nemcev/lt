Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.EditView extends Backbone.View
  template : JST["backbone/templates/tasks/edit"]

  tagName: 'div'
  className: 'task-form'

  events :
    "submit form" : "update"
    "click .delete" : "delete"
    "click .cancel" : "cancel"
    "focus": "focus"

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
      $(@el).trigger('closeEditTask')
      @render

    return

  update : (ev) ->
    ev.preventDefault()

    attrs = body: @$('[name="body"]').val()
    @model.save(attrs,
      success : (task) =>
        $(@el).trigger('closeEditTask')
    )
    return

  focus: (ev) ->
    @$('[name="body"]').focus()
    return

  render : ->
    $(@el).html(@template(@model))
    return this
