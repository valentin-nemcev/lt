Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Backbone.View

  tagName: 'ul'
  className: 'tasks'

  initialize: ->
    @collection.bind 'reset'   , @reset   , @
    @collection.bind 'sort'    , @sort    , @
    @collection.bind 'add'     , @add     , @
    @collection.bind 'remove'  , @remove  , @
    @collection.bind 'destroy' , @destroy , @

    @allItemViews = @options.allItemViews
    @itemViews = {}

  updateEmptyItem: ->
    return unless @$emptyItem?
    if @collection.length == 0
      @$emptyItem.appendTo(@$el)
    else
      @$emptyItem.detach()

  reset: ->
    @remove cid for cid of @itemViews
    @add model, @collection, {}, -1 for model in @collection.models
    @updateEmptyItem()
    return

  sort: ->
    @add model, @collection, {}, index for model, index in @collection.models
    return

  add: (model, collection = null, options = {}, index) ->
    cid = model.cid
    @allItemViews[cid] ?= new Views.ItemView(
      model: model
      allItemViews: @allItemViews
      tagName: 'li'
      attributes:
        record: 'task'
      id: 'task' + '-' + model.cid
    ).render()

    @itemViews[cid] = @allItemViews[cid]
    $el = @itemViews[cid].$el.detach()
    index ?= collection.indexOf(model)
    if 0 <= index < collection.length - 1
      $elAtIndex = @$el.children().eq index
      $el.insertBefore $elAtIndex
    else
      $el.appendTo @$el

    @updateEmptyItem()

    return

  remove: (model) ->
    cid = model.cid ? model
    $el = @itemViews[cid].$el
    $el.detach() if $el.parent() is @el
    @updateEmptyItem()

  destroy: (model) ->
    cid = model.cid ? model
    @itemViews[cid].$el.remove()
    delete @itemViews[cid]
    @updateEmptyItem()

  render: (opts = {})->
    if $emptyItem = opts.$emptyItem
      @$emptyItem = $('<li/>', class: 'empty').append($emptyItem.contents())
    @reset(@collection)

    return this
