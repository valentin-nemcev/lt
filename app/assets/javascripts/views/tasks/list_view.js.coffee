Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Backbone.View

  tagName: 'ul'
  className: 'tasks'

  initialize: ->
    @collection.bind 'reset'   , @reset,   @
    @collection.bind 'add'     , @add,     @
    @collection.bind 'remove'  , @remove,  @
    @collection.bind 'destroy' , @destroy,  @

    @itemViews = {}

  updateEmptyItem: ->
    return unless @$emptyItem?
    if @collection.length == 0
      @$emptyItem.appendTo(@$el)
    else
      @$emptyItem.detach()

  reset: ->
    @remove cid for cid of @itemViews
    @add model for model in @collection.models
    @updateEmptyItem()
    return

  add: (model, collection = null, options = {}) ->
    cid = model.cid
    @itemViews[cid] ?= new Views.ItemView(
      model: model
      tagName: 'li'
      attributes:
        record: 'task'
      id: 'task' + '-' + model.cid
    ).render()

    $el = @itemViews[cid].$el
    index = options.index
    if index == 0
      $el.prependTo @$el
    else if index > 0
      $beforeIndex = @$el.children().eq index - 1
      $el.insertAfter $beforeIndex
    else
      $el.appendTo @$el

    @updateEmptyItem()

    return

  remove: (model) ->
    cid = model.cid ? model
    @itemViews[cid].$el.detach()
    @updateEmptyItem()

  destroy: (model) ->
    cid = model.cid ? model
    @itemViews[cid].$el.remove()
    delete @itemViews[cid]

  render: (opts = {})->
    if $emptyItem = opts.$emptyItem
      @$emptyItem = $('<li/>', class: 'empty').append($emptyItem.contents())
    @reset(@collection)

    return this
