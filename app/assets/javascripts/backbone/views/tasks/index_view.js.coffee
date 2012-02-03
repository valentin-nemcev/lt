Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.IndexView extends Backbone.View
  template: JST["backbone/templates/tasks/index"]

  events:
    'editTask li' : 'editTask'
    'closeEditTask li' : 'closeEditTask'

  initialize: () ->
    @options.tasks.bind('reset', @addAll)

  editTask: (ev, task) ->
    $('.task', ev.currentTarget).hide()
    $('.task-form', ev.currentTarget).show()

  closeEditTask: (ev, task) ->
    $('.task', ev.currentTarget).show()
    $('.task-form', ev.currentTarget).hide()

  addAll: () =>
    @options.tasks.each(@addOne)

  addOne: (task) =>
    formView = new Lt.Views.Tasks.EditView({model : task})
    taskView = new Lt.Views.Tasks.TaskView({model : task})
    $li = $('<li/>')
      .append(taskView.render().el)
      .append($(formView.render().el).hide())
    $(@el).append($li)

  render: =>
    $(@el).html(@template(tasks: @options.tasks.toJSON() ))
    @addAll()

    return this
