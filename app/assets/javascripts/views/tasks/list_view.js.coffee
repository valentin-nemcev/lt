Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Backbone.View

  tagName: 'ul'
  className: 'tasks'

  initialize: ->
    @collection.bind 'add', (model) =>
      @detachEmptyItem()
      @add(model, @getModels())

    @collection.bind 'reset'   , @reset   , @
    @collection.bind 'sort'    , @sort    , @
    @collection.bind 'remove'  , @remove  , @

    @collection.bind 'add remove reset', @updateArchivedItem, @

    @allItemViews = @options.allItemViews
    @itemViews = {}

  getModels: ->
    if @archivedToggled
      @collection.models
    else
      @collection.getRecent()

  detachEmptyItem: -> @$emptyItem.detach()

  attachEmptyItem: -> @$emptyItem.appendTo(@$el) if @collection.length == 0

  updateArchivedItem: ->
    archived = @collection.length - @getModels().length
    if archived > 0
      @$archivedItem.prependTo(@$el).find('.count').text(archived)
    else
      @$archivedItem.detach()

  toggleArchived: (toggled = not @archivedToggled) ->
    @archivedToggled = toggled

    @$archivedItem.find('[control=show-archived]').toggle(not toggled)
    @$archivedItem.find('[control=hide-archived]').toggle(toggled)
    @reset()

  reset: ->
    @detachEmptyItem()
    @remove cid for cid of @itemViews
    recent = @getModels()
    @add model, recent, -1 for model in recent
    @attachEmptyItem()
    return

  sort: ->
    recent = @getModels()
    @add model, recent, index for model, index in recent
    return

  add: (model, models, index) ->
    cid = model.cid
    @itemViews[cid] = @allItemViews[cid]

    $el = @itemViews[cid].$el.detach()
    index ?= _(models).indexOf(model)
    if 0 <= index < models.length - 1
      $elAtIndex = @$el.children().not('.archived').eq index
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

    if $archivedItem = opts.$archivedItem
      @$archivedItem = $('<li/>', class: 'archived').append($archivedItem.contents())
      @$archivedItem.on('click', '[control=show-archived]',
        (ev) => ev.preventDefault(); @toggleArchived on )
      @$archivedItem.on('click', '[control=hide-archived]',
        (ev) => ev.preventDefault(); @toggleArchived off )
    else
      @$archivedItem = $()

    @updateArchivedItem()
    @toggleArchived(off)

    return this
