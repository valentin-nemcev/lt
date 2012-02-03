class Lt.Routers.TasksRouter extends Backbone.Router
  initialize: (options) ->
    @tasks = new Lt.Collections.TasksCollection()
    @tasks.reset options.tasks

    @view = new Lt.Views.Tasks.IndexView(tasks: @tasks, el: $('#tasks')[0])
    @view.render()


