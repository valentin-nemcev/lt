Views = Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.ItemView extends Backbone.View
  template: JST['backbone/templates/tasks/item']

  events:
    'click [control=select]'       : -> @toggleSelect(on)  ; false
    'click [control=deselect]'     : -> @toggleSelect(off) ; false
    'click [control=toggle-select]': -> @toggleSelect()    ; false

    'click [control=update]'       : -> @toggleForm(on)    ; false

    'click [control=new-subtask]'  : -> @newSubtask()      ; false
    'click [control=delete]'       : -> @delete()          ; false

  initialize: ->
    @model.bind 'change', @change, @
    @model.bind 'changeState', @changeState, @

    @formView = new Views.FormView model: @model
    @formView.on 'close', => @toggleForm(off)

    @subtasksView = new Views.ListView
      collection: @model.subtasksCollection
      attributes:
        records: 'subtasks'

  newSubtask: ->
    @model.collection.add project_id: @model.id

  delete: ->
    @model.destroy()

  toggleForm: (toggled = not @formToggled) ->
    @formView.$el.toggle(toggled)
    @$fields.toggle(not toggled)
    @formToggled = toggled

    return this

  toggleSelect: (toggled = not @selectToggled) ->
    @$el.toggleClass('selected', toggled)
    @$('[control=select],[control=deselect]')
      .attr control: if toggled then 'deselect' else 'select'
    @$('.additional-controls').toggle(toggled)
    @selectToggled = toggled

    return this

  changeState: ->
    @$el.attr 'record-id': @model.id, 'record-state': @model.getState()

  change: ->
    @$fields.find('[field=objective]').text @model.get('objective')
    @$el.attr 'task-type': @model.get('type')
    @subtasksView.$el.toggle @model.get('type') is 'project'

  render: ->
    @$el.html @template()
    @$fields = @$el.children('.fields')

    @formView.render().$el.insertAfter(@$fields)
    @toggleForm @model.isNew()

    $emptyItem = @$el.children('.empty').detach()
    @subtasksView.render($emptyItem: $emptyItem).$el.appendTo @$el

    @changeState()
    @change()

    @toggleSelect off
    return this
