Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.IndexView extends Backbone.View
  template: JST["backbone/templates/tasks/index"]

  events:
    'editTask      li': 'editTask'
    'closeEditTask li': 'closeEditTask'
    'click .new': 'newTask'

  initialize: () ->
    @options.tasks.bind('reset', @addAll)
    @options.tasks.bind('add', @addOne)

  newTask: (ev) ->
    ev.preventDefault()

    newTask = new Lt.Models.Task()
    @options.tasks.add(newTask)

  editTask:      (ev) -> @toggleEditTask(ev.currentTarget, true)
  closeEditTask: (ev) -> @toggleEditTask(ev.currentTarget, false)

  toggleEditTask: (li, edit) ->
    $('.task', li).toggle(!edit)
    $('.task-form', li).toggle(edit)

  addAll: () =>
    @options.tasks.each(@addOne)

  addOne: (task) =>
    formView = new Lt.Views.Tasks.EditView({model : task})
    taskView = new Lt.Views.Tasks.TaskView({model : task})
    $li = $('<li/>')
      .append(taskView.render().el)
      .append(formView.render().el)
    @toggleEditTask($li[0], task.isNew())
    $(@el).append($li)

  render: =>
    $(@el).html(@template(tasks: @options.tasks.toJSON() ))
    @addAll()

    return this
