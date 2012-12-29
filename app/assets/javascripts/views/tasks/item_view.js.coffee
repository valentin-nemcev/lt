Views = Lt.Views.Tasks ||= {}

class Lt.Views.Tasks.ItemView extends Backbone.View

  template: JST['templates/tasks/item']

  events:
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
    @model.get('type') is 'project' and @model.get('computed_state') is 'underway'

  toggleSubtasks: (toggled = not @subtasksToggled) ->
    toggled = no unless @hasSubtasks
    @subtasksToggled = toggled

    @subtasksView.$el.toggleClass('hidden', not toggled)
    @updateSubtaskControls()

  toggleForm: (toggled = not @formToggled) ->
    @formToggled = toggled

    @formView.$el.toggleClass('hidden', not toggled)
    @$fields.toggleClass('hidden', toggled)
    @$controls.toggleClass('hidden', toggled)
    @$task.toggleClass('updated', toggled)
    @formView.render() if toggled
    # Clear selection after double click
    window?.getSelection().removeAllRanges() unless toggled
    @toggleSelect off

    return this

  toggleSelect: (toggled = not @selectToggled) ->
    @selectToggled = toggled

    @$task.toggleClass('selected', toggled)
    @$controls.toggleClass('hidden', @formToggled or not toggled)
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
      'task-computed-state': @model.get('computed_state')

    @$task.find('[field=subtask-count]').text(@model.get('subtask_count'))
    @hasSubtasks = !!@model.get('subtask_count')
    @updateSubtaskControls()

    @subtasksView.$el.toggleClass('hidden', @model.get('type') isnt 'project')
    @toggleSelect(@model.isNew())

  updateSubtaskControls: ->
    @$showSubtasks ?= @$task.find('[control=show-subtasks]')
    @$hideSubtasks ?= @$task.find('[control=hide-subtasks]')
    @$showSubtasks.toggleClass('hidden', !(@hasSubtasks and not @subtasksToggled))
    @$hideSubtasks.toggleClass('hidden', !(@hasSubtasks and @subtasksToggled))

  render: ->
    @$el.html @template()
    @$task = @$el.children('.task')
    @$fields = @$task.children('.fields')
    @$controls = @$task.children('.controls')
    @$fields.find('[field=objective]').on
      'click'      : => @toggleSubtasks()  ; false
      # 'dblclick'   : => @toggleForm(on)    ; false
    @$task.on
      'mouseenter' : => @toggleSelect(on)  ; false
      'mouseleave' : => @toggleSelect(off) ; false



    @formView.$el.appendTo(@$task)
    @toggleForm @model.isNew()

    $emptyItem = @$el.children('.empty').detach()
    @subtasksView.render($emptyItem: $emptyItem).$el.appendTo @$el
    @$emptyObjective = @$fields.find('[field=objective] .empty')

    @toggleSelect off
    @change()

    @toggleSubtasks(@subtasksAreShown())


    return this
