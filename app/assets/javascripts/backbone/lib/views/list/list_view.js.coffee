Lt.Views.List ||= {}

class Lt.Views.List.ListView extends Backbone.View

  initialize: () ->
    @itemsName = @itemName + 's' # TODO: Install underscore-string

    @sortable = @collection.sortable

    @template = JST["backbone/templates/#{@itemsName}/list"]

    @collection.bind 'reset'  , @reset,   @
    @collection.bind 'add'    , @add,     @
    @collection.bind 'remove' , @remove,  @

  reset: (collection) ->
    $rootUl = @$('ul.' + @itemsName)
    @$emptyItem ?= $rootUl.children('.empty').detach()
    $rootUl.empty()
    @add model for model in collection.models
    @$emptyItem.appendTo($rootUl) if collection.models.length == 0
    return

  add: (model) ->
    $li = @buildItem model
    @addItem($li, model)

    return

  remove: (model) ->
    @getItem(model).remove()


  getItem: (model) -> @$('#' + @itemName + '-' + (model.cid ? model))

  getModel: ($item) ->
    modelCidRegExp = new RegExp "#{@itemName}-(.*)"
    $item.attr('id').match(modelCidRegExp)[1]

  buildItem: (model) ->
    itemView = new @Views.ItemView 
      model: model
      tagName: 'li'
      attributes: 
        record: @itemName
      id: @itemName + '-' + model.cid
    itemView.render().el

  addItem: ($li, model) ->
    $ul = @getParentList(model.getParent() if @sortable)
    $ul.append($li)

  getParentList: (parentModel) ->
    if parentModel?
      $parentLi = @getItem(parentModel)
      if ($subUl = $parentLi.children('ul.sub' + @itemsName)).length
        $subUl
      else
        # nestedSortable plugin destroys empty uls nested inside lis so we
        # create them only when needed and we better not forget to remove empty
        # uls when reordering list without nestedSortable
        $('<ul/>', class: 'sub' + @itemsName).appendTo($parentLi)
    else
      @$('ul.' + @itemsName)


  events: -> {}


  render: ->
    @$el.html @template(this)
    @reset(@collection)
    @setupSortable @getParentList() if @sortable

    return this

  setupSortable: ($ul) ->
    $ul.nestedSortable
      listType             : 'ul'
      items                : 'li:not(.empty)'
      # handle               : 'div.' + @itemName
      # toleranceElement     : '> div.' + @itemName
      maxLevels            : 30
      placeholder          : 'sort-placeholder'
      forcePlaceholderSize : true
      tolerance            : 'pointer'

    $ul.bind 'sortupdate', (ev, ui) =>
      $moved = ui.item

      [position, $target] = if ($prev = $moved.prev('li')).length
        ['right', $prev]
      else if ($next = $moved.next('li')).length
        ['left', $next]
      else if ($parent = $moved.parent().closest('li', @el)).length
        ['child', $parent]
      else
        ['root']

      [movedCid, targetCid] = (@getModel($li) for $li in [$moved, $target])
      @collection.move movedCid, to: position, of: targetCid

    return this


