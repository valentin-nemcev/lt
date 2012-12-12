#= require_self
#= require_tree ./lib
#= require_tree ./templates
#= require_tree ./models
#= require_tree ./views
#= require_tree ./routers

window.Lt =
  Models: {}
  Collections: {}
  Routers: {}
  Views: {}

  initTaskView: (selector, tasks, taskViewState) ->
    @tasks = new Lt.Collections.Tasks
    @taskEvents = new Lt.TaskEvents([], tasks: @tasks)
    @tasks.events = @taskEvents

    @taskViewState = new Lt.Models.TaskViewState taskViewState

    @taskEvents.fetch success: =>
      @taskView = new Lt.Views.Tasks.MainView
        collection: @tasks
        state: @taskViewState
        el: $(selector)[0]
      @taskView.render()
