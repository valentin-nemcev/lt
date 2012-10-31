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

  collectionsToIds = (collections) ->
    ids = {}
    for type, collection of collections
      ids["#{field}_#{type}"] = collection.pluck('id')
    ids

  # TODO: Maybe use https://github.com/powmedia/backbone-deep-model
  toJSON: ->
    attrs = super
    for field in ['supertask', 'subtask']
      attrs["#{field}_ids"] = {}
      collections = @["_#{field}s"]
      for type, collection of collections
        ids = attrs["#{field}s_#{type}"]
        attrs["#{field}_ids"][type] = ids if ids?
        delete attrs["#{field}s_#{type}"]

    attrs

  _initializeRelatedTasks: (attributes) ->
    @_supertasks = {}
    @_subtasks   = {}

  newSubtask: (type, attributes = {}, options = {})->
    options.collection ?= @collection
    subtask = new @collection.model attributes, options
    subtask.addSupertask type, this
    this.addSubtask type, subtask
    @collection.add(subtask)
    subtask

  addSupertask: (type, tasks...) -> @_addRelated('supertasks', type, tasks)
  addSubtask:   (type, tasks...) -> @_addRelated('subtasks'  , type, tasks)

  getSupertasks: (type) -> @_getRelated('supertasks', type)
  getSubtasks:   (type) -> @_getRelated('subtasks'  , type)

  _getRelated: (field, type) ->
    collections = @['_' + field]
    collections[type] ?= new Lt.Collections.RelatedTasks

  _addRelated: (field, type, tasks) ->
    collection = @_getRelated(field, type)
    collection.add tasks
    @set "#{field}_#{type}", collection.pluck('id')
    this

class Lt.Collections.Tasks extends Backbone.Collection
  url: '/tasks'
  model: Lt.Models.Task

  initialize: ->
    @rootTasks = {}

  relationFilterFor: (relationType) ->
    (task) -> task.getSupertasks(relationType).length == 0

  getRootTasksFor: (relationType) ->
    @rootTasks[relationType] ?= new Backbone.FilteredCollection this,
      modelFilter: @relationFilterFor(relationType)

class Lt.Collections.RelatedTasks extends Backbone.Collection
  model: Lt.Models.Task

