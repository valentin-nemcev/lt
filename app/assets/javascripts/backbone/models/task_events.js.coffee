class Lt.Models.TaskEvent extends Backbone.Model
  getPositionString: ->
    date = Date.parse(@get('date'))
    type = @typePriority + @type
    date + ' ' + type

# TODO: Add unified event date
class Lt.Models.TaskCreation extends Lt.Models.TaskEvent
  type: 'creation'
  typePriority: 1

  apply: (tasks) ->
    console.log this, tasks
    tasks.add(id: @get('task_id'), type: @get('task_type'))

class Lt.Models.TaskUpdate extends Lt.Models.TaskEvent
  type: 'update'
  typePriority: 2

  apply: (tasks) ->
    console.log this, tasks
    task = tasks.get(@get('task_id'))
    task or throw "No creation event for task " + @get('task_id')
    task.set(@get('attribute_name'), @get('updated_value'))

class Lt.TaskEvents extends Backbone.Collection
  url: '/tasks'

  initialize: (models, params) ->
    {tasks: @tasks} = params
    @on 'reset', @resetTasks, @

  comparator: (event) -> event.getPositionString()

  parse: (events) =>
    creations = for creation in events.task_creations ? []
      new Lt.Models.TaskCreation(creation)

    updates = for update in events.task_updates ? []
      new Lt.Models.TaskUpdate(update)

    return creations.concat updates

  resetTasks: ->
    event.apply(@tasks) for event in @models
