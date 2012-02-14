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
    $li = @buildLi task

    parentTask = @collection.get task.get('parent_id')
    $ul = if parentTask?
      @$('#task-' + parentTask.cid).children('ul.subtasks')
    else
      @$('ul.tasks')

    $ul.append($li)
    @toggleEditTask($li, task.isNew())

  destroy: (task) ->
    @$('#task-' + task.cid).remove()

  buildLi: (task) ->
    formView = new Lt.Views.Tasks.EditView({model : task})
    taskView = new Lt.Views.Tasks.TaskView({model : task})
    $('<li/>', 'id': 'task-' + task.cid)
      .append(taskView.render().el, formView.render().el)
      .append($('<ul/>', class: 'subtasks'))


  setupSortable: ($ul) ->
    $ul.nestedSortable
      listType             : 'ul'
      items                : 'li'
      handle               : 'div.task'
      toleranceElement     : '> div.task'
      maxLevels            : 30
      placeholder          : 'sort-placeholder'
      forcePlaceholderSize : true
      tolerance            : 'pointer'

    $ul.bind 'sortupdate', (ev, ui) =>
      $moved = ui.item

      [position, $target] = if ($prev = $moved.prev('li')).length
        ['right', $prev]
      else if ($next = $moved.next('li')).length
        ['left', $next]
      else if ($parent = $moved.parent().closest('li', @el)).length
        ['child', $parent]
      else
        ['root']

      [movedCid, targetCid] = for $li in [$moved, $target]
        $li.attr('id').match(/task-(.*)/)[1]
      @collection.move movedCid, to: position, of: targetCid

    return this


  events:
    'editTask'        : 'editOrCloseTask'
    'closeEditTask'   : 'editOrCloseTask'
    'newSubtask'      : 'newSubtask'
    'click .new'      : 'newTask'

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
    @setupSortable @$('ul.tasks')
    @reset()

    return this
