class Lt.Models.TaskViewState extends Backbone.Model
  paramRoot: 'state'

  url: -> "ui_states/task_view"

  isNew: -> false


  defaults:
    show_completed: no
    current_tab: 'plan'
