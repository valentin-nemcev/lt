Views = Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.ItemView extends Backbone.View

  template: JST['templates/tasks/item']

  events:
    'click [control=update]'       : -> @toggleForm(on)     ; false
    'click [control=show-subtasks]': -> @toggleSubtasks(on) ; false
    'click [control=hide-subtasks]': -> @toggleSubtasks(off); false

    'click [control=new-subtask]'  : -> @newSubtask()       ; false

  initialize: ->
    @model.on {
      'change:id'                   : @changeId
      'change:type'                 : @changeType
      'change:computed_state'       : @changeComputedState
      'change:subtasks_composition' : @changeSubtasks
      'change:objective'            : @changeObjective
    }, this

    @changeAll = ->
      @changeId()
      @changeType()
      @changeComputedState()
      @changeSubtasks()
      @changeObjective()

    @formView = new Views.FormView model: @model, mainView: @options.mainView
    @formView.on 'close', => @toggleForm(off)

    @subtasksView = new Views.ListView
      collection: @model.getSubtasks('composition')
      allItemViews: @options.allItemViews
      attributes:
        records: 'subtasks'

  newSubtask: ->
    @model.newSubtask('composition')
    @hasSubtasks = yes
    @toggleSubtasks on

  subtasksAreShown: ->
    @model.get('type') is 'project' and @model.get('computed_state') is 'underway'

  toggleSubtasks: (toggled = not @subtasksToggled) ->
    toggled = no unless @hasSubtasks
    @subtasksToggled = toggled

    @subtasksView.$el.toggleClass('hidden', not toggled)
    @updateSubtaskControls()

  toggleForm: (toggled = not @formToggled) ->
    @formToggled = toggled

    @formView.$el.toggleClass('hidden', not toggled)
    @formView.render() if toggled

    @$fields.toggleClass('hidden', toggled)
    @$controls.toggleClass('hidden', toggled)
    @$task.toggleClass('updated', toggled)

    # Clear selection after double click
    if window.getSelection?
      window.getSelection().removeAllRanges() unless toggled

    @toggleSelect off

    return this

  toggleSelect: (toggled = not @selectToggled) ->
    @selectToggled = toggled

    @$task.toggleClass('selected', toggled)
    @$task.toggleClass('selection-mode', toggled and @selectionModeToggled)
    @$controls.toggleClass('hidden', @formToggled or not toggled)
    return this

  changeId: ->
    @$el.attr 'record-id': @model.id
    @toggleSelect(@model.isNew())

  changeObjective: ->
    objective = @model.get('objective') || ''
    @$objectiveField ?= @$fields.find('[field=objective]')
    if objective.match(/\S/)
      @$emptyObjective.detach()
      @$objectiveField.text(objective)
    else
      @$objectiveField.text('')
      @$emptyObjective.appendTo(@$objectiveField)

  changeType: ->
    @$el.attr 'task-type': @model.get('type')

  changeComputedState: ->
    @$el.attr 'task-computed-state': @model.get('computed_state')


  changeSubtasks: (model, subtasks) ->
    count = @model.get('subtasks_composition')?.length
    @$subtaskCountField ?= @$task.find('[field=subtask-count]')
    @$subtaskCountField.text(count)
    @hasSubtasks = !!count
    @subtasksView.$el.toggleClass('hidden', not @hasSubtasks)
    @updateSubtaskControls()

  updateSubtaskControls: ->
    @$showSubtasks ?= @$task.find('[control=show-subtasks]')
    @$hideSubtasks ?= @$task.find('[control=hide-subtasks]')
    @$showSubtasks.toggleClass('hidden', !(@hasSubtasks and not @subtasksToggled))
    @$hideSubtasks.toggleClass('hidden', !(@hasSubtasks and @subtasksToggled))

  toggleSelectionMode: (toggled = not @selectionModeToggled, callback) ->
    @selectionModeToggled = toggled
    @selectionModeCallback = callback

  render: ->
    @$el.html @template()

    @$task     = @$el.children('.task')
    @$fields   = @$task.children('.fields')
    @$controls = @$task.children('.controls')

    @$fields.find('[field=objective]').click =>
      if @selectionModeToggled
        @selectionModeCallback()
      else
        @toggleSubtasks()
      return false

    @$task.on
      'mouseenter': => @toggleSelect(on)  ; false
      'mouseleave': => @toggleSelect(off) ; false

    @formView.$el.appendTo(@$task)
    @toggleForm @model.isNew()

    @subtasksView.render(
      $emptyItem:    @$el.children('.empty').detach()
      $archivedItem: @$el.children('.archived').detach()
    ).$el.appendTo @$el

    @$emptyObjective = @$fields.find('[field=objective] .empty')

    @toggleSelect off
    @toggleSelectionMode off
    @changeAll()

    @toggleSubtasks(@subtasksAreShown())

    return this
