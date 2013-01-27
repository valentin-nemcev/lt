class Lt.Models.TaskEvent extends Backbone.Model
  getPositionString: ->
    date = Date.parse(@get('date'))
    type = @typePriority + @type
    date + ' ' + type

  apply: ->

class Lt.Models.TaskCreation extends Lt.Models.TaskEvent
  type: 'task_creation'
  typePriority: 1

  initialize: (attributes, options = {}) ->
    @updatedTask = options.updatedTask

  apply: (tasks) ->
    attrs = id: @get('task_id')
    task = tasks.get @updatedTask
    if task
      task.set(attrs)
    else
      tasks.add(attrs)

class Lt.Models.TaskUpdate extends Lt.Models.TaskEvent
  type: 'task_update'
  typePriority: 2

  apply: (tasks) ->
    task = tasks.get(@get('task_id'))
    task or throw "No creation event for task " + @get('task_id')
    task.set(@get('attribute_name'), @get('updated_value'))

class Lt.Models.RelationAddition extends Lt.Models.TaskEvent
  type: 'relation_addition'

  apply: (tasks) ->
    supertask = tasks.get(@get('supertask_id'))
    subtask   = tasks.get(@get('subtask_id'))
    type = @get('relation_type')

    supertask.addSubtask type, subtask
    subtask.addSupertask type, supertask

class Lt.Models.RelationRemoval extends Lt.Models.TaskEvent
  type: 'relation_removal'

  apply: (tasks) ->
    supertask = tasks.get(@get('supertask_id'))
    subtask   = tasks.get(@get('subtask_id'))
    type = @get('relation_type')

    supertask.removeSubtask type, subtask
    subtask.removeSupertask type, supertask

class Lt.TaskEvents extends Backbone.Collection
  url: '/tasks'

  initialize: (models = [], params = {}) ->
    {tasks: @tasks} = params
    @on 'reset', @resetTasks, @
    @on 'add', @applyEvent, @

  comparator: (event) -> event.getPositionString()

  addEvents: (eventsJSON, updatedTask) -> @add @parse(eventsJSON, updatedTask)

  applyEvent: (event) -> event.apply @tasks

  classes = _.chain(Lt.Models).pick(
    'TaskCreation', 'TaskUpdate', 'RelationAddition', 'RelationRemoval'
  ).values().value()
  eventClasses = {}
  eventClasses[cls.prototype.type] = cls for cls in classes

  parse: (eventsJSON, updatedTask = null) ->
    updatedTask = null unless updatedTask?.cid?
    for event in eventsJSON.events ? []
      new eventClasses[event.type](event, updatedTask: updatedTask)

  resetTasks: ->
    @applyEvent(event) for event in @models

