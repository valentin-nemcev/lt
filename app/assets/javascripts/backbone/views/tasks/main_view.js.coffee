Views = Lt.Views.Tasks ||= {}

class Views.MainView extends Backbone.View

  template: JST['backbone/templates/tasks/main']

  initialize: ->
    @listView = new Views.ListView
      collection: @collection #.rootTasksCollection
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
