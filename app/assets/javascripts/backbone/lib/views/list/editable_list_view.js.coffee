#= require ./list_view

Lt.Views.List ||= {}

class Lt.Views.List.EditableListView extends Lt.Views.List.ListView

  # buildItem: (model) ->
    # $item = $(super)
    # formView = new @Views.FormView model: model
    # $item.append(formView.render().el)

  # addItem: ($li, model) ->
    # super
    # @editItem($li, model.isNew())

  events: ->
    _.extend super,
      # 'editItem'      : (ev, model) -> @editItem @getItem(model), on
      # 'closeEditItem' : (ev, model) -> @editItem @getItem(model), off
      'newModel'      : 'newModel'
      'click [control=new]'    : 'newModel'


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

