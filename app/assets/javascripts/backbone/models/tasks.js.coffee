class Lt.Models.Task extends Backbone.Model
  @comparator: (task) -> task.getSortRank()

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

  states = ['underway', 'considered', 'completed', 'canceled']
  stateRanks = {}
  stateRanks[rank] = state for rank, state in states

  types = ['action', 'project']
  typeRanks = {}
  typeRanks[rank] = type for rank, type in types

  getSortRank: -> [stateRanks[@get('state')], typeRanks[@get('type')]]

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

  setCurrentProject: (newProject) ->
    projects = @getSupertasks('composition')
    newProject = @collection.getByCid(newProject)
    currentProject = projects.at(0)
    console.log currentProject, newProject
    return if newProject is currentProject
    @removeSupertask('composition', currentProject)
    @addSupertask('composition', newProject) if newProject


  _initializeRelatedTasks: (attributes) ->
    @_supertasks = {}
    @_subtasks   = {}
    @addSupertask(type, tasks...) for type, tasks of attributes.supertasks ? {}
    @addSubtask(type, tasks...)   for type, tasks of attributes.subtasks   ? {}

  newSubtask: (type, attributes = {}, options = {})->
    attributes.supertasks ?= {}
    attributes.supertasks[type] = [this]
    subtask = new @collection.model attributes, options
    @collection.add(subtask)
    this.addSubtask type, subtask
    subtask

  addSupertask: (type, tasks...) -> @_addRelated('supertasks', type, tasks)
  addSubtask:   (type, tasks...) -> @_addRelated('subtasks'  , type, tasks)

  removeSupertask: (type, tasks...) -> @_removeRelated('supertasks', type, tasks)
  removeSubtask:   (type, tasks...) -> @_removeRelated('subtasks'  , type, tasks)

  getSupertasks: (type) -> @_getRelated('supertasks', type)
  getSubtasks:   (type) -> @_getRelated('subtasks'  , type)

  _getRelated: (field, type) ->
    collections = @['_' + field]
    collections[type] ?= new Lt.Collections.RelatedTasks

  _addRelated: (field, type, tasks) ->
    collection = @_getRelated(field, type)
    collection.add tasks
    @_updateRelatedIds field, type, collection
    this

  _removeRelated: (field, type, tasks) ->
    collection = @_getRelated(field, type)
    collection.remove tasks
    @_updateRelatedIds field, type, collection
    this

  _updateRelatedIds: (field, type, collection) ->
    @set "#{field}_#{type}", collection.pluck('id')

class Lt.Collections.Tasks extends Backbone.Collection
  url: '/tasks'
  model: Lt.Models.Task
  comparator: Lt.Models.Task.comparator

  initialize: ->
    @rootTasks = {}

  relationFilterFor: (relationType) ->
    (task) -> task.getSupertasks(relationType).length == 0

  getRootTasksFor: (relationType) ->
    @rootTasks[relationType] ?= new Backbone.FilteredCollection this,
      modelFilter: @relationFilterFor(relationType)
      comparator: Lt.Models.Task.comparator

  getProjects: ->
    @projects ?= new Backbone.FilteredCollection this,
      modelFilter: (task) -> task.get('type') is 'project'
      comparator: (task) -> task.get('objective')

class Lt.Collections.RelatedTasks extends Backbone.Collection
  model: Lt.Models.Task
  comparator:  Lt.Models.Task.comparator

  initialize: ->
    @on 'change:state', => @sort()

