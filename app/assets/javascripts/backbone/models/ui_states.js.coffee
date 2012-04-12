class Lt.Models.TasksListState extends Backbone.Model
  paramRoot: 'state'

  url: -> "ui_states/tasks_list"

  isNew: -> false


  defaults:
    show_completed: no
