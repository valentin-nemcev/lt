Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.TaskView extends Backbone.View
  template  : JST['backbone/templates/tasks/task']

  tagName   : 'div'
  className : 'task'

  events:
    'dblclick' : 'edit'

  initialize: ->
    @model.bind 'change', @render, @

  edit: (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    $(@el).trigger('editTask', [@model.cid])
    return

  render: ->
    $(@el).html @template(@model.toJSON())
    $(@el).toggleClass('done', @model.get('done'))
    return this
