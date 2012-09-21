class Lt.Models.Task extends Backbone.Model
  initialize: ->
    @on 'change:id', @onChangeId, @
    @onChangeId(this, @id, silent: true)

    @on 'destroy', @onDestroy, @

    @on 'add', @onAdd, @
    @onAdd(this, @collection)

  getState: ->
    @state

  onAdd: (model, collection, options = {}) ->
    return unless collection?
    model.subtasksCollection ?=
      new Lt.Collections.Subtasks collection, project: model

  onDestroy: (model, collection, options = {}) ->
    @setState 'deleted', options

  onChangeId: (model, value, options = {})->
    state = if @id then 'persisted' else 'new'
    @setState state, options

  setState: (state, options = {}) ->
    @state = state
    @trigger 'changeState', this, state, options

  isValidNextState: (state) -> yes

class Lt.Collections.Tasks extends Backbone.Collection
  url: '/tasks'
  model: Lt.Models.Task
