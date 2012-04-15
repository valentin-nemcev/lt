Lt.Views.ActionableTasks ||= {}

class Lt.Views.ActionableTasks.ItemView extends Backbone.View
  template  : JST['backbone/templates/tasks/item']

  tagName   : 'div'
  className : 'task'

  events:
    'dblclick' : 'edit'

  initialize: ->
    @model.bind 'change', @render, @

  edit: (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    $(@el).trigger('editItem', [@model.cid])
    return

  render: ->
    $(@el).html @template(@model.toJSON())
    $(@el).toggleClass('completed', @model.isCompleted())
    return this
