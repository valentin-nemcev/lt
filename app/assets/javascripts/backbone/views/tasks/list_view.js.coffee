Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Backbone.View

  tagName: 'ul'
  className: 'tasks'

  initialize: ->
    @collection.bind 'reset'  , @reset,   @
    @collection.bind 'add'    , @add,     @
    @collection.bind 'remove' , @remove,  @

    @items = {}

  updateEmptyItem: ->
    return unless @$emptyItem?
    if @collection.length == 0
      @$emptyItem.appendTo(@$el)
    else
      @$emptyItem.detach()

  reset: ->
    @remove cid for cid of @items
    @add model for model in @collection.models
    @updateEmptyItem()
    return

  add: (model) ->
    itemView = new Views.ItemView
      model: model
      tagName: 'li'
      attributes:
        record: 'task'
      id: 'task' + '-' + model.cid

    itemView.render().$el.appendTo(@$el)
    @items[model.cid] = itemView
    @updateEmptyItem()

    return

  remove: (model) ->
    cid = model.cid ? model
    @items[cid].$el.remove()
    @updateEmptyItem()


  render: (opts = {})->
    if $emptyItem = opts.$emptyItem
      @$emptyItem = $('<li/>', class: 'empty').append($emptyItem.contents())
    @reset(@collection)

    return this
