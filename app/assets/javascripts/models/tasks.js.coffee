class Lt.Models.Task extends Backbone.Model
  @comparator: (task) -> task.getSortRank()

  initialize: (attributes = {}, options = {}) ->
    @on 'destroy', @onDestroy, @

    @on 'add', @onAdd, @
    @onAdd(this, @collection)

    @_initializeRelatedTasks(attributes)

  parse: (eventsJSON) -> @collection.events.addEvents(eventsJSON, this); {}

  onAdd: (model, collection, options = {}) ->

  isValidNextState: (state) -> yes

  states = ['underway', 'considered', 'completed', 'canceled']
  stateRanks = {}
  stateRanks[rank] = state for rank, state in states

  types = ['action', 'project']
  typeRanks = {}
  typeRanks[rank] = type for rank, type in types

  getSortRank: -> [!@isNew(), stateRanks[@get('state')], typeRanks[@get('type')]]


  getType: ->
    if @get('subtasks_composition')?.length
      'project'
    else
      'action'

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
    return if newProject is currentProject
    @removeSupertask('composition', currentProject)
    @addSupertask('composition', newProject) if newProject


  _initializeRelatedTasks: (attributes) ->
    @_supertasks = {}
    @_subtasks   = {}
    @addSupertask(type, tasks...) for type, tasks of attributes.supertasks ? {}
    @addSubtask(type, tasks...)   for type, tasks of attributes.subtasks   ? {}
    @unset 'supertasks'
    @unset 'subtasks'

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
    collections[type] ?= @_createRelated(field, type)

  _createRelated: (field, type) ->
    related = new Lt.Collections.RelatedTasks
    related.on 'add'   , => @_updateRelatedIds(field, type, related)
    related.on 'remove', => @_updateRelatedIds(field, type, related)
    related.on 'reset' , => @_updateRelatedIds(field, type, related)

  _addRelated: (field, type, tasks) ->
    collection = @_getRelated(field, type)
    collection.add tasks
    this

  _removeRelated: (field, type, tasks) ->
    collection = @_getRelated(field, type)
    collection.remove tasks
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

class Lt.Collections.RelatedTasks extends Backbone.Collection
  model: Lt.Models.Task
  comparator:  Lt.Models.Task.comparator

  initialize: ->
    @on 'change:state', => @sort()

