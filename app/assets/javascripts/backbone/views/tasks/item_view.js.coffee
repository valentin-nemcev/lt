Lt.Views.Tasks ||= {}

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

    @model.bind 'change changeState', @updateIds, @

    @formView = new Lt.Views.Tasks.FormView model: @model
    @formView.on 'close', => @toggleForm(off)

  newSubtask: ->
    @model.collection.add project_id: @model.id

  delete: ->
    @model.destroy()

  toggleForm: (toggled = not @formToggled) ->
    @formView.$el.toggle(toggled)
    @$('.fields').toggle(not toggled)
    @formToggled = toggled

    return this

  toggleSelect: (toggled = not @selectToggled) ->
    @$el.toggleClass('selected', toggled)
    @$('[control=select],[control=deselect]')
      .attr control: if toggled then 'deselect' else 'select'
    @$('.additional-controls').toggle(toggled)
    @selectToggled = toggled

    return this

  updateIds: =>
      id = @model.id
      project_id = @model.get('project_id')
      @$('.ids').text (project_id and "#{project_id} → " or "") + (id or "new")


  changeState: ->
    @$el.attr 'record-id': @model.id, 'record-state': @model.getState()

  change: ->
    @$('[field=objective]').text @model.get('objective')
    @$el.attr 'task-type': @model.get('type')

  render: ->
    @$el.html @template()
    @changeState()
    @change()
    @updateIds()

    @formView.render().$el.insertAfter(@$('.fields'))
    @toggleForm @model.isNew()

    @toggleSelect off
    return this
