Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.EditView extends Backbone.View
  template : JST["backbone/templates/tasks/edit"]

  tagName: 'div'
  className: 'task-form'

  events :
    "submit #edit-task" : "update"

  initialize: ->
    @model.bind 'change', @render, @

  update : (e) ->
    e.preventDefault()
    e.stopPropagation()

    attrs = body: @$('[name="body"]').val()
    @model.save(attrs,
      success : (task) =>
        $(@el).trigger('closeEditTask')
    )

  render : ->
    $(@el).html(@template(@model.toJSON()))

    return this
