Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.IndexView extends Backbone.View
  template: JST["backbone/templates/tasks/index"]

  initialize: () ->
    @options.tasks.bind 'reset'   , @reset, @
    @options.tasks.bind 'add'     , @add, @
    @options.tasks.bind 'destroy' , @destroy, @

  reset: () ->
    @add task for task in @options.tasks.models
    return

  add: (task) ->
    formView = new Lt.Views.Tasks.EditView({model : task})
    taskView = new Lt.Views.Tasks.TaskView({model : task})
    $li = $('<li/>', 'id': 'task-' + task.cid)
      .append(taskView.render().el)
      .append(formView.render().el)
    @toggleEditTask($li[0], task.isNew())
    @$('ul').append($li)

  destroy: (task) ->
    @$('#task-' + task.cid).remove()


  events:
    'editTask      li': 'editTask'
    'closeEditTask li': 'closeEditTask'
    'click .new': 'newTask'

  newTask: (ev) ->
    ev.preventDefault()

    newTask = new Lt.Models.Task()
    @options.tasks.add(newTask)

    return

  editTask:      (ev) -> @toggleEditTask(ev.currentTarget, true)
  closeEditTask: (ev) -> @toggleEditTask(ev.currentTarget, false)

  toggleEditTask: (li, edit) ->
    $('.task', li).toggle(!edit)
    $('.task-form', li).toggle(edit)

  render: ->
    $(@el).html(@template(tasks: @options.tasks.toJSON() ))
    @reset()

    return this
