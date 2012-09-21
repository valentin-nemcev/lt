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

    # @subtasksView = new Views.ListView
    #   collection: @model.subtasksCollection
    #   attributes:
    #     records: 'subtasks'

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
    @$fields.find('[field=objective]').text @model.get('objective')
    @$el.attr
      'task-type':  @model.get('type')
      'task-state': @model.get('state')

    @$task.find('[control=new-subtask]').toggle(@model.get('type') is 'project')
    # @subtasksView.$el.toggle @model.get('type') is 'project'

  render: ->
    @$el.html @template()
    @$task = @$el.children('.task')
    @$fields = @$task.children('.fields')

    @formView.render().$el.insertAfter(@$fields)
    @toggleForm @model.isNew()

    $emptyItem = @$el.children('.empty').detach()
    # @subtasksView.render($emptyItem: $emptyItem).$el.appendTo @$el

    @toggleSelect off
    @changeState()
    @change()

    return this
