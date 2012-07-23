Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Lt.Views.List.EditableListView
  Views: Views

  itemName: 'task'

  attributes:
    widget: 'tasks'

  initialize: ->
    super
    @state = @options.state
    @state.bind 'change:show_completed', @showCompleted, @

  events: ->
    _.extend super,
      'change .show-completed input' : (ev) =>
        @state.save show_completed: $(ev.currentTarget).prop('checked')

  buildItem: (model) ->
    @toggleCompletedVisibility(model, super)

  showCompleted: (state, showingCompleted) ->
    @$('.show-completed input').prop('checked', showingCompleted)
    for task in @collection.models
      @toggleCompletedVisibility(task, @getItem(task))

    return

  toggleCompletedVisibility: (model, item) ->
    $(item).toggle(not model.isCompleted() or @state.get('show_completed'))


