class Lt.Models.Task extends Backbone.Model
  paramRoot: 'task'

  defaults:
    body: null

  getParent: ->
    @collection.get @get('parent_id')

class Lt.Collections.TasksCollection extends Backbone.Collection
  model: Lt.Models.Task
  url: '/tasks'

  sortable: yes

  addChild: (model, parent) ->
    if parent = @getByCid parent
      return false if parent?.isNew()
      model.set parent_id: parent.id
    return @add model

  move: (model, position) ->
    model = @getByCid model
    position.of = @getByCid(position.of)?.id
    model.save position: position
