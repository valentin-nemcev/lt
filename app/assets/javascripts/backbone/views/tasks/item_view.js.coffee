Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.ItemView extends Backbone.View
  itemTemplate    : JST['backbone/templates/tasks/item']
  newFormTemplate : JST['backbone/templates/tasks/new_form']

  events:
    'click [control=select]'       : -> @select(on);     false
    'click [control=deselect]'     : -> @select(off);    false
    'click [control=toggle-select]': -> @toggleSelect(); false

    'click [control=update]'       : -> @form(on);       false

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


  isFormActive: -> @formActive ?= no

  initFormView: ->
    view = new Lt.Views.Tasks.FormView model: @model
    view.on 'close', => @form(off)
    view

  form: (activate) ->
    if not activate and @isFormActive()
      @render()
      @formActive = no
    else if activate
      @formView ?= @initFormView()
      @$('.fields').hide()
      @formView.render().$el.insertAfter(@$('.fields'))
      @formActive = yes

    return this


  isSelected: -> @selected ?= no

  toggleSelect: ->
    @select(not @isSelected())

  select: (activate) ->
    @$el.toggleClass('selected', activate)
    @$('[control=select],[control=deselect]')
      .attr control: if activate then 'deselect' else 'select'
    @$('.additional-controls').toggle(activate)
    @selected = activate

    return this


  updateState: ->
    @$el.attr 'record-id': @model.id, 'record-state': @model.getState()

  render: ->
    @updateState()

    @$el.html @itemTemplate(@model.toJSON())
    @form(on) if @model.isNew()

    @select @isSelected()
    return this
