Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.TaskView extends Backbone.View
  template: JST["backbone/templates/tasks/task"]

  events:
    "dblclick" : "edit"

  tagName: "div"
  className: 'task'

  initialize: ->
    @model.bind 'change', @render, @

  edit: (ev) ->
    ev.preventDefault()
    $(@el).trigger('editTask', [@model])
    return

  render: ->
    $(@el).html(@template(@model.toJSON() ))
    return this
