Views = Lt.Views.List ||= {}

class Views.ListView extends Backbone.View
  Views: Views

  initialize: () ->
    @itemName  = @collection.model.name.toLowerCase()
    @itemsName = @itemName + 's' # TODO: Install underscore-string

    @sortable = @collection.sortable

    @template = JST["backbone/templates/#{@itemsName}/list"]

    @collection.bind 'reset'   , @reset,   @
    @collection.bind 'add'     , @add,     @
    @collection.bind 'destroy' , @destroy, @

  reset: (collection) ->
    @add model for model in collection.models
    return

  add: (model) ->
    $li = @buildItem model

    $ul = @getParentList(model.getParent() if @sortable)
    $ul.append($li)
    @editItem($li, model.isNew())

    return

  destroy: (model) ->
    @getItem(model).remove()


  getItem: (model) -> @$('#' + @itemName + '-' + (model.cid ? model))

  getModel: ($item) ->
    modelCidRegExp = new RegExp "#{@itemName}-(.*)"
    $item.attr('id').match(modelCidRegExp)[1]

  buildItem: (model) ->
    itemView = new @Views.ItemView model: model
    formView = new @Views.FormView model: model
    $('<li/>', 'id': @itemName + '-' + model.cid)
      .append(itemView.render().el, formView.render().el)

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


  events:
    'editItem'      : (ev, model) -> @editItem @getItem(model), on
    'closeEditItem' : (ev, model) -> @editItem @getItem(model), off
    'newModel'      : 'newModel'
    'click .new'    : 'newModel'

  editItem: ($li, edit) ->
    $li.children('.' + @itemName).toggle(!edit)
    $form = $li.children('.' + @itemName + '-form')
    $form.toggle(edit)
    $form.trigger('focus') if edit

  newModel: (ev, parentModelCid) ->
    ev.preventDefault()

    newModel = new @collection.model()
    if @sortable
      @collection.addChild newModel, parentModelCid
    else
      @collection.add newModel

    return


  render: ->
    @$el.html @template()
    @reset(@collection)
    @setupSortable @getParentList() if @sortable

    return this

  setupSortable: ($ul) ->
    $ul.nestedSortable
      listType             : 'ul'
      items                : 'li'
      handle               : 'div.' + @itemName
      toleranceElement     : '> div.' + @itemName
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


