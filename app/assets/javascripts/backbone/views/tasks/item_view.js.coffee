Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.ItemView extends Backbone.View
  itemTemplate    : JST['backbone/templates/tasks/item']
  newFormTemplate : JST['backbone/templates/tasks/new_form']

  events:
    'click [control=select]'       : -> @select(on);     false
    'click [control=deselect]'     : -> @select(off);    false
    'click [control=toggle-select]': -> @toggleSelect(); false
    'submit form': (ev) -> ev.preventDefault(); @save()
    'click [control=delete]': (ev) -> @delete(); false

  initialize: ->
    @model.bind 'change', @render, @
    @model.bind 'changeState', @updateState, @

  edit: (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    $(@el).trigger('editItem', [@model.cid])
    return

  delete: ->
    @model.destroy()

  save: ->
    attrs = {}
    for {name: name, value: value} in @$('form').serializeArray()
      attrs[name] = value
    @model.save(attrs)
    return this

  isSelected: -> @selected ?= no

  toggleSelect: ->
    @select(not @isSelected())

  select: (state) ->
    @$el.toggleClass('selected', state)
    @$('[control=select],[control=deselect]')
      .attr control: if state then 'deselect' else 'select'
    @$('.additional-controls').toggle(state)
    @selected = state

    return this


  updateState: ->
    @$el.attr 'record-id': @model.id, 'record-state': @model.getState()

  render: ->
    @updateState()

    if @model.isNew()
      $(@el).html @newFormTemplate(@model.toJSON())
    else
      $(@el).html @itemTemplate(@model.toJSON())


    @select(@isSelected())
    $(@el).toggleClass('completed', @model.isCompleted())
    return this
