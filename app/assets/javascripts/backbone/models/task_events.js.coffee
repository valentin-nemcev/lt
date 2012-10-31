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
    attrs = id: @get('task_id'), type: @get('task_type')
    task = tasks.getByCid @updatedTask
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

class Lt.TaskEvents extends Backbone.Collection
  url: '/tasks'

  initialize: (models = [], params = {}) ->
    {tasks: @tasks} = params
    @on 'reset', @resetTasks, @
    @on 'add', @applyEvent, @

  comparator: (event) -> event.getPositionString()

  addEvents: (eventsJSON, updatedTask) -> @add @parse(eventsJSON, updatedTask)

  applyEvent: (event) -> event.apply @tasks

  parse: (eventsJSON, updatedTask = null) ->
    creations = for creation in eventsJSON.task_creations ? []
      new Lt.Models.TaskCreation(creation, updatedTask: updatedTask)

    updates = for update in eventsJSON.task_updates ? []
      new Lt.Models.TaskUpdate(update)

    additions = for addition in eventsJSON.relation_additions ? []
      new Lt.Models.RelationAddition(addition)

    return creations.concat(updates).concat(additions)

  resetTasks: ->
    @applyEvent(event) for event in @models

