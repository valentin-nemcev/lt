Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.IndexView extends Backbone.View
  template: JST["backbone/templates/tasks/index"]

  initialize: () ->
    @options.tasks.bind('reset', @addAll)

  addAll: () =>
    @options.tasks.each(@addOne)

  addOne: (task) =>
    view = new Lt.Views.Tasks.TaskView({model : task})
    $(@el).append(view.render().el)

  render: =>
    $(@el).html(@template(tasks: @options.tasks.toJSON() ))
    @addAll()

    return this
