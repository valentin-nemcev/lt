Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.ItemView extends Backbone.View
  itemTemplate    : JST['backbone/templates/tasks/item']
  newFormTemplate : JST['backbone/templates/tasks/new_form']

  events:
    'dblclick' : 'edit'
    'submit form': (ev) -> ev.preventDefault(); @save()

  initialize: ->
    @model.bind 'change', @render, @
    @model.bind 'all', -> console.log arguments

  edit: (ev) ->
    ev.preventDefault()
    ev.stopPropagation()
    $(@el).trigger('editItem', [@model.cid])
    return

  save: ->
    attrs = {}
    for {name: name, value: value} in @$('form').serializeArray()
      attrs[name] = value
    @model.save(attrs)
    return this

  render: ->
    if @model.changed['id']?
      @$el.addClass('created')

    if @model.isNew()
      $(@el).html @newFormTemplate(@model.toJSON())
      @$el.removeAttr('record-id')
    else
      $(@el).html @itemTemplate(@model.toJSON())
      @$el.attr('record-id', @model.id)

    $(@el).toggleClass('completed', @model.isCompleted())
    return this
