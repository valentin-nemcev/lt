class Lt.Models.TaskEvent extends Backbone.Model
  getPositionString: ->
    date = Date.parse(@get('date'))
    type = @typePriority + @type
    date + ' ' + type

  apply: ->

# TODO: Add unified event date
class Lt.Models.TaskCreation extends Lt.Models.TaskEvent
  type: 'task_creation'
  typePriority: 1

  apply: (tasks) ->
    tasks.add(id: @get('task_id'), type: @get('task_type'))

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

    supertask.addSubtask subtask.id
    subtask.addSupertask supertask.id

class Lt.TaskEvents extends Backbone.Collection
  url: '/tasks'

  initialize: (models = [], params = {}) ->
    {tasks: @tasks} = params
    @on 'reset', @resetTasks, @

  comparator: (event) -> event.getPositionString()

  parse: (events) =>
    creations = for creation in events.task_creations ? []
      new Lt.Models.TaskCreation(creation)

    updates = for update in events.task_updates ? []
      new Lt.Models.TaskUpdate(update)

    additions = for addition in events.relation_additions ? []
      new Lt.Models.RelationAddition(addition)

    return creations.concat(updates).concat(additions)

  resetTasks: ->
    event.apply(@tasks) for event in @models
