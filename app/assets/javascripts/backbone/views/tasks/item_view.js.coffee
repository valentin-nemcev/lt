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
      collection: @model.getSubtasks('composition')
      attributes:
        records: 'subtasks'

  newSubtask: ->
    @model.newSubtask('composition')

  delete: ->
    @model.destroy()

  toggleForm: (toggled = not @formToggled) ->
    @formView.$el.toggle(toggled)
    @$fields.toggle(not toggled)
    @formToggled = toggled

    return this

  toggleSelect: (toggled = not @selectToggled) ->
    @$task.toggleClass('selected', toggled)
    @$task.find('[control=select],[control=deselect]')
      .attr control: if toggled then 'deselect' else 'select'
    showControls = toggled and @model.getState() isnt 'new'
    @$task.find('.additional-controls').toggle(showControls)
    @selectToggled = toggled

    return this

  changeState: ->
    @$el.attr 'record-id': @model.id, 'record-state': @model.getState()
    @toggleSelect(@model.getState() is 'new')

  change: ->
    objective = @model.get('objective') || ''
    $objective = @$fields.find('[field=objective]')
    if objective.match(/\S/)
      @$emptyObjective.detach()
      $objective.text(objective)
    else
      $objective.text('')
      @$emptyObjective.appendTo($objective)

    @$el.attr
      'task-type':  @model.get('type')
      'task-state': @model.get('state')

    @$task.find('[control=new-subtask]').toggle(@model.get('type') is 'project')
    @subtasksView.$el.toggle @model.get('type') is 'project'

  render: ->
    @$el.html @template()
    @$task = @$el.children('.task')
    @$fields = @$task.children('.fields')

    @formView.render().$el.insertAfter(@$fields)
    @toggleForm @model.isNew()

    $emptyItem = @$el.children('.empty').detach()
    @subtasksView.render($emptyItem: $emptyItem).$el.appendTo @$el
    @$emptyObjective = @$fields.find('[field=objective] .empty')

    @toggleSelect off
    @changeState()
    @change()

    return this
