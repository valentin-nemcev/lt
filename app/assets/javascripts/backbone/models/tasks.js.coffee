class Lt.Models.Task extends Backbone.Model

  initialize: (attributes = {}, options = {}) ->
    @on 'change:id', @onChangeId, @
    @onChangeId(this, @id, silent: true)

    @on 'destroy', @onDestroy, @

    @on 'add', @onAdd, @
    @onAdd(this, @collection)

    @_initializeRelatedTasks(attributes)

  parse: (eventsJSON) -> @collection.events.addEvents(eventsJSON, this); {}

  getState: ->
    @state

  onAdd: (model, collection, options = {}) ->

  onDestroy: (model, collection, options = {}) ->
    @setState 'deleted', options

  onChangeId: (model, value, options = {})->
    state = if @id then 'persisted' else 'new'
    @setState state, options

  setState: (state, options = {}) ->
    @state = state
    @trigger 'changeState', this, state, options

  isValidNextState: (state) -> yes

  _initializeRelatedTasks: (attributes) ->
    @set
      supertaskIds: []
      subtaskIds:   []

    @subtaskCollection   = new Lt.Collections.RelatedTasks
    @supertaskCollection = new Lt.Collections.RelatedTasks

  newSubtask: (attributes = {}, options = {})->
    options.collection ?= @collection
    subtask = new @collection.model attributes, options
    subtask.addSupertask this
    this.addSubtask subtask
    @collection.add(subtask)
    subtask

  addSupertask: (tasks...) -> @_addRelated('supertask', tasks)
  addSubtask:   (tasks...) -> @_addRelated('subtask'  , tasks)

  _addRelated: (field, tasks) ->
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

