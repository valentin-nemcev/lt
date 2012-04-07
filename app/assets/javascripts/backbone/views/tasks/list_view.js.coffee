Views = Lt.Views.Tasks ||= {}

class Views.ListView extends Lt.Views.List.ListView
  Views: Views

  itemName: 'task'

  initialize: ->
    super
    @showCompleted yes

  events: ->
    _.extend super,
      'change .show-completed input' : (ev) =>
        @showCompleted $(ev.currentTarget).prop('checked')

  buildItem: (model) ->
    @toggleCompletedVisibility(model, super)

  showCompleted: (showingCompleted) ->
    @showingCompleted = showingCompleted
    @$('.show-completed input').prop('checked', showingCompleted)
    @toggleCompletedVisibility(task, @getItem(task)) for task in @collection.models

  toggleCompletedVisibility: (model, item) ->
    item.toggle(not model.isCompleted() or @showingCompleted)


