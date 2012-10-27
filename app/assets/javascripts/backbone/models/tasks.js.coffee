class Lt.Models.Task extends Backbone.Model

  initialize: ->
    @on 'change:id', @onChangeId, @
    @onChangeId(this, @id, silent: true)

    @on 'destroy', @onDestroy, @

    @on 'add', @onAdd, @
    @onAdd(this, @collection)

    @_initializeRelatedTasks()

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

  _initializeRelatedTasks: ->
    @set
      supertaskIds: []
      subtaskIds:   []

    @subtaskCollection   = new Lt.Collections.RelatedTasks
    @supertaskCollection = new Lt.Collections.RelatedTasks

  addSupertask: (tasks...) -> @_addRelated('supertask', tasks)
  addSubtask:   (tasks...) -> @_addRelated('subtask'  , tasks)

  _addRelated: (field, tasks) ->
    tasks = _.chain(tasks)
      .map((task) => @collection.get(task))
      .compact()
      .value()

    collection = @[field + 'Collection']
    collection.add tasks
    @set(field + 'Ids', collection.pluck('id'))

class Lt.Collections.Tasks extends Backbone.Collection
  url: '/tasks'
  model: Lt.Models.Task

  initialize: ->
    @rootTasks = new Lt.Collections.RootTasks this

class Lt.Collections.RelatedTasks extends Backbone.Collection
  model: Lt.Models.Task

class Lt.Collections.RootTasks extends Backbone.FilteredCollection
  modelFilter: (task) ->
    not task.get('supertaskIds').length

