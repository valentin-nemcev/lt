Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Backbone.View

  tagName: 'ul'
  className: 'tasks'

  initialize: ->
    @collection.bind 'add', (model) =>
      @detachEmptyItem()
      @add(model, @collection.models)

    @collection.bind 'reset'   , @reset   , @
    @collection.bind 'sort'    , @sort    , @
    @collection.bind 'remove'  , @remove  , @

    @allItemViews = @options.allItemViews
    @itemViews = {}


  detachEmptyItem: -> @$emptyItem.detach()

  attachEmptyItem: -> @$emptyItem.appendTo(@$el) if @collection.length == 0

  reset: ->
    @detachEmptyItem()
    @remove cid for cid of @itemViews
    @add model, @collection.models, -1 for model in @collection.models
    @attachEmptyItem()
    return

  sort: ->
    @add model, @collection.models, index for model, index in @collection.models
    return

  add: (model, models, index) ->
    cid = model.cid
    @itemViews[cid] = @allItemViews[cid]

    $el = @itemViews[cid].$el.detach()
    index ?= _(models).indexOf(model)
    if 0 <= index < models.length - 1
      $elAtIndex = @$el.children().eq index
      $el.insertBefore $elAtIndex
    else
      $el.appendTo @$el

    return

  remove: (model) ->
    cid = model.cid ? model
    $el = @itemViews[cid].$el
    $el.detach() if $el.parent()[0] is @el
    delete @itemViews[cid]
    @attachEmptyItem()
    return

  render: (opts = {})->
    if $emptyItem = opts.$emptyItem
      @$emptyItem = $('<li/>', class: 'empty').append($emptyItem.contents())
    else
      @$emptyItem = $()

    @reset()

    return this
