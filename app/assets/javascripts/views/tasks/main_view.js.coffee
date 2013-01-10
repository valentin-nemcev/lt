Views = Lt.Views.Tasks ||= {}

class Views.MainView extends Backbone.View

  template: JST['templates/tasks/main']

  initialize: ->
    @collection.bind 'destroy' , @destroy, @
    @collection.bind 'add'     , @add    , @
    @collection.bind 'reset'   , @reset  , @

    rootTasks = @collection.getRootTasksFor 'composition'
    @allItemViews = {}

    @listView = new Views.ListView
      collection: rootTasks
      allItemViews: @allItemViews
      attributes:
        records: 'root-tasks'

  reset: ->
    views = (@buildView model for model in @collection.models)
    # Build all views before rendering them because task models are not listed
    # in topological order and item views may reference subtask view which
    # doesn't exist yet
    view.render() for view in views
    return

  buildView: (model) ->
    @allItemViews[model.cid] ?= new Views.ItemView(
      model: model
      allItemViews: @allItemViews
      mainView: this
      tagName: 'li'
      attributes:
        record: 'task'
      id: 'task' + '-' + model.cid
    )

  add: (model) -> @buildView(model).render()

  destroy: (model) ->
    cid = model.cid ? model
    @allItemViews[cid].remove()
    delete @allItemViews[cid]
    return

  events: ->
    'click [control=new]' : -> @newTask(); false

  newTask: ->
    @collection.add()

  render: ->
    @$el.html @template(this)

    @reset()
    @listView.render($emptyItem: @$('.empty').detach()).$el.appendTo @$el

    return this


  selectTask: (selected) ->
    for cid, view of @allItemViews
      do (cid) =>
        view.toggleSelectionMode on, =>
          @cancelSelectTask()
          selected(@collection.get(cid))

    return this

  cancelSelectTask: ->
    for cid, view of @allItemViews
      view.toggleSelectionMode off

    return this
