Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.IndexView extends Backbone.View
  template: JST["backbone/templates/tasks/index"]

  initialize: () ->
    @collection.bind 'reset'   , @reset, @
    @collection.bind 'add'     , @add, @
    @collection.bind 'destroy' , @destroy, @

  reset: () ->
    @add task for task in @collection.models
    return

  add: (task) ->
    formView = new Lt.Views.Tasks.EditView({model : task})
    taskView = new Lt.Views.Tasks.TaskView({model : task})
    $li = $('<li/>', 'id': 'task-' + task.cid)
      .append(taskView.render().el)
      .append(formView.render().el)
      .append($('<ul/>', class: 'subtasks'))

    parentTask = @collection.get task.get('parent_id')
    $ul = if parentTask?
      @$('#task-' + parentTask.cid).children('ul.subtasks')
    else
      @$('ul.tasks')

    $ul.append($li)
    @toggleEditTask($li, task.isNew())

  destroy: (task) ->
    @$('#task-' + task.cid).remove()


  events:
    'editTask'      : 'editOrCloseTask'
    'closeEditTask' : 'editOrCloseTask'
    'newSubtask'    : 'newSubtask'
    'click .new'    : 'newTask'

  newTask: (ev) ->
    ev.preventDefault()

    newTask = new Lt.Models.Task()
    @collection.add(newTask)

    return

  newSubtask: (ev, taskCid) ->
    ev.preventDefault()

    parentTask = @collection.getByCid taskCid
    return if not parentTask? or parentTask.isNew()
    newSubtask = new Lt.Models.Task(parent_id: parentTask.id)
    @collection.add(newSubtask)

    return

  editOrCloseTask: (ev, taskCid) ->
    @toggleEditTask(@$('#task-' + taskCid), ev.type == 'editTask')

  toggleEditTask: ($li, edit) ->
    $li.children('.task').toggle(!edit)
    $form = $li.children('.task-form')
    $form.toggle(edit)
    $form.trigger('focus') if edit

  render: ->
    $(@el).html(@template(tasks: @collection.toJSON() ))
    @reset()

    return this
