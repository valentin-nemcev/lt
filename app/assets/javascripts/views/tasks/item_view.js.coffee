Views = Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.ItemView extends Backbone.View

  template: JST['templates/tasks/item']

  events:
    'click [control=select]'       : -> @toggleSelect(on)   ; false
    'click [control=deselect]'     : -> @toggleSelect(off)  ; false
    'deselect'                     : -> @toggleSelect(off)  ; false
    'click [control=toggle-select]': -> @toggleSelect()     ; false

    'click [control=update]'       : -> @toggleForm(on)     ; false
    'click [control=show-subtasks]': -> @toggleSubtasks(on) ; false
    'click [control=hide-subtasks]': -> @toggleSubtasks(off); false

    'click [control=new-subtask]'  : -> @newSubtask()       ; false

  initialize: ->
    @model.bind 'change', @change, @

    @formView = new Views.FormView model: @model
    @formView.on 'close', => @toggleForm(off)

    @subtasksView = new Views.ListView
      collection: @model.getSubtasks('composition')
      allItemViews: @options.allItemViews
      attributes:
        records: 'subtasks'

  newSubtask: ->
    @model.newSubtask('composition')
    @toggleSubtasks on

  subtasksAreShown: ->
    @model.get('type') is 'project' and @model.get('state') is 'underway'

  toggleSubtasks: (toggled) ->
    @subtasksView.$el.toggle(toggled)
    @$task.find('[control=show-subtasks]').toggle(not toggled)
    @$task.find('[control=hide-subtasks]').toggle(toggled)

  toggleForm: (toggled = not @formToggled) ->
    @formView.$el.toggle(toggled)
    @$fields.toggle(not toggled)
    @$task.toggleClass('updated', toggled)
    @formView.render() if toggled
    # Clear selection after double click
    window?.getSelection().removeAllRanges() unless toggled
    @formToggled = toggled
    @toggleSelect off

    return this

  toggleSelect: (toggled = not @selectToggled) ->
    @$task.toggleClass('selected', toggled)
    @$task.find('[control=select],[control=deselect]')
      .attr control: if toggled then 'deselect' else 'select'
    showControls = toggled and !@model.isNew()
    @$task.find('.additional-controls').toggle(showControls)

    if toggled
      @$el.closest('[widget=tasks]')
        .find('.task').not(@$task).trigger('deselect')

    @selectToggled = toggled
    return this

  change: ->
    @$el.attr 'record-id': @model.id

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

    @subtasksView.$el.toggle @model.get('type') is 'project'
    @toggleSelect(@model.isNew())

  render: ->
    @$el.html @template()
    @$task = @$el.children('.task')
    @$task.on 'dblclick', => @toggleForm(on); false
    @$fields = @$task.children('.fields')

    @formView.$el.insertAfter(@$fields)
    @toggleForm @model.isNew()

    $emptyItem = @$el.children('.empty').detach()
    @subtasksView.render($emptyItem: $emptyItem).$el.appendTo @$el
    @$emptyObjective = @$fields.find('[field=objective] .empty')

    @toggleSelect off
    @change()

    @toggleSubtasks(@subtasksAreShown())


    return this
