Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.TaskView extends Backbone.View
  template: JST["backbone/templates/tasks/task"]

  events:
    "click .edit" : "edit"
    "click .delete" : "delete"

  tagName: "div"
  className: 'task'

  initialize: ->
    @model.bind 'change', @render, @

  edit: (ev) ->
    ev.preventDefault()
    $(@el).trigger('editTask', [@model])

  delete: (ev) ->
    ev.preventDefault()
    @model.destroy()

  render: ->
    $(@el).html(@template(@model.toJSON() ))
    return this
