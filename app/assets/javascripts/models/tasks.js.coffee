class Lt.Models.Task extends Backbone.Model
  @comparator: (task) -> [!task.isNew(), task.get('sort_rank')]

  @setupComparator: (collection) ->
    collection.comparator = @comparator
    collection.on 'change:id change:sort_rank', -> @sort()
    # collection.sort()

  initialize: (attributes = {}, options = {}) ->
    @on 'destroy', @onDestroy, @

    @on 'change', => @_isRecent = null

    @_initializeRelatedTasks(attributes)

  parse: (eventsJSON) -> @collection.events.addEvents(eventsJSON, this); {}

  isRecent: ->
    return @_isRecent if @_isRecent?
    ms = new Date() - new Date(@get('last_state_change_date'))
    days = ms / 1000 / 60 / 60 / 24
    done = @get('computed_state') in ['canceled', 'completed']
    @_isRecent = not (done and days > 3)

  isValidNextState: (state) -> yes

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
    newProject = @collection.get(newProject)
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
    related.on 'add remove reset change:id',
      => @_updateRelatedIds(field, type, related)

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
    @rootTasks[relationType] ?= @buildRootTasksFor(relationType)

  buildRootTasksFor: (relationType) ->
    tasks = new Backbone.FilteredCollection this,
      modelFilter: @relationFilterFor(relationType)

    Lt.Models.Task.setupComparator(tasks)
    _.extend(tasks, Lt.Collections.TaskCollection)
    tasks

class Lt.Collections.RelatedTasks extends Backbone.Collection
  model: Lt.Models.Task

  initialize: ->
    Lt.Models.Task.setupComparator(this)
    _.extend(this, Lt.Collections.TaskCollection)

Lt.Collections.TaskCollection =
  getRecent: ->
    if @length > 7
      @filter (task) -> task.isRecent()
    else
      @models
