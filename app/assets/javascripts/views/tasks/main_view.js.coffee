Views = Lt.Views.Tasks ||= {}

class Views.MainView extends Backbone.View

  template: JST['templates/tasks/main']

  initialize: ->
    rootTasks = @collection.getRootTasksFor 'composition'

    @listView = new Views.ListView
      collection: rootTasks
      attributes:
        records: 'root-tasks'

  events: ->
    'click [control=new]' : -> @newTask(); false

  newTask: ->
    @collection.add()

  render: ->
    @$el.html @template(this)

    @listView.render($emptyItem: @$('.empty').detach()).$el.appendTo @$el

    return this
