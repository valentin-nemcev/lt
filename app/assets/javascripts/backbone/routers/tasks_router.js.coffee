class Lt.Routers.TasksRouter extends Backbone.Router
  initialize: (options) ->
    @tasks = new Lt.Collections.TasksCollection()
    @tasks.reset options.tasks

    @view = new Lt.Views.Tasks.IndexView(tasks: @tasks)
    $("#tasks").html(@view.render().el)

  routes:
    "/new"      : "newTask"
    "/index"    : "index"
    "/:id/edit" : "edit"
    "/:id"      : "show"
    ".*"        : "index"

  newTask: ->
    @view = new Lt.Views.Tasks.NewView(collection: @tasks)
    $("#tasks").html(@view.render().el)

  index: ->

