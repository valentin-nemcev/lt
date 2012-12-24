Views = Lt.Views.Tasks ||= {}

class Views.MainView extends Backbone.View

  template: JST['templates/tasks/main']

  initialize: ->
    @collection.bind 'destroy' , @destroy, @

    rootTasks = @collection.getRootTasksFor 'composition'
    @allItemViews = {}

    @listView = new Views.ListView
      collection: rootTasks
      allItemViews: @allItemViews
      attributes:
        records: 'root-tasks'

  destroy: (model) ->
    cid = model.cid ? model
    delete @allItemViews[cid]

  events: ->
    'click [control=new]' : -> @newTask(); false

  newTask: ->
    @collection.add()

  render: ->
    @$el.html @template(this)

    @listView.render($emptyItem: @$('.empty').detach()).$el.appendTo @$el

    return this
