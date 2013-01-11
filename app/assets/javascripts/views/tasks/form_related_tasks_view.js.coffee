Views = Lt.Views.Tasks ||= {}

class TaskView extends Backbone.View
  tagName: 'li'

  toggleChange: (toggled = not @changeToggled) ->
    @changeToggled = toggled

    @$change.toggle(not toggled)
    @$cancel.toggle(toggled)

    @$el.toggleClass('changed', toggled)

  render: ->
    $('<span/>',
      field : 'objective',
      text  : @model.get('objective')
    ).appendTo(@$el)

    @$change = $('<button/>',
      class   : 'link'
      control : 'change'
      text    : 'Изменить'
      click   : => @onChange(); false
    ).appendTo(@$el)

    @$cancel = $('<button/>',
      class   : 'link'
      control : 'cancel'
      text    : 'Отменить'
      click   : => @onCancel(); false
    ).appendTo(@$el)

    @$remove = $('<button/>',
      class   : 'link'
      control : 'remove'
      text    : 'Удалить'
      click   : => @onRemove(); false
    ).appendTo(@$el)

    return this

class AddTaskView extends Backbone.View
  tagName: 'li'

  toggleAdd: (toggled = not @addToggled) ->
    @addToggled = toggled

    @$add.toggle(not toggled)
    @$cancel.toggle(toggled)

    @$el.toggleClass('added', toggled)

  render: ->
    @$add = $('<button/>',
      class   : 'link'
      control : 'add'
      text    : 'Добавить'
      click   : => @onAdd(); false
    ).appendTo(@$el)

    @$cancel = $('<button/>',
      class   : 'link'
      control : 'cancel'
      text    : 'Отменить'
      click   : => @onCancel(); false
    ).appendTo(@$el)

    return this


class Lt.Views.Tasks.FormRelatedTasksView extends Backbone.View

  initialize: ->
    @taskViews = {}

  render: ->
    $tasksList = @$('.related-tasks').empty()
    view.remove() for cid, view of @taskViews
    @addTaskView?.remove()

    @taskViews = {}
    for task in @currentTasks
      view = @taskViews[task.cid] = @buildTaskView(task)
      view.$el.appendTo($tasksList)

    @addTaskView = @buildAddTaskView()
    unless @options.singular and @currentTasks.length
      @addTaskView.$el.appendTo($tasksList)

    return this

  buildAddTaskView: ->
    view = new AddTaskView
    view.render()
    view.onAdd = => view.toggleAdd on; @addTask()
    view.onCancel = => @cancelTaskSelection()
    view.toggleAdd off

    return view

  buildTaskView: (task) ->
    view = new TaskView model: task
    view.onChange = => view.toggleChange on; @changeTask(task)
    view.onRemove = => @removeTask(task)
    view.onCancel = => @cancelTaskSelection()
    view.render().toggleChange off

    return view

  addTask: ->
    @options.mainView.selectTask (newTask) =>
      @currentTasks.push newTask
      @render()

    return this

  changeTask: (oldTask) ->
    @options.mainView.selectTask (newTask) =>
      index = _.indexOf(@currentTasks, oldTask)
      @currentTasks[index] = newTask
      @render()

    return this

  removeTask: (task) ->
    index = _.indexOf(@currentTasks, task)
    @currentTasks.splice(index, 1)
    @render()

    return this

  cancelTaskSelection: () ->
    @options.mainView.cancelSelectTask()
    @addTaskView.toggleAdd off
    for cid, view of @taskViews
      view.toggleChange off

    return this
